# Chapter 02 — Runtime Message Flow

This chapter traces one inbound chat message to its eventual reply.

## 1) Channel ingestion

The channel adapter receives a message and calls orchestrator callbacks:

- Persist inbound message.
- Persist chat metadata.
- Associate message with channel-specific JID.

## 2) Queue and polling

The orchestrator polling loop discovers unprocessed messages and enqueues work by group.

- Per-group ordering is maintained.
- Global concurrency limits prevent resource exhaustion.

## 3) Group processing

For each queue item:

- Resolve registered group and policy (`requiresTrigger`, trigger patterns).
- Gather recent context and state.
- Start or reuse container execution path.

## 4) Agent execution

`src/container-runner.ts` prepares mounts and environment, then invokes the agent runner.

- Group folder is writable.
- Global memory and project mounts are controlled by role and policy.

## 5) Output routing

Agent output is post-processed and sent through `src/router.ts`.

- Formatting normalizes outbound content.
- Correct channel is selected by JID ownership.
