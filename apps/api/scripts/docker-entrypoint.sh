#!/bin/sh
set -e

cd /app/apps/api

echo "[entrypoint] Waiting for PostgreSQL..."
TRIES=0
until pg_isready -h postgres -U resilia -d resilia -q 2>/dev/null; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 30 ]; then
    echo "[entrypoint] Database not ready after 60s"
    exit 1
  fi
  sleep 2
done

echo "[entrypoint] Generating Prisma client..."
npx prisma generate

echo "[entrypoint] Running migrations..."
npx prisma migrate deploy

if [ "$SEED_ON_START" = "true" ]; then
  echo "[entrypoint] Seeding demo data..."
  node prisma/seed.js
fi

echo "[entrypoint] Starting API..."
exec "$@"
