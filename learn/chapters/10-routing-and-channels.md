# Chapter 10 — Routing and Channels

NanoClaw separates transport concerns (channels) from formatting/routing concerns (router).

## Channel contract

The channel abstraction in `src/types.ts` defines:

- `connect()` / `disconnect()` lifecycle
- `sendMessage(jid, text)` outbound primitive
- `ownsJid(jid)` ownership resolution
- Optional typing indicators

This lets the host route by JID without embedding transport-specific logic in business flow.

## Router role

`src/router.ts` normalizes outbound content and handles message output policy.

- Format before send to avoid transport drift.
- Keep channel adapters thin.

## Multi-channel correctness rules

- Every outbound send must resolve exactly one owning channel.
- Unknown JID should fail loudly with observability.
- Channel adapters should not duplicate router formatting logic.

## Reading exercise

Compare `src/channels/whatsapp.ts` with `src/router.ts` and list what each file must never do.
