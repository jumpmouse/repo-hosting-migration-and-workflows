$ErrorActionPreference = 'SilentlyContinue'

docker stop mssql azurite | Out-Null
docker rm mssql azurite | Out-Null

Write-Host "Stopped and removed containers: mssql, azurite (if existed)."
