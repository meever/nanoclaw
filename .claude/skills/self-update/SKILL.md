---
name: self-update
description: Make code changes to NanoClaw by spawning a Developer subagent that branches, writes the code, pushes to GitHub, and opens a PR — it cannot merge directly to main. Triggers on "self-update", "make code change", "code change request", "update nanoclaw code", "add feature", "fix bug", "developer subagent".
triggers:
  - self.?update
  - code.?change
  - make.?change
  - update.?nanoclaw.?code
  - developer.?subagent
  - implement.?feature
  - implement.?fix
---

# Self-Update

Implements code changes to NanoClaw via a **Developer subagent**. The subagent works in an isolated git worktree, writes the code, pushes to a new branch, and opens a Pull Request. It **cannot** merge to main — the PR waits for your review.

## 1. Pre-flight

Verify `gh` CLI is installed and authenticated:

```bash
gh auth status
```

If unauthenticated, tell the user: "GitHub CLI is not authenticated. Run `gh auth login` and try again." Stop here.

Check a remote named `origin` exists:

```bash
git remote get-url origin
```

If missing, tell the user to add a GitHub remote first. Stop here.

## 2. Gather Requirements

Use `AskUserQuestion` to ask:

- **"What changes do you want made to NanoClaw?"** — get a full description: what to build, fix, or change, and any specific files or behaviour to touch.

From the description, synthesize a concise kebab-case branch name (prefix with `feature/`, `fix/`, or `refactor/` as appropriate — e.g. `feature/add-rate-limiting`, `fix/message-truncation`). Tell the user the suggested branch name before continuing.

## 3. Spawn Developer Subagent

Use the `Task` tool with:
- `subagent_type: "general-purpose"`
- `isolation: "worktree"` — the subagent gets an isolated copy of the repo on a fresh branch

Pass the following prompt, substituting `{TASK}` and `{BRANCH}` with the values from Phase 2:

---

You are a **Developer subagent** for the NanoClaw project. Implement the requested code changes, push a branch, and open a Pull Request. **You must not merge to main under any circumstances.**

### Your Task

{TASK}

### Suggested Branch Name

`{BRANCH}`

### NanoClaw Architecture

NanoClaw is a personal Claude assistant (Node.js + TypeScript). Key files:

| File | Purpose |
|------|---------|
| `src/index.ts` | Orchestrator: message loop, agent invocation |
| `src/channels/whatsapp.ts` | WhatsApp connection |
| `src/channels/telegram.ts` | Telegram channel |
| `src/channels/discord.ts` | Discord channel |
| `src/channels/gmail.ts` | Gmail channel |
| `src/router.ts` | Message formatting and outbound routing |
| `src/config.ts` | Trigger pattern, paths, intervals |
| `src/container-runner.ts` | Spawns agent containers with mounts |
| `src/ipc.ts` | IPC watcher and task processing |
| `src/db.ts` | SQLite operations |

### Steps — follow in order, do not skip

**Step 1 — Explore before writing.**
Read the relevant files with `Read`, `Glob`, and `Grep`. Understand existing patterns before touching anything.

**Step 2 — Rename the branch.**
You are on an auto-generated worktree branch. Rename it:

```bash
git branch -m "{BRANCH}"
```

**Step 3 — Implement the changes.**
Edit or create files. Keep changes minimal and focused. Match existing TypeScript conventions. Do not refactor unrelated code.

**Step 4 — Build and test.**

```bash
npm run build && npm test
```

Fix any build errors or test failures before proceeding. Do not push broken code.

**Step 5 — Commit.**
Stage only the files you intentionally changed:

```bash
git add <changed files>
git commit -m "$(cat <<'EOF'
{conventional-commit-type}: {short description}

{one or two sentences explaining what changed and why}

Co-Authored-By: Developer subagent <noreply@anthropic.com>
EOF
)"
```

**Step 6 — Push the branch.**

```bash
git push -u origin "{BRANCH}"
```

**Step 7 — Open a Pull Request. Do NOT merge.**

```bash
gh pr create \
  --title "{short descriptive title}" \
  --body "$(cat <<'EOF'
## Summary

{2-4 bullet points describing the changes}

## Test plan

{bulleted checklist of how to verify these changes work}

---
🤖 Implemented by Developer subagent via \`/self-update\`
EOF
)"
```

**Step 8 — Output the PR URL.**
Print the full PR URL so it can be reported back to the user.

**Step 9 — Stop.**
Your work is complete. Do **not** merge. Do **not** push to main. Do **not** run `git merge`. The PR must be reviewed and merged by the repository owner.

---

## 4. Report

After the subagent returns, tell the user:

- The PR URL (link them directly to it)
- A brief summary of what was changed
- "The PR is ready for your review. It has not been merged."

## Troubleshooting

**`gh auth status` fails:** Run `gh auth login` to authenticate the GitHub CLI.

**Build fails in the subagent:** The subagent should fix errors before pushing. If it can't, it should report what failed — you can then invoke `/self-update` again with clarification or fix manually.

**Branch name already exists remotely:** The subagent should append a short suffix (e.g., `-2`) and retry the push.

**`git push` rejected:** Usually means the remote branch already exists with different history. The subagent should use `git push --force-with-lease` only if it created the branch in this session.
