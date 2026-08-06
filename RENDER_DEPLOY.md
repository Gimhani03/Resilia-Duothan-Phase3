# Deploy RESILIA to Render.com

Team **Cybernauts** · Step-by-step for Phase 3 submission

**Repo:** https://github.com/Gimhani03/Resilia-Duothan-Phase3

---

## Before you start

- Render account (free): https://dashboard.render.com/register
- GitHub connected to Render
- Credit card may be required for Postgres/Redis starter plans (often free trial)

---

## Step 1 — Create Blueprint from GitHub

1. Open https://dashboard.render.com
2. Click **New +** → **Blueprint**
3. Connect GitHub if prompted → select **`Gimhani03/Resilia-Duothan-Phase3`**
4. Render reads `render.yaml` and shows **4 resources**:
   - `resilia-api` (Web / Docker)
   - `resilia-web` (Web / Docker)
   - `resilia-redis` (Key Value)
   - `resilia-db` (PostgreSQL)
5. Click **Apply**

First deploy takes **10–20 minutes** (Docker builds for API + Web).

---

## Step 2 — Set CORS on API (after URLs exist)

When deploy finishes, copy your **web URL** (e.g. `https://resilia-web.onrender.com`).

1. Dashboard → **resilia-api** → **Environment**
2. Set **`CORS_ORIGINS`** = `https://resilia-web.onrender.com` (your actual web URL)
3. Save → API redeploys automatically

`API_UPSTREAM` is wired automatically via `render.yaml` (internal `hostport`).

---

## Step 3 — Verify live

| Check | URL |
|-------|-----|
| **Submission URL (web)** | `https://resilia-web.onrender.com` |
| **Ops sign-in** | `https://resilia-web.onrender.com/ops/signin` |
| **API health** | `https://resilia-api.onrender.com/api/health/ready` |

Expected health JSON:

```json
{"status":"ready","checks":{"database":"up","redis":"up"}}
```

---

## Step 4 — Demo login

| Role | Username | Password | MFA secret |
|------|----------|----------|------------|
| Officer | `s.jayasuriya` | `OpsConsole2065!` | `JBSWY3DPEHPK3PXP` |
| Customer | `a.perera.2065` | `Resilia2065!` | `JBSWY3DPEHPK3PXP` |

Demo OTP (if enabled): `482916`

---

## Step 5 — Mobile app (optional)

Point mobile at live API:

```bash
# apps/mobile/.env
EXPO_PUBLIC_API_URL=https://resilia-api.onrender.com/api
EXPO_PUBLIC_DEMO_MODE=true
```

Run `npm run dev:mobile` → scan QR in Expo Go.

---

## Step 6 — Submit to Duothan

1. **GitHub:** https://github.com/Gimhani03/Resilia-Duothan-Phase3
2. **Live URL:** `https://resilia-web.onrender.com` (your web URL)
3. **Docs:** `DEPLOYMENT.md` + screenshots from this guide
4. Form: https://duothan.ieeensbm.org/submission

---

## Screenshots for judges

1. Render dashboard — all 4 services **Live**
2. `/api/health/ready` — database + redis **up**
3. `/ops/signin` — officer login on public URL
4. GitHub Actions — CI workflow green

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| API deploy fails on build | Check **Logs** tab; rebuild from Render dashboard |
| API unhealthy | Wait 2–3 min for migrations + seed; check logs for Prisma errors |
| Web 502 on `/api` | API not healthy yet; wait or check `API_UPSTREAM` in web env |
| CORS error in browser | Set `CORS_ORIGINS` on API to exact web URL (https, no trailing slash) |
| Render free spin-down | First request after idle takes ~30s to wake |

---

## Cost note

Starter plans for API + Web + Postgres + Redis may incur charges after trial. Delete the Blueprint from Render dashboard when the hackathon ends if you don't need it.
