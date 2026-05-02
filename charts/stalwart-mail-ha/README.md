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

For a brand-new deployment, run with `recovery.enabled=true`. Only the HTTP listener will be exposed and a temporary admin is provisioned. Apply your configuration and disable recovery mode:

```bash
helm install mail l4g/stalwart-mail-ha \
  --set recovery.enabled=true \
  --set recovery.adminPassword=ChangeMe \
  -f my-values.yaml

kubectl port-forward svc/mail-stalwart-mail-ha-http 8080:8080 &
export STALWART_URL=http://127.0.0.1:8080
export STALWART_USER=admin
export STALWART_PASSWORD=ChangeMe
stalwart-cli apply --file my-bootstrap-plan.json

helm upgrade mail l4g/stalwart-mail-ha \
  --set recovery.enabled=false \
  -f my-values.yaml
```

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
