#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="azurite"
IMAGE="mcr.microsoft.com/azure-storage/azurite"

docker start "$CONTAINER_NAME" >/dev/null 2>&1 || \
docker run -d --name "$CONTAINER_NAME" -p 10000:10000 -p 10001:10001 -p 10002:10002 "$IMAGE"

echo "Azurite container '$CONTAINER_NAME' is running."
