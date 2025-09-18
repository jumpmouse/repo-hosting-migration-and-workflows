# Phase 4 — Content Correctness Across V2 Carousels

Owner: FE/BE team (lead: CTO)
Status: Planned
Date: 2025-09-18

Goal: Ensure each V2 carousel presents the correct content (titles, subtitles, labels, images) according to product expectations. Fix inconsistencies (e.g., header/featured showing ID-derived titles instead of human-readable asset titles).

## Scope
- Carousels: Header (4), Featured (3), Standard (2), Grid (5)
- Sources of truth: Asset human-readable `title`, optional `subTitle`, category texts, presentation overlays from `presentationJson`.

## Current Issues (from Phase 1 findings)
- Header and Featured: item title sometimes appears as a derived placeholder (e.g., "Asset {id}"). Should use the asset's human-readable title.
- Standard/Grid: `deriveTitle()` is used as fallback. We should prefer an explicit `title` field if available in data, and only fall back when truly missing.

## Data Availability Review
- FE model `AssetModel` (`libs/shared/src/lib/models/asset.model.ts`) contains only `id` and `files[]`.
- Full `AssetDto` (`libs/shared/src/lib/models/asset.dto.ts`) has `title`, `subTitle`, and richer metadata but is not currently used in category→carousel payload mapping on FE side.
- Category API payload (Promo) includes `categories[].carousels[].assets[]` minimal assets (id + files). Title is not present in the payload.

## Options to fix titles (choose ONE; prefer stability and minimal BE churn)
1) FE-only enrichment via `presentationJson` (short-term)  
   - Keep payload shape. Use `presentationJson` (if provided per-asset in category carousel) to inject a `title` override explicitly at Admin level.  
   - Pros: No BE change; immediate control from Admin UI.  
   - Cons: Requires Admin to populate titles; duplication of existing asset data.

2) BE payload enhancement (recommended medium-term)  
   - Enhance Category→Carousel payload to include `title` (and optionally `subTitle`) per `carousel.assets[]`.  
   - Mapper then uses `asset.title` directly; `deriveTitle()` only as last resort.

3) FE cross-fetch (not recommended)  
   - Load asset titles on the client by fetching each asset detail; introduces N+1 requests, latency, and complexity.

## Proposed Plan
- Adopt (1) immediately where needed using `presentationJson` to ensure demo correctness.  
- Plan for (2) with a BE change in a follow-up ticket:
  - Update DTO that backs `categories[].carousels[].assets[]` to include `title` (and `subTitle?`).
  - Update Admin mapper and FE mapper to accept and use the new fields.

## One-Change-One-Commit Backlog (Phase 4)
- [ ] P4-C01: Audit templates for displayed titles/subtitles across Header, Featured, Standard, Grid
- [ ] P4-C02: Document the exact field priority per carousel (e.g., `presentationJson.title` → `asset.title` → fallback text)
- [ ] P4-C03: Implement FE mapper preference for human-readable title when provided; retain `deriveTitle()` only as last resort
- [ ] P4-C04: If missing in payload, add temporary Admin-side `presentationJson` titles for Header/Featured items
- [ ] P4-C05: Prepare BE change proposal to include `title` (and `subTitle?`) in `categories[].carousels[].assets[]` and reflect in FE models
- [ ] P4-C06: QA pass with Promo payload — verify corrected titles across all four carousels

## Definition of Done (DoD)
- All four V2 carousels display human-readable asset titles; no ID-derived placeholders in normal cases
- Title priority and fallback rules are documented and implemented uniformly
- Evidence (screenshots/snippets) committed under `docs/.../phase-4-content-correctness.md`

## Risks & Mitigations
- BE change lead time: start with `presentationJson` overrides for time-sensitive demos
- Data consistency: clearly document precedence rules to avoid regressions when BE fields arrive
