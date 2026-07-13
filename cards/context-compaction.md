---
title: Context Compaction
created: 2026-05-31
tags: [context-management, compaction, tool-safety]
last_verified: 2026-07-13
---
# Context Compaction

Mechanisms for compressing or summarizing agent context to fit within token limits while preserving critical state across conversation boundaries.

## OpenClaw's Implementation (audited 2026-07-03)

**Key files:** `compaction-planning-DNCdhmpK.js`, `session-transcript-repair-CzUOZPU5.js`

### Tool-Call Atomicity — Fully Handled

The elephant-agent PR#36 problem (splitting `assistant(tool_calls)` from paired `toolResult` messages → provider 400 errors) is **already solved** in OpenClaw via two layers:

1. **Proactive grouping** — `splitMessagesByTokenShare()`:
   - Tracks `pendingToolCallIds` set from `extractToolCallsFromAssistant()`
   - Won't create chunk boundary while pending tool results exist
   - `splitCurrentAtPendingBoundary()` backtracks to safe split point if chunk exceeds target
   - Handles `stopReason === "aborted" | "error"` (no pending in those cases)

2. **Defensive repair** — `repairToolUseResultPairing()`:
   - Called after every chunk drop in `pruneHistoryForContextShare()`
   - Inserts synthetic `[openclaw] missing tool result` for unpaired tool_calls
   - Drops orphaned `toolResult` messages without matching assistant
   - Deduplicates and relocates misplaced results
   - Returns `droppedOrphanCount` for observability

### Non-Tool-Safe Chunking (by design)

`chunkMessagesByMaxTokens()` does NOT handle tool-call atomicity, but it's only used by `buildSummaryChunks()` — which feeds content to the summarization model as text input, not as structured conversation messages. No structural risk.

### Architecture Comparison

| Aspect | Elephant-Agent PR#36 | OpenClaw |
|--------|---------------------|----------|
| Grouping | `message_groups()` | `splitMessagesByTokenShare()` pendingToolCallIds tracking |
| Repair | N/A (prevention only) | `repairToolUseResultPairing()` as safety net |
| Scope | `split_for_compress()` only | All compaction paths via `pruneHistoryForContextShare()` |
| ID tracking | `tool_call_id` matching | Same, via `extractToolResultId()` + `extractToolCallsFromAssistant()` |

**Verdict:** No action needed. OpenClaw's approach is actually more robust (prevention + repair vs prevention only).

## Related

- [[context-management]] — broader context handling strategies
- [[token-efficiency]] — optimization techniques for token usage
- [[context-window-management]] — window-level management approaches
