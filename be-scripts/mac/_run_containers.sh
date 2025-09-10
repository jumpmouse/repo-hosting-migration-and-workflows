#!/bin/zsh
set -euo pipefail

AZURITE_CONTAINER_NAME="azurite"
AZURITE_IMAGE="mcr.microsoft.com/azure-storage/azurite"
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd)"
DATA_DIR="$SCRIPT_DIR/../../.azurite-data"

# Ensure local persistent data directory exists
mkdir -p "$DATA_DIR"

# Start existing Azurite container; do NOT create here
if ! /bin/zsh -i -c "docker start $AZURITE_CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Error: Azurite container '$AZURITE_CONTAINER_NAME' not found or Docker not running."
  echo "Use be-scripts/mac/start_containers.sh (or make start) for first-time setup to create containers."
  exit 1
fi

echo "Azurite container '$AZURITE_CONTAINER_NAME' is running."

# Starts SQL Server 2022 in Docker on port 1433 with default SA password
# Adjust SA password if you change it in appsettings.Development.json

MSSQL_CONTAINER_NAME="mssql"
MSSQL_SA_PASSWORD="LoT_StrongP@ssw0rd1"
MSSQL_IMAGE="mcr.microsoft.com/mssql/server:2022-latest"

# Start existing MSSQL container; do NOT create here
if ! /bin/zsh -i -c "docker start $MSSQL_CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Error: SQL Server container '$MSSQL_CONTAINER_NAME' not found or Docker not running."
  echo "Use be-scripts/mac/start_containers.sh (or make start) for first-time setup to create containers."
  exit 1
fi

echo "SQL Server container '$MSSQL_CONTAINER_NAME' is running."
