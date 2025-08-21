#!/usr/bin/env bash
set -euo pipefail

# Runs the DataMigrations API and triggers the migrate endpoint

# If you have multiple dotnet versions, ensure dotnet 8 is first on PATH
# or set DOTNET_ROOT before running this script.

# Start migrations API (background)
( dotnet run --project "$(dirname "$0")/../../LoT.DataMigrations.Api/LoT.DataMigrations.Api.csproj" & )

# Wait for Kestrel
sleep 3

BASIC_AUTH=$(printf '1Xiu7BP56WZ6f58VVO:D4lXZezOfr8AdRyFg2' | base64)
# Try HTTP first per launchSettings (http://localhost:5230)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Basic ${BASIC_AUTH}" http://localhost:5230/api/DataMigration/migrate || true)
if [ "$HTTP_CODE" != "200" ]; then
  # fallback to HTTPS profile
  curl -ks -o /dev/null -w "%{http_code}\n" -H "Authorization: Basic ${BASIC_AUTH}" https://localhost:7200/api/DataMigration/migrate || true
fi
