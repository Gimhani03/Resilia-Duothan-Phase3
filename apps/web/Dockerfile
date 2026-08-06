# RESILIA Web — static SPA + API reverse proxy (Phase 3)
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
COPY packages/shared/package.json packages/shared/
COPY apps/web/package.json apps/web/
COPY scripts/docker-npm-ci.sh /tmp/docker-npm-ci.sh

RUN chmod +x /tmp/docker-npm-ci.sh && /tmp/docker-npm-ci.sh

COPY packages/shared packages/shared
COPY apps/web apps/web

RUN npm run build -w @resilia/shared
WORKDIR /app/apps/web
RUN npm run build

FROM nginx:1.27-alpine AS runner

RUN apk add --no-cache gettext

COPY apps/web/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY apps/web/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

RUN chmod +x /docker-entrypoint.sh

ENV API_UPSTREAM=http://api:3001

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
