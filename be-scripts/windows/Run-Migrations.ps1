$ErrorActionPreference = 'Stop'

# Runs the DataMigrations API using .NET 8 and triggers the migrate endpoint
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir '_EnvVars.ps1')

$proj = Resolve-Path (Join-Path $scriptDir '..\..\LoT.DataMigrations.Api\LoT.DataMigrations.Api.csproj')

# Start migrations API (background)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'dotnet'
$psi.Arguments = "run --launch-profile http --project `"$proj`""
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$proc = [System.Diagnostics.Process]::Start($psi)

Start-Sleep -Seconds 8

# Trigger migrate (HTTP profile uses port 5230 per launchSettings.json)
$user = '1Xiu7BP56WZ6f58VVO'
$pass = 'D4lXZezOfr8AdRyFg2'
$pair = [System.Text.Encoding]::ASCII.GetBytes("$user:$pass")
$basic = [Convert]::ToBase64String($pair)

try {
  $resp = Invoke-WebRequest -Uri 'http://localhost:5230/api/DataMigration/migrate' -Headers @{ Authorization = "Basic $basic" } -UseBasicParsing -TimeoutSec 120
  Write-Host "[migrate] HTTP $($resp.StatusCode)"
} catch {
  Write-Warning "[migrate] Request failed: $($_.Exception.Message)"
}

# Stop migrations API
try { Stop-Process -Id $proc.Id -Force } catch {}
