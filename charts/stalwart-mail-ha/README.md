# stalwart-mail-ha

Helm chart for [Stalwart Mail Server](https://stalw.art) running multi-replica with all state on external backends.

[![ArtifactHub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/l4g)](https://artifacthub.io/packages/search?repo=l4g)

Pinned to Stalwart **0.16.3**.
Stalwart 0.16 stores configuration as JMAP records inside the data store, so the on-disk `config.json` rendered by this chart only describes the data store wiring.
SMTP listeners, blob store, DKIM, directories, rate limits, and everything else are managed at runtime through the Stalwart WebUI or [`stalwart-cli apply`](https://stalw.art/docs/management/cli/apply).

## Architecture

```
                        ┌────────────────────────────┐
                        │        Kubernetes          │
                        │                            │
   ───── 25/465/587 ───▶│   Service: <name>-mail     │
   ───── 143/993 ──────▶│   (LoadBalancer / NLB)     │─┐
   ───── 4190 ─────────▶│                            │ │
                        └────────────────────────────┘ │
                                                       ▼
                              ┌──────────────────────────────────┐
                              │   Deployment: stalwart-mail      │
                              │   replicas=N, anti-affinity      │
                              │                                  │
                              │   Pod 1   Pod 2   Pod 3   ...    │
                              │     │       │       │            │
                              └─────┼───────┼───────┼────────────┘
                                    │       │       │
   ┌── HTTP/JMAP/Admin ──┐          │       │       │
   │ Service: <name>-http│◀─────────┴───────┴───────┘
   │ (ClusterIP, 8080)   │                 │
   └──────────┬──────────┘                 │
              │                            │
              ▼                            ▼
        Ingress (TLS)            ┌──────────────────────┐
                                 │  Data store          │  (config.json)
                                 │  Postgres / MySQL    │
                                 │  FoundationDB / Rocks│
                                 └──────────────────────┘
                                            │
                                            ▼ (configured at runtime)
                                 ┌──────────────────────┐
                                 │ Blob: S3 / Azure / FS│
                                 │ Lookup: Redis        │
                                 │ FTS: ES / Meilisearch│
                                 │ Directory: LDAP/SQL  │
                                 └──────────────────────┘
```

## Quick start

```bash
helm repo add l4g https://l4gdev.github.io/helm-charts
helm install mail l4g/stalwart-mail-ha \
  -f charts/stalwart-mail-ha/examples/values-minimal.yaml
```

The minimal values use RocksDB on a single replica.
For production HA, start with `examples/values-ha.yaml` (Postgres + S3 + Redis + LDAP).

## First-boot bootstrap

Stalwart 0.16 stores its configuration inside the data store and auto-bootstraps roles, listeners, queues, and the web UI Application bundle on first start. It does NOT create an initial admin Account, so you must inject a fallback admin via `STALWART_RECOVERY_ADMIN`. The chart wires this for you whenever `recovery.adminPassword` (or `recovery.existingSecret`) is set, regardless of `recovery.enabled`.

```bash
helm install mail l4g/stalwart-mail-ha \
  --set recovery.adminPassword=ChangeMe \
  -f my-values.yaml

# Wait for the pod to download the web UI bundle from
# github.com/stalwartlabs/webui/releases/latest/download/webui.zip,
# then log in as admin/ChangeMe at:
#   https://<your-ingress-host>/admin/
```

Inside the admin UI you create real Accounts, domains, directories, blob/lookup backends, and so on. Once a real admin Account exists you can drop `recovery.adminPassword` from the values file and roll the deployment to remove the fallback.

`recovery.enabled=true` is a separate emergency mode that sets `STALWART_RECOVERY_MODE=1`. It skips the bootstrap defaults and only exposes `/api/auth`, `/jmap`, and `/healthz` — the web UI is NOT loaded. Use it to recover from a misconfigured data store, not for first boot.

## Cross-origin webmail (Bulwark, JMAP clients)

Browsers reject credentialed CORS requests when the JMAP server replies with `Access-Control-Allow-Origin: *`. Stalwart 0.16 emits exactly that and has no built-in option for `Allow-Credentials: true`, so a webmail running on a different hostname will fail with `The server is reachable but is blocking cross-origin requests`.

Two ways to make it work, in order of preference:

1. **Override at the ingress.** Add `nginx.ingress.kubernetes.io/enable-cors: "true"` plus `cors-allow-origin`, `cors-allow-credentials`, `cors-allow-methods`, and `cors-allow-headers` annotations to the Stalwart ingress. ingress-nginx handles preflight itself and replaces Stalwart's wildcard reply with a per-origin one. See `examples/values-ha.yaml` for the full annotation set.
2. **Configure it in Stalwart.** In the admin UI go to Settings → HTTP, set `usePermissiveCors=false`, and add `responseHeaders` containing `Access-Control-Allow-Origin: <webmail-origin>` and `Access-Control-Allow-Credentials: true`. The values live in the data store along with the rest of the config.

A same-origin deployment (webmail on `https://mail.example.com/webmail/`, Stalwart on `https://mail.example.com/`) avoids the issue entirely. Bulwark supports a subpath via `NEXT_PUBLIC_BASE_PATH`.

## Values

### Top-level

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `2` | Pod replicas. RocksDB / SQLite force single replica. |
| `image.repository` | `docker.io/stalwartlabs/stalwart` | Container image. |
| `image.tag` | `""` | Defaults to `Chart.appVersion`. |
| `image.variant` | `""` | Set `fdb` for FoundationDB image; auto-selected when `dataStore.type=foundationdb`. |
| `publicUrl` | `https://mail.example.com` | Wired into `STALWART_PUBLIC_URL`. |

### Data store

| Key | Default | Description |
| --- | --- | --- |
| `dataStore.type` | `postgres` | One of `postgres`, `mysql`, `foundationdb`, `rocksdb`, `sqlite`. |
| `dataStore.postgres.host` | `pg-cluster.example.svc` | Postgres host. |
| `dataStore.postgres.existingSecret` | `""` | Secret containing the Postgres password. |
| `dataStore.postgres.existingSecretKey` | `STALWART_STORE_PG_PASSWORD` | Key inside the Secret. |
| `dataStore.rocksdb.persistence.size` | `20Gi` | PVC size for embedded RocksDB. |

### Listeners

Each listener compiles to a `containerPort` and a `Service` port.
Server-side binding (which protocol speaks on which port) is part of the runtime configuration applied through `stalwart-cli`.

| Listener | Default | Port |
| --- | --- | --- |
| `smtp` | enabled | 25 |
| `submission` | enabled | 587 |
| `submissions` | enabled | 465 |
| `imap` | enabled | 143 |
| `imaps` | enabled | 993 |
| `pop3` | disabled | 110 |
| `pop3s` | disabled | 995 |
| `managesieve` | enabled | 4190 |
| `http` | enabled | 8080 |

### Optional resources

Each is gated behind `<resource>.enabled`:

- `ingress` — HTTP/JMAP/admin only, multi-host TLS supported.
- `metrics.serviceMonitor` — Prometheus scrape, supports bearer-token auth.
- `networkPolicy` — namespace-level ingress, DNS + outbound SMTP egress.
- `podDisruptionBudget` — `minAvailable` or `maxUnavailable`.
- `autoscaling` — HPA on CPU and / or memory.

### Required Secret keys

The chart never creates Secrets containing credentials; reference existing Secrets through `existingSecret`.
Keys it expects to find:

| Backend | Env var the chart maps into the container | Default key |
| --- | --- | --- |
| `dataStore.postgres` | `STALWART_STORE_PG_PASSWORD` | configurable via `existingSecretKey` |
| `dataStore.mysql` | `STALWART_STORE_MYSQL_PASSWORD` | configurable via `existingSecretKey` |
| `recovery` | `STALWART_RECOVERY_PASSWORD` | configurable via `existingSecretKey` |

For blob/lookup/directory credentials, drop them in a Secret and add it to `extraEnvFrom`; the runtime apply plan can reference them via `{"@type":"EnvVar","envVar":"..."}`.

## Upgrading

This chart targets Stalwart **0.16.x** which is **not compatible** with the configuration files of 0.15 and earlier.
If you are coming from 0.15, follow the upstream [v0.16 upgrading guide](https://github.com/stalwartlabs/stalwart/blob/main/UPGRADING/v0_16.md) first; the chart cannot perform that migration for you.

For 0.16.x → 0.16.y upgrades a `helm upgrade` is sufficient.

## What's not in this chart

- The Stalwart server-side configuration (SMTP listeners, DKIM, queues, rate limits).
  Apply via `stalwart-cli apply` — see `examples/`.
- A bundled Postgres / Redis / S3.
  Bring your own; this chart is intentionally generic.
- A built-in `stalwart-cli` Job.
  Bootstrap is run by an operator once, not on every upgrade.
