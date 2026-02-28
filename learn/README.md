# NanoClaw Learning Book

This is a fresh, sequential book for learning NanoClaw from zero.

## Audience

- New to TypeScript
- New to Claude/agent workflows
- Wants practical, safe changes in this repository

## Book structure

Chapters are ordered to reduce cognitive load:

1. Foundations and glossary
2. TypeScript essentials used in this codebase
3. Claude agent model in NanoClaw
4. Setup and first run
5. Configuration model
6. Architecture map
7. Channel intake
8. Routing and outbound path
9. Container runtime
10. IPC and task processing
11. SQLite state model
12. Scheduler
13. Skills customization
14. Testing/debugging
15. Security and isolation
16. Operations and updates

## Build HTML

```powershell
powershell -ExecutionPolicy Bypass -File learn/build-book.ps1
```

Output: `learn/book.html`
