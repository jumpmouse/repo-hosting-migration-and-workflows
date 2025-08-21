#!/bin/zsh
set -euo pipefail

# Starts SQL Server 2022 in Docker on port 1433 with default SA password
# Adjust SA password if you change it in appsettings.Development.json

CONTAINER_NAME="mssql"
SA_PASSWORD="LoT_StrongP@ssw0rd1"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"

/bin/zsh -i -c "docker start $CONTAINER_NAME" >/dev/null 2>&1 || \
/bin/zsh -i -c "docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=$SA_PASSWORD' -p 1433:1433 --name $CONTAINER_NAME -d $IMAGE"

echo "SQL Server container '$CONTAINER_NAME' is running."
