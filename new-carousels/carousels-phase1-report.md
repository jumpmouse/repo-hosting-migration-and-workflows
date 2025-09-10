# Carousels – Phase 1 Implementation Report

This report documents the exact changes made to support new carousel types on the backend (Phase 1), why we made them, and how to run and verify the system locally.

## What was implemented (Phase 1)

- Entity and enum changes
  - Added `CarouselType` enum: `be/LoT.DataModels/Enums/CarouselType.cs` with values `LegacyVideo`, `LegacyBook`, `Standard`, `Featured`, `Header`, `Grid`.
  - Extended `CarouselEntity`: `be/LoT.DataModels/Domain/CarouselEntity.cs`
    - `Type: CarouselType` – the canonical type of the carousel.
    - `ConfigJson: string?` – optional per-carousel configuration.
  - Extended `CarouselAssetEntity`: `be/LoT.DataModels/Domain/CarouselAssetEntity.cs`
    - `PresentationJson: string?` – optional per-item overrides for presentation (e.g., badge text, button label, image overrides). If null, UI defaults derive from Asset.

- DTO changes (additive/backward-compatible)
  - `CarouselDto`, `CarouselEdit`, `CarouselPost`, `CarouselListModel`
    - Added `Type: CarouselType` and `ConfigJson: string?`
  - `CarouselAssetDto`, `CarouselAssetPost`, `CarouselAssetEdit`
    - Added `PresentationJson: string?`

- Migration
  - `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs`
    - Adds `Carousel.Type` (smallint, default 0) and `Carousel.ConfigJson` (NVARCHAR(MAX), nullable).
    - Backfills `Type = 1` (LegacyBook) where `IsBookCarousel = 1`; leaves `0` (LegacyVideo) otherwise.
    - Adds `CarouselAsset.PresentationJson` (NVARCHAR(MAX), nullable).

- Mapping/Services
  - AutoMapper profiles map new fields by convention (property names and types match). No service behavior changes are required; all endpoints remain backward-compatible.

## Why we run `dotnet build LoT.sln -c Debug`

- Compiles the solution to ensure the codebase is consistent and free of compile-time errors after changes.
- Restores and validates NuGet dependencies for the updated types and DTOs.
- Produces build artifacts for local testing and CI.
- `-c Debug` uses the Debug configuration (faster, includes debug symbols); production builds normally use `-c Release`.

## Key commands (macOS/Linux)

- Start containers only (SQL Server + Azurite):
  - `make start_containers`
- Run database migrations:
  - `make migrate`
- Start the full stack (infra → migrations → API):
  - `make start`
- Start API only:
  - `make start_api`
- Clean containers:
  - `make clean`

Notes:
- The Makefile automatically dispatches to OS-specific scripts in `be-scripts/<os>/`.
- Local development per project policy uses Docker SQL Server and Azurite only; RabbitMQ and email background tasks remain disabled.

## Local validation workflow

1) Ensure Docker is running and your containers are stopped (as requested).
2) Start containers: `make start_containers`
3) Apply migrations: `make migrate`
4) Optionally, start API: `make start_api`
5) Smoke test endpoints (examples):
   - `GET /api/Carousel/CategoryId/{categoryId}` – response should now include `type` and `configJson`.
   - `GET /api/CarouselAsset?CarouselId={carouselId}` – response items may include `presentationJson` if set.

## Production safety

- Changes are additive with safe defaults; the current frontend continues to work without updates.
- Recommended deployment sequence: deploy BE + migrations first, validate in staging/UAT (with DB backup), then deploy FE changes when ready.

## Files changed (reference)

- Enums
  - `be/LoT.DataModels/Enums/CarouselType.cs`
- Entities
  - `be/LoT.DataModels/Domain/CarouselEntity.cs`
  - `be/LoT.DataModels/Domain/CarouselAssetEntity.cs`
- DTOs
  - `be/LoT.DataModels/Models/CarouselDto.cs`
  - `be/LoT.DataModels/Models/CarouselEdit.cs`
  - `be/LoT.DataModels/Models/CarouselPost.cs`
  - `be/LoT.DataModels/Models/CarouselListModel.cs`
  - `be/LoT.DataModels/Models/CarouselAssetDto.cs`
  - `be/LoT.DataModels/Models/CarouselAssetPost.cs`
  - `be/LoT.DataModels/Models/CarouselAssetEdit.cs`
- Migration
  - `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs`

---

For any questions or to extend to Phase 2 (FE typings/admin) and Phase 3 (FE rendering), see:
- BE plan: `be/docs/carousels-be-plan.md`
- FE plan: `fe/landOfTales/docs/new-carousels-fe-plan.md`
