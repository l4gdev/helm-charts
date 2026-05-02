# bulwark-mail

Helm chart for [Bulwark Mail](https://github.com/bulwarkmail/webmail) — a self-hosted JMAP webmail.

[![ArtifactHub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/l4g)](https://artifacthub.io/packages/search?repo=l4g)

Pinned to Bulwark **1.6.0**.
The chart deploys a stateless Bulwark Deployment behind a native Kubernetes `Ingress` with multi-host TLS support, suitable for serving multiple webmail domains from a single deployment.

## Architecture

```
                   ┌──────────────────────────────────┐
                   │        Ingress (nginx)           │
                   │   mail.example.com               │
                   │   webmail.example.com            │
                   │   tls: bulwark-tls (multi-SAN)   │
                   └──────────────┬───────────────────┘
                                  │
                   ┌──────────────▼───────────────────┐
                   │     Service: bulwark-mail        │
                   │     ClusterIP, :80 → :3000       │
                   └──────────────┬───────────────────┘
                                  │
                   ┌──────────────▼───────────────────┐
                   │   Deployment: bulwark-mail       │
                   │   replicas=N, anti-affinity      │
                   │                                  │
                   │   Pod 1   Pod 2   Pod 3          │
                   │     │       │       │            │
                   └─────┼───────┼───────┼────────────┘
                         │       │       │
                         └───────┴───────┴───▶  JMAP_SERVER_URL
                                                 (Stalwart)
```

## Quick start

```bash
helm repo add l4g https://l4gdev.github.io/helm-charts
helm install bulwark l4g/bulwark-mail \
  --set config.jmapServerUrl=https://mail.example.com
```

Or with a values file:

```bash
helm install bulwark l4g/bulwark-mail \
  -f charts/bulwark-mail/examples/values-minimal.yaml
```

## Values

### Top-level

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `2` | Pod replicas. Bulwark is stateless. |
| `image.repository` | `ghcr.io/bulwarkmail/webmail` | Container image. |
| `image.tag` | `""` | Defaults to `Chart.appVersion`. |
| `service.type` | `ClusterIP` | |
| `service.port` | `80` | Service port. |
| `service.targetPort` | `3000` | Container listen port (matches `config.port`). |

### Bulwark configuration

Each value under `config` maps to one upstream env var (`JMAP_SERVER_URL`, `APP_NAME`, etc.).
Empty strings are skipped, so unsetting a branding value falls back to the upstream default.

| Key | Maps to | Required |
| --- | --- | --- |
| `config.jmapServerUrl` | `JMAP_SERVER_URL` | yes |
| `config.hostname` | `HOSTNAME` | yes (default `0.0.0.0`) |
| `config.port` | `PORT` | yes (default `3000`) |
| `config.appName` | `APP_NAME` | no |
| `config.loginCompanyName` | `LOGIN_COMPANY_NAME` | no |
| `config.allowCustomJmapEndpoint` | `ALLOW_CUSTOM_JMAP_ENDPOINT` | no |
| `config.stalwartFeatures` | `STALWART_FEATURES` | no |

The full list lives in `values.yaml` under `config:`.

### OIDC

Set `oidc.enabled: true` and reference an existing Secret holding the client secret:

```yaml
oidc:
  enabled: true
  clientId: bulwark-webmail
  issuerUrl: "https://idp.example.com/application/o/bulwark/"
  existingClientSecret: bulwark-oidc
  existingClientSecretKey: client-secret
```

The chart mounts the secret at `/etc/bulwark/oauth-client-secret` and points `OAUTH_CLIENT_SECRET_FILE` at it, so the value never lands in an env var.

### Session secret

`session.existingSecret` references a Secret containing the cookie-encryption key.
If unset, the chart generates a random 64-character key on first install and stores it in `<release>-bulwark-mail-session`; subsequent upgrades preserve it via `lookup`.

### Ingress (multi-host TLS)

Group multiple hosts under one `tls[]` entry to share a SAN cert:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: mail.example.com
      paths:
        - path: /
          pathType: Prefix
    - host: webmail.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: bulwark-tls
      hosts:
        - mail.example.com
        - webmail.example.com
```

### Settings sync

By default Bulwark stores per-user settings server-side under `/app/data`.
The chart mounts it as `emptyDir` (per-pod, lost on restart).
For persistent settings, drop to a single replica and enable PVC:

```yaml
replicaCount: 1
settingsSync:
  enabled: true
  persistence:
    enabled: true
    size: 5Gi
```

### Optional resources

Each gated behind `<resource>.enabled`:

- `metrics.serviceMonitor` — Prometheus scrape on `/metrics`.
- `networkPolicy` — namespace-level ingress; egress to DNS and `jmapEgressPorts` only.
- `podDisruptionBudget`, `autoscaling`.

## Security

- Runs as non-root user 1000, read-only root filesystem, all capabilities dropped.
- Session secret and OIDC client secret are file-mounted, never env-injected.
- `automountServiceAccountToken: false`.

## Upgrading

`helm upgrade` is sufficient for any 1.x → 1.y bump within Bulwark.
This chart targets Bulwark 1.6.0; on rollback to a chart version pinning an older Bulwark, the new image features (subpath deployment, image attachment thumbnails, mobile-friendly admin) revert automatically.
