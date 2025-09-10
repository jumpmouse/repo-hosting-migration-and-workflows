# Land of Tales Backend Plan: Introduce 4 New Carousel Types

This document describes the backend changes required to support four new carousel types (as demoed in `slick-carousel/`) across data model, migrations, DTOs, services, mapping, and API surface. It also outlines a backward-compatible rollout and testing strategy.

## Current State (Findings)
- Entities
  - `LoT.DataModels/Domain/CarouselEntity.cs` has `Name`, `Description`, `IsBookCarousel?`, `IsNameVisible`, and navigation to `CarouselAssets`, `CategoryCarousels`, `CarouselPagePlaceHolders`.
  - `CarouselAssetEntity` links a `Carousel` and an `Asset` with `OrderIndex`.
  - `CategoryCarouselEntity` links a `Category` and a `Carousel` with `OrderIndex`.
- DTOs / Models
  - `CarouselDto`, `CarouselEdit`, `CarouselPost` contain `Name`, `Description`, `IsBookCarousel?`, `IsNameVisible`.
  - `CarouselListModel` used for landing returns `Name`, `Description`, `IsBookCarousel`, `IsNameVisible`, and `Assets`.
- Mapping
  - `LoT.Logic/Mappings/CarouselProfile.cs` maps between entity and DTOs, and projects `CarouselListModel` assets from `CarouselAssets`.
- Services / Repos / API
  - `CarouselService.GetByCategoryId(categoryId)` loads carousels and their assets for a category via `CarouselRepository.GetByCategoryId`.
  - REST controllers: `CarouselController`, `CarouselAssetController`, `CategoryCarouselController` provide CRUD and ordering.
- Schema
  - Migration 29 adds `IsBookCarousel` (misnamed as "Add Carousel Type").
  - Migration 41 adds `IsNameVisible`.

Limitation: carousels are logically one type distinguished by `IsBookCarousel`. There is no way to store per-carousel layout/configuration or per-item presentation overrides required by the new UI components seen in `slick-carousel/` (Standard, Featured, Header, Grid).

## Target Capability
Support 4+ distinct carousel types, each with its own config (and optionally per-item presentation overrides), while keeping the current book/video carousels working.

- Types (proposed)
  - `LegacyVideo` (current non-book)
  - `LegacyBook` (current book)
  - `Standard` (multi-card slider)
  - `Featured` (hero feature card with background + foreground images and meta)
  - `Header` (top hero banner/slider)
  - `Grid` (non-slider grid)

- Per-carousel config examples (from `slick-carousel`):
  - `Standard`: `autoPlay`, `autoPlaySpeed`, `speed`, `loop`, `slidesPerView{Desktop,Tablet,Mobile}`, `componentTitle`, `componentTitleVisible`, `componentTitleColor`, `backgroundColorOrImage`, `showInfoPanelOnClick`.
  - `Featured`: `autoPlay`, `autoPlaySpeed`, `speed`, `loop` (most styling comes from items).
  - `Header`: `autoplay`, `autoplaySpeed`, `arrows`, `fade`, `infinite`.
  - `Grid`: `backgroundColorOrImage` (+ optional grid sizing if needed).

- Per-item presentation (optional but recommended):
  - For `Featured`/`Header`, items may need overrides beyond default Asset data: badge text, CTA label, background/feature images per breakpoint, meta fields.

## Data Model Changes
1) Extend `Carousel` with a type and a JSON config
   - Add to table `Carousel`:
     - `Type` (tinyint) NOT NULL DEFAULT 0
     - `ConfigJson` (nvarchar(max)) NULL
   - Add enum `CarouselType` in `LoT.DataModels/Enums` (or existing enums location):
     - 0 `LegacyVideo`, 1 `LegacyBook`, 2 `Standard`, 3 `Featured`, 4 `Header`, 5 `Grid`
   - Backfill migration logic:
     - If `IsBookCarousel = 1` => `Type = LegacyBook`
     - Else => `Type = LegacyVideo`

2) (Optional but recommended) Extend `CarouselAsset` for per-item presentation overrides
   - Add to table `CarouselAsset`:
     - `PresentationJson` (nvarchar(max)) NULL
   - This will allow specifying fields like `topLeftBadgeText`, `buttonLabel`, `featureImage{Desktop,Tablet,Mobile}`, `backgroundImage{Desktop,Tablet,Mobile}`, `meta1`, `meta2` when default asset data is insufficient.

Note: We can keep `IsBookCarousel` for backward compatibility through transition and eventually deprecate it in code once FE fully switches to `Type`.

## DTO and API Contract Changes
- Update DTOs in `LoT.DataModels/Models`:
  - `CarouselDto`, `CarouselEdit`, `CarouselPost`, `CarouselListModel`:
    - Add `CarouselType Type { get; set; }`
    - Add `object? Config { get; set; }` (or strongly-typed union if preferred)
    - Keep `IsBookCarousel?` during transition; FE will move to `Type`.
  - `CarouselAssetDto`, `CarouselAssetPost`, `CarouselAssetEdit`:
    - Add `object? Presentation { get; set; }` to carry item-level overrides (maps to `PresentationJson`).

- Mapping in `LoT.Logic/Mappings`:
  - `CarouselProfile`:
    - Map `Type` <-> `CarouselType`
    - Serialize/deserialize `ConfigJson` to/from `Config` (using `System.Text.Json`).
    - For list model, include `Type` and forward `Config`.
  - `CarouselAssetProfile`:
    - Map `PresentationJson` <-> `Presentation`.

- Controllers: existing generic CRUD can remain. Ensure POST accepts the extended DTOs. No new endpoints strictly required. Optionally add:
  - `GET /api/Carousel/types` for admin dropdown
  - `POST /api/CarouselAsset/{id}/presentation` shortcut (optional)

## Service / Repository Changes
- `CarouselService`/`CarouselRepository`
  - No behavioral change for `GetByCategoryId`, but return `Type` and `Config` in the projection. Carousels of different types can still carry `Assets` as now.
- `CategoryCarouselService` and `CarouselAssetService` remain same for ordering; validation may enforce that assets exist for types that require them.

## Migrations
Create a new migration (e.g., `Migration_0006X_Carousel_Type_Config`) with:
- `Alter.Table("Carousel").AddColumn("Type").AsInt16().NotNullable().WithDefaultValue(0);`
- `Alter.Table("Carousel").AddColumn("ConfigJson").AsString(int.MaxValue).Nullable();`
- Backfill script setting `Type` based on `IsBookCarousel` values.
- (Optional) `Alter.Table("CarouselAsset").AddColumn("PresentationJson").AsString(int.MaxValue).Nullable();`

Keep migration id aligned with your sequence. Ensure that the Data Migrations API (`LoT.DataMigrations.Api`) is prepared to run this migration locally and in CI.

## Backward Compatibility Strategy
- Phase 1: BE writes and returns both `IsBookCarousel` and `Type`; FE keeps using `isBookCarousel` until it supports `type`.
- Phase 2: FE reads `type`. Existing records without `type` are treated as `LegacyVideo/LegacyBook` via migration default.
- Phase 3: Optionally drop `IsBookCarousel` after FE fully migrates.

## Validation Rules
- On create/update:
  - `Type` is required.
  - If `Type == Standard`: validate `Config` has `slidesPerView*`, `autoPlay*` fields.
  - If `Type == Featured` or `Header`: allow empty `Config` (defaults), but validate that FE can derive required visuals from asset files unless overridden by `Presentation` per item.
  - If per-item `Presentation` is posted, validate that values are sensible and URLs (if any) are from allowed origins (or are blob URLs).

## Mapping Defaults (derive from Asset when Presentation not provided)
- `Featured`/`Header` item fields can default to asset properties:
  - `assetTitle` => `Asset.Title`
  - `shortDescription` => `Asset.Summary`
  - `duration` => `Asset.PlayingTime`
  - Images:
    - Feature/FeatureMobile for foreground images
    - Thumbnail/ThumbnailMobile for cards
    - Background fallback: `BookBackground` or `AuthorsBg` where applicable

No schema change is needed for these defaults; use mapper/server-side projection to compute when `Presentation` is null.

## Sample DTO Shapes
- Carousel (create/update):
```json
{
  "id": "...",
  "name": "Summer Picks",
  "description": "Our favourites",
  "type": "Featured",
  "isNameVisible": true,
  "config": {
    "autoPlay": true,
    "autoPlaySpeed": 3000,
    "speed": 500,
    "loop": true
  }
}
```

- CarouselAsset (optional presentation override):
```json
{
  "id": "...",
  "carouselId": "...",
  "assetId": "...",
  "presentation": {
    "topLeftBadgeText": "New",
    "buttonLabel": "Watch",
    "featureImageDesktop": "https://...",
    "featureImageTablet": "https://...",
    "featureImageMobile": "https://..."
  }
}
```

## Implementation Steps
1) Enums & Models
   - Add `CarouselType` enum.
   - Extend DTOs: `CarouselDto/Edit/Post/ListModel` and `CarouselAssetDto/Post/Edit` with `Type`, `Config`, `Presentation`.

2) Migrations
   - Add `Type`, `ConfigJson` to `Carousel`.
   - Backfill `Type` from `IsBookCarousel`.
   - (Optional) Add `PresentationJson` to `CarouselAsset`.

3) Entity Updates
   - Add `CarouselType Type` and `string? ConfigJson` to `CarouselEntity`.
   - Add `string? PresentationJson` to `CarouselAssetEntity` (optional).

4) Mapping
   - Update `CarouselProfile` and `CarouselAssetProfile` to handle JSON (serialize/deserialize) and to include `Type` in outputs.
   - Update `CarouselListModel` mapping to include `Type` and forward `Config`.

5) Services/Repos
   - `CarouselRepository.GetByCategoryId` remains; ensure includes/ordering unchanged. Verify projection includes new fields.

6) Controllers
   - No new endpoints required. Ensure create/update paths accept additional fields.
   - Optionally add `GET /api/Carousel/types`.

7) Tests
   - Unit tests for JSON serialization and type validation.
   - Integration test: create each carousel type, attach assets, verify `GetByCategoryId` payload contains `type`, `config`, and combined asset presentation.

## Decisions and Clarifications

- HeaderCarousel placement: Do NOT replace the current landing category cover image. If a `Header`-type carousel exists for a category, it should be returned like other carousels and rendered by FE as an additional entry in the list. No BE changes to category cover logic are needed.

- Per-item overrides (better explanation): Each carousel item references an `Asset`. By default, presentation data is derived from the Asset (title, summary, playing time, and file images like `Feature`, `FeatureMobile`, `Thumbnail`, `ThumbnailMobile`). Some carousel types (`Featured`, `Header`) benefit from customizing this per item (badge text, CTA label, per-breakpoint images, meta). “Per-item overrides” means an optional, type-specific blob stored alongside the `CarouselAsset` that overrides asset-derived defaults when present. Decision: support optional `PresentationJson` for flexibility and backward compatibility. If `PresentationJson` is null, BE maps defaults from the Asset.

- Image file types: No new file types initially. Reuse existing `Feature`/`FeatureMobile` for foreground, `Thumbnail`/`ThumbnailMobile` for cards, and `BookBackground`/`AuthorsBg` for backgrounds where applicable. If a future design requires tablet-specific backgrounds or other gaps, we can introduce new file types later without blocking Phase 1.

## Production Safety, Side Effects, and Compatibility

- Backward compatibility: Adding `Type`, `ConfigJson`, and optional `PresentationJson` is additive. Existing records default to `LegacyVideo/LegacyBook` via migration, and existing FE continues to work.
- Deployment sequencing: Deploy BE and run migrations first (via `LoT.DataMigrations.Api`), then FE. Since `ForwardOnlyMigration` is used, validate on staging/UAT before production. Consider a DB backup before applying the migration in production.
- Side effects: Slightly larger DB rows due to JSON fields; negligible performance impact expected. Validation paths expand to account for `Type` and optional `Config`.
- App settings: No new settings required; existing blob and streaming configs remain unchanged.

## Minimal FE Changes if Only BE Is Updated

- None required for stability: current FE ignores unknown fields and will continue rendering with legacy `lot-carousel`.
- To leverage new types visually, FE must minimally:
  1) Extend `Carousel`/`CarouselModel` typings with `type` and `config`.
  2) Branch rendering by `type` and plug in new components (Standard/Featured/Header/Grid). Admin UI can be updated later to author `type`/`config`.

## Rollout Notes
- Local development uses Docker SQL Server and Azurite; no additional secrets required.
- After merging BE changes, run migrations via `LoT.DataMigrations.Api`.
- Coordinate with FE:
  - Phase 1: FE reads `type` and starts rendering new components while still supporting `isBookCarousel`.
  - Phase 2: Admin UI exposes `type` + `config` fields and optional per-item presentation editing.

