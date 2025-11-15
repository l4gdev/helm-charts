# Overpass API Helm Chart

Helm chart for deploying [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) - a powerful read-only API for querying OpenStreetMap data.

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/overpass-api)](https://artifacthub.io/packages/search?repo=overpass-api)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/l4gdev/helm-charts/blob/main/LICENSE)

## Features

- **Flexible Initialization** - Support for both clone (fast) and init (from-scratch) modes
- **Resource Presets** - Pre-configured sizes from city-level to full planet
- **Production Ready** - Security hardening, health probes, resource management
- **High Availability** - Pod disruption budgets, affinity rules, topology spread
- **Monitoring** - Prometheus ServiceMonitor integration
- **Extensible** - Extra volumes, environment variables, ConfigMaps/Secrets support

## Quick Start

```bash
# Add the Helm repository
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update

# Install with default settings (medium preset, clone mode)
helm install overpass l4gdev/overpass-api \
  --set config.cloneUrl="https://overpass-api.de/api/"

# Or install with a specific regional extract
helm install overpass l4gdev/overpass-api \
  --set config.mode=init \
  --set config.planetUrl="https://download.geofabrik.de/europe/poland-latest.osm.pbf" \
  --set resources.preset=small
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure
- Sufficient storage for OSM data (see [Resource Presets](#resource-presets))

## Installation

### Basic Installation

```bash
helm install overpass l4gdev/overpass-api
```

### Custom Values

```bash
helm install overpass l4gdev/overpass-api -f custom-values.yaml
```

### With Ingress

```bash
helm install overpass l4gdev/overpass-api \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=overpass.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

## Configuration

### Resource Presets

The chart provides pre-configured resource presets based on expected data coverage:

| Preset   | Use Case                  | CPU   | Memory | Storage |
|----------|---------------------------|-------|--------|---------|
| `micro`  | City-level extracts       | 1-2   | 2-4Gi  | 10Gi    |
| `small`  | Country-level extracts    | 2-4   | 8-16Gi | 50Gi    |
| `medium` | Multi-country regions     | 4-8   | 16-32Gi| 150Gi   |
| `large`  | Continental extracts      | 8-16  | 32-64Gi| 400Gi   |
| `xlarge` | Full planet database      | 16-32 | 64-128Gi| 1Ti    |
| `custom` | User-defined resources    | -     | -      | -       |

Example:

```yaml
resources:
  preset: small  # For Poland extract
```

### Operational Modes

#### Clone Mode (Recommended for faster initialization)

Copies data from an existing Overpass instance:

```yaml
config:
  mode: clone
  cloneUrl: "https://overpass-api.de/api/"
  diffUrl: "https://download.openstreetmap.fr/replication/europe/minute/"
```

Advantages: Faster (30 min - 2 hours), data arrives pre-indexed

#### Init Mode (From planet file)

Downloads and processes OSM data from scratch:

```yaml
config:
  mode: init
  planetUrl: "https://download.geofabrik.de/europe/poland-latest.osm.pbf"
  diffUrl: "https://download.openstreetmap.fr/replication/europe/poland/minute/"
```

Advantages: Full control over data source, no dependency on existing instance

### Common Configuration Examples

#### Regional Extract (Poland)

```yaml
resources:
  preset: small

config:
  mode: init
  planetUrl: "https://download.geofabrik.de/europe/poland-latest.osm.pbf"
  diffUrl: "https://download.openstreetmap.fr/replication/europe/poland/minute/"
  meta: "yes"
  compression: "lz4"
  fastcgiProcesses: 4
```

#### Continental Extract (Europe)

```yaml
resources:
  preset: large

config:
  mode: clone
  cloneUrl: "https://overpass-api.de/api/"
  diffUrl: "https://download.openstreetmap.fr/replication/europe/minute/"
  fastcgiProcesses: 8
  useAreas: true
```

#### Full Planet

```yaml
resources:
  preset: xlarge

config:
  mode: clone
  cloneUrl: "https://overpass-api.de/api/"
  diffUrl: "https://planet.openstreetmap.org/replication/minute/"
  fastcgiProcesses: 16
  useAreas: false  # Very resource-intensive for planet
```

## Parameters

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.storageClass` | Global storage class | `""` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Overpass API Docker image | `wiktorn/overpass-api` |
| `image.tag` | Image tag (defaults to chart appVersion) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Overpass Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.mode` | Operational mode: `clone` or `init` | `clone` |
| `config.meta` | Metadata handling: `yes`, `attic`, `no` | `yes` |
| `config.compression` | Database compression: `no`, `gz`, `lz4` | `lz4` |
| `config.fastcgiProcesses` | Number of FastCGI processes | `4` |
| `config.rateLimit` | Concurrent connections per IP | `2` |
| `config.maxTimeout` | Query timeout (seconds) | `1000` |
| `config.useAreas` | Enable area generation | `false` |
| `config.rulesLoad` | Area generation work/sleep ratio | `10` |
| `config.updateSleep` | Seconds between update checks | `3600` |
| `config.planetUrl` | Planet file URL (init mode) | `""` |
| `config.diffUrl` | Diff repository URL | `""` |
| `config.cloneUrl` | Clone source URL (clone mode) | `""` |
| `config.planetPreprocess` | Preprocessing command for planet file | `""` |
| `config.diffPreprocess` | Preprocessing command for diff updates | `""` |
| `config.cookieJar` | Cookie jar contents for authenticated downloads | `""` |
| `config.useOAuthCookie` | Enable OAuth cookie client | `false` |
| `config.stopAfterInit` | Stop container after initialization | `true` |
| `config.allowDuplicateQueries` | Allow duplicate queries from same IP | `false` |
| `config.healthcheck` | Custom health check command | `""` |

### Persistence

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.storageClass` | Storage class | `""` |
| `persistence.accessModes` | Access modes | `[ReadWriteOnce]` |
| `persistence.size` | Storage size (auto from preset) | `""` |
| `persistence.existingClaim` | Use existing PVC | `""` |

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.annotations` | Service annotations | `{}` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

### Monitoring

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.serviceMonitor.enabled` | Enable Prometheus ServiceMonitor | `false` |
| `monitoring.serviceMonitor.interval` | Scrape interval | `30s` |
| `monitoring.serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |

See [values.yaml](values.yaml) for complete parameter reference.

## Monitoring

### Health Probes

The chart includes health probes for service monitoring:

- **Liveness Probe:** Checks if the API is responsive
- **Readiness Probe:** Validates API availability for traffic
- **Startup Probe:** Handles initial startup delay

### Prometheus Integration

Enable Prometheus monitoring:

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: 30s
```

## Troubleshooting

### Check Initialization Status

```bash
# View init job status
kubectl get jobs overpass-init

# View init job logs
kubectl logs -f job/overpass-init

# Check if database is initialized
kubectl exec overpass-0 -- ls -la /db/.initialized
```

### Check StatefulSet Status

```bash
# View pod status
kubectl get pods -l app.kubernetes.io/name=overpass-api

# View pod logs
kubectl logs -f overpass-0

# Check resource usage
kubectl top pod overpass-0
```

### Common Issues

**Init job takes too long:**
- Clone mode: Check network connectivity to clone source
- Init mode: Expected for large extracts (hours to days for planet)
- Monitor progress: `kubectl logs -f job/overpass-init`

**Pod not starting:**
- Check PVC binding: `kubectl get pvc`
- Verify resource availability: `kubectl describe pod overpass-0`
- Review logs: `kubectl logs overpass-0`

**API queries failing:**
- Verify initialization completed: `kubectl exec overpass-0 -- ls /db/nodes.bin`
- Check probe status: `kubectl describe pod overpass-0`
- Review configuration: `kubectl get cm overpass -o yaml`

## Upgrading

```bash
helm upgrade overpass l4gdev/overpass-api
```

The chart uses safe defaults and preserves PVCs across upgrades.

## Uninstalling

```bash
# Uninstall the release
helm uninstall overpass

# Optionally delete PVC (data will be lost!)
kubectl delete pvc overpass
```

## Examples

See the [examples/](examples/) directory for complete configuration examples:

- [values-minimal.yaml](examples/values-minimal.yaml) - Minimal configuration
- [values-regional.yaml](examples/values-regional.yaml) - Regional extract setup
- [values-planet.yaml](examples/values-planet.yaml) - Full planet deployment

## Development

### Prerequisites

- Kubernetes cluster (minikube, kind, k3s, or cloud provider)
- kubectl configured
- Helm 3.2.0+

### Testing

```bash
# Lint the chart
helm lint charts/overpass-api

# Template rendering
helm template test charts/overpass-api

# Install locally
helm install test charts/overpass-api --dry-run --debug
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `helm lint charts/overpass-api`
5. Submit a pull request

## License

This Helm chart is licensed under the MIT License. See [LICENSE](https://github.com/l4gdev/helm-charts/blob/main/LICENSE) for details.

The Overpass API software itself is licensed under AGPL-3.0.

## Links

- [Overpass API Documentation](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Docker Image Source](https://github.com/wiktorn/Overpass-API)
- [Overpass API Upstream](https://github.com/drolbr/Overpass-API)
- [Chart Repository](https://github.com/l4gdev/helm-charts)
- [Report Issues](https://github.com/l4gdev/helm-charts/issues)

## Credits

Developed and maintained by L4G Team.

Based on the excellent work of:
- [wiktorn/Overpass-API](https://github.com/wiktorn/Overpass-API) - Docker image
- [drolbr/Overpass-API](https://github.com/drolbr/Overpass-API) - Overpass API software
- [OpenStreetMap Community](https://www.openstreetmap.org/)