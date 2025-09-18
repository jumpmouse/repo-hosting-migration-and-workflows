# New Carousels – Validation and Group Type Plan

Owner: FE/BE team (lead: CTO)
Date: 2025-09-18
Status: In Progress

This folder is the single source of truth for our short-running initiative to:
1) Validate Admin configurations end-to-end for the four new V2 carousels.
2) Validate click outputs and unify UX interactions across these carousels.
3) Add a new carousel type: Asset Group ("group").

We follow a one-change-one-commit style. Each atomic change must be:
- Small, reversible, and independently testable
- Squashable into release branches without conflicts

Phases
- Phase 1: Validate Admin configurations end-to-end (BE → DB → API → FE mapper → Components)
- Phase 2: Validate outputs/click handlers and unify UX rules across V2 carousels
- Phase 3: Add Asset Group as a new carousel type (BE + Admin + FE)

Definitions of Done (DoD)
- Phase 1 DoD:
  - For each V2 carousel (header, featured-assets, standard-carousel, standard-grid):
    - BE DTOs and endpoints documented and verified with live data
    - DB fields/relationships confirmed (no missing fields or type mismatches)
    - Angular mapper produces the exact inputs each component expects
    - Each component renders correctly from live endpoint data (no reliance on mock-only fields)
    - A short verification script or set of manual steps is documented per carousel
- Phase 2 DoD:
  - All clickable elements inventoried per carousel template
  - Each intended link/button has an explicit click handler or routerLink
  - Non-used anchors (href="#") are either removed or repurposed according to the UX rule-set
  - A single UX rule-set documented (when to open modal vs. play/read vs. expand)
  - Consistent behavior across all V2 carousels (with configuration switches)
- Phase 3 DoD:
  - New CarouselType.Group available in BE and persisted in DB
  - API returns group carousels with correct shape
  - Admin supports creating/editing Group carousels (including item list management)
  - FE model + mapper + component implemented; renders correctly with real data
  - Unit/Integration checks added as appropriate (smoke tests)

Files in this folder
- phase-1-validate-configs.md
- phase-2-validate-outputs.md
- phase-3-add-group-carousel.md

Change log
- 2025-09-18: Initial plan created and Phase 1 started (discovery + checklists).
