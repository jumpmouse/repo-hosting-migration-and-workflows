$ErrorActionPreference = 'Stop'

# Fresh local setup for Windows
# - Removes old containers
# - Starts MSSQL, creates DB
# - Starts Azurite
# - Runs migrations
# - Starts API

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir '_EnvVars.ps1')

Write-Host "[dev_fresh] Cleaning existing containers..."
& (Join-Path $scriptDir 'Stop.ps1')
& (Join-Path $scriptDir '_Clean.ps1')

Write-Host "[dev_fresh] Starting SQL Server and Azurite..."
& (Join-Path $scriptDir 'Start-Containers.ps1')

Write-Host "[dev_fresh] Running data migrations..."
& (Join-Path $scriptDir 'Run-Migrations.ps1')

Write-Host "[dev_fresh] Starting LoT.Api..."
& (Join-Path $scriptDir 'Start-Api.ps1')
