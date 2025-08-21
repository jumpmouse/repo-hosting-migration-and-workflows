$ErrorActionPreference = 'Stop'

$container = "azurite"
$image = "mcr.microsoft.com/azure-storage/azurite"

try {
  docker start $container | Out-Null
}
catch {
  docker run -d --name $container -p 10000:10000 -p 10001:10001 -p 10002:10002 $image | Out-Null
}

Write-Host "Azurite container '$container' is running."
