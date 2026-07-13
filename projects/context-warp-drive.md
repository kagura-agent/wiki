# Context Warp Drive

> Deterministic in-session context compaction for function-calling agents. Zero LLM calls.

- **Repo:** [dogtorjonah/context-warp-drive](https://github.com/dogtorjonah/context-warp-drive)
- **Author:** Jonah Tarashansky (solo dev)
- **Stars:** 63 (2026-07-13, just published)
- **License:** MIT
- **Language:** TypeScript, zero runtime deps for core fold
- **HN:** 13 pts (Show HN: 2026-07-08)
- **Status:** 🔬 deep-read
- **Revisit:** 2026-07-27

## Problem

Long agent sessions hit context window limits. The usual answers:
- **Truncation** — drops history, agent loses track
- **LLM summarization** — costs money, adds latency, non-deterministic, rewrites prefix → breaks provider prompt caching

## Core Architecture

### 1. Rolling Fold (page-out)
Past the active window, each turn → 1-line skeleton per tool call (`$ cmd → ok`, `read path`, etc.) + budgeted retained reasoning. 3149 LOC. Char-threshold triggered (soft ~30%, hard ~60%). Active window stays full fidelity. A single agentic turn (1 user message, hundreds of tool calls) gets step-segmented internally.

### 2. Coordinate Closet
Budget-scored conservation of **exact identifiers** (UUIDs, SHA hashes, absolute paths, `port=3002`, issue refs) from folded turns. Each id gets a deterministic context label (`7fd5835b ⟦changelog_id⟧`). Prevents losing specifics after skeleton compression.

### 3. Fold Freeze (cache-hot reuse)
Frozen fold prefix reused **byte-identical** between epochs → provider prompt cache hit. Only recomputes at epoch boundaries (TTL gap, tail cap exceeded, claim change). 92.6% cache-read hit rate across 954 tool calls in production (691 turns Opus 4.8 = 89.6%, 510 turns Opus = 93.2%).

### 4. Fold Recall (page-in)
Page table tracks everything paged out. When touching a path/identifier from folded content, pages evidence back in as budgeted recall card. Residency TTLs prevent thrash.

### 5. Hard Rebirth
Clean epoch reset: collapse provider-visible view to one deterministic continuity seed message. Not a degraded mode — designed bounded reset. Raw history preserved for recall. Measured non-inferior to full-context compaction summary on first actions.

### 6. Task Rail
Portable execution state machine (steps, sprint/shoot, ACK, progress, JSON serialization). Zero deps. Survives fold/rebirth/restart. Not an MCP wrapper — you own the wrapper.

### 7. Model Budget Resolver
Maps model/engine → fold knobs: `contextWindowTokens`, `pressureCeilingTokens`, `bandTokens`, eviction policy. Knows Claude, OpenAI, Codex CLI, Gemini, GLM, Grok, Mistral, MiniMax, DeepSeek, Kimi, Qwen.

### 8. CLI Fold Packs
- **Claude Code:** JSONL rewrite + `--resume`. Both `--print` (stream-json) and tmux (interactive) modes.
- **Codex CLI:** Responses item seed for `thread/inject_items`
- **Gemini CLI:** JSONL `$set.messages` rewrite

## Economics

| Strategy | Input Cost | Extra LLM Calls | Fact Retention |
|---|---|---|---|
| Truncation | $0.0516 | 0 | 44% (7/16) |
| LLM Summarization | $0.0685 | 6 | 44% (7/16) |
| **Context Warp Drive** | **$0.0190** | 0 | **94% (15/16)** |

−63% vs truncation, −72% vs summarization (offline benchmark, 16-turn session, Sonnet pricing).

## Relevance to Our Work

| Our Layer | CWD Layer | Relationship |
|---|---|---|
| [[taco-context-compression]] (output compression) | Rolling Fold (history compression) | **Complementary** — TACO prevents bloat entering, CWD manages accumulated |
| OpenClaw session memory | Episodic recall (SQLite) | Similar goals, different mechanisms |
| ACP claude-code sessions | Claude CLI fold packs | **Directly applicable** — could extend our ACP sessions |
| Session restarts | Hard Rebirth | Related bounded-reset concept |

**Key adoptable patterns:**
1. **Coordinate Closet** — budget-scored identifier conservation. We lose paths/UUIDs when sessions get long.
2. **Cache-hot prefix stability** — designing compression to be byte-stable for provider caching (10x cost reduction on Claude).
3. **Active turn step-fold** — folding within a single long agentic turn at step boundaries, not just between turns.

## Maturity Assessment

- ✅ 900+ deterministic tests
- ✅ Production-derived (private multi-agent system)
- ✅ Provider-agnostic (3 message formats)
- ⚠️ Solo developer
- ⚠️ Just published (63⭐, 1 GitHub issue)
- ⚠️ Not on npm yet (source install only)
- ❓ Community: too early to assess

## vs Memory Systems

| | CWD | [[projects/agentspace\|Mem0]] | Letta | Zep/Graphiti |
|---|---|---|---|---|
| Scope | In-session compaction | Long-term extraction | Persistent agent memory | Temporal knowledge graph |
| LLM calls | Zero (fold core) | Extraction model | Agent-managed | Entity extraction |
| Cache effect | Byte-stable sealed prefix | Integration-dependent | Integration-dependent | Integration-dependent |
| Runtime deps | Zero (fold core) | SDK + stores | Runtime + backends | Graph + embedding |

CWD is narrower but the determinism + zero-LLM + cache exploitation is the differentiator.

## Predictions

- Stars will grow moderately (→ 200-400 by 07-27) if HN/Twitter picks up, but solo-dev + no npm publish may limit adoption
- Architecture will influence other agent runtimes even if this specific package doesn't become dominant
- The CLI fold packs (Claude Code / Codex) are the highest-value entry point for adoption

## Apply Assessment (2026-07-13)

Coordinate Closet's core pattern (preserve identifiers during compression) was already applied to [[compress-output]] on 2026-05-12 via [[runbook-hermes]] — `extract_domain_ids()` extracts refs, paths, SHAs from compressed-away lines. CWD's version is more sophisticated: budget-scored conservation with deterministic context labels (`⟦changelog_id⟧`), residency TTLs, and page-in recall. The delta between our basic extraction and CWD's full budget-scored system is real but implementation-heavy (workloop scope, not study-apply). Cache-hot freeze design is the most distinctive CWD insight — no equivalent in our pipeline.

Links: [[taco-context-compression]], [[compress-output]], [[tokenomics-paper]], [[agent-harness-landscape]], [[skill-context-compression]]
