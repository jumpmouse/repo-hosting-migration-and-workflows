#!/usr/bin/env bash
set -euo pipefail

# Start existing Azurite and MSSQL containers; do NOT create here
AZURITE_CONTAINER_NAME="azurite"
MSSQL_CONTAINER_NAME="mssql"

# Start Azurite if it exists
if ! docker start "$AZURITE_CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Error: Azurite container '$AZURITE_CONTAINER_NAME' not found or Docker not running."
  echo "Use be-scripts/linux/start_containers.sh (or make start) for first-time setup to create containers."
  exit 1
fi
echo "Azurite container '$AZURITE_CONTAINER_NAME' is running."

# Start MSSQL if it exists
if ! docker start "$MSSQL_CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Error: SQL Server container '$MSSQL_CONTAINER_NAME' not found or Docker not running."
  echo "Use be-scripts/linux/start_containers.sh (or make start) for first-time setup to create containers."
  exit 1
fi
echo "SQL Server container '$MSSQL_CONTAINER_NAME' is running."
