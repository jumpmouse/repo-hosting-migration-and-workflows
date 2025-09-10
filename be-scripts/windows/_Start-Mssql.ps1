$ErrorActionPreference = 'Stop'

# Starts SQL Server 2022 in Docker on port 1433 with default SA password
$containerName = 'mssql'
$saPassword = 'LoT_StrongP@ssw0rd1'
$image = 'mcr.microsoft.com/mssql/server:2022-latest'

try {
  docker start $containerName | Out-Null
} catch {
  docker run -e 'ACCEPT_EULA=Y' -e "MSSQL_SA_PASSWORD=$saPassword" -p 1433:1433 --name $containerName -d $image | Out-Null
}

Write-Host "SQL Server container '$containerName' is running."
