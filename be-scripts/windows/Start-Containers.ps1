$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir '_EnvVars.ps1')

Write-Host "[dev_fresh] Starting SQL Server..."
& (Join-Path $scriptDir '_Start-Mssql.ps1')

Write-Host "[dev_fresh] Creating database if missing..."
& (Join-Path $scriptDir '_Create-Db.ps1')

Write-Host "[dev_fresh] Starting Azurite..."
& (Join-Path $scriptDir '_Start-Azurite.ps1')
