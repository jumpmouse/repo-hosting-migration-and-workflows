# Sync Dev→Test (Push)

Source YAML: ../../../.github/workflows/_sync-dev-to-test.yml

## Purpose
Keep `test` branch synchronized with `dev` automatically on push to `dev`.

## Trigger
- push: branches [dev]

## Logic
- Attempt fast-forward from `origin/dev` into `test`.
- If histories diverged, mirror `dev` into `test` via `--force-with-lease`.

## Snippet
```bash
if git merge-base --is-ancestor origin/test origin/dev; then
  git checkout test
  git reset --hard origin/test
  git merge --ff-only origin/dev
  git push origin test
else
  git checkout dev
  git push --force-with-lease origin dev:test
fi
```

## Notes
- Configures git identity from `${{ github.actor }}` for traceability.

## Related
- Deploy Dev/Test: ./_deploy-dev-test.md
