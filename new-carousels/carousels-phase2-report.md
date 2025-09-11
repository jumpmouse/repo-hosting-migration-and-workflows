# Carousels – Phase 2 Implementation Report (Frontend Authoring)

This report documents the exact frontend work completed for Phase 2, with minor Phase 2.5 and Phase 3-aligned adjustments where they were safe and low-risk. It also summarizes validation steps and links back to the overall plan.

## What was implemented (Phase 2)

- __Shared models__
  - `libs/shared/src/lib/models/carousel.ts` and `libs/shared/src/lib/models/carousel.model.ts`
    - Added optional `type?: CarouselType` and `configJson?: string | null` to align with BE Phase 1.

- __Admin UI – Carousel Create/Update__
  - File: `libs/admin/.../carousel-administration/components/carousel-administration-edit/carousel-administration-edit.component.ts/html`
  - Changes:
    - Added a `Type` dropdown with options: LegacyVideo, LegacyBook, Standard, Featured, Header, Grid.
    - Introduced dynamic type-specific config sub-forms:
      - Standard: autoplay/loop/speed/slides-per-view/etc.
      - Featured: autoplay/loop/speed.
      - Header: autoplay/autoplaySpeed/arrows/fade/infinite.
      - Grid: columnsDesktop/Tablet/Mobile, gutter, background.
      - Legacy types: no config.
    - Kept `isBookCarousel` in the form model for BE compatibility but __hid the checkbox from the UI__ and made it driven by `type`:
      - On init and on each `type` change: `isBookCarousel = (type === LegacyBook)`.
      - Before save: re-assert `isBookCarousel` from `type` and serialize `configJson`.
    - Dialog width standardized to 600px across Admin for consistency.

- __Admin UI – Asset per-item presentation (Phase 2.5; planned)__
  - Planned for a follow-up phase (2.5). Not implemented in this phase.
  - Intended scope: dialog to edit `presentationJson` for Featured/Header carousels with type-specific fields.

- __Admin UI – Asset list add/remove modal UX fix__
  - File: `libs/admin/.../asset-administration/components/carousel-asset-administration-edit/...`
  - Fixed checkbox “blink” by immediately syncing the FormArray item’s `checked` state before calling create/delete and refreshing filtered view.

--

- __Admin UI – Middle panel modal widths__
  - File: `libs/admin/.../carousel-administration/carousel-administration.component.ts`
  - Standardized widths to `width: '600px'` for Create/Update list modals.

## Phase 3-aligned but safe adjustments

- __Landing/Promo prefer `type` with fallback__
  - Landing: `libs/content/src/lib/landing/landing.component.ts/html`
  - Promo: `libs/public/src/lib/component/promo/promo.component.ts/html`
  - Introduced helpers to compute “book” behavior from `carousel.type === LegacyBook`, falling back to legacy `isBookCarousel` only when `type` is absent.
  - These changes are non-breaking and prioritize new data from BE.

## Compatibility and safety

- __Backend migration confirmed__:
  - `be/LoT.DataMigrations/Migration_00075_Alter_Carousel_And_CarouselAsset.cs`:
    - Adds `Carousel.Type` (default 0 = LegacyVideo) and `Carousel.ConfigJson`.
    - Backfills `Type = 1` (LegacyBook) where `IsBookCarousel = 1`.
    - Adds `CarouselAsset.PresentationJson`.
  - Therefore, every row has a `Type` value after migration; FE can safely prefer `type`.

- __Admin continues sending `isBookCarousel`__
  - Kept for BE compatibility and any downstream consumers; the value now mirrors `type` automatically.

## Validation steps

- __Admin__
  - Create/update carousel of each type; verify config fields and payload.
  - Add/remove assets via the checkbox dialog; checkboxes persist immediately.
  - For Featured/Header, use the row pencil to edit per-item presentation; save and reopen to confirm persistence.

- __Landing/Promo__
  - Verify that “book” behavior (visible items/offsets/dialog flag) matches `type === LegacyBook` for new carousels.
  - For legacy rows with no `type`, behavior falls back to old boolean.

## Links

- Overall plan: `docs/new-carousels/phased-plan.md`
- BE plan: `docs/new-carousels/carousels-be-plan.md`
- FE plan: `docs/new-carousels/new-carousels-fe-plan.md`

## Next steps

- Proceed to Phase 3 rendering components if desired (Standard/Featured/Header/Grid) and full landing integration by `type`.
- Prepare Phase 4 to remove `isBookCarousel` end-to-end.
