#!/bin/sh
set -e

RAW="${API_UPSTREAM:-http://api:3001}"
case "$RAW" in
  http://*|https://*) export API_UPSTREAM="$RAW" ;;
  *) export API_UPSTREAM="http://${RAW}" ;;
esac

export PORT="${PORT:-80}"

envsubst '${API_UPSTREAM} ${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "[web] Listening on :${PORT}, proxying /api -> ${API_UPSTREAM}/api/"
exec nginx -g 'daemon off;'
