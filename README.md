# LoT Documentation

Quick links:

- Local setup and run: [LOCAL_SETUP.md](./LOCAL_SETUP.md)
- Azurite blob sync guide: [AZURITE_SYNC.md](./AZURITE_SYNC.md)
- New carousels:
  - Phased plan: [new-carousels/phased-plan.md](./new-carousels/phased-plan.md)
  - Backend plan: [new-carousels/carousels-be-plan.md](./new-carousels/carousels-be-plan.md)
  - Frontend plan: [new-carousels/new-carousels-fe-plan.md](./new-carousels/new-carousels-fe-plan.md)
  - Phase 1 backend report: [new-carousels/carousels-phase1-report.md](./new-carousels/carousels-phase1-report.md)
- Book reader investigation: [book-readrer-investigation/](./book-readrer-investigation/)
- GitHub overview and rules: [github/README.md](./github/README.md)
- GitHub workflows: [github/github-workflows/README.md](./github/github-workflows/README.md)
- Bitbucket to GitHub migration: [github/bitbucket-to-github-migration.md](./github/bitbucket-to-github-migration.md)
- Azure docs: [azure/README.md](./azure/README.md)
- Backend helper scripts: [be-scripts/README.md](./be-scripts/README.md)

## What’s new

- Phase 1 (Backend) for New Carousels completed:
  - Schema extended with `Carousel.Type`, `Carousel.ConfigJson`, and optional `CarouselAsset.PresentationJson`.
  - Migration applied locally with backfill of `Type` from `IsBookCarousel`.
  - All changes documented under [new-carousels/](./new-carousels/):
    - [Backend plan](./new-carousels/carousels-be-plan.md)
    - [Frontend plan](./new-carousels/new-carousels-fe-plan.md)
    - [Phase 1 backend report](./new-carousels/carousels-phase1-report.md)
  - Makefile extended with `start_containers` target; see [be-scripts/README.md](./be-scripts/README.md) and [LOCAL_SETUP.md](./LOCAL_SETUP.md).