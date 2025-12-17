# Ente Photos Helm Chart

A Helm chart for deploying [Ente Photos](https://ente.io) - an end-to-end encrypted photo storage and backup platform.

## Introduction

This chart deploys Ente Photos on a Kubernetes cluster using the Helm package manager. Ente is a privacy-focused, open-source alternative to Google Photos with end-to-end encryption.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- PV provisioner support in the underlying infrastructure (for PostgreSQL persistence)
- S3-compatible object storage (AWS S3, Wasabi, Backblaze B2, Scaleway, etc.)

## Components

This chart deploys the following components:

| Component | Description | Default |
|-----------|-------------|---------|
| **Museum** | Main API server (Go backend) | Enabled |
| **PostgreSQL** | Database (Bitnami subchart) | Enabled |
| **Web Photos** | Photos web application | Enabled |
| **Web Auth** | Authentication web application | Enabled |
| **Web Accounts** | Account management web application | Enabled |
| **Web Cast** | Chromecast support web application | Disabled |
| **Web Share** | Public sharing web application | Enabled |

## Installing the Chart

Add the Helm repository:

```bash
helm repo add l4g https://l4gdev.github.io/helm-charts
helm repo update
```

Install the chart:

```bash
helm install ente-photos l4g/ente-photos \
  --namespace ente-photos \
  --create-namespace \
  --values values.yaml
```

## Configuration

### Minimal Configuration

At minimum, you need to configure S3 storage:

```yaml
credentials:
  s3:
    primary:
      key: "your-s3-access-key"
      secret: "your-s3-secret-key"
      endpoint: "https://s3.eu-central-1.wasabisys.com"
      region: "eu-central-1"
      bucket: "your-bucket-name"
```

### External PostgreSQL

To use an external PostgreSQL database instead of the bundled one:

```yaml
postgresql:
  enabled: false

externalDatabase:
  enabled: true
  host: "your-postgres-host"
  port: 5432
  database: "ente_db"
  user: "ente"
  password: "your-password"
```

### Ingress Configuration

Enable ingress for external access:

```yaml
museum:
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hosts:
      - host: api.ente.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: ente-api-tls
        hosts:
          - api.ente.example.com

web:
  photos:
    ingress:
      enabled: true
      className: nginx
      hosts:
        - host: photos.ente.example.com
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: ente-photos-tls
          hosts:
            - photos.ente.example.com
```

### SMTP Configuration

Enable email notifications:

```yaml
credentials:
  smtp:
    enabled: true
    host: "smtp.example.com"
    port: 587
    username: "your-username"
    password: "your-password"
    from: "noreply@example.com"
```

### Using Existing Secrets

For production, use existing secrets:

```yaml
credentials:
  existingSecret: "my-ente-credentials"

postgresql:
  auth:
    existingSecret: "my-postgres-credentials"
```

The credentials secret should contain a `credentials.yaml` key with the Ente credentials format.

## S3 Storage Providers

Ente supports any S3-compatible storage. Here are configurations for popular providers:

### AWS S3

```yaml
credentials:
  s3:
    primary:
      key: "AKIAIOSFODNN7EXAMPLE"
      secret: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      endpoint: "https://s3.eu-west-1.amazonaws.com"
      region: "eu-west-1"
      bucket: "my-ente-bucket"
```

### Wasabi

```yaml
credentials:
  s3:
    primary:
      key: "your-wasabi-key"
      secret: "your-wasabi-secret"
      endpoint: "https://s3.eu-central-2.wasabisys.com"
      region: "eu-central-2"
      bucket: "my-ente-bucket"
```

### Backblaze B2

```yaml
credentials:
  s3:
    primary:
      key: "your-b2-application-key-id"
      secret: "your-b2-application-key"
      endpoint: "https://s3.eu-central-003.backblazeb2.com"
      region: "eu-central-003"
      bucket: "my-ente-bucket"
```

### Scaleway

```yaml
credentials:
  s3:
    primary:
      key: "your-scaleway-access-key"
      secret: "your-scaleway-secret-key"
      endpoint: "https://s3.fr-par.scw.cloud"
      region: "fr-par"
      bucket: "my-ente-bucket"
```

## Web Frontends

### Disabling Frontends

If you only need the API server (e.g., using mobile apps only):

```yaml
web:
  photos:
    enabled: false
  auth:
    enabled: false
  accounts:
    enabled: false
  share:
    enabled: false
```

### Custom Frontend Images

Override default images per frontend:

```yaml
web:
  photos:
    image:
      repository: my-registry/ente-photos
      tag: "v1.0.0"
```

## Monitoring

Prometheus metrics are enabled by default:

```yaml
metrics:
  enabled: true
  port: 2112
  serviceMonitor:
    enabled: true
    interval: 30s
```

## Security Considerations

### Production Checklist

1. **Use external secrets management** - Don't store credentials in values.yaml
2. **Enable TLS** - Configure ingress with TLS certificates
3. **Set resource limits** - Define CPU/memory requests and limits
4. **Enable network policies** - Restrict pod communication
5. **Use non-root containers** - Configure security contexts
6. **Enable database SSL** - Set `museum.config.db.sslmode: "require"`

### Security Contexts

```yaml
museum:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
  podSecurityContext:
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
```

## Upgrading

### From 0.x to 0.y

Check the [CHANGELOG](CHANGELOG.md) for breaking changes between versions.

## Troubleshooting

### Database Connection Issues

Check PostgreSQL connectivity:

```bash
kubectl exec -it deploy/ente-museum -- psql -h ente-postgresql -U ente -d ente_db
```

### S3 Connection Issues

Verify S3 credentials and endpoint accessibility:

```bash
kubectl logs deploy/ente-museum | grep -i s3
```

### Health Check Failures

Check museum server health:

```bash
kubectl exec -it deploy/ente-museum -- wget -qO- http://localhost:8080/health
```

## Values

See [values.yaml](values.yaml) for the full list of configurable values.

## License

This chart is licensed under the MIT License. Ente itself is licensed under AGPL-3.0.

## Links

- [Ente Website](https://ente.io)
- [Ente GitHub](https://github.com/ente-io/ente)
- [Ente Self-Hosting Documentation](https://ente.io/help/self-hosting/)
- [Chart Source](https://github.com/l4gdev/helm-charts/tree/main/charts/ente-photos)
