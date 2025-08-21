#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="mssql"
SA_PASSWORD="Your_password123"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"

docker start "$CONTAINER_NAME" >/dev/null 2>&1 || \
docker run -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 --name "$CONTAINER_NAME" -d "$IMAGE"

echo "SQL Server container '$CONTAINER_NAME' is running."
