# Chibisafe Helm Chart

A Helm chart for deploying [Chibisafe](https://chibisafe.app/) - a blazing fast file vault and sharing platform written in TypeScript.

## Description

Chibisafe is a modern, self-hosted file uploader and sharing service that supports:

- Chunked uploads for large files
- Album creation and sharing
- URL shortening
- User management with quotas
- S3-compatible storage integration
- Public, private, or invite-only modes
- RESTful API for programmatic access

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (for persistence)

## Installation

### Add the Helm Repository

```bash
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update
```

### Install the Chart

```bash
# Install with default values
helm install chibisafe l4gdev/chibisafe

# Install with custom values
helm install chibisafe l4gdev/chibisafe -f my-values.yaml

# Install in a specific namespace
helm install chibisafe l4gdev/chibisafe -n chibisafe --create-namespace
```

### Install from Source

```bash
git clone https://github.com/l4gdev/helm-charts.git
cd helm-charts/charts/chibisafe
helm install chibisafe .
```

## Architecture

This chart deploys Chibisafe as a single pod with three containers:

```
┌─────────────────────────────────────────────────────┐
│                      Pod                            │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────┐  │
│  │  Frontend   │ │   Backend   │ │    Caddy     │  │
│  │    :8001    │ │    :8000    │ │     :80      │──┼──→ Service → Ingress
│  └─────────────┘ └─────────────┘ └──────────────┘  │
│                        │                           │
│                        ↓                           │
│              ┌─────────────────┐                   │
│              │      PVCs       │                   │
│              │ database/uploads│                   │
│              └─────────────────┘                   │
└─────────────────────────────────────────────────────┘
```

- **Frontend**: Next.js web interface (port 8001)
- **Backend**: API server handling uploads and data (port 8000)
- **Caddy**: Internal reverse proxy routing requests (port 80)

## Configuration

### Common Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full release name | `""` |
| `replicaCount` | Number of replicas | `1` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.image.repository` | Frontend image | `chibisafe/chibisafe` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `frontend.resources` | Resource requests/limits | `{}` |
| `frontend.env` | Additional environment variables | `[]` |
| `frontend.envFrom` | Environment from ConfigMaps/Secrets | `[]` |
| `frontend.extraVolumeMounts` | Additional volume mounts | `[]` |
| `frontend.securityContext` | Container security context | `{}` |

### Backend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.image.repository` | Backend image | `chibisafe/chibisafe-server` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `backend.resources` | Resource requests/limits | `{}` |
| `backend.env` | Additional environment variables | `[]` |
| `backend.envFrom` | Environment from ConfigMaps/Secrets | `[]` |
| `backend.extraVolumeMounts` | Additional volume mounts | `[]` |
| `backend.securityContext` | Container security context | `{}` |

### Caddy Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `caddy.image.repository` | Caddy image | `caddy` |
| `caddy.image.tag` | Caddy image tag | `2-alpine` |
| `caddy.resources` | Resource requests/limits | `{}` |

### Persistence

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.database.enabled` | Enable database persistence | `true` |
| `persistence.database.storageClass` | Storage class | `""` |
| `persistence.database.size` | Storage size | `1Gi` |
| `persistence.database.existingClaim` | Use existing PVC | `""` |
| `persistence.uploads.enabled` | Enable uploads persistence | `true` |
| `persistence.uploads.storageClass` | Storage class | `""` |
| `persistence.uploads.size` | Storage size | `10Gi` |
| `persistence.uploads.existingClaim` | Use existing PVC | `""` |
| `persistence.logs.enabled` | Enable logs persistence | `false` |
| `persistence.logs.size` | Storage size | `1Gi` |

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

### Security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable network policy | `true` |
| `podDisruptionBudget.enabled` | Enable PDB | `true` |
| `podDisruptionBudget.minAvailable` | Minimum available pods | `1` |
| `serviceAccount.create` | Create service account | `true` |

### Pod Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Pod labels | `{}` |
| `podSecurityContext` | Pod security context | `{fsGroup: 1000}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `extraVolumes` | Additional volumes | `[]` |

## Examples

### Basic Installation with Ingress

```yaml
# values-production.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: files.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: chibisafe-tls
      hosts:
        - files.example.com

persistence:
  uploads:
    size: 100Gi
```

```bash
helm install chibisafe l4gdev/chibisafe -f values-production.yaml
```

### With Resource Limits

```yaml
frontend:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

backend:
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi

caddy:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi
```

### Using Existing PVCs

```yaml
persistence:
  database:
    enabled: true
    existingClaim: my-existing-database-pvc
  uploads:
    enabled: true
    existingClaim: my-existing-uploads-pvc
```

### With Custom Environment Variables

```yaml
backend:
  env:
    - name: NODE_ENV
      value: production
  envFrom:
    - secretRef:
        name: chibisafe-secrets
```

## Post-Installation

### Default Credentials

The default credentials for a new Chibisafe installation are:

- **Username**: `admin`
- **Password**: `admin`

**Important**: Change these immediately after first login!

### Accessing Chibisafe

If using port-forward:

```bash
kubectl port-forward svc/chibisafe 8080:80
# Open http://localhost:8080
```

### Configuration via Dashboard

Most Chibisafe settings can be configured through the web dashboard at **Dashboard → Settings**, including:

- Site name and branding
- Upload limits and allowed file types
- User registration settings
- S3/Object storage configuration
- Rate limiting

## Upgrading

```bash
helm repo update
helm upgrade chibisafe l4gdev/chibisafe
```

## Uninstalling

```bash
helm uninstall chibisafe
```

**Note**: PVCs are not deleted automatically. To remove all data:

```bash
kubectl delete pvc -l app.kubernetes.io/name=chibisafe
```

## Troubleshooting

### View Logs

```bash
# Backend logs
kubectl logs -l app.kubernetes.io/name=chibisafe -c backend

# Frontend logs
kubectl logs -l app.kubernetes.io/name=chibisafe -c frontend

# Caddy logs
kubectl logs -l app.kubernetes.io/name=chibisafe -c caddy
```

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=chibisafe
kubectl describe pod -l app.kubernetes.io/name=chibisafe
```

## Links

- [Chibisafe Documentation](https://chibisafe.app/docs)
- [Chibisafe GitHub](https://github.com/chibisafe/chibisafe)
- [Chart Source](https://github.com/l4gdev/helm-charts)
- [Report Issues](https://github.com/l4gdev/helm-charts/issues)

## License

This chart is licensed under the MIT License.

Chibisafe itself is licensed under its own terms - see the [Chibisafe repository](https://github.com/chibisafe/chibisafe) for details.
