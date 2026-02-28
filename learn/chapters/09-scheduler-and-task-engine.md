# Chapter 09 — Scheduler and Task Engine

Scheduled tasks are host-managed jobs that trigger agent execution with explicit group context.

## Lifecycle of a scheduled task

1. Task definition created (type, schedule value, context mode, target JID).
2. `next_run` computed and persisted.
3. Scheduler loop scans due tasks.
4. Due task is executed through the same group processing contracts.
5. Result and timing are logged; `next_run` advanced or task completed.

## Important invariants

- Only authorized group scopes can create/manage tasks.
- `next_run` transitions must be deterministic and idempotent.
- Failed runs should not corrupt schedule state.

## Common correctness pitfalls

- Cron timezone mismatches.
- Interval parsing and numeric validation errors.
- Duplicate execution when status transitions are not atomic enough.

## Suggested audit checklist

- Verify schedule parser error paths are fail-closed.
- Verify paused/canceled tasks cannot execute.
- Verify once-tasks complete exactly once.
