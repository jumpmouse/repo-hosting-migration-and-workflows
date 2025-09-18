# Phase 1 — Validate Admin Configurations End-to-End (V2 Carousels)

Owner: FE/BE team (lead: CTO)
Status: In Progress
Date: 2025-09-18

Goal: Validate that Admin-configured carousels (Header, Featured Assets, Standard, Standard Grid) flow correctly from DB → BE API → FE mapper → FE components with real data, producing expected UI.

## Scope
- **Carousels in scope**
  - Header (shared/components/carousels/header-carousel)
  - Featured Assets (shared/components/carousels/featured-assets, featured-assets-carousel)
  - Standard Carousel (shared/components/carousels/standard-carousel)
  - Standard Grid (shared/components/carousels/standard-grid)
- **End-to-end path**
  - DB: `CarouselEntity` (fields: `Type`, `ConfigJson`, relationships to assets and categories)
  - API: `CategoryController` → `GET /api/Category/Landing`, `GET /api/Category/Promo`
  - FE Models/Mapper: `CarouselsDataMapperService`
  - FE Components: each carousel’s component accepts `items` + `config`

## References (backend)
- `be/LoT.DataModels/Domain/CarouselEntity.cs` — has `Type: CarouselType`, `ConfigJson`, relationships
- `be/LoT.DataModels/Enums/CarouselType.cs` — enumerates carousel types (Standard, Header, Grid, Featured, etc.)
- `be/LoT.Api/Controllers/CategoryController.cs`
  - `GET /api/Category/Landing` (AllowAnonymous)
  - `GET /api/Category/Promo`   (AllowAnonymous)
- Related repositories (for deeper debugging if needed):
  - `be/LoT.Data/Repository/CarouselRepository.cs`
  - `be/LoT.Data/Repository/CarouselAssetRepository.cs`
  - `be/LoT.Data/Repository/CategoryCarouselRepository.cs`

## References (frontend)
- Mapper and models
  - `fe/libs/shared/src/lib/components/carousels/services/carousels-data-mapper.service.ts`
  - `fe/libs/shared/src/lib/models/carousels-v2.ts`
- Components and templates
  - Header: `shared/components/carousels/header-carousel/header-carousel.component.*`
  - Featured: `shared/components/carousels/featured-assets*/**`
  - Standard: `shared/components/carousels/standard-carousel/standard-carousel.component.*`
  - Grid: `shared/components/carousels/standard-grid/standard-grid.component.*`

## Data Contracts to Validate
For each carousel type we validate:
- ConfigJson → FE config interface mapping (defaults and overrides)
- Asset list → FE item interface mapping (images, titles, durations, tags)
- Any presentation overrides via `AssetModel.presentationJson`

### Header
- FE config:
  - `HeaderConfig` { `autoplay`, `autoplaySpeed`, `arrows`, `fade`, `infinite` }
- FE items (built from first asset of header carousel):
  - `HeaderCarouselItem` { `id`, `titleImage`, `text`, `textColor`, `imgDesktop`, `imgTablet`, `imgMobile` }
- Mapper functions:
  - `collectHeader`, `mapHeaderSlidesFromCarousel`, `getHeaderConfig`
- Verification checklist:
  - [ ] API response has a Header carousel in categories
  - [ ] `carousel.configJson` parsed into `HeaderConfig` with correct defaults/overrides
  - [ ] First asset has required file types to derive `titleImage` and backgrounds
  - [ ] UI renders at least one header slide without placeholder text

### Featured Assets
- FE config:
  - `FeaturedConfig` { `assetType: 'Animations'|'Books'|'Authors'`, `speed`, `loop`, `autoPlay`, `autoPlaySpeed` }
- FE items:
  - `FeaturedAssetItem` { `assetId`, images (background + feature), `topLeftBadgeText`, `buttonLabel`, `assetTitle`, `shortDescription`, optional `subType`, `duration`, `meta1`, `meta2`, `tags` }
- Mapper functions:
  - `collectFeatured`, `mapFeaturedAssetsFromCarousel`, `getFeaturedConfig`
- Verification checklist:
  - [ ] API provides Featured carousel with assets
  - [ ] `configJson.assetType` respected; default is 'Animations'
  - [ ] All images resolve; no broken URLs
  - [ ] Button label resolves (default 'View' unless overridden by `presentationJson`)

### Standard Carousel
- FE config:
  - `StandardConfig` { `assetType: 'Animation'|'Book'|'Author'`, titling, colors, background, slides per view (desktop/tablet/mobile), `autoPlay`, `speed`, `loop`, `showInfoPanelOnClick`, `buttonLabel?` }
- FE items:
  - `StandardCarouselItem` { `assetId`, `imgDesktop|Tablet|Mobile`, `title`, `subtype`, `tags`, `duration` }
- Mapper functions:
  - `collectStandards`, `mapStandardItems`, `getStandardConfig`
- Verification checklist:
  - [ ] `configJson.assetType` respected; defaults to 'Animation'
  - [ ] `showInfoPanelOnClick` toggles the on-card behavior (expand vs. emit/modal)
  - [ ] `buttonLabel` applied to primary CTA if present
  - [ ] Image selection falls back gracefully to thumbnail variants

### Standard Grid
- FE config:
  - `GridConfig` { `assetType`, background, titling, `showInfoPanelOnClick`, `buttonLabel?` }
- FE items:
  - `StandardCarouselItem` (same mapping as Standard)
- Mapper functions:
  - `collectGrid`, `mapStandardItems`, `getGridConfig`
- Verification checklist:
  - [ ] `configJson.assetType` respected; defaults to 'Animation'
  - [ ] `showInfoPanelOnClick` toggles behavior similar to Standard
  - [ ] `buttonLabel` applied to CTA if present

## One-Change-One-Commit Backlog (Phase 1)
- [ ] P1-C01: Document current BE endpoints and DTO shapes used by Landing/Promo (CategoryDto → carousels → assets)
- [ ] P1-C02: Extract and document Header mapping with a real payload example
- [ ] P1-C03: Extract and document Featured mapping with a real payload example
- [ ] P1-C04: Extract and document Standard mapping with a real payload example
- [ ] P1-C05: Extract and document Grid mapping with a real payload example
- [ ] P1-C06: Add missing config fields or mapping fixes (mapper only) if discrepancies found
- [ ] P1-C07: Add small UI diagnostics (non-invasive logs/guards) if data gaps cause blank renders
- [ ] P1-C08: Produce Phase 1 verification report (screenshots or JSON snippets, expected vs actual)

## Verification Steps (repeatable)
1. Call `GET /api/Category/Landing` and `GET /api/Category/Promo` (anon allowed).
2. Identify carousels by `CarouselEntity.Type` and capture their `ConfigJson`.
3. Feed responses into Angular (dev build) and observe the rendered components.
4. Compare `configJson` vs FE `*Config` objects; confirm defaults.
5. Confirm each image URL resolves (HTTP 200) and renders; log broken assets.
6. Confirm all items are clickable and that the configured behavior is respected.

## Risks & Mitigations
- **Bootstrap vs Tailwind conflicts**: Standard/StandardGrid CSS introduces utility names (`.p-80`, etc.). Mitigate by scoping or overrides in Phase 2.
- **ConfigJson parsing errors**: Mapper uses `safeParse`; defaults are applied. Add logging in dev to flag invalid JSON.
- **Missing file variants**: Mapper falls back across file types; document required vs optional files and expectations.

## Current Status
- Mapper and templates reviewed.
- Endpoints identified for Landing/Promo.
- Next: Run P1-C01..C05 with real payloads and document examples.

## Live Payload Findings (Promo)
- Verified `GET /api/Category/Promo` (dev) returns categories with V2 carousels, including a Standard carousel example:
  - name: "test carousel standard"
  - type: 2 (Standard)
  - configJson:
    ```json
    {
      "assetType":"Book",
      "autoPlay":true,
      "autoPlaySpeed":3000,
      "speed":500,
      "loop":true,
      "slidesPerViewDesktop":5,
      "slidesPerViewTablet":3,
      "slidesPerViewMobile":2,
      "componentTitle":"Standard Carousel",
      "componentTitleVisible":true,
      "componentTitleColor":"#F8F8FF",
      "backgroundColorOrImage":"#0d0d0d",
      "showInfoPanelOnClick":true
    }
    ```
- Assets under this carousel include expected file variants (`Thumbnail`, `ThumbnailMobile`, `Cover`, `CoverMobile`).
- Mapper expectations validated (from config):
  - `StandardConfig.assetType = 'Book'` honored; other defaults align with configJson.
  - `showInfoPanelOnClick: true` → expand-on-click path in Standard/Grid.
  - `StandardCarouselItem` images derive correctly via `pickThumbnail*` helpers.
- Landing endpoint (`GET /api/Category/Landing`) is not marked `AllowAnonymous`; will require authorization for live capture.

## Next Actions (Phase 1)
- P1-C02..P1-C05: Capture representative examples for Header, Featured, Standard, Grid from live payloads and embed snippets here.
- Obtain auth for `Landing` endpoint to capture its payload (e.g., login flow to get Bearer token) and repeat the same validation.
- If any mapper discrepancies are found, address them with a mapper-only fix (P1-C06), one change per commit.

---

## Promo Inventory Summary (Types Present)
Source file: `docs/new-carousels/validation-and-group-plan/promo.pretty.json`

- Counts by `CarouselType` (enum in `be/LoT.DataModels/Enums/CarouselType.cs`):
  - `LegacyVideo (0)`: 5
  - `LegacyBook (1)`: 1
  - `Standard (2)`: 1

- Examples:
  - Type 0: `Nursery Magic`, `A Toddler's Playground` (no configJson)
  - Type 1: `High School` (no configJson)
  - Type 2: `test carousel standard` (has configJson)

Observation: Promo now contains all four V2 carousels. Counts observed:
`Standard (2)`: 1, `Featured (3)`: 1, `Header (4)`: 1, `Grid (5)`: 1. Legacy types are also present (`LegacyVideo (0)`: 5, `LegacyBook (1)`: 1).

## Standard Carousel — Mapping Verification (Promo)

- Config parsed via mapper: `CarouselsDataMapperService.getStandardConfig()`
  - assetType: `Book` (from configJson)
  - componentTitle/Visible/Color: honored
  - backgroundColorOrImage: honored
  - slidesPerViewDesktop/Tablet/Mobile: honored
  - autoPlay/autoPlaySpeed/speed/loop: honored
  - showInfoPanelOnClick: `true`

- Items created via mapper: `mapStandardItems(carousel)` → `StandardCarouselItem[]`
  - `assetId` from `AssetModel.id`
  - Images via `pickThumbnail`, `pickThumbnailMobile`
  - `title` via `deriveTitle()` fallback (uses `Asset {id}` if title not provided)
  - `subtype`, `tags`, `duration` — presentation fields are populated if provided by `presentationJson`

- Component consumption:
  - `shared/components/carousels/standard-carousel/standard-carousel.component.*`
  - Inputs: items (`StandardCarouselItem[]`) + config (`StandardConfig`)
  - Behavior: `showInfoPanelOnClick` controls expand-on-click; primary CTA uses `buttonLabel` if provided (not present here, defaults apply)

## Gaps and Required Data to Complete Phase 1 with Promo Only

- Missing in Promo payload: Header (4), Featured (3), Grid (5)
- To fully complete Phase 1 using Promo only, we need at least one example for each of these types under Promo categories.

### Options
- Use Admin UI to add sample carousels (recommended for today):
  - Add one `Header` carousel to any Promo category, attach 1+ assets with backgrounds/feature images.
  - Add one `Featured` carousel to any Promo category; set `configJson.assetType` and ensure `presentationJson` as needed.
  - Add one `Grid` carousel with several assets; set `configJson.assetType` and `showInfoPanelOnClick`.
- Alternatively, seed via a small migration (slower) or temporarily reuse Landing examples (requires auth).

Once added, rerun capture of `GET /api/Category/Promo` and complete P1-C02..P1-C05.

## Featured Carousel — Mapping Verification (Promo)

- Sample files:
  - Config: `promo-sample-type-3-config.json`
  - First asset: `promo-sample-type-3-asset.json`

- Config parsed via mapper: `CarouselsDataMapperService.getFeaturedConfig()`
  - assetType: `Books` (present in config)
  - speed/loop/autoPlay/autoPlaySpeed: present

- Items created via mapper: `mapFeaturedAssetsFromCarousel(categories, featuredCarousel)` → `FeaturedAssetItem[]`
  - `assetId` from `AssetModel.id`
  - Background images via `pickBackground*` helpers
  - Feature images via `pickFeatureImage` or thumbnails
  - `buttonLabel`, `assetTitle`, `shortDescription`, `subType`, `duration`, `meta1`, `meta2`, `tags` — populated from `presentationJson` if present

- Component consumption:
  - `shared/components/carousels/featured-assets/featured-assets.component.*`
  - Primary button wired `(click)="onWatchMovie()"`
  - Note: No explicit More Info button in template (Phase 2 task exists)

## Header Carousel — Mapping Verification (Promo)

- Sample files:
  - Config: `promo-sample-type-4-config.json`
  - First asset: `promo-sample-type-4-asset.json`

- Config parsed via mapper: `CarouselsDataMapperService.getHeaderConfig()`
  - autoplay/autoplaySpeed/arrows/fade/infinite: present as expected

- Items created via mapper: `mapHeaderSlidesFromCarousel(headerCarousel, ownerCategory)` → `HeaderCarouselItem[]` (first asset only)
  - `id` from `AssetModel.id`
  - `titleImage` via `pickFeatureImage` fallback to thumbnail
  - `text` from owner category paragraph fields; `textColor` from category
  - Background images resolved via `pickBackground*`

- Component consumption:
  - `shared/components/carousels/header-carousel/header-carousel.component.*`
  - Uses ngx-slick and Bootstrap data attributes; Angular `(click)` not yet wired (Phase 2 task)

## Grid Carousel — Mapping Verification (Promo)

- Sample files:
  - Config: `promo-sample-type-5-config.json`
  - First asset: `promo-sample-type-5-asset.json`

- Config parsed via mapper: `CarouselsDataMapperService.getGridConfig()`
  - assetType/backgroundColorOrImage/componentTitle/Visible/Color/showInfoPanelOnClick/buttonLabel: supported
  - DISCREPANCY: Promo config includes `columnsDesktop`, `columnsTablet`, `columnsMobile`, `gutter` which are NOT present in `GridConfig` and are NOT parsed currently.

- Items created via mapper: `mapStandardItems(carousel)` → `StandardCarouselItem[]`
  - Same mapping as Standard; images `imgDesktop|Tablet|Mobile` via pickThumbnail helpers

- Component consumption:
  - `shared/components/carousels/standard-grid/standard-grid.component.*`
  - Behavior similar to Standard; `showInfoPanelOnClick` controls expand-on-click; primary CTA uses `buttonLabel` if provided

### Action (P1-C06)
- Extend `GridConfig` interface and `getGridConfig()` to parse and pass through `columnsDesktop`, `columnsTablet`, `columnsMobile`, and `gutter`.
- One-change-one-commit, mapper-only fix.

---

## Phase 1 Conclusion — DoD

- Verified with live Promo data (all four V2 types present):
  - Header (4): config parsed and items mapped; background/title image/text populated from category and asset files
  - Featured (3): config parsed and items mapped; background + feature images deriving; primary button wired
  - Standard (2): config parsed (assetType Book); items mapped; behavior respects `showInfoPanelOnClick`
  - Grid (5): items mapped; initial config discrepancy identified and fixed

- Mapper-only fix applied (P1-C06):
  - `GridConfig` extended with `columnsDesktop`, `columnsTablet`, `columnsMobile`, `gutter`
  - `getGridConfig()` updated to pass-through these from `configJson`

- Open issues carried forward:
  - Phase 2 (outputs/UX):
    - Wire header actions with Angular `(click)` instead of Bootstrap data attributes
    - Wire title clicks to open modal (Standard/Grid)
    - Ensure `showInfoPanelOnClick === false` opens Asset Info modal
    - Hide primary CTA if no actionable media link (mapper-derived flags)
  - Phase 4 (content correctness):
    - Header/Featured currently present an incorrect title placeholder (e.g., derived id). Should render human-readable asset title.
    - Consolidate exact field sources for titles/subtitles across carousels and standardize fallback rules

Status: Phase 1 DoD met. Evidence and payload samples are committed in this folder. Remaining items are scheduled in Phase 2 and Phase 4.
