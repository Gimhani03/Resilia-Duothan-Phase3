#!/bin/sh
set -e

export API_UPSTREAM="${API_UPSTREAM:-http://api:3001}"
envsubst '${API_UPSTREAM}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "[web] Proxying /api -> ${API_UPSTREAM}/api/"
exec nginx -g 'daemon off;'
