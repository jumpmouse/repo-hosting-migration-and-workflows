#!/bin/zsh
set -euo pipefail

# Stop containers
CONTAINERS=(mssql azurite)
for c in ${CONTAINERS[@]}; do
  echo "[stop_all] Stopping container '$c' if it exists..."
  /bin/zsh -i -c "docker ps -q --filter name=$c" | xargs docker stop || true
done

# Clean up existing ports
PORTS=(5057 7057 5230 7200 59622 59623)
if command -v lsof >/dev/null 2>&1; then
  echo "[stop_all] Cleaning ports via lsof..."
  for p in ${PORTS[@]}; do lsof -ti :$p | xargs kill || true; done
elif command -v fuser >/dev/null 2>&1; then
  echo "[stop_all] Cleaning ports via fuser..."
  for p in ${PORTS[@]}; do fuser -k $p/tcp || true; done
else
  echo "[stop_all] Skipping port cleanup (lsof/fuser not found)."
fi
echo "[stop_all] Done."
