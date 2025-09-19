# New Carousels – Phased Plan

This document defines the phased delivery plan for introducing new carousel types to Land of Tales. It aligns backend, frontend, deployment sequencing, and QA so we can ship safely without affecting production.

## Scope and goals
- Add support for multiple carousel types with per-carousel config and optional per-item presentation overrides.
- Maintain backward compatibility (legacy carousels continue to work) and avoid production risk.
- Deliver value incrementally (BE first, then FE authoring, then FE rendering).

---

## Phase 1 – Backend foundations (DONE)

- Schema
  - `Carousel.Type` (SMALLINT) with enum `CarouselType`: `LegacyVideo`, `LegacyBook`, `Standard`, `Featured`, `Header`, `Grid`.
  - `Carousel.ConfigJson` (NVARCHAR(MAX)) – optional per-carousel config.
  - `CarouselAsset.PresentationJson` (NVARCHAR(MAX)) – optional per-item overrides (e.g., badge, button label, per-breakpoint images, meta).
  - Migration backfills `Type = LegacyBook` where `IsBookCarousel = 1`, else `LegacyVideo`.

- DTOs
  - `CarouselDto`, `CarouselEdit`, `CarouselPost`, `CarouselListModel` → add `Type`, `ConfigJson`.
  - `CarouselAssetDto`, `CarouselAssetPost`, `CarouselAssetEdit` → add `PresentationJson`.

- Compatibility
  - Keep `IsBookCarousel` during transition. No breaking changes to existing FE.

- Deliverables
  - Entities/DTOs updated, migration applied locally.
  - Makefile `start_containers` target added for dev ergonomics.

Links: [Backend plan](./carousels-be-plan.md), [Phase 1 report](./carousels-phase1-report.md)

---

## Phase 2 – Frontend authoring (models/services + Admin UI) — DONE

- Models/types
  - Add `CarouselType` enum in shared models.
  - Extend `Carousel`/`CarouselModel` with `type` and optional `config` (type-specific shapes with defaults).

- Services
  - Update `CarouselService` typings to send/receive `type` and `config`.
  - Optionally add a `types` helper (hardcoded enum map or BE endpoint) for admin select options.

- Admin UI
  - In `carousel-administration-edit`: add a “Type” select.
  - Show a dynamic `config` sub-form depending on selected type (Standard/Featured/Header/Grid) with safe defaults.
  - Show the type in carousel list/grid views.
  - (Phase 2.5) Per-item “presentation” editor for Featured/Header items to override asset-derived defaults.

- Testing
  - Unit tests for typing and form validation.
  - E2E: create/update each type and verify persisted payloads.

- Acceptance criteria (met)
  - Admin can author `type` and `config`.
  - Existing carousels remain unaffected and remain backward compatible.

Links: [Frontend plan](./new-carousels-fe-plan.md), [Phase 2 report](./carousels-phase2-report.md)

---

## Phase 3 – Frontend rendering (components + integrate into existing pages)

 - Components (in `libs/shared/src/lib/components/carousels/`)
   - Use the V2 components already present in the repo:
     - `lot-standard-carousel`, `lot-featured-assets-carousel`, `lot-header-carousel`, `lot-standard-grid`, `lot-asset-group`.
   - Note: `AssetGroup` is a separate section (not a `CarouselType`) but is rendered alongside other carousels on Promo/Landing.
   - Ensure inputs have safe defaults and perform responsive behavior.

 - Integration (no new routes)
   - Integrate V2 components directly into the existing Promo and Landing pages.
   - No new routes will be introduced.
   - Use `CarouselsDataMapperService` (shared) for all data transformations from API models to V2 component inputs; provided per component (no root DI) to avoid bloating components with mapping logic.

 - Rendering logic
   - On existing Promo and Landing pages, branch by `carousel.type`:
     - Legacy types → existing `lot-carousel`.
     - Standard → `lot-standard-carousel`.
     - Featured → `lot-featured-assets-carousel`.
     - Header → `lot-header-carousel` (additional carousel entry; do NOT replace category cover).
     - Grid → `lot-standard-grid`.

- Data mapping
  - Derive images/text from `Asset` (Feature/FeatureMobile, Thumbnail/ThumbnailMobile, BookBackground/AuthorsBg; title/summary/tags/playingTime).
  - Apply `PresentationJson` overrides when present.

 - QA
  - Responsive checks (mobile/tablet/desktop), performance, accessibility, and regression on legacy pages (no route changes).

- Acceptance criteria
  - New types render correctly with defaults on existing Promo and Landing pages; legacy behavior remains unchanged for legacy carousels.

### Status (2025-09-19)

- Promo page: DONE via a single `lot-carousel-wrapper` per category that orchestrates all V2 types (`Standard`, `Grid`, `Featured`, `Header`).
- Unified pause: Implemented using `AssetModalService.uiPlayback$` and propagated through the wrapper to child carousels.
- Landing page: PENDING similar wrapper adoption.

---

## Deployment and safety
- Sequence: BE first (with migration) → FE Phase 2 (admin) → FE Phase 3 (rendering).
- Feature flags are optional; we can gate Phase 3 rendering if needed.
- Always validate in staging/UAT; back up DB before running the migration in production.

## Backward compatibility
- Old FE continues to work with BE Phase 1 changes.
- FE progressively adopts `type` and `config`; legacy `isBookCarousel` remains for a period.
- Optional cleanup later to deprecate `IsBookCarousel` after full FE adoption.

---

## Phase 4 – Migrate legacy landing/promo to V2 components (dual-render by Type)

- Scope
  - Update Promo and Landing to support both legacy carousels and V2 components simultaneously, based on `Carousel.Type` received from BE.
  - Legacy types render with the existing `lot-carousel`; new types map to the appropriate V2 components and options.
- Links: Migration plan: `docs/new-carousels/carousels-phase4-migration-plan.md`

---

## Phase 5 – Deprecate IsBookCarousel end-to-end (TBD)

- Scope (draft):
  - Remove `IsBookCarousel` from BE DTOs and DB schema; rely exclusively on `Type`.
  - Remove FE boolean fallbacks; prefer `type` across Admin, Landing, Promo, and Search (where applicable).
  - Update shared models to drop or mark `isBookCarousel` as deprecated.
  - Migration: drop column and clean up indices/defaults.

Links: Deprecation plan (existing document): `docs/new-carousels/carousels-phase4-plan.md`

---

## Deployment and safety
- Sequence: BE first (with migration) → FE Phase 2 (admin) → FE Phase 3 (rendering).
- Feature flags are optional; we can gate Phase 3 rendering if needed.
- Always validate in staging/UAT; back up DB before running the migration in production.

## Backward compatibility
- Old FE continues to work with BE Phase 1 changes.
- FE progressively adopts `type` and `config`; legacy `isBookCarousel` remains for a period.
- Optional cleanup later to deprecate `IsBookCarousel` after full FE adoption.
