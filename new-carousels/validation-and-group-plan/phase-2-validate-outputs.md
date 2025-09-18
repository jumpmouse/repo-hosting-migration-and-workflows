# Phase 2 — Validate Outputs and Unify Click/UX Behavior (V2 Carousels)

Owner: FE team (lead: CTO)
Status: Planned
Date: 2025-09-18

Goal: Inventory and validate all clickable outputs for the four V2 carousels and unify UX behavior. Ensure all intended actions are wired with explicit handlers, and legacy-equivalent modal behavior is available when configured.

## Scope
- **Carousels in scope**
  - Header (`shared/components/carousels/header-carousel`)
  - Featured Assets (`shared/components/carousels/featured-assets` and `featured-assets-carousel`)
  - Standard Carousel (`shared/components/carousels/standard-carousel`)
  - Standard Grid (`shared/components/carousels/standard-grid`)

## UX Rule-Set (Proposed)
- **Primary click on card**
  - If `showInfoPanelOnClick === true` → expand card content (Standard/Grid)
  - If `showInfoPanelOnClick === false` → open Asset Info modal (legacy parity), or execute primary action directly based on asset type
- **Primary CTA button**
  - Label from config (`buttonLabel`) if present; default based on asset type
  - Action: play video OR open reader depending on asset file presence
- **More Info**
  - Always opens Asset Info modal (same component used elsewhere)
- **Title click**
  - Opens Asset Info modal (consistency with legacy)

### No Actionable Link → Hide Primary CTA
- If an item has no actionable media for its configured asset type (e.g., no video file for `Animation`, no book/book-pdf for `Book`), the primary CTA (Read/Watch/View) must be hidden.
- Detection options (choose one and standardize):
  - Mapper-driven flags per item, e.g., `canPlay` (video), `canRead` (book). Preferred for clarity.
  - Component-level detection based on available `StandardCarouselItem` fields (requires extending item shape to include availability).
- Recommendation: extend the mapper to emit per-item availability flags derived from `AssetModel.files` and use them in components to conditionally render the primary CTA.

## Template Inventory (Current)

### Standard Carousel — `standard-carousel.component.html`
- **Card (div.featured-card)**
  - `(click)="onCardClick(i)"` — uses `showInfoPanelOnClick` to expand
- **Title (a > h3)**
  - `<a href="#"><h3>...</h3></a>` — NO `(click)` handler (candidate to open modal)
- **Primary CTA (a.cus-btn.filled)**
  - `(click)="onPrimaryClick(i, $event)"` — wired
- **More Info (a.cus-btn.bordered)**
  - `(click)="onMoreInfoClick(i, $event)"` — wired

### Standard Grid — `standard-grid.component.html`
- **Card (div.featured-card)**
  - `(click)="onCardClick(i)"` — uses `showInfoPanelOnClick` to expand
- **Title (a > h3)**
  - `<a href="#"><h3>...</h3></a>` — NO `(click)` handler (candidate to open modal)
- **Primary CTA (a.cus-btn.filled)**
  - `(click)="onPrimaryClick(i, $event)"` — wired
- **More Info (a.cus-btn.bordered)**
  - `(click)="onMoreInfoClick(i, $event)"` — wired

### Header Carousel — `header-carousel.component.html`
- **Play (a.cus-btn.filled)**
  - `<a href="#" data-bs-toggle="modal" data-bs-target="#videoModal">` — Bootstrap-based, NO angular `(click)`
- **More Info (a.cus-btn.bordered)**
  - `<a href="" class="cus-btn bordered ms-16">` — NO angular `(click)`
- Observation: Header relies on Bootstrap attributes; unify by wiring Angular `(click)` to open modal and/or play, and remove data attributes for consistency.

### Featured Assets — `featured-assets.component.html`
- **Primary button (button.cus-btn.filled)**
  - `(click)="onWatchMovie()"` — wired
- **Missing**
  - No explicit More Info button. If required by UX parity, add a secondary button `(click)="onMoreInfo()"`.

## One-Change-One-Commit Backlog (Phase 2)
- [ ] P2-C01: Wire title click to open modal in Standard Carousel
- [ ] P2-C02: Wire title click to open modal in Standard Grid
- [ ] P2-C03: Replace Header Bootstrap data-attributes with Angular `(click)` handlers (Play and More Info)
- [ ] P2-C04: Add optional More Info button in Featured Assets (behind config flag if necessary)
- [ ] P2-C05: Ensure `showInfoPanelOnClick === false` path opens modal for Standard/Grid
- [ ] P2-C06: Centralize open-modal behavior (shared service) for consistency across carousels
- [ ] P2-C07: Update mapper to pass any required flags for modal/open behavior (if missing)
- [ ] P2-C08: QA pass — verify all actions across all carousels behave consistently
 - [ ] P2-C09: Hide primary CTA when no actionable link (mapper emits availability flags; components conditionally render)

## Definition of Done (DoD)
- All clickable UI elements have explicit Angular handlers or routerLinks (no unused `href="#"` anchors)
- The same modal and open behavior is used across all carousels where applicable
- `showInfoPanelOnClick` consistently toggles expand vs modal behavior in Standard and Grid
- Header’s Play and More Info actions no longer rely on Bootstrap data attributes; Angular events handle everything
- Documentation updated with before/after inventory

## Risks & Mitigations
- **CSS/JS conflicts (Bootstrap vs Tailwind)**: ensure new click handlers don’t rely on Bootstrap’s JS. Prefer Angular services for modals.
- **Behavioral divergence**: consolidate the open-modal logic in a shared service to avoid drift.

---

# Phase 2a — CarouselWrapperComponent (Container)

Goal: Centralize carousel event wiring, modal opening, and primary-action routing so pages like Promo stay thin and any future pages can reuse a single, consistent orchestration layer.

## Responsibilities
- **Input normalization**: Accept mapper outputs per carousel (items + config) and pass them to the underlying carousel component.
- **Event orchestration**: Handle card/title/More Info/primary clicks and decide whether to expand, open modal, or execute primary action.
- **Modal control**: Open Asset Info modal via a shared modal service (no Bootstrap data attributes).
- **Primary action routing**: Execute play/read depending on `assetType` and availability flags (P2-C09).
- **Availability checks**: Use mapper-emitted `canPlay`/`canRead` (or similar) to show/hide CTAs.
- **Consistency hooks**: Provide outputs (events) that pages can subscribe to for analytics/navigation.

## API (proposed)
- `@Input() type: 'header'|'featured'|'standard'|'grid'`
- `@Input() items: HeaderCarouselItem[] | FeaturedAssetItem[] | StandardCarouselItem[]`
- `@Input() config: HeaderConfig | FeaturedConfig | StandardConfig | GridConfig`
- `@Output() action = new EventEmitter<{ kind: 'primary'|'moreInfo'|'openModal'|'navigate'; itemIndex: number }>()`

## Integration Steps
- Create `CarouselWrapperComponent` in `libs/shared/src/lib/components/carousels/wrapper/`.
- Introduce a shared `AssetModalService` to open the Asset Info modal (and inject any required data).
- For Standard/Grid:
  - Respect `showInfoPanelOnClick`: expand vs modal
  - Title click → open modal
  - Primary click → play/read if available; otherwise hidden (P2-C09)
- For Header:
  - Replace Bootstrap data attributes with Angular `(click)` calls to wrapper methods
  - Map item indices consistently
- For Featured:
  - Ensure primary button calls wrapper primary action
  - Introduce optional More Info button based on config

## One-Change-One-Commit Backlog (2a)
- [ ] P2a-C01: Scaffold `CarouselWrapperComponent` and `AssetModalService`
- [ ] P2a-C02: Wire Standard carousel through wrapper (card/title/primary/more info)
- [ ] P2a-C03: Wire Grid carousel through wrapper
- [ ] P2a-C04: Wire Header carousel through wrapper (remove Bootstrap data attrs)
- [ ] P2a-C05: Wire Featured carousel through wrapper (add optional More Info)
- [ ] P2a-C06: Integrate availability flags to hide primary CTA (uses P2-C09 mapper flags)
- [ ] P2a-C07: Update Promo page to use wrapper (minimize page logic footprint)
- [ ] P2a-C08: Unit smoke tests for wrapper (handlers and modal open)

# Phase 2b — Template and Handler Fixes (Per Carousel)

After wrapper adoption, finalize per-component template fixes to ensure consistent UX.

## Tasks
- **Standard**
  - Add `(click)` on title to open modal
  - Ensure `showInfoPanelOnClick === false` path opens modal via wrapper
- **Grid**
  - Same as Standard (title click + modal path)
- **Header**
  - Replace Bootstrap attributes with Angular `(click)` handlers
  - Ensure More Info opens modal
- **Featured**
  - Introduce optional More Info button and wire to modal

## One-Change-One-Commit Backlog (2b)
- [ ] P2b-C01: Standard — title click opens modal
- [ ] P2b-C02: Standard — modal path for `showInfoPanelOnClick=false`
- [ ] P2b-C03: Grid — title click opens modal
- [ ] P2b-C04: Grid — modal path for `showInfoPanelOnClick=false`
- [ ] P2b-C05: Header — switch to Angular click handlers
- [ ] P2b-C06: Header — More Info opens modal
- [ ] P2b-C07: Featured — add optional More Info and wire to modal
