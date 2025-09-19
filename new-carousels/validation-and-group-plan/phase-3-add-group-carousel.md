# Phase 3 — Add "Group" as a New Carousel Type

Owner: FE/BE team (lead: CTO)
Status: Deferred
Date: 2025-09-18

Goal: Introduce a new carousel type, `Group`, enabling Admins to curate groups of assets/categories rendered by a simple grid/list FE component. Ensure full E2E support across DB → API → Admin → FE mapper → FE component.

Decision (2025-09-19): Do NOT add `Group` to `CarouselType` at this time. Keep the `asset-group` component as a reusable section (not a carousel). Mapper helpers (`buildAssetGroup`, `getAssetGroupConfig`, `mapAssetGroup`) remain available for optional use, but we will not wire Group as a first-class carousel type.

## Context
- Existing FE already contains an `asset-group` component (`shared/components/carousels/asset-group/asset-group.component.*`) and mapper helpers (`buildAssetGroup`, `getAssetGroupConfig`, `mapAssetGroup`).
- The BE currently does not expose a `CarouselType.Group` in `CarouselType.cs` (to be confirmed), and Admin likely lacks Group-specific editing UI.

## BE Scope (Deferred)
- Do not add `Group` to the backend `CarouselType` enum for now.
- No DB/DTO changes required at this stage.

## Admin Scope (Deferred)
- No Admin changes. If we reintroduce Group later, revisit:
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

## FE Scope (Adjusted)
- Keep `AssetGroupItem` and `AssetGroupConfig` in `carousels-v2.ts`.
- Mapper: keep `buildAssetGroup` and related helpers for optional use by pages.
- Component: `asset-group` remains available as a section component (not driven by `Carousel.Type`).
- Pages: Do not integrate Group as a `CarouselType`. If needed, a page can explicitly render `asset-group` using mapper outputs.

## One-Change-One-Commit Backlog (Deferred)
- [x] Decision: Keep `asset-group` as a section, not a `CarouselType` (no BE enum change).
- [ ] Optional: Document example usage of `asset-group` as a non-carousel section on pages (future doc card).
- [ ] Optional: Visual polish and a11y review of `asset-group` styles (future).

## Definition of Done (DoD) — Deferred scenario
- `asset-group` component remains available for optional use by pages via mapper outputs.
- No changes to API or Admin are required at this time.

## Risks & Mitigations
- **Enum change + DB**: Confirm DB doesn’t store enum as integer with implicit values. If so, verify ordering and add migration carefully.
- **Admin UX**: Item management UI should reuse existing asset pickers to avoid regressions.
- **Styling conflicts**: Ensure Group component styles are scoped to avoid Tailwind conflicts.
