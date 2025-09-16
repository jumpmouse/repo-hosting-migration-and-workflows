# Carousels – Phase 4 Migration Plan: Dual-render by Carousel.Type on existing pages

This document describes how to migrate the existing Promo and Landing pages to support both legacy carousels and the new V2 carousels, branching by `Carousel.Type` while keeping current UX intact. No new routes are introduced; all changes occur within the existing pages.

## Goals
- Render new carousel types (Standard, Featured, Header, Grid) using the V2 components.
- Preserve legacy behavior for existing carousels (LegacyVideo, LegacyBook) via the existing `lot-carousel`.
- Use `Carousel.Type` as the source of truth, with the ability to accept type-specific `configJson` and per-item `presentationJson` overrides.

## Preconditions
- Backend migration completed (Type backfilled): every Carousel row has a valid `Type`.
- V2 components available under `libs/shared/src/lib/components/carousels/`:
  - `lot-standard-carousel` (StandardCarouselComponent)
  - `lot-featured-assets-carousel` (FeaturedAssetsCarouselComponent)
  - `lot-header-carousel` (HeaderCarouselComponent)
  - `lot-standard-grid` (StandardGridComponent)
- Shared item models in `libs/shared/src/lib/models/carousels-v2.ts`.

## Type-to-component mapping
- LegacyVideo, LegacyBook → existing `lot-carousel`.
- Standard → `lot-standard-carousel`.
- Featured → `lot-featured-assets-carousel` (uses `lot-featured-assets` internally).
- Header → `lot-header-carousel` (banner-like hero; does not replace existing category cover logic).
- Grid → `lot-standard-grid`.

## Data mapping
Where not explicitly overridden by `presentationJson`, derive values from `Asset` fields/files:

- Images
  - Desktop/Tablet/Mobile fallbacks use available `Asset.files` by preference:
    1) Feature/FeatureMobile for hero/feature visuals.
    2) Thumbnail/ThumbnailMobile for standard cards.
    3) BookBackground/AuthorsBg where applicable for banner backgrounds.

- Textual metadata
  - Title: `asset.title`
  - Short description/summary: `asset.description` (truncate as needed)
  - Tags: `asset.tags` if present
  - Duration/playing time: `asset.playingTime` or derived from media metadata

- presentationJson overrides (per-item)
  - Featured/Header items can override:
    - `buttonLabel`, `topLeftBadgeText`, `assetTitle`, `shortDescription`, `subType`, `duration`, `meta1`, `meta2`, `tags`
    - Per-breakpoint images (desktop/tablet/mobile) for background/feature/title images

### Shape targets by component
- Standard (lot-standard-carousel, lot-standard-grid)
  - Target item: `StandardCarouselItem` ({ imgDesktop, imgTablet, imgMobile, title, subtype, tags, duration })
  - If `assetType` is Book/Animation/Author, map accordingly for button labels and styling.

- Featured (lot-featured-assets-carousel)
  - Target item: `FeaturedAssetItem` ({ backgroundImage*, featureImage*, topLeftBadgeText, buttonLabel, assetTitle, shortDescription, subType, duration, meta1/meta2, tags, assetType })

- Header (lot-header-carousel)
  - Target item: `HeaderCarouselItem` ({ titleImage, text, textColor, imgDesktop, imgTablet, imgMobile })

## configJson → component inputs
Each carousel’s `configJson` allows type-specific options. Suggested JSON shapes and mapping:

- Standard
  - `{ "autoPlay": boolean, "autoPlaySpeed": number, "speed": number, "loop": boolean,
      "slidesPerViewDesktop": number, "slidesPerViewTablet": number, "slidesPerViewMobile": number,
      "showInfoPanelOnClick": boolean, "backgroundColorOrImage": string, "buttonLabel": string,
      "componentTitle": string, "componentTitleVisible": boolean, "componentTitleColor": string,
      "assetType": "Animation"|"Book"|"Author" }`
  - Map directly to inputs in `StandardCarouselComponent` and `StandardGridComponent`.

- Featured
  - `{ "autoPlay": boolean, "autoPlaySpeed": number, "speed": number, "loop": boolean }`
  - Map to `FeaturedAssetsCarouselComponent` inputs.

- Header
  - `{ "autoplay": boolean, "autoplaySpeed": number, "arrows": boolean, "fade": boolean, "infinite": boolean }`
  - Map to `HeaderCarouselComponent` inputs.

- Grid
  - Same presentational options as Standard minus the carousel motion options.

Defaults: If a config property is absent, rely on the component’s built-in defaults.

## Implementation plan (no route changes)
1) Mapping utilities (shared)
   - Create pure functions that transform `CarouselModel` + `AssetModel[]` into the specific V2 input shapes listed above.
   - Apply `presentationJson` per item if present; otherwise derive from `Asset`.

2) Promo page integration (`libs/public/.../promo/promo.component.{ts,html}`)
   - In the template, branch by `carousel.type`:
     - Legacy types → existing `<lot-carousel>`.
     - Standard → `<lot-standard-carousel ...>`.
     - Featured → `<lot-featured-assets-carousel ...>`.
     - Header → `<lot-header-carousel ...>`.
     - Grid → `<lot-standard-grid ...>`.
   - Use mapping utilities to supply `assets` and component options from `configJson`.

3) Landing page integration (`libs/content/.../landing/landing.component.{ts,html}`)
   - Apply the same branching and mapping approach.
   - Maintain existing cover image and scroll/animation logic; Header type acts as an additional carousel section, not a replacement for the cover.

4) Backward compatibility
   - If `type` is missing (older data), continue to compute book behavior from legacy `isBookCarousel` in the interim.
   - When `type` is present, prefer it entirely for component selection.

5) Testing & QA
   - Unit tests for mapping utilities (verify config defaults and presentation overrides).
   - Integration tests on Promo and Landing to confirm:
     - Correct component selected by `type`.
     - Responsive behavior and performance are acceptable.
     - Legacy carousels continue to render as before.

## Rollout
- Deploy behind a simple feature toggle if desired (e.g., enable V2 per environment).
- Validate on UAT with mixed data: legacy-only, V2-only, and mixed-type pages.

## Acceptance criteria
- Existing Promo and Landing pages correctly render new carousel types using V2 components by `carousel.type`.
- Legacy carousels continue to appear with the existing `lot-carousel`.
- Config and per-item presentation overrides take effect.
- No new routes are introduced.
