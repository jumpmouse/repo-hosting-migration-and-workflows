---
description: Migrating integrations and webhooks from Bitbucket to GitHub — Slack, Sentry, deploy providers
---

# GitHub Integrations Migration

> [← Back to Docs Index](./README.md)

## TL;DR
- Inventory Bitbucket webhooks and apps; recreate as GitHub Apps or webhooks.
- Migrate secrets to org/repo/env; rotate tokens; prefer OIDC for cloud.
- Validate end-to-end by triggering events (PR opened, tag push, deploy).

## 1) Inventory and Mapping
- List current Bitbucket webhooks/integrations (Slack, CI, Sentry, deploys).
- Map to GitHub Apps or custom webhooks.

## 2) Recreate and Secure
- Install GitHub Apps with least-privilege scopes; restrict to needed repos.
- Recreate webhooks; use secret signing; restrict source IPs if supported.

## 3) Validate
- Open PRs, push tags, trigger deploys; ensure notifications and pipelines run.

See also:
- [Post‑Migration Setup](./github-post-migration-setup.md)
- [Security Hardening](./github-security-hardening.md)

---

## Examples

### Webhook secret validation (Node/Express example)

```ts
// webhook.ts
import crypto from 'crypto';
import type { Request, Response } from 'express';

const secret = process.env.WEBHOOK_SECRET || '';

function isValid(signature256: string | undefined, payload: Buffer) {
  if (!signature256) return false;
  const hmac = crypto.createHmac('sha256', secret);
  const digest = 'sha256=' + hmac.update(payload).digest('hex');
  // Use constant-time comparison
  return crypto.timingSafeEqual(Buffer.from(digest), Buffer.from(signature256));
}

export function handler(req: Request, res: Response) {
  const sig = req.get('x-hub-signature-256');
  const raw = (req as any).rawBody as Buffer; // ensure raw body middleware
  if (!isValid(sig, raw)) return res.status(401).send('invalid signature');
  // process event
  res.sendStatus(204);
}
```

### Integration validation checklist

```txt
[ ] GitHub App installed on required repos only (least privilege)
[ ] Webhook URL reachable, secret configured and validated
[ ] Events subscribed match the need (avoid broad wildcards)
[ ] Cloud credentials via OIDC where possible (no long-lived tokens)
[ ] Test: open PR, push tag, trigger deploy → integration responds
```

