$ErrorActionPreference = 'Stop'

$containerName = 'azurite'
$image = 'mcr.microsoft.com/azure-storage/azurite'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataDir = Join-Path $scriptDir '..\..\.azurite-data'
$dataDir = (Resolve-Path $dataDir).Path

if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Force -Path $dataDir | Out-Null }

# Try start, else run
try {
  docker start $containerName | Out-Null
} catch {
  docker run -d --name $containerName `
    -p 10000:10000 -p 10001:10001 -p 10002:10002 `
    -v "$dataDir`:/data" `
    $image azurite --location /data --debug /data/debug.log --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0 | Out-Null
}

Write-Host "Azurite container '$containerName' is running."

# Configure permissive CORS for Blob service for dev
if (Get-Command az -ErrorAction SilentlyContinue) {
  $connStr = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
  Write-Host "[azurite] Waiting for blob endpoint to be ready at http://127.0.0.1:10000 ..."
  $ready = $false
  for ($i=0; $i -lt 20; $i++) {
    try {
      $tcp = New-Object System.Net.Sockets.TcpClient
      $tcp.Connect('127.0.0.1', 10000)
      if ($tcp.Connected) { $ready = $true; $tcp.Close(); break }
    } catch { Start-Sleep -Milliseconds 500 }
    Start-Sleep -Milliseconds 500
  }
  if (-not $ready) {
    Write-Host "[azurite] Warning: blob endpoint not reachable; skipping CORS setup for now."
  } else {
    Write-Host "[azurite] Ensuring CORS is enabled for Blob service (GET, OPTIONS, HEAD from any origin)..."
    $env:AZURE_STORAGE_CONNECTION_STRING = $connStr
    for ($i=0; $i -lt 3; $i++) {
      try { az storage cors clear --services b | Out-Null; break } catch { Start-Sleep -Seconds 1 }
    }
    for ($i=0; $i -lt 3; $i++) {
      try {
        az storage cors add --services b --origins "*" --methods GET OPTIONS HEAD --allowed-headers "*" --exposed-headers "*" --max-age 3600 | Out-Null; break
      } catch { Start-Sleep -Seconds 1 }
    }
    Write-Host "[azurite] Current CORS rules:"
    az storage cors list --services b | Out-Null
  }
} else {
  Write-Host "[azurite] Warning: Azure CLI (az) not found. Skipping automatic CORS setup for Azurite."
}
