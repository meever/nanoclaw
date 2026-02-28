# Chapter 01 — System Overview

NanoClaw is a single Node.js host process that receives messages, stores state in SQLite, and delegates agent reasoning to isolated containers.

## Core architectural pieces

- Host orchestrator (`src/index.ts`): process lifecycle, queueing, and subsystem startup.
- Channel adapters (`src/channels/*`): transport-specific inbound/outbound integration.
- SQLite persistence (`src/db.ts`): messages, tasks, router state, sessions metadata.
- Scheduler (`src/task-scheduler.ts`): evaluates due tasks and triggers execution.
- IPC watcher (`src/ipc.ts`): file-based bridge between container and host.
- Container runner (`src/container-runner.ts`): isolated execution environment.

## Trust boundaries

- Main group: administrative authority.
- Non-main groups: untrusted by default.
- Container agents: sandboxed and constrained to mounts.
- Host process: authority for routing, auth checks, and task writes.

## Why this shape works

- Keeps mutable authority in one place (host).
- Moves reasoning and tool execution into isolated sandboxes.
- Uses simple primitives (SQLite + filesystem IPC) for debuggability.
