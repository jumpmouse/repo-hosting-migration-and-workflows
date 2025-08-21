#!/usr/bin/env bash
set -euo pipefail

# Runs LoT.Api. Ensure .NET 8 is available on PATH

echo "Starting LoT.Api on https://localhost:7057 (and http://localhost:5057) ..."
dotnet run --project "$(dirname "$0")/../../LoT.Api/LoT.Api.csproj"
