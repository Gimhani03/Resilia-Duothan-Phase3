# RESILIA API — production container (Phase 3)
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
COPY packages/shared/package.json packages/shared/
COPY apps/api/package.json apps/api/

RUN npm ci

COPY packages/shared packages/shared
COPY apps/api apps/api

RUN npm run build -w @resilia/shared
WORKDIR /app/apps/api
RUN npx prisma generate
RUN npm run build
RUN npx tsc prisma/seed.ts \
  --outDir prisma \
  --esModuleInterop \
  --module commonjs \
  --target ES2021 \
  --skipLibCheck \
  --moduleResolution node \
  --resolveJsonModule

FROM node:22-alpine AS runner

WORKDIR /app

RUN apk add --no-cache curl postgresql-client

COPY package.json package-lock.json ./
COPY packages/shared/package.json packages/shared/
COPY apps/api/package.json apps/api/

# Install all deps (incl. dev) before NODE_ENV=production omits them
RUN npm ci

ENV NODE_ENV=production
ENV PATH="/app/node_modules/.bin:${PATH}"

COPY --from=builder /app/packages/shared/dist packages/shared/dist
COPY --from=builder /app/apps/api/dist apps/api/dist
COPY --from=builder /app/apps/api/prisma apps/api/prisma
COPY apps/api/scripts/docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

WORKDIR /app/apps/api

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD sh -c 'curl -fsS "http://127.0.0.1:${PORT:-3001}/api/health/ready" || exit 1'

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["node", "dist/src/main.js"]
