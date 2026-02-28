# Chapter 11 — Safe Change Playbook

This is a practical method for making changes without destabilizing NanoClaw.

## Step 1: Define scope tightly

- Name the behavior change in one sentence.
- Identify exact files that should change.
- Explicitly list files that must not change.

## Step 2: Trace existing path first

- Reproduce current behavior.
- Trace call flow through orchestrator, IPC, and container boundaries.
- Identify security checks and persistence touchpoints.

## Step 3: Change one seam at a time

- Prefer extending existing handler patterns.
- Keep data contracts backward compatible where possible.
- Avoid combining security changes and feature changes in one commit.

## Step 4: Validate locally

- Run build/typecheck/tests.
- Run targeted tests near changed modules.
- Inspect logs for rejected auth cases and edge paths.

## Step 5: Review with risk lens

- Could untrusted groups trigger this path?
- Could this path execute host shell commands?
- Could this bypass mount or task authorization boundaries?

## Step 6: Document the decision

- Capture intent, constraints, and rollback plan in PR notes.
- Update docs/skills only where user behavior actually changes.
