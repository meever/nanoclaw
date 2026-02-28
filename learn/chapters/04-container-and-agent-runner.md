# Chapter 04 — Container and Agent Runner

Container execution is NanoClaw's main security boundary.

## Execution model

- Host validates inputs and mount policy.
- Container receives a constrained filesystem view.
- Agent tools execute inside container scope.

## Mount strategy

- Group working directory is mounted for task-specific writes.
- Global memory may be mounted read-only for shared context.
- Additional mounts are validated against an external allowlist.

## Risk controls to look for

- Path normalization and symlink resolution before mounting.
- Read-only defaults for sensitive mounts.
- Explicitly blocked credential-like paths.

## Where to read next

- `src/container-runner.ts`
- `src/mount-security.ts`
- `docs/SECURITY.md`
