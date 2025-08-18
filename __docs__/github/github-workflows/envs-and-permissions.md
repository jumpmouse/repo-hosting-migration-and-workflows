# Environments & Permissions

[← Back to Workflows README](./README.md)

This document details how environments, approvals, variables, and permissions integrate with our workflows.

## Environments
We use GitHub Environments for gated deployments and secret scoping:
- `dev`, `test`: non‑production, no manual approvals by default.
- `staging`: pre‑prod, requires approval.
- `prod1`, `prod2`: production, require approvals and stricter protections.

Configure in repo Settings → Environments:
- Required reviewers (teams/users)
- Wait timers if needed
- Environment secrets and variables

## Variables and Feature Flags
Common repo/org variables referenced in workflows:
- `RELEASE_FREEZE`: when `'1'`, blocks RC tagging and staging deploys in `/_release-rc-on-push.yml`.
- `ALLOWED_DEPLOYERS` (comma‑separated): optional allowlist for deploy‑initiating actors.
- `ALLOWED_DEPLOYERS_GLOBAL`: global fallback allowlist used by reusable deploy.

Example guard step:
```yaml
- name: Validate allowed deployers
  env:
    ALLOWED: ${{ vars.ALLOWED_DEPLOYERS || '' }}
  run: |
    if [ -z "$ALLOWED" ]; then
      echo "No ALLOWED_DEPLOYERS var set; skipping allowlist check"; exit 0;
    fi
    IFS=',' read -ra USERS <<< "$ALLOWED"
    for u in "${USERS[@]}"; do [ "$u" = "${{ github.actor }}" ] && exit 0; done
    echo "${{ github.actor }} is not in ALLOWED_DEPLOYERS"; exit 1
```

## Permissions
We follow the principle of least privilege and explicitly set permissions per workflow:
```yaml
permissions:
  contents: read
```
Elevate only where needed, e.g., tagging/releases:
```yaml
permissions:
  contents: write
  actions: write
```

## Approvals and Concurrency
- Use environment approvals for staging and prod.
- Concurrency prevents overlapping deploys to the same target:
```yaml
concurrency:
  group: deploy-${{ github.ref_name }}
  cancel-in-progress: true
```

## Secrets
- Keep secrets in environment secrets; avoid repo‑level secrets for prod.
- Do not print secrets in logs; prefer masked outputs/actions.
