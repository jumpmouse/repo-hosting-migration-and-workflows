# Carousels – Phase 4 Plan: Remove IsBookCarousel and rely solely on Type

This plan outlines all backend and frontend steps to fully deprecate and remove `IsBookCarousel`, completing the migration to `Carousel.Type` as the single source of truth.

## Preconditions (must be true before executing Phase 4)

- __Migration backfill completed__: `Carousel.Type` is populated for every record.
  - Verified in `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs` which sets `Type = 1` for `IsBookCarousel = 1` and leaves `0` otherwise.
- __FE prefers `type` with fallback__ already:
  - Landing and Promo use `type === LegacyBook` with fallback to `isBookCarousel` only if type is absent.
  - Admin authors `type`; `isBookCarousel` is computed from `type` and hidden.

## Backend (BE) tasks

1) __DTO cleanup__
   - Remove `IsBookCarousel` from:
     - `LoT.DataModels/Models/CarouselDto.cs`
     - `LoT.DataModels/Models/CarouselEdit.cs`
     - `LoT.DataModels/Models/CarouselPost.cs`
     - `LoT.DataModels/Models/CarouselListModel.cs`
   - Ensure mappings and controllers no longer bind/emit the boolean.

2) __Entity cleanup__
   - Remove `IsBookCarousel` from `LoT.DataModels/Domain/CarouselEntity.cs`.

3) __Migration to drop the column__
   - Create migration e.g. `Migration_00076_Drop_Carousel_IsBookCarousel.cs`:
     - `Alter.Table("Carousel").DeleteColumn("IsBookCarousel");`
   - Validate the column is no longer referenced by views/stored procedures.

4) __Service/Mapping cleanup__
   - Remove any code paths that derive logic from `IsBookCarousel`.
   - Ensure `Type` is required and validated in create/update.

5) __API contract__
   - Update API docs and clients to reflect the removal.

## Frontend (FE) tasks

1) __Admin__
   - `libs/admin/.../carousel-administration/components/carousel-administration-edit/carousel-administration-edit.component.ts/html`
     - Remove the `isBookCarousel` control from the form group.
     - Stop populating/sending `isBookCarousel` to BE.
     - Keep the Type dropdown and type-specific config forms.
   - `libs/admin/.../carousel-administration/carousel-administration.component.ts/html`
     - Update `getTypeLabel(type, isBookCarousel)` to `getTypeLabel(type)` and remove boolean fallback.
   - `libs/admin/.../asset-administration/asset-administration.component.ts`
     - Remove fallbacks deriving `CarouselType` from `isBookCarousel`; rely on `c.type` only.
   - `libs/admin/.../asset-administration/components/carousel-asset-administration-edit/...`
     - Remove `isBookCarousel` fallbacks when computing `carouselType`.

2) __Shared models__
   - `libs/shared/src/lib/models/carousel.ts` and `carousel.model.ts`
     - Remove the `isBookCarousel` property (or mark deprecated and then remove).
     - Ensure downstream code relies on `type: CarouselType` only.

3) __Landing / Promo__
   - Remove fallback to `isBookCarousel` entirely; compute book behavior only from `type === LegacyBook`.

4) __Search (content)__
   - `libs/content/src/lib/search/model.ts` and `search.component.{ts,html}`
     - Replace boolean `isBookCarousel` in `SearchItem` / `SearchConfig` with a type-oriented flag if useful (e.g., `fileType: FileType.Book`) or use a derived `isBook`.
     - Adjust the UI and dialog invocations to rely on derived `isBook`.

5) __Testing and validation__
   - Admin: Create/update each carousel type; verify payloads no longer contain `isBookCarousel`.
   - Landing/Promo: Validate rendering and dialog behavior purely by `type`.
   - Search: Validate sections behave as before using the new field.

## Deployment sequence

1) Deploy FE changes that no longer send the boolean and no longer rely on it.
2) Deploy BE migration to drop the `IsBookCarousel` column.
3) Deploy BE DTO cleanup and API contract updates.

Note: If BE strictly validates incoming DTOs, invert steps 1 and 3 (remove DTO field first), but ensure FE stops sending the field before the migration that drops the column is applied.

## Rollback considerations

- Keep a short-lived feature branch that retains the boolean fallback in FE. If issues arise, roll back to the branch that still understands `isBookCarousel` while BE rollbacks the drop migration.

## Acceptance criteria

- No FE references to `isBookCarousel` remain.
- BE no longer has the `IsBookCarousel` column nor exposes it via DTOs.
- All carousels are classified solely via `Type`, and Admin can author/update type and config.
