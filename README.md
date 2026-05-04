# L4G Helm Charts

Production-ready Helm charts for self-hosted services.
This branch is the published Helm repository at <https://l4gdev.github.io/helm-charts>.

[![ArtifactHub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/l4g)](https://artifacthub.io/packages/search?repo=l4g)

## Add the repository

```bash
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update
helm search repo l4gdev
```

## Available charts

| Chart | App version | Source | What it deploys |
| --- | --- | --- | --- |
| `bulwark-mail` | 1.6.0 | [src](https://github.com/l4gdev/helm-charts/tree/main/charts/bulwark-mail) | [Bulwark](https://github.com/bulwarkmail/webmail) JMAP webmail. Native Ingress, multi-host TLS, OIDC, optional ServiceMonitor / NetworkPolicy / PVC for settings sync. |
| `chibisafe` | latest | [src](https://github.com/l4gdev/helm-charts/tree/main/charts/chibisafe) | [Chibisafe](https://github.com/chibisafe/chibisafe) file vault and sharing platform. |
| `ente-photos` | latest | [src](https://github.com/l4gdev/helm-charts/tree/main/charts/ente-photos) | [Ente Photos](https://github.com/ente-io/ente) end-to-end encrypted photo storage. Bundled museum API + photos / albums / accounts / auth / cast / share frontends; optional custom CA mount, ServiceMonitor, NetworkPolicy, PDB. |
| `overpass-api` | latest | [src](https://github.com/l4gdev/helm-charts/tree/main/charts/overpass-api) | [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) — read-only OpenStreetMap query service. |
| `stalwart-mail-ha` | 0.16.3 | [src](https://github.com/l4gdev/helm-charts/tree/main/charts/stalwart-mail-ha) | [Stalwart](https://github.com/stalwartlabs/stalwart) mail server (SMTP, IMAP, JMAP, CalDAV/CardDAV) with multi-replica HA. Postgres / MySQL / FoundationDB / RocksDB / SQLite data stores. |

## Install

```bash
helm install bulwark   l4gdev/bulwark-mail     -f my-values.yaml
helm install chibisafe l4gdev/chibisafe        -f my-values.yaml
helm install ente      l4gdev/ente-photos      -f my-values.yaml
helm install overpass  l4gdev/overpass-api     -f my-values.yaml
helm install mail      l4gdev/stalwart-mail-ha -f my-values.yaml
```

Every chart ships an `examples/` directory with reference values (minimal, HA, OIDC, LDAP, etc.) — start there.

## Compatibility

- Kubernetes 1.23+
- Helm 3.8+

## Links

- [Source repository](https://github.com/l4gdev/helm-charts)
- [Issues](https://github.com/l4gdev/helm-charts/issues)
- [Artifact Hub](https://artifacthub.io/packages/search?repo=l4g)

## License

Charts are MIT-licensed.
The applications deployed by these charts have their own licenses (mostly AGPL-3.0).

Provided as-is, no warranties.
