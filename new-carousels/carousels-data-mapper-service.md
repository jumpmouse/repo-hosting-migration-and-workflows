# CarouselsDataMapperService – Frontend mapping to V2 components

Location: `fe/landOfTales/libs/shared/src/lib/components/carousels/services/carousels-data-mapper.service.ts`

Purpose: Centralize all data transformation from API models (`CategoryModel`, `CarouselModel`, `AssetModel`) into view models required by the V2 carousels:
- `lot-standard-carousel`
- `lot-standard-grid`
- `lot-featured-assets-carousel` (and `lot-featured-assets`)
- `lot-header-carousel`
- `lot-asset-group` (section; not a CarouselType)

The service ensures that components stay DRY and free of mapping logic. It can be provided per component (no root DI) to keep scope and lifecycle local.

## Backend alignment
- Fields added in migration 75 (see `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs`):
  - `Carousel.Type: SMALLINT` → surfaced to FE as `CarouselModel.type?: CarouselType`
  - `Carousel.ConfigJson: NVARCHAR(MAX)` → surfaced to FE as `CarouselModel.configJson?: string | null`
  - `CarouselAsset.PresentationJson: NVARCHAR(MAX)` → surfaced per asset as `presentationJson?: string | null` (merged as overrides)
- Image selection uses `FileType` values from FE:
  - Feature/FeatureMobile, Thumbnail/ThumbnailMobile, BookBackground/AuthorsBg, AuthorsBgMobile

## Public API (selected)
- Collectors by type (find and map from provided categories):
  - `collectHeader(categories): { items: HeaderCarouselItem[]; config: HeaderConfig }`
  - `collectFeatured(categories): { items: FeaturedAssetItem[]; config: FeaturedConfig }`
  - `collectStandards(categories): Array<{ items: StandardCarouselItem[]; config: StandardConfig }>`
  - `collectGrid(categories): Array<{ items: StandardCarouselItem[]; config: GridConfig }>`

- Direct mappers:
  - `mapHeaderSlides(categories): HeaderCarouselItem[]`
  - `mapFeaturedAssets(categories): FeaturedAssetItem[]`
  - `mapStandardItems(carousel?): StandardCarouselItem[]`

- Config getters (parse `configJson` with sensible defaults):
  - `getHeaderConfig(carousel?): HeaderConfig`
  - `getFeaturedConfig(carousel?): FeaturedConfig`
  - `getStandardConfig(carousel?, index=0): StandardConfig`
  - `getGridConfig(carousel?): GridConfig`

- Per-carousel builder helpers:
  - `buildHeaderForCarousel(categories, carousel?)`
  - `buildFeaturedForCarousel(categories, carousel?)`
  - `buildStandardForCarousel(carousel?, index=0)`
  - `buildGridForCarousel(carousel?)`
  - `buildAssetGroup(categories, overrides?)`

## Mapping rules
- `presentationJson` (per asset) overrides any derived defaults. Unknown keys are merged onto the base shape.
- Standard/Grid items use `Thumbnail` (and `ThumbnailMobile` for mobile) as defaults for images.
- Featured/Header use `BookBackground`/`AuthorsBg` for background and `Feature` for foreground/title images when present.
- If tablet-specific backgrounds are absent, desktop background is reused.
- Titles default to `Asset ${id}` when metadata is not available.
- AssetGroup items are derived from the first asset of each category’s first carousel; image uses ThumbnailMobile → Thumbnail fallback, title uses category name.

## DI usage (component-level)
We provide the service per component to avoid global coupling and to match the user preference.

Example (Landing):
```ts
import { Component, inject } from '@angular/core';
import { CarouselsDataMapperService } from '@land-of-tales/shared';

@Component({
  // ...
  providers: [CarouselsDataMapperService]
})
export class LandingComponent {
  readonly mapper = inject(CarouselsDataMapperService);
}
```

### AssetGroup (Landing/Promo)
```html
@let ag = mapper.buildAssetGroup(categories());
<lot-asset-group
  [assets]="ag.items"
  [title]="ag.config.title"
  [subtitle]="ag.config.subtitle"
  [textColor]="ag.config.textColor"
  [textColorHover]="ag.config.textColorHover"
/>
```

## Examples

### Landing (switch by type)
```html
@for (carousel of landingCategoriesStore.carousels(); track carousel.name; let i = $index) {
  @switch (carousel.type) {
    @case (CarouselType.Standard) {
      @let cfg = mapper.getStandardConfig(carousel, i);
      <lot-standard-carousel [assets]="mapper.mapStandardItems(carousel)" [assetType]="cfg.assetType" [autoPlay]="cfg.autoPlay" [autoPlaySpeed]="cfg.autoPlaySpeed" [speed]="cfg.speed" [loop]="cfg.loop" [componentTitle]="cfg.componentTitle" [componentTitleVisible]="cfg.componentTitleVisible" [componentTitleColor]="cfg.componentTitleColor" [backgroundColorOrImage]="cfg.backgroundColorOrImage" [slidesPerViewDesktop]="cfg.slidesPerViewDesktop" [slidesPerViewTablet]="cfg.slidesPerViewTablet" [slidesPerViewMobile]="cfg.slidesPerViewMobile" [buttonLabel]="cfg.buttonLabel" />
    }
    @case (CarouselType.Grid) {
      @let cfg = mapper.getGridConfig(carousel);
      <lot-standard-grid [assets]="mapper.mapStandardItems(carousel)" [componentTitle]="cfg.componentTitle" [componentTitleVisible]="cfg.componentTitleVisible" [componentTitleColor]="cfg.componentTitleColor" [backgroundColorOrImage]="cfg.backgroundColorOrImage" [buttonLabel]="cfg.buttonLabel" />
    }
    @case (CarouselType.Featured) {
      @let cfg = mapper.getFeaturedConfig(carousel);
      <lot-featured-assets-carousel [assets]="mapper.mapFeaturedAssets(landingCategoriesStore.categories())" [autoPlay]="cfg.autoPlay" [autoPlaySpeed]="cfg.autoPlaySpeed" [speed]="cfg.speed" [loop]="cfg.loop" />
    }
    @case (CarouselType.Header) {
      @let cfg = mapper.getHeaderConfig(carousel);
      <lot-header-carousel [assets]="mapper.mapHeaderSlides(landingCategoriesStore.categories())" [autoplay]="cfg.autoplay" [autoplaySpeed]="cfg.autoplaySpeed" [arrows]="cfg.arrows" [fade]="cfg.fade" [infinite]="cfg.infinite" />
    }
    @default {
      <lot-carousel ...legacy bindings...></lot-carousel>
    }
  }
}
```

### Promo (mini-carousel)
```html
@switch (category.carousels[0].type) {
  @case (CarouselType.Standard) {
    @let std = mapper.buildStandardForCarousel(category.carousels[0], 0);
    <lot-standard-carousel [assets]="std.items" [assetType]="std.config.assetType" ... />
  }
  @case (CarouselType.Grid) {
    @let grid = mapper.buildGridForCarousel(category.carousels[0]);
    <lot-standard-grid [assets]="grid.items" ... />
  }
  @case (CarouselType.Featured) {
    @let feat = mapper.buildFeaturedForCarousel(categories(), category.carousels[0]);
    <lot-featured-assets-carousel [assets]="feat.items" ... />
  }
  @case (CarouselType.Header) {
    @let head = mapper.buildHeaderForCarousel(categories(), category.carousels[0]);
    <lot-header-carousel [assets]="head.items" ... />
  }
  @default {
    <lot-carousel ...legacy bindings...></lot-carousel>
  }
}
```

## Notes
- Keep legacy routes/pages intact. Dual-render by `Carousel.Type` on existing pages.
- When `type` is missing (very old data), legacy behavior remains via existing `lot-carousel` and `isBookCarousel` fallback.
- Consider future enhancement: allow `showInfoPanelOnClick` in Standard/Grid configs if needed.
