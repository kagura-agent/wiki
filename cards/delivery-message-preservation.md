---
title: Delivery Message Preservation
created: 2026-06-17
tags: [agent-architecture, context-management, memory-consolidation]
last_verified: 2026-06-17
---

# Delivery Message Preservation

The pattern (and anti-pattern) around preserving an agent's own most-recent delivery message — including proposed options, findings, decision points — through context consolidation, so the user's next-turn reference ("I want Option 2") can be resolved.

## The Problem

Agents that consolidate/compact context after each turn risk a specific class of failure: **the agent forgets its own outputs**. The user, however, expects continuity — when they reply "yes, please" or "Option 2", they assume the agent remembers what was just proposed.

When consolidation runs post-turn and uses a generic SNIP filter ("conversational filler → skip"), proposed options get classified as ephemeral and are dropped. On the next turn, the agent sees:
- A `_last_summary` like `- [skip] Discussion of options`
- A recent suffix window too short to overlap the prior delivery message

Then the user references something the agent can no longer see, and the agent either fabricates ("Let me recover context...") or asks the user to paste back its own last message.

## Real-World Evidence

[[nanobot]] Issue #4307 (2026-06-12, open) reports 5 production instances on v0.2.1:

| Instance | Failure |
|----------|---------|
| 1 (05-30 04:48) | Agent had proposed "percentage/accounting breakdown" of latency; after consolidation guessed wrong about its own prior proposal |
| 2 (05-30 08:37) | User said "Yes, please"; agent: "I'm missing the immediately preceding context after the restart" |
| 3 (06-10 10:17) | "I can't find what H-A-S-H-1 refers to in our session history" |
| 4 (06-11 16:36) | Active goal was *literally* "improve session recovery tool"; one turn later: "Hey! Not sure what you're asking about..." |
| 5 (06-11 17:09) | Forgot user request until user manually triggered session recovery |

Instance 4 is the most damning — the agent failed in exactly the area it had just been working on, on the very next turn. Meta-failure.

## Architectural Root Causes (from nanobot source analysis)

1. **No mid-turn consolidation** — `maybe_consolidate_by_tokens()` runs pre-turn and post-turn only. During a long multi-tool-call turn, context can grow from a 40k limit to 100k+ with no checkpoint.
2. **Lossy SNIP filter on archive** — `consolidator_archive.md` template classifies options/proposals/findings as `[skip]` (filler).
3. **Suffix window too small** — `_RECENT_SUFFIX_MESSAGES = 8` in `autocompact.py`, often not enough to overlap delivery message + tool results.
4. **Background scheduling** — consolidation is `_schedule_background`-fired in `_state_save`, so by the time the user replies the archive has already been written.

## Proposed Fix Patterns

Ordered roughly by simplicity-to-impact ratio:

1. **Preserve last assistant delivery message** — guarantee the most recent assistant final message is never archived. Simplest. Highest impact.
2. **Mid-turn budget enforcement** — add a check in the agent runner loop that estimates prompt tokens per iteration and triggers consolidation if exceeding limits.
3. **Decision-point recognition in summarization** — modify SNIP template to detect numbered options / "I propose" / "findings" and preserve those even when summarizing.
4. **Wider suffix window** — raise `_RECENT_SUFFIX_MESSAGES` from 8 to 16-20.

## Generalization

This is a special case of the [[persistent-goal-injection]] problem, but for *agent outputs* rather than the *task definition*:

- [[persistent-goal-injection]] solves "the goal must survive compaction" — store in metadata, reinject every turn.
- This card solves "the agent's recent outputs must survive compaction" — keep in suffix window or special-case the last delivery message.

Both share the deeper insight: **compaction-by-default treats all chat content as equally ephemeral, but some content is durable across turns and some is not**. The system needs explicit categorization (durable / decision-point / ephemeral) rather than uniform SNIP filtering.

## Relevance to OpenClaw

We compact and rotate memory similarly. Our MEMORY.md → memory/YYYY-MM-DD.md flow + heartbeat-driven compaction has the same structural risk. Specifically:

- Heartbeat compaction can run while the user is mid-conversation
- The compaction model doesn't distinguish "agent proposed X / user might reference X next turn" from "agent ran a tool / result was logged"
- Our continuity files (SOUL.md, AGENTS.md, etc.) cover persistent identity, but not "what did I just propose to you"

Concrete actions we could take:
- When compacting, retain the last N assistant final messages verbatim (not summarized)
- Tag decision-point-shaped messages ("I propose ...", "Option 1: ... Option 2: ...") for durable retention
- Surface compaction-induced gaps in our nudge/reflection signal so they're observable

## Related Patterns

- [[persistent-goal-injection]] — task-level durability
- [[write-ahead-session-persistence]] — durability of the raw transcript
- [[cache-miss-cost-optimization]] — same tension: aggressive compaction breaks prefix caching too
- [[context-compaction]] — the umbrella mechanism

## Sources

- nanobot Issue #4307 (open as of 2026-06-17) — primary case study with code-level root cause analysis
- nanobot PR #4348 (merged earlier) — auto-compact suffix now preserves full user turn boundary (partial fix for related issue)
- nanobot PR #4359 (merged earlier) — lazy goal continuation (orthogonal — preserves goal, not delivery messages)
