# 0008 — Private online authority (later milestone)
Status: Accepted; implementation deferred until local release

## Context
Browser sharing does not itself provide remote multiplayer.
## Decision
Headless Godot server reuses rules; JSON WebSockets behind HTTPS/WSS. Server validates seat, action sequence and turn; owns RNG; sends filtered per-player observations. Private invite rooms without accounts. Opaque reconnect seat token, bounded reconnect grace, persisted active state, expiry, resign/rematch. Sequence IDs deduplicate retries. Static browser hosting plus containerized server. No raw TCP browser port or peer-authoritative hidden state.
## Alternatives
Peer authority leaks hidden information and complicates reconnect; existing Lua TCP protocol cannot be used directly in browsers.
## Consequences and interfaces
Future room messages wrap the ADR-0003 action contract. No online secrets in diagnostic exports. Core APIs are designed now; networking is separate work items nnqr-50/51/52.
## Verification
Two independent remote clients complete a match, reject stale/duplicate/unauthorized commands, reconnect and recover after server restart.
