#!/bin/zsh
set -euo pipefail

# Runs LoT.Api using .NET 8

echo "Starting LoT.Api on https://localhost:7057 (and http://localhost:5057) ..."
dotnet run --project "$(dirname $0)/../../LoT.Api/LoT.Api.csproj"
