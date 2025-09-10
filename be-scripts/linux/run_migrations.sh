#!/usr/bin/env bash
set -euo pipefail

# Runs the DataMigrations API using .NET 8 and triggers the migrate endpoint
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR"/_env_vars.sh

# Start migrations API (background)
dotnet run --launch-profile http --project "$SCRIPT_DIR/../../LoT.DataMigrations.Api/LoT.DataMigrations.Api.csproj" &
MIG_PID=$!

# Wait for Kestrel to boot
sleep 8

# Trigger migrate (prefer HTTP profile port 5230 per launchSettings.json)
BASIC_AUTH=$(printf '1Xiu7BP56WZ6f58VVO:D4lXZezOfr8AdRyFg2' | base64 | tr -d '\n')
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Basic ${BASIC_AUTH}" http://localhost:5230/api/DataMigration/migrate || true)
echo "[migrate] HTTP ${HTTP_CODE}"

# Stop migrations API
echo "Stopping migrations API (pid=$MIG_PID)..."
kill "$MIG_PID" >/dev/null 2>&1 || true
