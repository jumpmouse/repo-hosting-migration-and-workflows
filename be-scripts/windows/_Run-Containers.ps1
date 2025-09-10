$ErrorActionPreference = 'Stop'

# Start existing Azurite and MSSQL containers; do NOT create here
$azuriteContainer = 'azurite'
$mssqlContainer = 'mssql'

try {
  docker start $azuriteContainer | Out-Null
} catch {
  Write-Host "Error: Azurite container '$azuriteContainer' not found or Docker not running."
  Write-Host "Use be-scripts/windows/Start-Containers.ps1 (or make start) for first-time setup to create containers."
  exit 1
}
Write-Host "Azurite container '$azuriteContainer' is running."

try {
  docker start $mssqlContainer | Out-Null
} catch {
  Write-Host "Error: SQL Server container '$mssqlContainer' not found or Docker not running."
  Write-Host "Use be-scripts/windows/Start-Containers.ps1 (or make start) for first-time setup to create containers."
  exit 1
}
Write-Host "SQL Server container '$mssqlContainer' is running."
