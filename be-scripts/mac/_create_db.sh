#!/bin/zsh
set -euo pipefail

# Creates the 'LoT' database in the running MSSQL container using mssql-tools
DB_NAME="LoT"
SA_PASSWORD="LoT_StrongP@ssw0rd1"
TOOLS_IMAGE="mcr.microsoft.com/mssql-tools"

# Wait for SQL Server to be ready
echo "[create_db] Waiting for SQL Server to be ready..."
for i in {1..60}; do
  if /bin/zsh -i -c "docker run --rm --network container:mssql ${TOOLS_IMAGE} /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P '${SA_PASSWORD}' -Q 'SELECT 1'" >/dev/null 2>&1; then
    echo "[create_db] SQL Server is ready."
    break
  fi
  sleep 2
  if [[ $i -eq 60 ]]; then
    echo "[create_db] Timed out waiting for SQL Server." >&2
    exit 1
  fi
done

# Create DB if it doesn't exist
CREATE_SQL="IF DB_ID('${DB_NAME}') IS NULL BEGIN CREATE DATABASE [${DB_NAME}] END"
/bin/zsh -i -c "docker run --rm --network container:mssql ${TOOLS_IMAGE} /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P '${SA_PASSWORD}' -Q \"${CREATE_SQL}\""

echo "[create_db] Ensured database '${DB_NAME}'."
