$ErrorActionPreference = 'Stop'

# LoT local dev: one-command startup for Windows
# - Sets required env locally (no manual CLI exports needed)
# - Starts MSSQL and Azurite
# - Starts the main API

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir '_EnvVars.ps1')

Write-Host "[dev_fresh] Starting SQL Server and Azurite..."
Write-Host "[dev_fresh] Creates database if missing..."
& (Join-Path $scriptDir '_Run-Containers.ps1')

Write-Host "[dev_up] Starting LoT.Api..."
& (Join-Path $scriptDir 'Start-Api.ps1')
