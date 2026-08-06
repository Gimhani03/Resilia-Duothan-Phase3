# RESILIA — Phase 3 Deployment Guide

Team **Cybernauts** · Duothan 6.0 · FORTIFY

This document describes how RESILIA is deployed to production: containers, infrastructure, CI/CD, health checks, and secrets.

---

## Architecture

```text
                    ┌─────────────────────────────────────┐
                    │           GitHub Actions            │
                    │  CI (build/test) → CD (push images) │
                    └─────────────────┬───────────────────┘
                                      │
                    ┌─────────────────▼───────────────────┐
                    │         Production stack            │
                    │                                     │
  Browser ────────► │  Web (nginx + React SPA) :80/443   │
                    │         │ proxy /api                │
                    │         ▼                           │
                    │  API (NestJS) :3001                 │
                    │         │                           │
                    │    ┌────┴────┐                      │
                    │    ▼         ▼                      │
                    │ Postgres   Redis                    │
                    └─────────────────────────────────────┘
```

| Service | Role | Health endpoint |
|---------|------|-----------------|
| **web** | Customer + ops UI (static SPA) | `GET /health` |
| **api** | Banking API gateway | `GET /api/health`, `GET /api/health/ready` |
| **postgres** | Primary datastore | `pg_isready` |
| **redis** | Sessions, rate limits | `redis-cli ping` |

---

## Quick start — local production stack

Simulates cloud deployment on your machine.

```bash
# 1. Create production env file
cp .env.prod.example .env.prod
# Edit JWT_SECRET to a long random string (32+ chars)

# 2. Build and start all services
npm run prod:up

# 3. Verify
curl http://localhost:3001/api/health/ready
curl http://localhost:8080/health
```

| URL | Purpose |
|-----|---------|
| http://localhost:8080 | Web app (ops: `/ops/signin`) |
| http://localhost:3001/api/health | API liveness |
| http://localhost:3001/api/health/ready | Readiness (DB + Redis) |

Demo accounts are seeded when `SEED_ON_START=true` (see [USER_GUIDE.md](./USER_GUIDE.md)).

Stop: `npm run prod:down`

---

## Container images

| Image | Dockerfile | Notes |
|-------|------------|-------|
| API | `apps/api/Dockerfile` | Runs migrations on boot, optional seed |
| Web | `apps/web/Dockerfile` | nginx serves SPA, proxies `/api` |

Build manually:

```bash
docker build -f apps/api/Dockerfile -t resilia-api .
docker build -f apps/web/Dockerfile -t resilia-web .
```

---

## Environment variables

### API (required in production)

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Access token signing secret (required when `NODE_ENV=production`) |
| `JWT_REFRESH_SECRET` | Refresh token secret |
| `REDIS_URL` | Redis URL (recommended) |
| `CORS_ORIGINS` | Comma-separated allowed origins |
| `DEMO_MODE` | `true` for judge demo features |
| `SEED_ON_START` | `true` to seed demo users on first boot |
| `APP_VERSION` | Shown in health response |
| `DEPLOY_REGION` | Region label for ops |

Secrets must **never** be committed. Use `.env.prod` locally and platform secret stores in cloud.

### Web

| Variable | Default | Description |
|----------|---------|-------------|
| `API_UPSTREAM` | `http://api:3001` | Upstream API base URL (no trailing slash) |

---

## CI/CD pipelines

### CI — `.github/workflows/ci.yml`

On every push/PR:

- Install & build shared, API, web
- Validate Prisma schema against PostgreSQL
- Typecheck mobile
- Build Docker images (no push)

### CD — `.github/workflows/deploy.yml`

On push to `main`/`master`:

- Build API + Web Docker images
- Push to **GitHub Container Registry**: `ghcr.io/<org>/resilia/api:latest` and `.../web:latest`

---

## Cloud deployment options

### Option A — Docker Compose on a VM (fastest for demo)

1. Provision a VM (AWS EC2, DigitalOcean, etc.)
2. Install Docker + Docker Compose
3. Clone repo, copy `.env.prod`, set strong secrets
4. `npm run prod:up`
5. Point domain → VM IP (port 8080 or put Caddy/nginx TLS in front)

### Option B — Render.com (IaC blueprint)

`render.yaml` defines API, Web, Postgres, and Redis as managed services.

1. Connect GitHub repo to Render
2. Create **Blueprint** from `render.yaml`
3. Set `CORS_ORIGINS` on API to your web URL
4. Set `API_UPSTREAM` on Web to `https://<your-api-host>` (no trailing slash)
5. Deploy — Render builds from Dockerfiles

### Option C — Pull pre-built images from GHCR

After CD pipeline runs:

```bash
docker pull ghcr.io/<your-org>/resilia/api:latest
docker pull ghcr.io/<your-org>/resilia/web:latest
```

Wire with your own compose file or orchestrator.

---

## Operational visibility

| Check | Endpoint | Use |
|-------|----------|-----|
| Liveness | `/api/health/live` | Process alive |
| Readiness | `/api/health/ready` | DB reachable; load balancer gate |
| Version | `/api/health` | Deploy verification |

Logs: `npm run prod:logs` or your cloud provider's log viewer.

---

## Security checklist

- [ ] `JWT_SECRET` and `JWT_REFRESH_SECRET` are long random values
- [ ] `POSTGRES_PASSWORD` changed from default
- [ ] HTTPS enabled in front of web (Caddy, nginx, or cloud TLS)
- [ ] `CORS_ORIGINS` locked to your domain(s)
- [ ] `DEMO_MODE=false` for real production (keep `true` for hackathon judges)
- [ ] No `.env` or secrets in git

---

## Submission checklist (Phase 3)

- [ ] Public GitHub repo with code + `docker-compose.prod.yml` + workflows + `render.yaml`
- [ ] Live URL reachable (web + API health)
- [ ] Screenshots: pipeline green, health checks, live login, cloud dashboard
- [ ] Submit at [duothan.ieeensbm.org/submission](https://duothan.ieeensbm.org/submission)

---

## Screenshots to capture for judges

1. GitHub Actions — CI + Deploy workflows passing
2. `curl /api/health/ready` showing `database: up`
3. Ops console live at `/ops/signin`
4. Customer transfer + fraud hold demo on production URL
5. Cloud provider dashboard (Render/VM/containers running)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API exits on boot | Check `JWT_SECRET` is set in `.env.prod` |
| `database: down` on ready | Wait for Postgres healthcheck; check `DATABASE_URL` |
| Web 502 on `/api` | Verify `API_UPSTREAM` points to running API |
| Seed not running | Set `SEED_ON_START=true` and recreate API container |
| CORS errors | Add web origin to API `CORS_ORIGINS` |
