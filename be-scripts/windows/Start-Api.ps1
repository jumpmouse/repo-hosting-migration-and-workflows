$ErrorActionPreference = 'Stop'

# Runs LoT.Api using .NET 8
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir '_EnvVars.ps1')

$proj = Resolve-Path (Join-Path $scriptDir '..\..\LoT.Api\LoT.Api.csproj')
Write-Host "Starting LoT.Api on https://localhost:7057 (and http://localhost:5057) ..."
dotnet run --project $proj
