# Chapter 05 — Data Model and State

The database is the source of truth for runtime coordination.

## Primary entities

- Messages: inbound/outbound records used by the polling flow.
- Registered groups: maps JIDs to folder identities and trigger behavior.
- Scheduled tasks: recurrence metadata and next-run timestamps.
- Run logs: execution outcomes and diagnostics.

## State responsibilities

- Durable conversation/event history lives in SQLite.
- Session artifacts and IPC data live under `data/`.
- Group memory files live under `groups/{name}/`.

## Operational rules

- Keep schema changes explicit and test-backed.
- Avoid storing derived values when they can be recomputed.
- Ensure task status transitions are idempotent.
