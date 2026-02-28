# Chapter 05 — Configuration and Environment Model

Configuration lives mainly in `src/config.ts` and setup modules. Safe configuration changes preserve behavior predictability and filesystem boundaries.

## What to learn

- How defaults and env variables shape runtime behavior
- Which settings affect performance vs safety
- How to test config changes incrementally

## Diagram: configuration resolution

```mermaid
flowchart LR
  D[Hardcoded Defaults] --> E[Env Variables]
  E --> C[Computed Paths/Patterns]
  C --> R[Runtime Behavior]
```

## Frequency relation

$$
f = \frac{1}{\Delta t}
$$

If you decrease polling interval $\Delta t$, frequency increases.

## Practical guardrails

- Change one timing parameter at a time.
- Keep paths inside approved roots.
- Rebuild and verify logs after each change.

Exercise: change one non-critical config value and document before/after behavior.
