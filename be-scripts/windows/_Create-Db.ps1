$ErrorActionPreference = 'Stop'

# Creates the 'LoT' database in the running MSSQL container using mssql-tools
$DbName = 'LoT'
$SaPassword = 'LoT_StrongP@ssw0rd1'
$ToolsImage = 'mcr.microsoft.com/mssql-tools'

Write-Host "[create_db] Waiting for SQL Server to be ready..."
for ($i = 1; $i -le 60; $i++) {
  try {
    docker run --rm --network container:mssql $ToolsImage /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SaPassword -Q 'SELECT 1' | Out-Null
    Write-Host "[create_db] SQL Server is ready."
    break
  } catch {
    Start-Sleep -Seconds 2
    if ($i -eq 60) {
      Write-Error "[create_db] Timed out waiting for SQL Server."
      exit 1
    }
  }
}

# Create DB if it doesn't exist
$createSql = "IF DB_ID('$DbName') IS NULL BEGIN CREATE DATABASE [$DbName] END"
docker run --rm --network container:mssql $ToolsImage /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SaPassword -Q $createSql | Out-Null

Write-Host "[create_db] Ensured database '$DbName'."
