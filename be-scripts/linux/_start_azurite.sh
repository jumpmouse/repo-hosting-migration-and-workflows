#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="azurite"
IMAGE="mcr.microsoft.com/azure-storage/azurite"
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DATA_DIR="$SCRIPT_DIR/../../.azurite-data"

# Ensure local persistent data directory exists
mkdir -p "$DATA_DIR"

# Start or run container
if ! docker start "$CONTAINER_NAME" >/dev/null 2>&1; then
  docker run -d --name "$CONTAINER_NAME" \
    -p 10000:10000 -p 10001:10001 -p 10002:10002 \
    -v "$DATA_DIR":/data \
    "$IMAGE" azurite --location /data --debug /data/debug.log --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0
fi

echo "Azurite container '$CONTAINER_NAME' is running."

# Configure permissive CORS for Blob service so browser can fetch HLS files from Azurite in dev
if command -v az >/dev/null 2>&1; then
  CONN_STR="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
  echo "[azurite] Waiting for blob endpoint to be ready at http://127.0.0.1:10000 ..."
  ATTEMPTS=0
  until nc -z 127.0.0.1 10000 >/dev/null 2>&1 || [ $ATTEMPTS -ge 20 ]; do
    ATTEMPTS=$((ATTEMPTS+1))
    sleep 0.5
  done
  if ! nc -z 127.0.0.1 10000 >/dev/null 2>&1; then
    echo "[azurite] Warning: blob endpoint not reachable; skipping CORS setup for now."
  else
    echo "[azurite] Ensuring CORS is enabled for Blob service (GET, OPTIONS, HEAD from any origin)..."
    for i in 1 2 3; do
      az storage cors clear --services b --connection-string "$CONN_STR" && break || sleep 1
    done
    for i in 1 2 3; do
      az storage cors add \
        --services b \
        --origins "*" \
        --methods GET OPTIONS HEAD \
        --allowed-headers "*" \
        --exposed-headers "*" \
        --max-age 3600 \
        --connection-string "$CONN_STR" && break || sleep 1
    done
    echo "[azurite] Current CORS rules:"
    az storage cors list --services b --connection-string "$CONN_STR" || true
  fi
else
  echo "[azurite] Warning: Azure CLI (az) not found. Skipping automatic CORS setup for Azurite."
fi
