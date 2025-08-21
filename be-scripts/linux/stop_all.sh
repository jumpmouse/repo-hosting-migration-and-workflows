#!/usr/bin/env bash
set -euo pipefail

docker stop mssql azurite >/dev/null 2>&1 || true
docker rm mssql azurite >/dev/null 2>&1 || true

echo "Stopped and removed containers: mssql, azurite (if existed)."
