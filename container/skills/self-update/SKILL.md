---
name: self-update
description: Request code changes to NanoClaw itself. Use when the user asks to add a feature, fix a bug, or modify how NanoClaw works. This delegates to a Developer subagent on the host that branches, writes the code, and opens a PR. Also use for restarting NanoClaw after a PR is merged.
allowed-tools: Bash
---

# Self-Update: Requesting Code Changes to NanoClaw

You cannot modify the NanoClaw codebase directly — the project directory is mounted read-only. Instead, write an IPC task and the host will spawn a Developer subagent to do the work.

## When to use

- User asks to add a feature, change behavior, or fix a bug in NanoClaw
- User says "restart" or "pull and restart" after a PR has been merged

## How to request a code change

Write a `self_update` IPC task. The host will pick it up, spawn Claude Code on the project directory, implement the change, and send back a PR URL.

**Only works from the main group.**

```bash
echo '{"type":"self_update","description":"<what to implement>","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > /workspace/ipc/tasks/$(date +%s%3N)-self-update.json
```

Replace `<what to implement>` with a clear description of the requested change. Be specific — the Developer subagent will read this as its task prompt.

Example:
```bash
echo '{"type":"self_update","description":"Add a /status command that replies with uptime and registered group count","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > /workspace/ipc/tasks/$(date +%s%3N)-self-update.json
```

After writing the task, tell the user: "On it — I've queued the change request. I'll let you know when the PR is ready for review."

## How to restart after a PR is merged

When the user has merged a PR and wants NanoClaw to restart:

```bash
echo '{"type":"self_restart","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > /workspace/ipc/tasks/$(date +%s%3N)-self-restart.json
```

After writing the task, tell the user: "Restarting — I'll send a message when I'm back online."

**Note:** The `self_restart` task will pull the latest `main`, rebuild, and restart the service. You will not receive a response after sending this — the next message will come from NanoClaw after it restarts.

## Constraints

- These tasks only work from the **main group**
- The Developer subagent will **not** merge to main — it opens a PR that you (the user) must review and merge
- If `claude` is not on PATH when running as a service, `self_update` will fail and report back via WhatsApp
