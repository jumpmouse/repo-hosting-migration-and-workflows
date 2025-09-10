#!/bin/zsh
set -euo pipefail

# Runs the DataMigrations API using .NET 8 and triggers the migrate endpoint

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd)"

source "$SCRIPT_DIR"/_env_vars.sh

# Start migrations API (background)
(/bin/zsh -i -c "dotnet run --launch-profile http --project '$(dirname $0)/../../LoT.DataMigrations.Api/LoT.DataMigrations.Api.csproj'" &)

# Wait a moment for Kestrel to boot
sleep 8

# Trigger migrate (prefer HTTP profile port 5230 per launchSettings.json)
BASIC_AUTH="$(printf '1Xiu7BP56WZ6f58VVO:D4lXZezOfr8AdRyFg2' | base64)"
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Basic ${BASIC_AUTH}" http://localhost:5230/api/DataMigration/migrate

# Stop migrations API (background process)
echo "Stopping migrations API..."
lsof -ti :5230 | xargs kill || true
echo "Migration complete."