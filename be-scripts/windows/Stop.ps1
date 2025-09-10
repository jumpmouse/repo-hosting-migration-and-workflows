$ErrorActionPreference = 'Stop'

# Stop containers
$containers = @('mssql','azurite')
foreach ($c in $containers) {
  Write-Host "[stop_all] Stopping container '$c' if it exists..."
  try {
    $ids = docker ps -q --filter "name=$c"
    if ($ids) { $ids | ForEach-Object { docker stop $_ | Out-Null } }
  } catch {}
}

# Free common dev ports
$ports = @(5057,7057,5230,7200,59622,59623)
foreach ($p in $ports) {
  try {
    $conns = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($conns) {
      $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
      foreach ($pid in $pids) {
        try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch {}
      }
    }
  } catch {}
}

Write-Host "[stop_all] Done."
