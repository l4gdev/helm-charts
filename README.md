# L4G Helm Charts

A collection of production-ready Helm charts for deploying various applications on Kubernetes.

## Available Charts

| Chart | Description |
|-------|-------------|
| **[chibisafe](charts/chibisafe)** | File vault and sharing platform for self-hosted file uploads |
| **[ente-photos](charts/ente-photos)** | End-to-end encrypted photo storage and backup platform |
| **[overpass-api](charts/overpass-api)** | Read-only API for querying OpenStreetMap data |

## Usage

### Add the Helm Repository

```bash
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update
```

### Install a Chart

```bash
# Install Chibisafe
helm install chibisafe l4gdev/chibisafe

# Install Ente Photos
helm install ente-photos l4gdev/ente-photos

# Install Overpass API
helm install overpass l4gdev/overpass-api

# Install with custom values
helm install myrelease l4gdev/<chart-name> -f custom-values.yaml
```

### Search Available Charts

```bash
helm search repo l4gdev
```

## Development

### Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

### Testing Charts Locally

```bash
# Lint a chart
helm lint charts/<chart-name>

# Test template rendering
helm template test charts/<chart-name>

# Install locally with dry-run
helm install test charts/<chart-name> --dry-run --debug
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart: `helm lint charts/<chart-name>`
5. Submit a pull request

## License

Charts are licensed under the MIT License unless otherwise noted.

Individual applications deployed by these charts may have different licenses.

## Links

- [Repository](https://github.com/l4gdev/helm-charts)
- [Report Issues](https://github.com/l4gdev/helm-charts/issues)
- [Artifact Hub](https://artifacthub.io/packages/search?repo=l4g)

## Disclaimer

The code is provided as-is with no warranties.
