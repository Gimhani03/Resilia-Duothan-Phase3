#!/bin/sh
set -e

cd /app/apps/api

echo "[entrypoint] Generating Prisma client..."
npx prisma generate

echo "[entrypoint] Waiting for PostgreSQL..."
TRIES=0
until node - <<'NODE'
const { execSync } = require("child_process");
const raw = process.env.DATABASE_URL;
if (!raw) process.exit(1);
const u = new URL(raw.replace(/^postgresql:/, "postgres:"));
const host = u.hostname;
const port = u.port || "5432";
const user = decodeURIComponent(u.username || "resilia");
const db = u.pathname.replace(/^\//, "") || "resilia";
try {
  execSync(`pg_isready -h "${host}" -p "${port}" -U "${user}" -d "${db}" -q`, {
    stdio: "ignore",
  });
  process.exit(0);
} catch {
  process.exit(1);
}
NODE
do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 90 ]; then
    echo "[entrypoint] Database not ready after 180s"
    exit 1
  fi
  sleep 2
done

echo "[entrypoint] Running migrations..."
npx prisma migrate deploy

if [ "$SEED_ON_START" = "true" ]; then
  echo "[entrypoint] Seeding demo data..."
  node prisma/seed.js
fi

echo "[entrypoint] Starting API..."
exec "$@"
