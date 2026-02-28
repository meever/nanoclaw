# Chapter 03 — IPC and Authorization

NanoClaw uses file-based IPC for container-to-host requests.

## IPC layout

- Base: `data/ipc/{groupFolder}/`
- Messages: `messages/*.json`
- Tasks: `tasks/*.json`
- Errors: `data/ipc/errors/`

## Why group-folder identity matters

The source identity is derived from the directory path, not just payload content.

- Prevents spoofing by payload-only claims.
- Enables clear main/non-main authorization decisions.

## Authorization patterns

- Main group can perform admin operations.
- Non-main groups are restricted to self-scoped operations.
- Sensitive operations are rejected when identity or ownership fails.

## Practical audit checks

- Every new IPC task type should include explicit auth checks.
- Task handlers should fail closed on missing required fields.
- Rejections should log source context for forensics.
