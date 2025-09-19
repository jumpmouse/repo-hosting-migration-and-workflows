# Release RC on Push (Push)

Source YAML: ../../../.github/workflows/_release-rc-on-push.yml

## Purpose
On push to `release/vX.Y.Z`, tag next RC `vX.Y.Z-rc.N` if not frozen.

## Trigger
- push: branches matching `release/**`

## Permissions and Concurrency
- permissions: contents: write
- concurrency: group `rc-${{ github.ref_name }}` with cancel-in-progress true

## Guards
- Skips when `RELEASE_FREEZE == 1`.
- Skips if a `promote-release.yml` run is currently in progress (queried via `gh api`).

## Jobs
- tag-rc
  - Compute next RC for the branch and push the tag.

## Snippet
```bash
EXISTING=$(git tag -l "${VER}-rc.*" | sed -E 's/^.*-rc\.([0-9]+)$/\1/' | sort -n | tail -n1)
NEXT=${EXISTING:+$((EXISTING+1))}; [ -z "$NEXT" ] && NEXT=1
```

## Related
- Promote Release: ./promote-release.md
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
