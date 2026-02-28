# Chapter 16 — Operations, Updates, and Production Readiness

Production-readiness means predictable startup, safe updates, and fast recovery.

## Outcome goals

- Operate service lifecycle confidently
- Apply updates/migrations with rollback awareness
- Monitor core reliability indicators

## Diagram: update cycle

```mermaid
sequenceDiagram
  participant O as Operator
  participant S as Service
  participant M as Migration
  O->>S: stop/snapshot
  O->>M: run update+migrations
  O->>S: restart
  S-->>O: health signals
  O->>S: keep or rollback
```

## Availability framing

$$
\text{SLO} = 1 - \frac{\text{downtime}}{\text{total time}}
$$

Exercise: write a mini runbook with pre-update checks, rollback trigger, and post-update verification.
