#!/bin/zsh
set -euo pipefail

# Runs the DataMigrations API using .NET 8 and triggers the migrate endpoint

# Start migrations API (background)
(dotnet run --project "$(dirname $0)/../../LoT.DataMigrations.Api/LoT.DataMigrations.Api.csproj" &)

# Wait a moment for Kestrel to boot
sleep 3

# Trigger migrate (prefer HTTP profile port 5230 per launchSettings.json)
BASIC_AUTH="$(printf '1Xiu7BP56WZ6f58VVO:D4lXZezOfr8AdRyFg2' | base64)"
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Basic ${BASIC_AUTH}" http://localhost:5230/api/DataMigration/migrate


