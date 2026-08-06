#!/bin/sh
# Install deps on Linux CI when lockfile was generated on macOS.
# npm ci skips optional platform binaries from another OS (npm/cli#4828).
set -e

npm ci --include=optional

ARCH=$(uname -m)
case "$ARCH" in
  aarch64|arm64)
    npm install --no-save \
      @rollup/rollup-linux-arm64-gnu \
      lightningcss-linux-arm64-gnu \
      @tailwindcss/oxide-linux-arm64-gnu
    ;;
  x86_64|amd64)
    npm install --no-save \
      @rollup/rollup-linux-x64-gnu \
      lightningcss-linux-x64-gnu \
      @tailwindcss/oxide-linux-x64-gnu
    ;;
  *)
    echo "ci-npm-ci: unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac
