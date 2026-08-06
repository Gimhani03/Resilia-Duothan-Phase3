#!/bin/sh
# Install deps inside Alpine Linux containers when lockfile was generated on macOS.
# npm ci skips optional platform binaries from another OS (npm/cli#4828).
set -e

npm ci --include=optional

ARCH=$(uname -m)
case "$ARCH" in
  aarch64|arm64)
    npm install --no-save \
      @rollup/rollup-linux-arm64-musl \
      lightningcss-linux-arm64-musl \
      @tailwindcss/oxide-linux-arm64-musl
    ;;
  x86_64|amd64)
    npm install --no-save \
      @rollup/rollup-linux-x64-musl \
      lightningcss-linux-x64-musl \
      @tailwindcss/oxide-linux-x64-musl
    ;;
  *)
    echo "docker-npm-ci: unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac
