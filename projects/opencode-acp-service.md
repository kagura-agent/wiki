# OpenCode ACP service — offline module note (2026-08-07)

**Source read:** `/mnt/data/repos/forks/opencode/packages/opencode/src/acp/service.ts` at local commit `6e46a496ac`.

## Lifecycle and state boundaries

- `newSession`, `loadSession`, `resumeSession`, and `forkSession` each create or restore an `ACPSession` record, cache a `Directory.Snapshot` per ACP session ID, register requested MCP servers, and send available commands. `loadSession` and `forkSession` replay historical messages; `resumeSession` restores only the last 20 messages for config inference and does not replay them.
- `closeSession` removes the local ACP session, its MCP-registration set, and its cached directory snapshot before attempting to abort the backing SDK session. Abort failures are logged and absorbed, so cleanup stays idempotent even when the remote abort fails.
- `listSessions` combines persistent SDK sessions with local ACP-only sessions, excludes IDs already represented by the SDK, sorts by `updatedAt` descending, and uses that timestamp in the cursor. Any persistence change must preserve the merge/dedup/sort/pagination contract.

## MCP registration and configuration

- MCP registration deduplicates per ACP session by `name:stableStringify(config)`. It ignores failed individual `sdk.mcp.add` calls, so the registration map only gains a key after a successful request. Duplicate registrations in one batch are suppressed with a separate pending set.
- Configuration requests validate against the cached directory snapshot. `setSessionConfigOption` returns refreshed options; the dedicated `setSessionMode` and `setSessionModel` endpoints return empty responses after updating state. Changes to configuration behavior need to preserve those distinct response contracts.

## Change-review checklist

Before altering ACP session lifecycle code, audit all four creation/restore paths, `closeSession`, the session-list merge logic, and the live/replay event consumers. For MCP changes, verify both successful-registration bookkeeping and behavior after an ignored registration failure.
