# NanoClaw Learning Book

This folder is a structured learning path for understanding NanoClaw end-to-end.

## Learning goal

Understand the codebase from architecture to runtime behavior so you can safely customize it.

## Chapter order

1. `00-roadmap.md` — how to use this learning track
2. `01-system-overview.md` — core architecture and boundaries
3. `02-runtime-message-flow.md` — message lifecycle through the orchestrator
4. `03-ipc-and-authorization.md` — IPC design and trust model
5. `04-container-and-agent-runner.md` — isolation, mounts, and agent execution
6. `05-data-model-and-state.md` — SQLite tables and persistent state
7. `06-skills-and-customization.md` — how skills modify behavior
8. `07-operations-and-debugging.md` — practical runbook for troubleshooting
9. `08-orchestrator-deep-dive.md` — `src/index.ts` control flow and subsystem lifecycle
10. `09-scheduler-and-task-engine.md` — scheduled task lifecycle and execution contracts
11. `10-routing-and-channels.md` — channel abstraction and routing semantics
12. `11-safe-change-playbook.md` — how to modify NanoClaw safely and incrementally

## Build the HTML book

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-learn-book.ps1
```

Output:

- `learn/book.html`
