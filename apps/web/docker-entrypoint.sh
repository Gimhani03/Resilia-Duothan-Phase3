#!/bin/sh
set -e

RAW="${API_UPSTREAM:-http://api:3001}"
case "$RAW" in
  http://*|https://*) export API_UPSTREAM="$RAW" ;;
  *) export API_UPSTREAM="http://${RAW}" ;;
esac

export PORT="${PORT:-80}"

# Host header must target the API, not the web app (fixes 502 on Render)
API_PROXY_HOST=$(echo "$API_UPSTREAM" | sed -E 's|https?://([^/:]+).*|\1|')
export API_PROXY_HOST

# Use container DNS (Render private network / Docker embedded DNS)
if [ -f /etc/resolv.conf ]; then
  NS=$(grep -m1 '^nameserver' /etc/resolv.conf | awk '{print $2}')
fi
export NGINX_RESOLVER="${NS:-127.0.0.11}"

envsubst '${API_UPSTREAM} ${PORT} ${NGINX_RESOLVER} ${API_PROXY_HOST}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "[web] Listening on :${PORT}, resolver ${NGINX_RESOLVER}, proxy Host ${API_PROXY_HOST}, upstream ${API_UPSTREAM}"
exec nginx -g 'daemon off;'
