# Phase 3 — Add "Group" as a New Carousel Type

Owner: FE/BE team (lead: CTO)
Status: Planned
Date: 2025-09-18

Goal: Introduce a new carousel type, `Group`, enabling Admins to curate groups of assets/categories rendered by a simple grid/list FE component. Ensure full E2E support across DB → API → Admin → FE mapper → FE component.

## Context
- Existing FE already contains an `asset-group` component (`shared/components/carousels/asset-group/asset-group.component.*`) and mapper helpers (`buildAssetGroup`, `getAssetGroupConfig`, `mapAssetGroup`).
- The BE currently does not expose a `CarouselType.Group` in `CarouselType.cs` (to be confirmed), and Admin likely lacks Group-specific editing UI.

## BE Scope
- Add `Group` to `LoT.DataModels.Enums.CarouselType` enum.
- Ensure `CarouselEntity` supports `ConfigJson` as needed.
- API: `CategoryController` landing/promo payloads should return Group carousels alongside existing types.
- Migration: If enum change requires DB data updates or seeds (new carousels), create a migration.

## Admin Scope
- Admin edit UI should allow creating/editing `Group` carousels:
  - Name, Description, Type=Group
  - Item management: select assets to include (or categories, if we define group-of-categories)
  - Optional `ConfigJson` for presentation, e.g.:
    ```json
    {
      "title": "Group Title",
      "subtitle": "Optional subtitle",
      "textColor": "#FFFFFF",
      "textColorHover": "#58DDA3"
    }
    ```

## FE Scope
- Models: ensure `carousels-v2.ts` has an `AssetGroupItem` and `AssetGroupConfig` (already present).
- Mapper: ensure `CarouselsDataMapperService` maps Group items from the API categories (already has `mapAssetGroup`/`buildAssetGroup`).
- Component: ensure `asset-group` component can be fed by `buildAssetGroup` outputs and styled consistently with Tailwind overrides.
- Pages: Landing/Promo integrate Group carousels by detecting `CarouselType.Group` in categories and rendering the component.

## One-Change-One-Commit Backlog (Phase 3)
- [ ] P3-C01: Add `Group` to `CarouselType` enum (BE)
- [ ] P3-C02: Update any BE DTO mapping to pass through Type=Group (Category/Carousel DTOs)
- [ ] P3-C03: Add migration if needed (seed a sample Group carousel for test)
- [ ] P3-C04: Admin UI — enable selecting Type=Group in carousel creation/edit
- [ ] P3-C05: Admin UI — implement Group item management UI (choose assets)
- [ ] P3-C06: FE — verify/extend mapper to detect and map Group carousels (use `buildAssetGroup`)
- [ ] P3-C07: FE — ensure `asset-group` component accepts mapper outputs and renders
- [ ] P3-C08: Pages — inject Group component when present in Landing/Promo payloads
- [ ] P3-C09: E2E verification with real payload (landing + promo)
- [ ] P3-C10: Documentation updates (screenshots/payload examples)

## Definition of Done (DoD)
- API returns Group carousels in `GET /api/Category/Landing` and `GET /api/Category/Promo` when configured.
- Admin can fully manage Group carousels (create/edit, add/remove items, save config).
- FE maps Group carousels into `AssetGroupItem[]` + `AssetGroupConfig` and renders them.
- QA passes on both Landing and Promo pages with at least one live Group carousel.

## Risks & Mitigations
- **Enum change + DB**: Confirm DB doesn’t store enum as integer with implicit values. If so, verify ordering and add migration carefully.
- **Admin UX**: Item management UI should reuse existing asset pickers to avoid regressions.
- **Styling conflicts**: Ensure Group component styles are scoped to avoid Tailwind conflicts.
