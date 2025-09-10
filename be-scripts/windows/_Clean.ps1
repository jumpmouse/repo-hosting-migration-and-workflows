$ErrorActionPreference = 'Stop'

# Remove containers if they exist
$containers = @('mssql','azurite')
foreach ($c in $containers) {
  Write-Host "[clean] Removing container '$c' if it exists..."
  try { docker rm -f $c | Out-Null } catch { }
}

Write-Host "[clean] Done."
