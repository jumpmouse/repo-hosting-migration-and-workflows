#!/usr/bin/env bash
set -euo pipefail

# Clean up existing containers for a fresh start
CONTAINERS=(mssql azurite)
for c in "${CONTAINERS[@]}"; do
  echo "[clean] Removing container '$c' if it exists..."
  docker rm -f "$c" >/dev/null 2>&1 || true
done

echo "[clean] Done."
