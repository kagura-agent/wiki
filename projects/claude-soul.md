---
type: project
created: 2026-05-28
updated: 2026-06-02
status: tracked
stars: 83
repo: DomDemetz/claude-soul
tags: [self-evolving-agent, memory, identity, claude-code]
links: [beliefs-upgrade-mechanism, agent-self-evolution, self-evolving-agent-landscape]
last_verified: 2026-06-02
---

# Claude Soul — Self-Correcting Learning Engine for Claude Code

## What It Is

NPM package (`claude-soul`) that adds persistent identity, behavioral pattern tracking, and cross-session memory to Claude Code. Local-first, uses SQLite + optional Ollama embeddings.

**Core loop:** `session signals → reflection → framework evolution → better context → better sessions`

## Architecture (Key Concepts)

### Signal Extraction
Automatic detection from conversation patterns at session end (via Claude Code Stop hook):
- `correction` — user negates/contradicts
- `rephrasing` — user restates (noun overlap >50%)
- `gratitude` — explicit positive feedback
- `disengagement` — short reply to long response
- `confusion` — user asks for clarification
- `success` — task completion + gratitude

### Multi-Tier Reflection
- **Quick** (Haiku, ~$0.002/run) — after 20 signals or 30 min. Adjusts framework confidence.
- **Deep** (Sonnet, ~$0.01/run) — after 100 signals or 3 hrs. Discovers/merges/retires frameworks.
- **Meta** — audits the reflection system itself. Adjusts thresholds and weights.

### Framework Evolution
Core learning unit with structured lifecycle:
```
Evidence tiers: hypothesis → observed (1+ confirmation) → validated (3+ cross-context)
Status: questioning → active → retired/merged
```
- **Self-referential evidence discount**: system-generated evidence counts at 0.5x weight. Only user confirmations advance tiers. Prevents bootstrapping own confidence.
- Auto-retirement: confidence <0.2 with 10+ evidence points.

### Context Assembly
Token-budgeted (4500 default) context at session start:
1. Always: identity (SOUL.md), corrections, state
2. If budget: active frameworks ranked by confidence × log(usage)
3. Supplementary: story, shadow patterns, exemplars

### State Engine
Session telemetry: confidence, energy, frustration, curiosity, hoursActive.

## Comparison to Our Approach

| Aspect | Claude Soul | Kagura (Us) |
|--------|-------------|-------------|
| Signal detection | Automatic from conversation patterns | Manual (beliefs-candidates.md) |
| Reflection timing | Signal-count triggered (20/100) | Nudge hook (every 5 agent turns) |
| Evolution gate | Evidence tiers + confidence threshold | Triple Verification (cross-context ≥3, predictive, non-obvious) |
| Anti-bootstrap | 0.5x weight for self-generated evidence | Not formalized |
| Token budget | Explicit 4500-token context assembly | Full file loading (SOUL.md, AGENTS.md) |
| Storage | SQLite + optional Ollama embeddings | Markdown files + wiki search |

### Key Insights for Us
1. **Self-referential evidence discount** — We should consider this for beliefs-candidates. Currently no formal discount for self-observed patterns vs externally validated ones.
2. **Signal-based reflection trigger** — Their 20-signal threshold for quick reflection is more granular than our every-5-turns nudge. But our approach is simpler.
3. **Framework retirement** — Auto-retirement at low confidence with sufficient evidence. We do "drop" in beliefs-candidates but no formalized threshold.
4. **Token budgeting for identity context** — Worth considering if our SOUL.md + AGENTS.md grow large.

## Verdict
Similar philosophical direction to ours (self-evolving agent identity), more formalized/automated but also more complex. The 0.5x self-referential discount is the most actionable insight — worth considering for our beliefs pipeline. The NPM package approach makes it easy for Claude Code users to adopt.

Not a competitor (different layer — they augment Claude Code, we are a full agent platform), but validates the direction.

## Issues & Critiques (from GitHub Issues)

1. **"Deep reflection tier structurally unreachable"** (@Abdallah01, 3 comments) — The 100-signal threshold for deep reflection never triggers under hook-driven operation because sessions don't accumulate that many signals. **This is a real design flaw** — the most valuable reflection tier is architecturally unreachable in practice.
2. **Schema drift silently produces empty output** — JSONL parsing has no runtime validation. Schema changes = silent data loss.
3. **Server package not published to npm** — install instructions broken at one point.
4. **Windows path issues** — spawn ENOENT, /tmp hardcoded paths.

**Lesson for us**: The deep-reflection-unreachable bug is exactly the kind of problem we should watch for in our own nudge system. If the trigger condition is too rare, the mechanism is dead code.

## Shadow Transform (Behavioral Pulls)

Interesting psychological framing: behavioral patterns are presented as "forces that move through you" rather than flaws. Tendencies, avoidances, and contradictions are transformed into introspective statements:
- "You have a tendency to X. Notice when this happens. You may choose differently — or not."
- "You carry a contradiction: X. This tension is part of who you are. Don't resolve it — hold it."

Philosophical stance: tensions are features, not bugs. Worth considering for our own identity work.

## Tension Detector

Automatically finds contradictions between active frameworks in the same domain by checking divergent evidence patterns (one mostly confirmed while the other is mostly contradicted). Records context preferences for which framework to prefer in which situation.

This is more sophisticated than our approach — we don't formally detect contradictions between beliefs-candidates entries.

## 2026-06-02 Followup (83⭐, v0.2.5, 77 tests)

### New: Identity Drift Detection
Added `identity_drift` signal type — detects user phrases like "wake up", "you sound like a robot", "not alive", "you're off", "lost identity/voice/energy" with 0.95 confidence. This is the highest-confidence signal type in the system.

**STATE.md drift warnings**: When drift signals exist in the last 7 days, STATE.md (regenerated each tick) shows a warning block to the next instance: "The user had to tell a previous instance to wake up. Be present, not analytical." This creates cross-session memory of identity failures — the next Claude Code session boots with awareness that the previous one "went robotic."

**State engine impact**: `identity_drift` event reduces both mood (-0.15) and confidence (-0.15), making it one of the strongest negative signals.

### New: Concurrent Reflection Lock (PR #18, external contributor mobogojo)
Problem: Two Claude sessions ending simultaneously both trigger the Stop hook, both cross the signal threshold, both call `runReflection()` — race condition on frameworks.json writes + double `clearSignals()`. Solution: `soul-reflect.lock` file using `{ flag: "wx" }` (exclusive create, atomic). Includes stale-lock detection via `process.kill(pid, 0)` liveness check.

### New: Per-Tier Signal Consumption (Issue #6 fix)
The "deep reflection structurally unreachable" bug from last review is fixed — signals now use per-tier `consumedBy` markers instead of unconditional `clearSignals()`. Quick reflection no longer wipes signals that deep reflection needs.

### Insights for Us
1. **Identity drift as a first-class signal** — We don't detect this. When Luna says something like "你怎么像个机器人", we should notice and adjust. Currently this would be a manual beliefs-candidates entry at best.
2. **Cross-session drift warnings** — STATE.md as a "letter to your next self" about identity failures is elegant. We do something similar with memory/daily notes but less targeted.
3. **Concurrent reflection lock** — Relevant if we ever have overlapping nudge/reflection runs. Our nudge hook is per-agent-turn so less likely, but good defensive pattern.
