# L4G Helm Charts

A collection of production-ready Helm charts for self-hosted services.

[![ArtifactHub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/l4g)](https://artifacthub.io/packages/search?repo=l4g)

## Available Charts

| Chart | App version | What it deploys |
| --- | --- | --- |
| **[bulwark-mail](charts/bulwark-mail)** | 1.6.0 | [Bulwark](https://github.com/bulwarkmail/webmail) JMAP webmail. Native Ingress, multi-host TLS, OIDC, optional ServiceMonitor / NetworkPolicy / PVC for settings sync. |
| **[chibisafe](charts/chibisafe)** | latest | [Chibisafe](https://github.com/chibisafe/chibisafe) file vault and sharing platform. |
| **[ente-photos](charts/ente-photos)** | latest | [Ente Photos](https://github.com/ente-io/ente) end-to-end encrypted photo storage. Bundled museum API + photos / albums / accounts / auth / cast / share frontends; optional custom CA mount, ServiceMonitor, NetworkPolicy, PDB. |
| **[overpass-api](charts/overpass-api)** | latest | [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) — read-only OpenStreetMap query service. |
| **[stalwart-mail-ha](charts/stalwart-mail-ha)** | 0.16.3 | [Stalwart](https://github.com/stalwartlabs/stalwart) mail server (SMTP, IMAP, JMAP, CalDAV/CardDAV) with multi-replica HA. Postgres / MySQL / FoundationDB / RocksDB / SQLite data stores, separate mail and HTTP Services, optional Ingress / ServiceMonitor / NetworkPolicy / PDB / HPA. |

## Usage

### Add the Helm repository

```bash
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update
```

### Install a chart

```bash
helm install bulwark   l4gdev/bulwark-mail     -f my-values.yaml
helm install chibisafe l4gdev/chibisafe        -f my-values.yaml
helm install ente      l4gdev/ente-photos      -f my-values.yaml
helm install overpass  l4gdev/overpass-api     -f my-values.yaml
helm install mail      l4gdev/stalwart-mail-ha -f my-values.yaml
```

Each chart ships an `examples/` directory with reference values (minimal, HA, OIDC, LDAP, etc.).
Start there.

### Search

```bash
helm search repo l4gdev
```

## Development

### Prerequisites

- Kubernetes 1.23+
- Helm 3.8+

### Local validation

```bash
helm lint charts/<chart-name>
helm template test charts/<chart-name> -f charts/<chart-name>/examples/values-minimal.yaml \
  | kubectl apply --dry-run=client -f -
```

CI (`.github/workflows/lint-test.yaml`) runs `ct lint` against changed charts on every PR.

## Contributing

1. Fork
2. Branch (`feature/...`)
3. Update / add chart, bump `Chart.yaml` `version` and the `artifacthub.io/changes` annotation
4. Run `helm lint` and `helm template ... | kubectl apply --dry-run=client -f -`
5. Open a pull request

## License

Charts are licensed under the MIT License unless otherwise noted.
Individual applications deployed by these charts have their own licenses (AGPL-3.0 in most cases).

## Links

- [Repository](https://github.com/l4gdev/helm-charts)
- [Issues](https://github.com/l4gdev/helm-charts/issues)
- [Artifact Hub](https://artifacthub.io/packages/search?repo=l4g)

## Disclaimer

Provided as-is, no warranties.
