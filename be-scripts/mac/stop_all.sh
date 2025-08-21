#!/bin/zsh
set -euo pipefail

/bin/zsh -i -c "docker stop mssql azurite" >/dev/null 2>&1 || true
/bin/zsh -i -c "docker rm mssql azurite" >/dev/null 2>&1 || true

echo "Stopped and removed containers: mssql, azurite (if existed)."
