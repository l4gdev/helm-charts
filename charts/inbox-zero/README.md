# inbox-zero

Helm chart for [Inbox Zero](https://github.com/elie222/inbox-zero), an open-source AI email assistant for Gmail and Outlook.

[![ArtifactHub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/l4g)](https://artifacthub.io/packages/search?repo=l4g)

Based on the upstream chart in `elie222/inbox-zero` (`charts/inbox-zero`).

## What it deploys

- `web`: Deployment for the Next.js app, plus a Service and an optional Ingress
- `worker`: optional BullMQ worker Deployment
- CronJobs for the scheduled endpoints (watch renewal, digests, meeting briefs, follow-up reminders, retention)
- A Prisma migration Job (pre-install/pre-upgrade hook) when you use external Postgres
- Optional bundled Postgres, Redis and a Redis HTTP bridge (`hiett/serverless-redis-http`) for demos and small installs

For production, use managed Postgres and Redis. The bundled StatefulSets have no backups, failover or monitoring.

## Install

```bash
helm repo add l4gdev https://l4gdev.github.io/helm-charts
helm repo update
helm upgrade --install inbox-zero l4gdev/inbox-zero \
  -n inbox-zero --create-namespace \
  -f my-values.yaml
```

Start from one of the files in [`examples/`](examples):

| File | Use case |
| --- | --- |
| `values-minimal.yaml` | Bundled Postgres / Redis, secrets inline, no Ingress |
| `values-production.yaml` | Managed Postgres / Redis, all credentials in existing Secrets, Ingress + TLS |

## Required configuration

- `env.NEXT_PUBLIC_BASE_URL`: the public HTTPS URL. It must match the OAuth redirect origin registered in Google / Microsoft.
- App secrets, set in `secretEnv` or in a Secret referenced by `existingSecret`: `AUTH_SECRET`, `EMAIL_ENCRYPT_SECRET`, `EMAIL_ENCRYPT_SALT`, `INTERNAL_API_KEY`, `API_KEY_SALT`, `CRON_SECRET`, OAuth client credentials and an LLM API key. The full list is in the [environment variables reference](https://docs.getinboxzero.com/hosting/environment-variables).
- Bundled data services: `postgresql.auth.password`, `redis.auth.password` and `redisHttp.token` are required. Generate them with `openssl rand -hex 32`.

## External Postgres / Redis

```yaml
externalDatabase:
  enabled: true
  existingSecret:
    name: inbox-zero-database   # DATABASE_URL, DIRECT_URL

externalRedis:
  enabled: true
  existingSecret:
    name: inbox-zero-redis      # REDIS_URL, REDIS_HTTP_URL, REDIS_HTTP_TOKEN

existingSecret: inbox-zero-secrets
```

Legacy `UPSTASH_REDIS_URL` / `UPSTASH_REDIS_TOKEN` keys still work. Leave `externalRedis.existingSecret.redisHttpUrlKey` and `redisHttpTokenKey` empty and the chart will accept either naming.

## Queue backend

BullMQ is the default (`env.QUEUE_BACKEND: bullmq`, `worker.enabled: true`). To use QStash instead, set `QUEUE_BACKEND: qstash`, disable the worker and provide the QStash secrets.

## Smoke test

```bash
kubectl -n inbox-zero rollout status deploy/inbox-zero-web
kubectl -n inbox-zero port-forward svc/inbox-zero-web 3000:80
curl http://localhost:3000/api/health

kubectl -n inbox-zero create job --from=cronjob/inbox-zero-watch-renewal test-watch-renewal
kubectl -n inbox-zero logs job/test-watch-renewal
```

## Differences from upstream

- The CronJob `curl` command is quoted. Upstream renders `Authorization: Bearer ...` unquoted, so YAML parses it as a map and the API server rejects the CronJobs.
- L4G metadata, ArtifactHub annotations, `ci/` values for chart-testing and `examples/`.

## Upstream docs

- [Kubernetes deployment](https://docs.getinboxzero.com/hosting/kubernetes)
- [Environment variables](https://docs.getinboxzero.com/hosting/environment-variables)
- [Google OAuth](https://docs.getinboxzero.com/hosting/google-oauth), [Microsoft OAuth](https://docs.getinboxzero.com/hosting/microsoft-oauth), [LLM setup](https://docs.getinboxzero.com/hosting/llm-setup)
