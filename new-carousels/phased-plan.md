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

## Phase 2 – Frontend authoring (models/services + Admin UI)

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

- Acceptance criteria
  - Admin can author `type` and `config`. Existing carousels remain unaffected.

Links: [Frontend plan](./new-carousels-fe-plan.md)

---

## Phase 3 – Frontend rendering (components + landing integration)

- Components
  - Port from demo to main FE repo:
    - `StandardCarousel`, `FeaturedAssetsCarousel`, `HeaderCarousel`, `StandardGrid`.
  - Ensure inputs have safe defaults and perform responsive behavior.

- Landing integration
  - Branch by `carousel.type`:
    - Legacy types → existing `lot-carousel`.
    - Standard → `StandardCarousel`.
    - Featured → `FeaturedAssetsCarousel`.
    - Header → `HeaderCarousel` (additional carousel entry; do NOT replace category cover).
    - Grid → `StandardGrid`.

- Data mapping
  - Derive images/text from `Asset` (Feature/FeatureMobile, Thumbnail/ThumbnailMobile, BookBackground/AuthorsBg; title/summary/tags/playingTime).
  - Apply `PresentationJson` overrides when present.

- QA
  - Responsive checks (mobile/tablet/desktop), performance, accessibility, and regression on legacy.

- Acceptance criteria
  - New types render correctly with defaults; legacy rendering unchanged.

---

## Deployment and safety
- Sequence: BE first (with migration) → FE Phase 2 (admin) → FE Phase 3 (rendering).
- Feature flags are optional; we can gate Phase 3 rendering if needed.
- Always validate in staging/UAT; back up DB before running the migration in production.

## Backward compatibility
- Old FE continues to work with BE Phase 1 changes.
- FE progressively adopts `type` and `config`; legacy `isBookCarousel` remains for a period.
- Optional cleanup later to deprecate `IsBookCarousel` after full FE adoption.
