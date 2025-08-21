$ErrorActionPreference = 'Stop'

# Optionally ensure dotnet 8 is used if multiple SDKs are installed
# $env:DOTNET_ROOT="C:\Program Files\dotnet"  # adjust if needed

# Start DataMigrations API in background
Start-Process -FilePath "dotnet" -ArgumentList @("run","--project","$(Resolve-Path ..\..\LoT.DataMigrations.Api\LoT.DataMigrations.Api.csproj)") -WindowStyle Hidden
Start-Sleep -Seconds 3

# Trigger migrate (HTTP profile default: 5230)
$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("1Xiu7BP56WZ6f58VVO:D4lXZezOfr8AdRyFg2"))
try {
  $resp = Invoke-WebRequest -Uri "http://localhost:5230/api/DataMigration/migrate" -Headers @{ Authorization = "Basic $basic" } -UseBasicParsing -Method GET
  Write-Host "Migrations HTTP: $($resp.StatusCode)"
}
catch {
  try {
    $resp = Invoke-WebRequest -Uri "https://localhost:7200/api/DataMigration/migrate" -Headers @{ Authorization = "Basic $basic" } -UseBasicParsing -Method GET -SkipCertificateCheck
    Write-Host "Migrations HTTPS: $($resp.StatusCode)"
  }
  catch {
    Write-Error "Migration call failed: $($_.Exception.Message)"
    exit 1
  }
}
