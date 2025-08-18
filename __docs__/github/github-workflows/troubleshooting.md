# Troubleshooting

[← Back to Workflows README](./README.md)

This page lists common issues and fixes for our GitHub Actions workflows.

## Common Errors
- Missing underscore in reusable workflow reference
  - Symptom: `Workflow does not exist` or path not found
  - Fix: Ensure `uses: ./.github/workflows/_build-reusable.yml` (underscore prefix) and that the file exists on the branch

- Environment approval not appearing
  - Symptom: Job is waiting but no approval prompt
  - Fix: Verify Environment exists and is referenced by exact name in `with: environment: ...`, and you have permission to approve

- Release freeze blocking RC
  - Symptom: RC tag or staging deploy does not trigger
  - Fix: Check repo/org variable `RELEASE_FREEZE`; set to `'0'` to unfreeze

- Actor not allowed to deploy
  - Symptom: Guard step fails with allowlist message
  - Fix: Add user to `ALLOWED_DEPLOYERS` or `ALLOWED_DEPLOYERS_GLOBAL` variable (comma-separated)

## Diagnosis Tips
- Re-run job with debug logging
  - Set `ACTIONS_STEP_DEBUG` secret to `true` temporarily to enable verbose logs
- Validate workflow syntax locally
  - Use `actionlint` or `act` for quick checks where possible
- Check permissions block
  - Ensure `permissions:` grants `contents: write` where tagging/releases occur

## Safe Rollback
- Re-run previous successful run with same inputs/ref
- For prod deploys, prefer promoting a known-good tag rather than rebuilding

## Contact Points
- CI/CD owners: see CODEOWNERS or repo settings
- Environments admins: owners of `staging`, `prod1`, `prod2` environments
