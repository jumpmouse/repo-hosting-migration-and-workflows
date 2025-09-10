$ErrorActionPreference = 'Stop'

<#
Seed Azurite with blobs from Azure Storage via local temp folders.
- Downloads from Azure: content, video-private, video-public (if SAS provided)
- Uploads only the folder contents to Azurite to avoid nested prefixes
- Optionally verifies nested prefixes

Inputs (env vars):
- AZURE_ACCOUNT, AZURE_CONTENT_SAS, AZURE_VIDEO_PRIVATE_SAS, AZURE_VIDEO_PUBLIC_SAS
- EMULATOR_SAS_CONTENT, EMULATOR_SAS_VIDEO_PRIVATE, EMULATOR_SAS_VIDEO_PUBLIC
- AZCOPY_CONCURRENCY_VALUE (default 1)
- CLEAN_TMP=1 to delete temp afterwards
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AZCOPY_CONCURRENCY_VALUE = if ($env:AZCOPY_CONCURRENCY_VALUE) { $env:AZCOPY_CONCURRENCY_VALUE } else { '1' }

# Azurite emulator constants
$EMULATOR_ACCOUNT = 'devstoreaccount1'
$EMULATOR_KEY = 'Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='
$EMULATOR_BASE = "http://127.0.0.1:10000/$EMULATOR_ACCOUNT"

$TMP_CONTENT = "$env:TEMP\lot_content_sync"
$TMP_VIDEO_PRIV = "$env:TEMP\lot_video_private_sync"
$TMP_VIDEO_PUB = "$env:TEMP\lot_video_public_sync"

function Ensure-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "'$name' is required in PATH"
  }
}

function Maybe-WarnContainer() {
  try {
    $names = docker ps --format '{{.Names}}'
    if (-not ($names -match '^azurite$')) {
      Write-Warning "Azurite container 'azurite' not detected. Ensure it's running (Start.ps1)."
    }
  } catch {}
}

function Ensure-EmulatorSas() {
  if (Get-Command az -ErrorAction SilentlyContinue) {
    $expiry = (Get-Date).ToUniversalTime().AddDays(7).ToString('yyyy-MM-ddTHH:mm:ssZ')
    if (-not $env:EMULATOR_SAS_CONTENT) {
      $env:EMULATOR_SAS_CONTENT = az storage container generate-sas `
        --name content --permissions racwdl --expiry $expiry `
        --account-name $EMULATOR_ACCOUNT --account-key $EMULATOR_KEY `
        --auth-mode key -o tsv
    }
    if (-not $env:EMULATOR_SAS_VIDEO_PRIVATE) {
      $env:EMULATOR_SAS_VIDEO_PRIVATE = az storage container generate-sas `
        --name video-private --permissions racwdl --expiry $expiry `
        --account-name $EMULATOR_ACCOUNT --account-key $EMULATOR_KEY `
        --auth-mode key -o tsv
    }
    if (-not $env:EMULATOR_SAS_VIDEO_PUBLIC) {
      $env:EMULATOR_SAS_VIDEO_PUBLIC = az storage container generate-sas `
        --name video-public --permissions racwdl --expiry $expiry `
        --account-name $EMULATOR_ACCOUNT --account-key $EMULATOR_KEY `
        --auth-mode key -o tsv
    }
  } else {
    if (-not ($env:EMULATOR_SAS_CONTENT -and $env:EMULATOR_SAS_VIDEO_PRIVATE -and $env:EMULATOR_SAS_VIDEO_PUBLIC)) {
      throw "EMULATOR_SAS_* not set and Azure CLI 'az' not available to auto-generate. Export these SAS tokens (no leading '?')."
    }
  }
}

# Checks
Ensure-Command azcopy
Maybe-WarnContainer

# Enforce single-threaded azcopy for reliability
$env:AZCOPY_CONCURRENCY_VALUE = $AZCOPY_CONCURRENCY_VALUE

# Prepare temp folders
New-Item -ItemType Directory -Force -Path $TMP_CONTENT,$TMP_VIDEO_PRIV,$TMP_VIDEO_PUB | Out-Null

# Optional downloads from Azure if SAS present
if ($env:AZURE_ACCOUNT -and $env:AZURE_CONTENT_SAS) {
  Write-Host "[seed] Downloading 'content' from Azure → $TMP_CONTENT ..."
  azcopy copy "https://$($env:AZURE_ACCOUNT).blob.core.windows.net/content?$($env:AZURE_CONTENT_SAS)" `
    "$TMP_CONTENT" --recursive --log-level INFO | Out-Null
} else {
  Write-Host "[seed] Skipping Azure download for 'content' (AZURE_ACCOUNT/AZURE_CONTENT_SAS not set)"
}

if ($env:AZURE_ACCOUNT -and $env:AZURE_VIDEO_PRIVATE_SAS) {
  Write-Host "[seed] Downloading 'video-private' from Azure → $TMP_VIDEO_PRIV ..."
  azcopy copy "https://$($env:AZURE_ACCOUNT).blob.core.windows.net/video-private?$($env:AZURE_VIDEO_PRIVATE_SAS)" `
    "$TMP_VIDEO_PRIV" --recursive --log-level INFO | Out-Null
} else {
  Write-Host "[seed] Skipping Azure download for 'video-private' (AZURE_ACCOUNT/AZURE_VIDEO_PRIVATE_SAS not set)"
}

if ($env:AZURE_ACCOUNT -and $env:AZURE_VIDEO_PUBLIC_SAS) {
  Write-Host "[seed] Downloading 'video-public' from Azure → $TMP_VIDEO_PUB ..."
  azcopy copy "https://$($env:AZURE_ACCOUNT).blob.core.windows.net/video-public?$($env:AZURE_VIDEO_PUBLIC_SAS)" `
    "$TMP_VIDEO_PUB" --recursive --log-level INFO | Out-Null
} else {
  Write-Host "[seed] Skipping Azure download for 'video-public' (AZURE_ACCOUNT/AZURE_VIDEO_PUBLIC_SAS not set)"
}

# Ensure Azurite SAS tokens
Ensure-EmulatorSas

# Upload only contents (avoid nested prefixes)

Write-Host "[seed] Uploading 'content' into Azurite (contents only)..."
azcopy copy "$TMP_CONTENT/content/*" "${EMULATOR_BASE}/content?$($env:EMULATOR_SAS_CONTENT)" `
  --recursive --from-to LocalBlob --overwrite true --log-level INFO | Out-Null

if (Test-Path "$TMP_VIDEO_PRIV/video-private") {
  Write-Host "[seed] Uploading 'video-private' into Azurite (contents only)..."
  azcopy copy "$TMP_VIDEO_PRIV/video-private/*" "${EMULATOR_BASE}/video-private?$($env:EMULATOR_SAS_VIDEO_PRIVATE)" `
    --recursive --from-to LocalBlob --overwrite true --log-level INFO | Out-Null
}

if (Test-Path "$TMP_VIDEO_PUB/video-public") {
  Write-Host "[seed] Uploading 'video-public' into Azurite (contents only)..."
  azcopy copy "$TMP_VIDEO_PUB/video-public/*" "${EMULATOR_BASE}/video-public?$($env:EMULATOR_SAS_VIDEO_PUBLIC)" `
    --recursive --from-to LocalBlob --overwrite true --log-level INFO | Out-Null
}

# Optional verify (if Azure CLI present)
if (Get-Command az -ErrorAction SilentlyContinue) {
  $connStr = "DefaultEndpointsProtocol=http;AccountName=$EMULATOR_ACCOUNT;AccountKey=$EMULATOR_KEY;BlobEndpoint=$EMULATOR_BASE"
  foreach ($c in 'content','video-private','video-public') {
    $count = az storage blob list --container-name $c --prefix "$c/" `
      --connection-string $connStr --query 'length(@)' -o tsv
    if ($count -ne '0') {
      Write-Warning "[verify] Found $count nested blobs under '$c/$c/'. Consider cleaning them:"
      Write-Host "az storage blob delete-batch --connection-string `"$connStr`" --source $c --pattern '$c/*'"
    } else {
      Write-Host "[verify] OK: No nested prefix under '$c/$c/'"
    }
  }
}

# Cleanup temp
if ($env:CLEAN_TMP -eq '1') {
  Write-Host "[seed] Cleaning up temp folders..."
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $TMP_CONTENT,$TMP_VIDEO_PRIV,$TMP_VIDEO_PUB
}

Write-Host "[seed] Done."
