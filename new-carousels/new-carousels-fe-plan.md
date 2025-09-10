# Land of Tales Frontend Plan: Introduce 4 New Carousel Types

This document outlines the changes required in the Angular frontend to support four new carousel types, based on the existing carousel administration and rendering. It incorporates findings from the demo app in `slick-carousel/` (Angular).

## Summary
- Today there is a single carousel type differentiated only by `isBookCarousel` (book vs video styling). Carousels are attached to Categories and render on the landing page.
- Admin lets you create carousels, attach them to categories, and add assets to a carousel.
- We will introduce 4 new carousel types (from `slick-carousel`), with different rendering and data needs:
  1) StandardCarousel (multi-card slider)
  2) FeaturedAssetsCarousel (hero slider with background and feature images)
  3) HeaderCarousel (top hero with text/CTA)
  4) StandardGrid (grid of assets)
- FE must be extended to store a `type` and a per-carousel `config` object, and optionally per-item `presentation` overrides (only if BE enables them). Rendering will branch by `type`.

## Current FE Architecture (where carousels are administered and used)
- Admin (content-management):
  - `libs/admin/.../content-administration/content-administration.component.html` embeds:
    - `lot-category-administration` (left)
    - `lot-carousel-administration` (middle)
    - `lot-asset-administration` (right)
  - Carousel list + CRUD and add-to-category:
    - `carousel-administration.component.ts/html`
    - Create/Update dialog: `carousel-administration-edit.component.ts/html`
      - Fields today: `name`, `description`, `isBookCarousel`, `isNameVisible`.
    - Add carousel to category dialog: `carousel-category-administration-edit.component.ts/html`.
  - Manage assets inside a carousel:
    - `carousel-asset-administration-edit.component.ts/html` (checkbox list of assets per carousel)
- Public content (landing page use):
  - `libs/content/src/lib/landing/landing.component.ts/html`
  - Loads categories and then carousels per category via `CarouselService.getByCategory(categoryId)`.
  - Renders each carousel with shared `CarouselComponent` (`libs/shared/src/lib/components/carousel/`), using `isBookCarousel` to style and to decide `visibleItems`.
- Shared HTTP services and models:
  - `CarouselService`, `CategoryCarouselService`, `CarouselAssetService` under `libs/shared/src/lib/services/http-services/`.
  - Models `Carousel` (id, name, description, isBookCarousel) and `CarouselModel` (name, description, isBookCarousel, isNameVisible, assets) under `libs/shared/src/lib/models/`.

## New Carousel Types and expected props (from demo `slick-carousel/`)
- StandardCarousel: `standard-carousel/standard-carousel.component.ts`
  - Per-carousel config: `autoPlay`, `autoPlaySpeed`, `speed`, `loop`, `slidesPerViewDesktop/Tablet/Mobile`, `componentTitle`, `componentTitleVisible`, `componentTitleColor`, `backgroundColorOrImage`, `showInfoPanelOnClick`.
  - Per-item content: cards with image + optional info panel. Images can reuse Asset files (Thumbnail/Feature).
- FeaturedAssetsCarousel: `featured-assets-carousel/...`
  - Per-carousel config: `autoPlay`, `autoPlaySpeed`, `speed`, `loop`.
  - Per-item inputs: `backgroundImageDesktop/Tablet/Mobile`, `featureImageDesktop/Tablet/Mobile`, `topLeftBadgeText`, `buttonLabel`, `assetTitle`, `shortDescription`, `subType`, `duration`, `meta1`, `meta2`, `tags`.
  - Many of these can be derived from `AssetModel` (title, summary, playingTime, tags, feature/thumb files). We may only need overrides when the defaults aren’t desired.
- HeaderCarousel: `header-carousel/`
  - Likely hero-like slides with background, title/subtitle, CTA link/label.
- StandardGrid: `standard-grid/`
  - Responsive grid, not a slider. Needs grid config (columns/rows by breakpoint) and items.

## Proposed FE Data Model Extensions
- Extend shared models to support types and config:
  - `libs/shared/src/lib/models/carousel.ts`
    - Add `type: CarouselType`.
    - Add optional `config?: CarouselConfig`.
  - `libs/shared/src/lib/models/carousel.model.ts`
    - Add `type: CarouselType` and `config?: CarouselConfig`.
  - Introduce `CarouselType` enum in shared models:
    - `LegacyVideo`, `LegacyBook`, `Standard`, `Featured`, `Header`, `Grid` (names to match BE `CarouselType`).
  - Introduce `CarouselConfig` union type (or discriminated union):
    - StandardConfig { autoPlay, autoPlaySpeed, speed, loop, slidesPerViewDesktop/Tablet/Mobile, componentTitle, componentTitleVisible, componentTitleColor, backgroundColorOrImage, showInfoPanelOnClick }
    - FeaturedConfig { autoPlay, autoPlaySpeed, speed, loop }
    - HeaderConfig { autoPlay, autoPlaySpeed, speed, loop, titleStyle?, ctaStyle? }
    - GridConfig { columnsDesktop, columnsTablet, columnsMobile, gutter?, background? }
  - Optionally (only if BE supports it) add `presentation?: unknown` to per-item `CarouselAssetDto` that carries type-specific overrides (e.g., `FeaturedItemPresentation`).

## Admin UI Changes
- Carousel Create/Update dialog (`carousel-administration-edit.component.*`):
  - Add a `type` select field.
  - Show a dynamic sub-form for `config` based on `type`.
  - Persist via `CarouselService.create()` (same endpoint) using the extended payload.
- Attach carousels to categories: no change to `CategoryCarousel` dialogs, but list should show type (optional label next to name).
- Manage carousel assets:
  - Keep existing checkbox-based add/remove workflow.
  - If BE introduces per-item `presentation` (recommended for Featured/Header), add a small “edit presentation” button per item to open `carousel-asset-presentation-edit` dialog with type-specific fields. Save via a new API (`POST /CarouselAsset/{id}/presentation` or `POST /CarouselAsset` with `presentation`).
- File management (images):
  - Prefer reusing existing Asset Files: `Feature`/`FeatureMobile`, `Thumbnail`/`ThumbnailMobile`, `BookBackground` (already present). Only add new file types if absolutely required for a design gap.

## Public Rendering Changes
- Landing page (`landing.component.ts/html`):
  - Branch rendering by `carousel.type` instead of only `isBookCarousel`.
  - Map:
    - `LegacyVideo`/`LegacyBook` => existing `lot-carousel` (keeps current behavior).
    - `Standard` => use `standard-carousel` from `slick-carousel` ported into `libs/shared` (or `libs/content`).
    - `Featured` => use `featured-assets-carousel` component.
    - `Header` => use `header-carousel` component as a carousel entry; do NOT replace the existing category cover.
    - `Grid` => use `standard-grid` component.
  - Data mapping strategy:
    - Images: resolve from `asset.files` (`FileType.Feature`, `FeatureMobile`, `Thumbnail`, `ThumbnailMobile`, `AuthorsBg`, `BookBackground`).
    - Texts: `asset.title`, `asset.summary`, `asset.tags`, `asset.playingTime`.
    - Button/CTA labels: derive by asset type (`Watch` for video, `Read` for book), with optional override from `presentation`.

## HTTP Services
- `CarouselService` already provides:
  - `get()` for admin, `getByCategory(categoryId)` for landing.
- Update typings to include `type` and `config` in responses and requests.
- If BE exposes a `GET /Carousel/types` for admin dropdown, add a method.
- If BE supports per-item presentation updates, add methods in `CarouselAssetService` accordingly.

## Migration/Compatibility Plan (FE)
- Keep reading `isBookCarousel` for `LegacyBook` styling.
- Gradually switch landing rendering to use `carousel.type` when available.
- For old carousels without `type`, treat as `LegacyVideo`/`LegacyBook` based on `isBookCarousel`.

## Testing
- Unit tests for mapping from `CarouselModel` to component props.
- E2E admin tests: create each new type, set config, attach to category, add assets, verify rendering on landing.

## Open Questions
- Do we need per-item overrides beyond what the asset model already provides? If yes, we need UI to edit and BE field to store them.
- Should `Header` render replace the current category cover (computed from category `files`)? If yes, clarify placement rules.
- Naming of the 4 types and exact UX for each (confirm with design).

## Phased Delivery (FE)
1) Introduce types and configs in models and services (no UI yet).
2) Admin: add `type` select and basic config forms; save to BE.
3) Landing rendering: branch by `type` and integrate new components (port from `slick-carousel`).
4) Phase 2.5: Per-item presentation UI (Featured/Header) using structured fields; persist to `CarouselAsset.presentationJson`.

## Phase 2.5 — Per-item Presentation Editor (Admin)

- Goal: Allow editors to override default, asset-derived fields for specific items in Featured/Header carousels without touching the global `Asset`.

- Data model (FE):
  - Extend `CarouselAssetDto` and `CarouselAssetPost` with `presentationJson?: string | null`.
  - No freeform entry in UI; the JSON is only a transport to the backend. The Admin shows type-specific structured fields.

- Services:
  - Reuse existing `CarouselAssetService.update()` (POST `/CarouselAsset`) to send `{ id, carouselId, assetId, presentationJson }`.

- UI behavior:
  - In `carousel-asset-administration-edit`, show an "Edit presentation" icon next to each checked asset.
  - Open `carousel-asset-presentation-edit` dialog:
    - Featured item fields: `topLeftBadgeText`, `buttonLabel`, `assetTitle`, `shortDescription`, optional `subType`, `duration`, `meta1`, `meta2`, `tags`, and optional image overrides (`backgroundImageDesktop/Tablet/Mobile`, `featureImageDesktop/Tablet/Mobile`).
    - Header item fields: `title`, `subtitle`, `ctaLabel`, `ctaHref`, optional `overlayOpacity`.
    - Values are saved into `presentationJson` (stringified). Empty fields mean "use defaults from Asset".

- Compatibility:
  - Only shown for carousels of type `Featured` or `Header`.
  - Legacy and other types have no per-item presentation UI.

- Testing:
  - Create Featured/Header carousel, add an asset, open presentation editor, set fields, save, reopen and verify values are persisted.

## Decisions and Clarifications

- HeaderCarousel placement: Do not replace the current landing category cover image. If a `Header`-type carousel is used, render it as an additional carousel in the list (same section), without touching the existing cover logic in `libs/content/src/lib/landing/landing.component.*`.

- Per-item overrides (better explanation): Each carousel contains items (assets). By default, the UI derives presentation data for each item from the `Asset` itself (e.g., `title`, `summary`, `playingTime`, and existing `Feature/FeatureMobile/Thumbnail/ThumbnailMobile` images). However, some carousels (especially `Featured` and `Header`) benefit from per-item presentation customizations such as `topLeftBadgeText`, custom `buttonLabel`, or custom images per breakpoint. “Per-item overrides” means allowing an optional, type-specific presentation blob on the `CarouselAsset` that, when present, overrides the defaults derived from the asset. If omitted, the UI falls back to the asset-derived values. We will adopt this model because it provides flexibility without polluting the global `Asset` with presentation-only fields, and it remains fully backward compatible.

- Image file types: No new file types are required initially. We will reuse existing asset files:
  - Foreground/feature images => `Feature` (desktop) and `FeatureMobile` (mobile); use desktop for tablet as fallback.
  - Card thumbnails => `Thumbnail` and `ThumbnailMobile`.
  - Backgrounds (when applicable) => prefer `BookBackground` or `AuthorsBg`; otherwise fall back to `Feature`.
  If a design gap emerges (e.g., tablet-specific backgrounds), we can add optional file types later; not required to ship Phase 1.

## Production Safety, Side Effects, and Compatibility

- Production safety: This plan is backward compatible. The backend will add fields (type/config/presentation) with safe defaults; existing carousels and the current frontend continue to work. Deployment sequencing: deploy BE first (with migrations), then FE. The landing page cover is unchanged.

- Side effects:
  - Storage: New JSON fields (config/presentation) increase DB row size; typical payloads are small.
  - Admin complexity (Phase 2+): Type-specific config/presentation forms add UI surface, but they are optional.

- BE-only change impact on current FE: The current FE ignores unknown fields. If BE alone is upgraded, FE keeps working and will render all carousels using the legacy `lot-carousel` presentation. New types won’t get their specialized visuals until FE is updated to branch by `type`.

## Asset Reuse Mapping (defaults and fallbacks)

- Featured/Header per-item inputs mapping:
  - backgroundImageDesktop => `Feature` or `BookBackground`/`AuthorsBg` if present.
  - backgroundImageTablet => fallback to `Feature`.
  - backgroundImageMobile => `FeatureMobile` else `Feature`.
  - featureImageDesktop => `Feature`.
  - featureImageTablet => `Feature` (fallback) unless overridden.
  - featureImageMobile => `FeatureMobile` else `Feature`.
  - assetTitle => `asset.title`.
  - shortDescription => `asset.summary`.
  - duration/meta/tags => `asset.playingTime`/custom asset fields/tags.
  - buttonLabel => derived by asset type (Read/Watch), overrideable.

## Input Optionality Check (from slick-carousel demo components)

- StandardCarousel (`standard-carousel.component.ts`):
  - Most inputs have defaults: `autoPlay=false`, `autoPlaySpeed=1000`, `speed=500`, `loop=true`, slides-per-view defaults; labels/colors/background have fallbacks. Assets array is required.

- FeaturedAssetsCarousel (`featured-assets-carousel.component.ts`):
  - Inputs `speed`, `autoPlaySpeed`, `loop`, `autoPlay` are declared without defaults in the demo. We will provide safe defaults via `CarouselConfig` (e.g., `autoPlay=false`, `autoPlaySpeed=3000`, `speed=500`, `loop=true`).

- FeaturedAssetsComponent (`featured-assets.component.ts`):
  - Image inputs (`backgroundImage*`, `featureImage*`) and core text fields (`assetTitle`, `shortDescription`, `buttonLabel`, `assetType`) are declared as required in the demo. Our integration will always provide them via mapping from `AssetModel` or via per-item overrides; therefore they can be treated as effectively optional at the data-entry level.

- HeaderCarousel (`header-carousel.component.ts`):
  - Inputs have sensible defaults: `autoplay=true`, `autoplaySpeed=3000`, `arrows=false`, `fade=true`, `infinite=true`.

- StandardGrid (`standard-grid.component.ts`):
  - Inputs have sensible defaults; assets array required.

## Minimal FE Changes if Only BE Is Updated

- None required for stability. The existing FE will continue to work and render carousels using `lot-carousel`.
- To take advantage of new types, the minimal FE enhancement is to:
  1) Extend `Carousel`/`CarouselModel` with `type` and `config` typings.
  2) Branch rendering in `landing.component.html` by `carousel.type` and plug in the new components.
