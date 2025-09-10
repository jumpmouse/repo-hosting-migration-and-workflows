#!/usr/bin/env bash
set -euo pipefail

# Runs LoT.Api using .NET 8
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR"/_env_vars.sh

echo "Starting LoT.Api on https://localhost:7057 (and http://localhost:5057) ..."
dotnet run --project "$SCRIPT_DIR/../../LoT.Api/LoT.Api.csproj"
