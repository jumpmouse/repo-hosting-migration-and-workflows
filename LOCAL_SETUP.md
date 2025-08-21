# Local Setup and Run Guide

This document explains how to install prerequisites and run the LoT backend locally on macOS, Windows, and Linux. It also shows how to use the helper scripts in the `be-scripts/` folder.

- API project: `LoT.Api/` (ASP.NET Core, Swagger enabled)
- Migrations API: `LoT.DataMigrations.Api/` (applies DB migrations via HTTP)
- Database: SQL Server (runs in Docker)
- Blob storage: Azurite (Azure Storage emulator in Docker)

Default ports
- API: https://localhost:7057 (HTTP: 5057) from `LoT.Api/Properties/launchSettings.json`
- Migrations API: https://localhost:7200 (HTTP: 5230)
- MSSQL: localhost:1433
- Azurite: blob endpoints on 10000/10001/10002

Configuration files
- API: `LoT.Api/appsettings.Development.json` (connection strings, blob config)
- Migrations API: `LoT.DataMigrations.Api/appsettings.Development.json` (DB and Basic auth)

The repo is preconfigured for:
- MSSQL in Docker with SA password `LoT_StrongP@ssw0rd1`
- Azurite for blobs: `BlobBaseUrl: http://127.0.0.1:10000/devstoreaccount1` and `BlobConnectionString: UseDevelopmentStorage=true`

---

## macOS

### Prerequisites
- Homebrew: https://brew.sh/
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- .NET 8 SDK:
  - `brew install --cask dotnet-sdk@8`
- Trust HTTPS developer certs (one-time):
  - `dotnet dev-certs https --trust`

### One-time database creation (only if not created by migrations)
If migrations fail due to missing DB, create it inside the container:
```zsh
docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'LoT_StrongP@ssw0rd1' -C -Q "IF DB_ID('LoT') IS NULL CREATE DATABASE [LoT];"
```

### Using helper scripts (recommended)
Scripts live in `be-scripts/mac/`. Make them executable once:
```zsh
chmod +x be-scripts/mac/*.sh
```

- Start MSSQL (Docker):
```zsh
be-scripts/mac/start_mssql.sh
```
- Start Azurite (Docker):
```zsh
be-scripts/mac/start_azurite.sh
```
- Apply DB migrations:
```zsh
be-scripts/mac/run_migrations.sh
```
- Run the API:
```zsh
be-scripts/mac/start_api.sh
```
- Stop and remove containers:
```zsh
be-scripts/mac/stop_all.sh
```

Verify:
```zsh
open https://localhost:7057/swagger
curl -k https://localhost:7057/api/test
```

---

## Windows

### Prerequisites
- Docker Desktop for Windows
- .NET 8+ SDK from https://dotnet.microsoft.com/download
- PowerShell 7+ recommended
- Trust HTTPS developer certs (one-time):
  - Open PowerShell as Administrator: `dotnet dev-certs https --trust`

### Using helper scripts (PowerShell)
Scripts live in `be-scripts/windows/`.
- Start MSSQL (Docker):
```powershell
./be-scripts/windows/Start-Mssql.ps1
```
- Start Azurite (Docker):
```powershell
./be-scripts/windows/Start-Azurite.ps1
```
- Apply DB migrations:
```powershell
./be-scripts/windows/Run-Migrations.ps1
```
- Run the API:
```powershell
./be-scripts/windows/Start-Api.ps1
```
- Stop and remove containers:
```powershell
./be-scripts/windows/Stop-All.ps1
```

Verify:
- Open https://localhost:7057/swagger in your browser
- Or run: `curl -k https://localhost:7057/api/test`

---

## Linux

### Prerequisites
- Docker Engine
- .NET 8+ SDK and runtime from your distro or Microsoft packages
- Trust certs: platform-dependent (you can skip trust and use `-k` with curl)

### Using helper scripts
Scripts live in `be-scripts/linux/`. Make them executable once:
```bash
chmod +x be-scripts/linux/*.sh
```

- Start MSSQL (Docker):
```bash
be-scripts/linux/start_mssql.sh
```
- Start Azurite (Docker):
```bash
be-scripts/linux/start_azurite.sh
```
- Apply DB migrations:
```bash
be-scripts/linux/run_migrations.sh
```
- Run the API:
```bash
be-scripts/linux/start_api.sh
```
- Stop and remove containers:
```bash
be-scripts/linux/stop_all.sh
```

Verify:
```bash
xdg-open https://localhost:7057/swagger || true
curl -k https://localhost:7057/api/test
```

---

## Notes and Troubleshooting

- SQL login:
  - Connection string is set in `appsettings.Development.json` files as:
    `Server=localhost,1433;Database=LoT;User Id=sa;Password=Your_password123;MultipleActiveResultSets=true;TrustServerCertificate=True`
  - If you change the SA password, update both appsettings and scripts accordingly.

- Migrations authentication:
  - `LoT.DataMigrations.Api` is protected with Basic auth; `Run-Migrations` scripts already include the header from `LoT.DataMigrations.Api/appsettings.Development.json`.

- Blob storage:
  - Azurite must be running. API blob config points to `UseDevelopmentStorage=true` and `http://127.0.0.1:10000/devstoreaccount1`.

- HTTPS trust:
  - If browsers or curl complain about certificates, ensure `dotnet dev-certs https --trust` was run (or use `curl -k`).

- .NET SDK pin:
  - The repo pins SDK `8.0.413` in `global.json`. Install `dotnet-sdk@8` to match; no extra PATH or DOTNET_ROOT exports are required on macOS.

- Test endpoint:
  - `GET https://localhost:7057/api/test` validates DB connection, a blob upload/delete cycle, and email sending.

---

## Quick start (macOS example)
```zsh
# 1) Prereqs (one-time)
brew install --cask dotnet-sdk@8
dotnet dev-certs https --trust

# 2) Start infra
be-scripts/mac/start_mssql.sh
be-scripts/mac/start_azurite.sh

# 3) Apply migrations
be-scripts/mac/run_migrations.sh

# 4) Run API
be-scripts/mac/start_api.sh
```
