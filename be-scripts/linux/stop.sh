#!/usr/bin/env bash
set -euo pipefail

# Stop containers
CONTAINERS=(mssql azurite)
for c in "${CONTAINERS[@]}"; do
  echo "[stop_all] Stopping container '$c' if it exists..."
  ids=$(docker ps -q --filter name="$c")
  if [[ -n "$ids" ]]; then
    echo "$ids" | xargs -r docker stop || true
  fi
done

# Clean up existing ports
PORTS=(5057 7057 5230 7200 59622 59623)
if command -v lsof >/dev/null 2>&1; then
  echo "[stop_all] Cleaning ports via lsof..."
  for p in "${PORTS[@]}"; do lsof -ti :"$p" | xargs -r kill || true; done
elif command -v fuser >/dev/null 2>&1; then
  echo "[stop_all] Cleaning ports via fuser..."
  for p in "${PORTS[@]}"; do fuser -k "$p"/tcp || true; done
else
  echo "[stop_all] Skipping port cleanup (lsof/fuser not found)."
fi

echo "[stop_all] Done."
