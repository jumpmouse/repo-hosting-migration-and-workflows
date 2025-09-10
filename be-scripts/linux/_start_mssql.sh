#!/usr/bin/env bash
set -euo pipefail

# Starts SQL Server 2022 in Docker on port 1433 with default SA password
CONTAINER_NAME="mssql"
SA_PASSWORD="LoT_StrongP@ssw0rd1"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"

if ! docker start "$CONTAINER_NAME" >/dev/null 2>&1; then
  docker run -e 'ACCEPT_EULA=Y' -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 --name "$CONTAINER_NAME" -d "$IMAGE"
fi

echo "SQL Server container '$CONTAINER_NAME' is running."
