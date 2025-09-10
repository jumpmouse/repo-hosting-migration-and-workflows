$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "[clean_up] Stopping containers and cleaning up ports..."
& (Join-Path $scriptDir 'Stop.ps1')

Write-Host "[clean_up] Removing existing containers..."
& (Join-Path $scriptDir '_Clean.ps1')
