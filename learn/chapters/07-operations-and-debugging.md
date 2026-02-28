# Chapter 07 — Operations and Debugging

Use a component-first debugging approach: isolate whether the issue is channel, queue, IPC, container, scheduler, or routing.

## Fast triage checklist

1. Is the channel connected and receiving messages?
2. Is the message persisted in SQLite?
3. Did queue processing start for that group?
4. Did container execution launch successfully?
5. Was a response generated and routed to the right JID?

## Typical failure classes

- Auth/session failures in channel integration.
- Mount or runtime issues in container startup.
- Authorization rejection in IPC tasks.
- Scheduler expression or timezone mistakes.

## Useful references

- `docs/DEBUG_CHECKLIST.md`
- `src/logger.ts`
- `src/ipc.ts`
- `src/task-scheduler.ts`
