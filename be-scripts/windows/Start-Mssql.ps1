Param(
  [string]$SaPassword = "Your_password123"
)

$ErrorActionPreference = 'Stop'

$container = "mssql"
$image = "mcr.microsoft.com/mssql/server:2022-latest"

try {
  docker start $container | Out-Null
}
catch {
  docker run -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SaPassword" -p 1433:1433 --name $container -d $image | Out-Null
}

Write-Host "SQL Server container '$container' is running."
