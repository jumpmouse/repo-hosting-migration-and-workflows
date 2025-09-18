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

## Definition of Done (DoD)
- All clickable UI elements have explicit Angular handlers or routerLinks (no unused `href="#"` anchors)
- The same modal and open behavior is used across all carousels where applicable
- `showInfoPanelOnClick` consistently toggles expand vs modal behavior in Standard and Grid
- Header’s Play and More Info actions no longer rely on Bootstrap data attributes; Angular events handle everything
- Documentation updated with before/after inventory

## Risks & Mitigations
- **CSS/JS conflicts (Bootstrap vs Tailwind)**: ensure new click handlers don’t rely on Bootstrap’s JS. Prefer Angular services for modals.
- **Behavioral divergence**: consolidate the open-modal logic in a shared service to avoid drift.
