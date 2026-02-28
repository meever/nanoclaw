# Chapter 08 — Orchestrator Deep Dive (`src/index.ts`)

The orchestrator is the runtime composition root. Most system behavior is understood by reading startup order and callback wiring.

## Startup sequence

1. Initialize runtime prerequisites (container runtime, cleanup, DB).
2. Load persisted state and register shutdown handlers.
3. Create channel instances and connect transport(s).
4. Start scheduler and IPC watcher loops.
5. Start queue-driven message loop.

This order ensures state and infrastructure exist before asynchronous workloads begin.

## Key responsibilities

- Source-of-truth for in-memory maps (`registeredGroups`, sessions, queue).
- Cross-component glue for callback interfaces.
- Graceful shutdown policy.
- Backpressure coordination via queue and concurrency limits.

## Design patterns worth noting

- Dependency injection through callback objects (low coupling).
- Durable persistence + polling instead of in-memory-only state.
- Queue-centric processing to preserve per-group ordering.

## Reading exercise

Trace these in `src/index.ts`:

- Where inbound messages are persisted.
- Where group ownership is resolved for outbound replies.
- Where subsystems start independently and why that matters.
