$ErrorActionPreference = 'Stop'

# Optionally ensure dotnet 8 is used if multiple SDKs are installed
# $env:DOTNET_ROOT="C:\Program Files\dotnet"  # adjust if needed

Write-Host "Starting LoT.Api on https://localhost:7057 (and http://localhost:5057) ..."
dotnet run --project (Resolve-Path ..\..\LoT.Api\LoT.Api.csproj)
