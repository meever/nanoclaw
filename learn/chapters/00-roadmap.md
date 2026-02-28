# Chapter 00 — Roadmap

This learning track is designed to move from high-level understanding to implementation detail.

## How to use this

- Read chapters in order.
- Keep `src/index.ts` open while reading Chapters 1–3.
- For each chapter, map concepts to concrete files.

## Learning outcomes

After this track, you should be able to:

- Explain NanoClaw's trust boundaries and where isolation is enforced.
- Trace one message from inbound channel to outbound reply.
- Add or modify behavior safely without breaking scheduling or IPC.
- Diagnose common failures using logs and component boundaries.

## Source map

- `src/index.ts`: orchestration and loop wiring
- `src/channels/whatsapp.ts`: channel integration
- `src/router.ts`: outbound formatting and routing
- `src/container-runner.ts`: container invocation
- `src/ipc.ts`: IPC watcher and task processing
- `src/task-scheduler.ts`: scheduled task execution
- `src/db.ts`: persistence layer
