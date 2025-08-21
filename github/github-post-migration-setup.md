---
description: Required GitHub setup after migrating from Bitbucket — step-by-step with UI and CLI, including CODEOWNERS
---

# Post‑Migration GitHub Setup (Required Steps)

> [← Back to Docs Index](./README.md)

## TL;DR (Quick Start)

- Create teams and invite members; grant repo access (`tech-leads`=Maintain, `frontend`=Write).
- Configure repo defaults: squash merges, Actions permissions, workflow permissions.
- Create env branches (`dev`, `test`, `staging`, `prod1`, `prod2`) and set branch protections.
- Add `.github/CODEOWNERS` and enable Code Owners review on higher envs.
- Create Environments with secrets and required reviewers; wire CI checks as required status checks.
- (If guarding workflows) Create repository variables: `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `RELEASE_FREEZE`.
- Validate release process (manual or automated on tag push).

See also:
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
- [GitHub Access Management](./github-access-management.md)

---

This is a complete, step‑by‑step checklist to finish moving from Bitbucket to GitHub for a single project/repo. It focuses on required steps and best‑practice defaults. UI paths are listed first, with optional GitHub CLI equivalents.

Scope: teams/permissions, repo defaults, branch protections, CODEOWNERS, Actions/permissions, environments and secrets, and release settings.

---

## 1) Organization: Teams and Membership

### 1.1 Create teams
- UI: Org → Teams → New team
  - `tech-leads` (role target: Maintain on repos)
  - `frontend` (role target: Write on repos)
- CLI (optional):
```bash
# create team
gh api -X POST /orgs/<org>/teams -f name=tech-leads -f privacy=closed
gh api -X POST /orgs/<org>/teams -f name=frontend -f privacy=closed
```

### 1.2 Invite members
- UI: Org → People → Invite member → enter username/email → Role: Member
- CLI:
```bash
gh api -X PUT /orgs/<org>/memberships/<username> -f role=member
```

### 1.3 Add users to teams
- UI: Org → Teams → <team> → Members → Add a member
- CLI:
```bash
gh api -X PUT /orgs/<org>/teams/tech-leads/memberships/<username>
gh api -X PUT /orgs/<org>/teams/frontend/memberships/<username>
```

---

## 2) Grant Team Access to the Repository

- UI: Repo → Settings → Collaborators and teams → Add teams
  - `tech-leads`: Maintain
  - `frontend`: Write
- CLI:
```bash
# grant Maintain to tech-leads on repo
gh api -X PUT \
  "/orgs/<org>/teams/tech-leads/repos/<org>/<repo>" \
  -f permission=maintain
# grant Write to frontend on repo
gh api -X PUT \
  "/orgs/<org>/teams/frontend/repos/<org>/<repo>" \
  -f permission=push
```

Required: keep `Owners` group small; avoid Admin for day‑to‑day work.

---

## 3) Repository Defaults

- UI: Repo → Settings → General →
  - Pull Requests:
    - Enable “Allow squash merging” (recommended)
    - Disable “Allow merge commits” (optional best practice)
    - Auto‑delete head branches
  - Actions → General:
    - Actions permissions: “Allow GitHub Actions to run” for this repo
    - Workflow permissions: Read repository contents + (if needed) Write for releases/deploy

CLI (selected):
```bash
# repo settings via API are limited; prefer UI for PR merge strategies.
```

---

## 4) Branching Model and Branch Creation

Create long‑lived branches:
- `dev`, `test`, `staging`, `prod1`, `prod2`

- UI: Repo → Code → Branches → New branch (from `main`)
- CLI:
```bash
git switch -c dev && git push -u origin dev
git switch -c test && git push -u origin test
# repeat for staging, prod1, prod2
```

Merge flow (policy):
- Features → PR to `dev` (1 approval)
- `test` is auto‑updated from `dev` by `_sync-dev-to-test.yml` (no PRs between `dev` and `test`)
- `staging` is updated only from `release/vX.Y.Z` via `start-release.yml` and `_release-rc-on-push.yml`
- Production is updated only by `promote-release.yml` operating on the `release/vX.Y.Z` branch; it merges the release back to `main`
- No PRs between env branches for `test`/`staging`; hotfixes are deployed via workflow and cherry‑picked back to `dev`

---

## 5) Branch Protection Rules (Required)

UI: Repo → Settings → Branches → Add rule (repeat per branch)
- For `dev`, `test`:
  - Require a pull request before merging
  - Require 1 approval
  - Require status checks to pass (select CI checks)
- For `staging`, `prod1`, `prod2`:
  - Require a pull request before merging
  - Require 2 approvals
  - Require status checks to pass (build, tests, lint, deploy check)
  - Include administrators (on)
  - Restrict who can push (add `tech-leads` if needed)
  - Require review from Code Owners (on; see section 6)

CLI example (requires REST calls per rule; UI is simpler):
```bash
# Example: require PR reviews and status checks (partial)
# Note: GitHub API for branch protections is verbose; consider UI for accuracy.
```

---

## 6) CODEOWNERS (Required for gated reviews)

Purpose: Automatically request reviews from responsible teams on matching paths and enforce required approvals when “Require review from Code Owners” is enabled in branch protection.

### 6.1 Create file
- Location (choose one, top‑to‑bottom precedence):
  - `.github/CODEOWNERS` (recommended)
  - `CODEOWNERS` at repo root
  - `docs/CODEOWNERS`

### 6.2 Reference teams or users
- Teams must be in the form `@<org>/<team>` and the team must have repo access.
- Users as `@username` must have at least Read access.

### 6.3 Example
Create `.github/CODEOWNERS` in the default branch:
```
# Tech Leads own critical folders
/infra/**      @<org>/tech-leads
/security/**   @<org>/tech-leads

# Frontend owns FE app code
/apps/web/**   @<org>/frontend

# Default fallback (optional)
*              @<org>/tech-leads
```
Commit and push:
```bash
mkdir -p .github
$EDITOR .github/CODEOWNERS
git add .github/CODEOWNERS
git commit -m "chore: add CODEOWNERS"
git push
```

### 6.4 Enforce Code Owners reviews
- UI: Repo → Settings → Branches → (staging/prod1/prod2 rules) → Enable “Require review from Code Owners”
- Result: PRs that touch matched paths will require approvals from those teams.

Troubleshooting:
- If teams are not auto‑requested: ensure the team has repo access and the CODEOWNERS path matches.
- Use absolute or glob paths; patterns are matched from repo root.

---

## 7) Environments and Secrets (Required for CI/CD)

Create environments: `dev`, `test`, `staging`, `prod1`, `prod2`.
- UI: Repo → Settings → Environments → New environment
  - Add environment secrets (e.g., `API_URL`, `DEPLOY_TOKEN`)
  - Protection rules: Required reviewers (e.g., `tech-leads`) for `staging`, `prod1`, `prod2`
  - Deployment branches: Restrict to matching branch

Repository Variables (Repo → Settings → Secrets and variables → Actions → Variables):
- Add `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `RELEASE_FREEZE` if your workflows use allowlists and freeze flags.

Workflow example:
```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/deploy.sh
        env:
          API_URL: ${{ secrets.API_URL }}
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

Secrets migration notes:
- Move Bitbucket variables to GitHub repo/Env/Org secrets; reference as `${{ secrets.NAME }}` in workflows.
- Prefer OIDC for cloud auth to reduce static secrets.

---

## 8) Actions: Required Checks and Permissions

- Ensure your CI workflow defines named jobs that become status checks (e.g., `build`, `test`). Map required checks using the exact job names as they appear in workflow runs.
- UI: Repo → Settings → Branches → Edit rule → Require status checks → select checks.
- UI: Repo → Settings → Actions → Workflow permissions → set Write only if needed (releases/deploys).

---

## 9) Releases (Tags + Notes)

- Tags come from migration (mirror push).
- For release notes/artifacts:
  - UI: Repo → Releases → Draft a new release → choose tag → add notes → publish.
  - Or automate on tag push using `softprops/action-gh-release`.

---

## 10) Final Verification Checklist

- Teams exist and have repo access (`tech-leads`=Maintain, `frontend`=Write)
- Members invited and added to teams
- Branches created (`dev`, `test`, `staging`, `prod1`, `prod2`)
- Branch protection rules enforced with Code Owners on `staging`/`prod*`
- `.github/CODEOWNERS` present and matching desired paths
- Environments and secrets configured; deployments gated by reviewers
- Actions enabled and required status checks selected
- Repository variables present (if used): `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `RELEASE_FREEZE`
- Release process validated (manual or automated)

This completes the required GitHub setup after migrating from Bitbucket.

---

> [← Back to Docs Index](./README.md)
