# Carousels V2 Audit and Implementation Plan

## Scope

- Audit all FE carousel components under `libs/shared/src/lib/components/carousels/`
- Verify `CarouselsDataMapperService` mapping shapes match component inputs
- Verify usage on `Promo` and `Landing` pages
- Include `Asset Group` in the analysis
- Audit Admin Content Management modal for carousel configuration support
- Verify FE/BE alignment (enums, entities, migrations)
- Provide fix plan and implement minimal, production-ready changes

## Components Reviewed

- Standard carousel: `standard-carousel/standard-carousel.component.ts`
- Standard grid: `standard-grid/standard-grid.component.ts` (+ `.html`)
- Featured assets carousel: `featured-assets-carousel/featured-assets-carousel.component.ts`
- Header carousel: `header-carousel/header-carousel.component.ts`
- Legacy carousel: `components/carousel/carousel.component.ts`
- Asset group: `asset-group/asset-group.component.ts`

## Mapper and Types Reviewed

- `libs/shared/src/lib/components/carousels/services/carousels-data-mapper.service.ts`
- V2 item models: `libs/shared/src/lib/models/carousels-v2.ts`
- FE enum: `libs/shared/src/lib/models/carousel-type.ts`
- FE model: `libs/shared/src/lib/models/carousel.model.ts`

## Admin UI Reviewed

- `carousel-administration-edit.component.ts`
- `carousel-administration-edit.component.html`

## Backend Reviewed

- Entity: `be/LoT.DataModels/Domain/CarouselEntity.cs`
- Enum: `be/LoT.DataModels/Enums/CarouselType.cs`
- Migration: `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs`

## Key Findings

- Standard mapper config misses `showInfoPanelOnClick`, while component and Admin support it.
- Standard mapper default slidesPerView are `3/2/1`; Admin defaults are `5/3/2`.
- Promo template for Grid does not pass `assetType`; StandardGrid uses it for icons/default labels.
- Landing template for Standard does not pass `showInfoPanelOnClick`.
- Admin Standard form lacks `buttonLabel`; component and mapper support it.
- Grid Admin form includes `columns*` and `gutter` fields that current StandardGrid component does not use.
- Header and Featured types are aligned across mapper, components, and Admin.
- `isBookCarousel` is deprecated; Admin derives it from `type` for legacy backward compatibility (to be fully removed in Phase 5).

## Fix Plan (Production-Ready)

1) Mapper and Types
- Add `showInfoPanelOnClick: boolean` to `StandardConfig` interface.
- In `getStandardConfig()`, include `showInfoPanelOnClick: true` default and align slidesPerView defaults to `5/3/2`.

2) Templates
- Landing: bind `[showInfoPanelOnClick]` on `<lot-standard-carousel>`.
- Promo: bind `[assetType]` on `<lot-standard-grid>`; bind `[showInfoPanelOnClick]` on `<lot-standard-carousel>`.

3) Admin UI
- Add `buttonLabel` to Standard config form (TS + HTML). Stringified via `configJson` on save.

## Backend Impact

- None. Config remains JSON. Existing entity and migration already support `ConfigJson`.

## Improvements (Proposals)

- Remove unused Grid `columns*`/`gutter` from Admin or implement them in the component.
- Consider making Featured `buttonLabel` configurable for parity.
- Phase 5: remove `isBookCarousel` end-to-end.

## Verification Checklist

- Each carousel type renders with correct inputs on both Promo and Landing pages.
- Admin changes persist in `ConfigJson` and are reflected by mapper into components.
- Standard shows/hides info panel per config; slidesPerView matches Admin defaults.
- Grid shows correct icon/button labels based on `assetType`.
- Header and Featured autoplay/loop settings function as configured.
