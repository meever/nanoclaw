# Copilot Instructions: Multi-Branch Syncing & Git Workflow

## Repository architecture & golden rules

- Base branch is `main` in this repository (use `master` only in repos that actually use it).
- Treat base branch as a strict, read-only mirror of `upstream/main`.
- Never commit custom code directly to `main`.
- Never merge custom branches into `main`.
- All personal development happens on isolated custom branches (for example: `learn`, `feat/add-self_update`).
- Keep custom branches isolated from each other unless explicitly instructed otherwise.

## Remote policy

- `origin` = personal fork (push target)
- `upstream` = original repository (sync source: `https://github.com/qwibitai/nanoclaw.git`)

## Base reset protocol (when told to sync with upstream)

Do not use `git pull` for sync. Execute exactly:

1. `git fetch upstream`
2. `git checkout main`
3. `git reset --hard upstream/main`
4. `git push origin main --force-with-lease`

## Feature branch sync loop

Immediately after base reset, update every active custom branch by rebasing onto `main`.

For each active custom branch:

1. `git checkout <branch-name>`
2. `git rebase main`
3. `git push origin <branch-name> --force-with-lease`

Examples of active custom branches in this repo include `learn` and `feat/add-self_update`.

## Conflict resolution

- If any rebase conflict occurs, stop immediately.
- Report the exact conflicting files.
- Wait for human intervention.
- Do not auto-resolve by guessing.

## Safety checks

- Before starting sync/rebase, run `git status --short --branch`.
- If working tree is dirty, stash first with `git stash -u`, then restore after sync with `git stash pop`.

## Local hygiene & defaults

- Keep local branch list minimal and prune stale branches periodically.
- Keep tracking explicit:
  - `main` tracks `origin/main`
  - each custom branch tracks its `origin/<branch-name>`
- Set local default start branch:
  - `git config --local init.defaultBranch learn`
