# Chapter 09 — Container Runtime and Agent Execution

Containers are execution sandboxes, not authority boundaries. Host remains source of truth; containers run scoped work.

## Understand

- How container spawn is parameterized
- Why mounts are constrained per group
- How output markers are parsed back into host state

## Diagram: container spawn lifecycle

```mermaid
sequenceDiagram
  participant O as Orchestrator
  participant R as ContainerRunner
  participant C as Container
  O->>R: runContainerAgent(config)
  R->>C: start with mounts/env
  C-->>R: output/status markers
  R-->>O: parsed ContainerOutput
```

## Latency budget

$$
L_{total} = L_{queue} + L_{exec} + L_{io}
$$

Exercise: inspect container logs for one run and map each phase to this equation.
