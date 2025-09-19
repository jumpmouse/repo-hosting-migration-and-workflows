# Deploy Dev/Test (Push)

Source YAML: ../../../.github/workflows/_deploy-dev-test.yml

## Purpose
On push to `dev` or `test`, run test+lint and build for the same-named branch using reusables. No deploy step.

## Trigger
- push: branches [dev, test]

## Concurrency
- group: `deploy-${{ github.ref_name }}` with cancel-in-progress true.

## Jobs
- test_lint (reusable)
  - Skips if actor is `github-actions` (avoids loops), tests the pushed branch.
- build (reusable)
  - Needs test_lint, builds with environment equal to branch name.

## Related
- Test/Lint reusable: ./_test-lint-reusable.md
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
