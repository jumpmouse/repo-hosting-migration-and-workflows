---
description: How to add users to a GitHub repository and organization with recommended permission levels and workflows
---

# GitHub Access Management: Repositories and Organizations

This guide explains how to add users to a GitHub repository and at the organization level, including the most common permission levels and workflows. It focuses on safe defaults and least-privilege access.

> [← Back to Docs Index](./README.md)

## TL;DR (Quick Start)

- Create teams (`tech-leads`, `frontend`) and invite members.
- Grant team access to repos: `tech-leads`=Maintain, `frontend`=Write.
- Enforce 2FA/SSO at org level; keep `Owners` small.
- Use branch protections + CODEOWNERS for gated reviews.
- Use outside collaborators for non-org users; scope access minimally.

See also:
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
- [Post‑Migration GitHub Setup](./github-post-migration-setup.md)

---

## 1) Repository-Level Access (Collaborators and Teams)

### Roles (most used)
- **Read**: clone, pull, issues; no push. Good for auditors, stakeholders.
- **Triage**: manage issues/PRs (label, assign), but no code push. For PMs, QA triage.
- **Write**: push to non-protected branches, create branches/PRs. For regular contributors.
- **Maintain**: manage repo settings except sensitive operations; manage labels, branches, workflows. For technical leads.
- **Admin**: full control including settings, collaborators, secrets, and deletion. Use sparingly.

### Add a user directly as a collaborator
1. Repo → `Settings` → `Collaborators and teams`.
2. `Add people` → enter GitHub username or email.
3. Choose role (e.g., `Write` for engineers, `Triage` for PM/QA).
4. Send invite. The user must accept.

### Add via an Organization Team (recommended)
1. Create/choose a team: Org → `Teams` → `New team` or select existing.
2. Add members to the team (`Add a member`).
3. Grant the team access to the repo: Repo → `Settings` → `Collaborators and teams` → `Add teams` → pick team and role.

### Common use-cases
- **Internal engineer**: Team with `Write`; protected branches enforce PR reviews.
- **Tech lead**: Team with `Maintain`. Rarely `Admin`.
- **External contractor**: Add as **Outside collaborator** to specific repos with `Write` or `Triage`.
- **Auditor/Read-only**: `Read` role.

---

## 2) Organization-Level Access

### Member vs Owner
- **Member**: default role for most users. Limited org settings access.
- **Owner**: full administrative control. Keep this small and trusted.

### Add a user to the Organization
1. Org → `People` → `Invite member`.
2. Enter username/email.
3. Select role: `Member` (default) or `Owner`.
4. Optionally assign to teams during invite.

### Use Teams to manage permissions (best practice)
- Create teams by function or product (e.g., `frontend`, `backend`, `devops`).
- Grant repos to teams with appropriate roles (`Read`, `Triage`, `Write`, `Maintain`).
- Add/remove users from teams to change access globally.

### Outside collaborators
- For non-org users who need access to specific repos only.
- Org → `People` → `Outside collaborators` → `Add outside collaborator`.
- Assign per-repo role.

### Default repository permissions
- Org → `Settings` → `Member privileges` → `Base permissions` for new repos (`None` recommended).
- Avoid granting broad defaults like `Write` to all members.

### SSO and 2FA
- Enforce 2FA and SSO for org security (Org → `Settings` → `Security`).

---

## 3) Quick Role Selection Guide

- **Read**: stakeholders, auditors, read-only bots.
- **Triage**: PM/QA, support engineers managing issues.
- **Write**: regular contributors.
- **Maintain**: tech leads/release managers.
- **Admin**: org/repo admins only.

---

## 4) Managing Secrets and Environments (Access-aware)

- Prefer **organization secrets** for shared CI tokens, restrict to selected repos.
- Use **environments** (e.g., `staging`, `production`) with required reviewers to gate deployments.
- Keep `Admin` limited; `Maintain` is usually enough for workflow management.

---

## 5) CLI (optional): Using GitHub CLI (`gh`)

```bash
# Add a collaborator to a repo with write access
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/<org>/<repo>/collaborators/<username>" \
  -f permission=push

# Add a repo to a team with maintain permission
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/orgs/<org>/teams/<team_slug>/repos/<org>/<repo>" \
  -f permission=maintain
```

Notes:
- `permission` values: `pull` (Read), `triage`, `push` (Write), `maintain`, `admin`.
- Requires `gh auth login` with appropriate scopes.

---

## 6) Governance Tips

- Use branch protection rules (require PR reviews, status checks).
- Limit `Admin` role; prefer `Maintain` for day-to-day repo management.
- Review access regularly (quarterly), remove stale collaborators.
- Use teams to centralize access control and keep auditability.

---

## 7) Quick Checklists

### Add a new engineer (org member)
- Add to org as `Member` → assign to `engineering` team.
- Grant team `Write` on relevant repos; enforce branch protection.
- Optional: add to `release-managers` team with `Maintain` on release repos.

### Add an external contractor
- Do not add to org. Add as **Outside collaborator** to the specific repos.
- Role: `Write` (or `Triage` if read-only + issue triage).
- Set expiration date on invitation if applicable; review monthly.

### Grant temporary admin access
- Prefer `Maintain` first; if `Admin` is required, set a calendar reminder to revoke.

---

## 8) Step-by-Step: Create "Tech Leads" Team (Maintain on all repos)

1. Org → Teams → New team → Name: `tech-leads` → Create team.
2. Grant access to all repos with `Maintain`:
   - Org → Teams → `tech-leads` → Repositories → `Add repository` → select each repo → Permission: `Maintain`.
   - If many repos: repeat, or use a parent team pattern; avoid `Admin` unless required.
3. Invite a user to the organization:
   - Org → People → `Invite member` → enter username/email → Role: `Member` → Send invite.
4. Add the user to the `tech-leads` team:
   - Org → Teams → `tech-leads` → Members → `Add a member` → select the invited user.
5. Verify access:
   - Open any repo → Settings → Collaborators and teams → confirm `tech-leads` has `Maintain`.

Notes:
- `Maintain` allows managing repo settings (labels, branches, workflows) without full admin powers.
- Keep `Owners` group small; prefer `Maintain` for tech leads.

---

## 9) Step-by-Step: Create "Frontend" Team (Write on all repos)

1. Org → Teams → New team → Name: `frontend` → Create team.
2. Grant access to repos with `Write`:
   - Org → Teams → `frontend` → Repositories → `Add repository` → select repos → Permission: `Write`.
   - For repos where FE contributes, ensure branch protection rules require PR reviews.
3. Invite a user to the organization:
   - Org → People → `Invite member` → enter username/email → Role: `Member` → Send invite.
4. Add the user to the `frontend` team:
   - Org → Teams → `frontend` → Members → `Add a member` → select the invited user.
5. Verify access:
   - User can push to non-protected branches and open PRs; protected branches still require reviews.

Tips:
- Pair `Write` with branch protection on `main`/release branches (require PR reviews and status checks).
- Use code owners (`CODEOWNERS`) to auto-request reviews from `tech-leads` on sensitive paths.

---

> [← Back to Docs Index](./README.md)
