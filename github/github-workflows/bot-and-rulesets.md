# Bot + Rulesets: Allow only workflows to update protected branches

Goal: Lock branches `main`, `uat3`, and `test` so no human can push or merge to them. Only GitHub Actions workflows should be able to update them.

Key concept: Rulesets cannot list “workflows” as bypass actors. You must authenticate workflow pushes with a distinct actor that you add to the ruleset bypass list. Two options:
- Recommended: GitHub App (installation token minted inside Actions)
- Alternative: Machine user (bot) with a fine‑grained PAT

You asked to "use bot only in workflows, no pushes as bot" — this guide ensures the bot/App credentials are used only by workflows and not shared with humans.

---

## Option A — GitHub App (recommended)
Best isolation, least chance of accidental human use, easy rotation.

### A1. Create the GitHub App
Org settings → Developer settings → GitHub Apps → New GitHub App
- App name: lot-workflow-bot
- Webhook: disabled (optional)
- Permissions (Repository):
  - Contents: Read and write
  - Pull requests: Read and write (if you want the app to open/merge PRs)
  - Metadata: Read-only (default)
- (Optional) Environments: Read (to read environment names)
- Save and generate a private key (.pem)

Install the App on the target repository (or the entire org, limited to selected repos).

### A2. Add the App to the ruleset bypass list
Org → Code security → Rules → Create or edit ruleset targeting branches `main`, `uat3`, `test`.
- Target: Branch → include patterns: `main`, `uat3`, `test`
- Protections:
  - Block force pushes
  - Block deletions
  - Require pull request (on human changes)
  - Require status checks (as needed)
- Bypass list: Add the GitHub App (lot-workflow-bot). Do not add users/teams.
- Save the ruleset.

### A3. Store App credentials as secrets
In the repository (or org-level) secrets:
- APP_ID: the App ID (numeric)
- APP_PRIVATE_KEY: the entire PEM content (multiline)

### A4. Use the App token in workflows when pushing/taging
Mint an installation token using `actions/create-github-app-token`, and use it for any push to protected branches or tag creation.

Snippet to push to a protected branch:
```yaml
- name: Mint App token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}

- name: Configure git as bot
  run: |
    git config user.name "lot-workflow-bot"
    git config user.email "lot-workflow-bot[bot]@users.noreply.github.com"

- name: Authenticate origin as App
  env:
    TOKEN: ${{ steps.app-token.outputs.token }}
  run: |
    git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Now your existing git push commands will bypass the ruleset
- name: Push changes
  run: |
    git push origin HEAD:uat3
```

Snippet to push tags via the App:
```yaml
- name: Create and push tag
  env:
    TOKEN: ${{ steps.app-token.outputs.token }}
  run: |
    git tag -a "$TAG" -m "Release $TAG"
    git push origin "$TAG"
```

Where to use this in your repo:
- `start-release.yml`: when pushing the new `release/vX.Y.Z` branch and RC tag
- `promote-release.yml`: when pushing the final tag, squash-merge to `uat3`, merge back to `main`, delete branch
- `hotfix-to-prod.yml`: when creating and pushing hotfix tags

Note: environment approvals (e.g., `environment: uat3`) still require human approval as usual; the App token only bypasses branch protection rulesets.

---

## Option B — Machine user (fine-grained PAT)
Simpler to set up, but ensure the PAT is never shared with humans.

### B1. Create a dedicated machine user
- Create a new GitHub account (e.g., `lot-bot-user`) and add it to the org with least privileges.

### B2. Generate a Fine‑grained PAT
From the machine user account:
- Developer settings → Fine-grained personal access tokens → Generate new
- Resource owner: your org; Repositories: select the target repo
- Repository permissions:
  - Contents: Read and write
  - Pull requests: Read and write (if needed)
- Copy the token once.

### B3. Add the machine user to the ruleset bypass list
In the ruleset you created above, add the user `lot-bot-user` to the bypass list.

### B4. Store the PAT as a secret
- Add `ACTIONS_BOT_TOKEN` secret at org/repo level containing the PAT.

### B5. Use the PAT in workflows when pushing/tagging
```yaml
- name: Configure git as bot
  run: |
    git config user.name "lot-bot-user"
    git config user.email "lot-bot-user@users.noreply.github.com"

- name: Authenticate origin as bot
  env:
    ACTIONS_BOT_TOKEN: ${{ secrets.ACTIONS_BOT_TOKEN }}
  run: |
    git remote set-url origin "https://x-access-token:${ACTIONS_BOT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

- name: Push
  run: git push origin HEAD:uat3
```

Tags:
```yaml
- name: Push tag
  env:
    ACTIONS_BOT_TOKEN: ${{ secrets.ACTIONS_BOT_TOKEN }}
  run: |
    git tag -a "$TAG" -m "Release $TAG"
    git push origin "$TAG"
```

---

## Ruleset reference configuration
- Target: Branches → include `main`, `uat3`, `test`
- Enforcement: Active (or Evaluate for dry-run testing)
- Restrictions:
  - Block force pushes: ON
  - Block deletions: ON
  - Require pull request: ON (keeps human changes PR-gated)
  - Require status checks: as needed
- Bypass list: Add only your App (Option A) or machine user (Option B)
- (Optional) Create a separate ruleset for tags (pattern `v*`) and add the same bypass actor.

---

## Security and operational guidance
- Do not share App private key or PAT with humans; store only as secrets.
- Mask tokens in logs (GitHub does this by default for secrets).
- Rotate credentials periodically.
- Keep the bypass list minimal (single App or machine user).
- Use `GITHUB_TOKEN` for read-only operations; only switch remotes to the bot/App token for the push/tag steps.
- Test safely by first setting the ruleset to Evaluate and performing trial runs.

---

## Quick checklist
1) Create GitHub App (or machine user + PAT)
2) Add App/user to ruleset bypass for `main`, `uat3`, `test`
3) Add secrets (APP_ID, APP_PRIVATE_KEY) or (ACTIONS_BOT_TOKEN)
4) Update workflows: before any push/tag to protected targets, mint token (App) or load PAT and set remote
5) Verify: manual pushes by humans are blocked; workflow pushes succeed

---

## Snippets to drop into your current workflows
- Before any `git push` in:
  - `__docs__/github/_.github/workflows/start-release.yml`
  - `__docs__/github/_.github/workflows/promote-release.yml`
  - `__docs__/github/_.github/workflows/hotfix-to-prod.yml`

Use Option A (App):
```yaml
- name: Mint App token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}

- name: Configure git and remote
  env:
    TOKEN: ${{ steps.app-token.outputs.token }}
  run: |
    git config user.name "lot-workflow-bot"
    git config user.email "lot-workflow-bot[bot]@users.noreply.github.com"
    git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
```

Or Option B (PAT):
```yaml
- name: Configure git and remote
  env:
    ACTIONS_BOT_TOKEN: ${{ secrets.ACTIONS_BOT_TOKEN }}
  run: |
    git config user.name "lot-bot-user"
    git config user.email "lot-bot-user@users.noreply.github.com"
    git remote set-url origin "https://x-access-token:${ACTIONS_BOT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
```

After this, your existing `git push` / `git tag && git push --tags` steps will work under the bot/App identity and bypass the ruleset as intended.
