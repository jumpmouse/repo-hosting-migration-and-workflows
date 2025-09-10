# New Carousels Documentation

This folder contains all documentation related to the introduction of new carousel types in LoT.

## Contents
- Backend plan: [carousels-be-plan.md](./carousels-be-plan.md)
- Frontend plan: [new-carousels-fe-plan.md](./new-carousels-fe-plan.md)
- Phase 1 backend report: [carousels-phase1-report.md](./carousels-phase1-report.md)

## Overview
- Phase 1 (Backend): Introduced carousel `Type` and per-carousel `ConfigJson`, plus optional per-item `PresentationJson` for carousel assets. Added migration to backfill `Type` from `IsBookCarousel`.
- Frontend will later read `type` and `config` to render new components (Standard, Featured, Header, Grid). Existing FE remains compatible while we transition.
