---
description: Choosing between GitHub-hosted and self-hosted runners, with security and scaling guidelines
---

# GitHub Actions Runner Strategy

> [← Back to Docs Index](./README.md)

## TL;DR
- Start with GitHub-hosted runners unless you need custom tooling, network, or GPUs.
- For self-hosted: isolate per repo/org, use ephemeral runners, and least-privilege.
- Lock down tokens/permissions; rotate credentials; monitor usage.

## 1) Hosted vs Self-hosted
- GitHub-hosted: zero maintenance, broad images; pay per minute.
- Self-hosted: custom images/network, potential cost efficiency; manage security/updates.

## 2) Security Baselines
- Use ephemeral/auto-scaling runners; avoid long-lived pets.
- Scope runners to specific repos or org with labels; restrict who can use.
- Run as non-root where possible; network egress controls; secrets mounted minimally.
- Use OpenID Connect (OIDC) to cloud providers to avoid static long-lived secrets.

## 3) Scaling and Performance
- Caching: actions/cache with lockfile keys; container registry pulls with auth.
- Reusable workflows and matrix builds to parallelize.
- Concurrency groups per branch/env to prevent overlapping deploys. See [Workflows guide](./github-workflows/README.md).

## 4) Observability
- Emit metrics (queue time, runtime, success rate).
- Alert on long queue times; scale runner pools accordingly.

See also:
- [Security Hardening](./github-security-hardening.md)
- [Monorepo CI Guide](./github-monorepo-ci-guide.md)

---

## Examples

### Self-hosted runner job with minimal permissions

```yaml
name: build
on: [pull_request]
jobs:
  build:
    runs-on: [self-hosted, linux, ephemeral]
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - name: Install
        run: npm ci
      - name: Test
        run: npm test -- --ci
```

### OIDC to cloud provider (generic)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: actions/checkout@v4
  # Authenticate to cloud using OIDC (example action varies by provider)
  - name: Cloud auth via OIDC
    uses: cloud/provider-oidc-action@v1
    with:
      audience: repo:${{ github.repository }}:ref:${{ github.ref }}
  - name: Deploy
    run: ./deploy.sh
```

