# SmallCode — Coding Agent for Small Local LLMs

- **repo**: Doorman11991/smallcode
- **stars**: 840 (created 2026-05-18, 3 days old)
- **lang**: JavaScript (Node.js)
- **license**: MIT
- **status**: active | deep-read | ✓2026-05-21

## What It Is

Terminal-native coding agent designed for small local models (7B-20B) on consumer hardware. While [[opencode]] and Claude Code assume frontier models with 128k+ context, SmallCode compensates for small model limitations through architecture.

Key innovations:
1. **Budget-managed context** — per-trace token and USD ceilings, auto-compaction
2. **Forgiving JSON parser** — repairs malformed tool call output from weak models
3. **TODO-file decomposition** — breaks tasks into steps via persistent TODO file
4. **Search-and-replace patch editing** — never rewrites full files (cheaper than full-file writes)
5. **Model escalation** — auto-escalate from local → cloud when local fails
6. **Governor** — Bayesian tool scoring that learns which tools work for which model
7. **Auto-validation** — compile/lint after every write, never delivers broken code

## Architecture — Cognition Layer (MarrowScript)

Uses a custom "MarrowScript" compiler that generates TypeScript from `.marrow` declarations. The cognition layer has 5 phases:

```
prompts → routing → budget → traces → validation + repair
```

### Deterministic Model Router
- Routes by task complexity (0-1 score) to tiered models:
  - trivial (≤0.3) → TinyClassifier
  - simple (≤0.6) → SmallCoder  
  - complex (>0.6) → MediumCoder
- **Escalation chain**: tier exhausted → try next tier → fallback to cloud
- Key: no dynamic dispatch, same input always selects same tier

### Repair Prompts (Core Innovation for Small Models)
- `on_invalid: retry_with_repair_prompt` — when model output fails validation
- Repair calls are **single-shot, smaller, more constrained** than original
- Pattern-specific guidance: detects common failure patterns (unterminated template literals, missing modules, undeclared types) and appends targeted fix instructions
- **This is the key insight**: small models fail predictably. The repair system learns the failure vocabulary.

### Budget Tracker
- Per-trace token/USD ceilings with pessimistic cost floors by model class
- Supports `charge()`, `refund()` (for rolled-back calls), `assertCanSpend()`
- Observable: metrics exported for monitoring

### Validation Modes
- `schema_only` — type/shape check against declared return type
- `ast_compiles` — runs tsc over output as if it were source
- `custom:<ext>` — user extension point
- All feed issues into repair prompt system

## Benchmarks (Self-Reported)

Claims 87% single-file task success with Gemma 4 E4B (~4B active params) vs ~75% for OpenCode with Qwen2.5-Coder-14B (3-4x larger model). Multi-file: 46% (60%+ with BoneScript scaffolding).

**Caveat**: benchmarks are self-reported, competitors are "estimated" not measured. Take with grain of salt.

## Issue Analysis (Critiques)

1. **Context overflow persists** — user reports "tool calling quickly exceeds 256k context with 9B model" (#10). The budget management isn't fully solving the core problem yet.
2. **Native dependency hell** — better-sqlite3 build failures on Node 26/macOS. Fixed by making it optional (v0.4.13).
3. **Solo developer** — all issues answered by owner with brief "fixed" replies. Zero external PRs. 🔴 SOLO (0/6 community health).
4. **No tests** — only stress tests in bench/, no unit tests. Red flag for reliability claims.

## Comparison with Our Tools

| Aspect | SmallCode | Kagura/OpenClaw |
|--------|----------|-----------------|
| Target | Small local LLMs | Frontier (Claude) |
| Budget mgmt | Per-trace token/USD ceiling | None explicit |
| Repair system | Pattern-matched retry prompts | Not applicable (frontier doesn't need) |
| Tool scoring | Bayesian governor | Not applicable |
| Editing | Search-and-replace only | Claude Code handles |

### Relevance to Us
- **Low** — we use frontier models, most SmallCode innovations compensate for weak model capabilities
- **Budget tracker pattern** is well-engineered and could be useful if we ever add cost tracking to subagent spawns
- **Repair prompt with pattern-specific guidance** is a generalizable idea — could apply to our own tool output validation

## Ecosystem Position

- Competes with: [[opencode]], Pi Agent, Claude Code (different tier)
- Related concepts: [[context-budget-constraint]], [[forge-guardrails]] (same "make bad models good" thesis)
- Niche: local-first, privacy-conscious developers who won't use cloud APIs

## Broader Scout Findings (2026-05-21)

### Identity Layer Explosion
The agent identity/soul space is exploding. Beyond [[claude-soul]] (76⭐) and [[engram]] (47⭐, up from 34⭐ yesterday), 10+ zero-star repos launched this week all building identity/memory/soul layers. The category is becoming crowded — our DNA system has differentiation through production usage + self-governance.

### Structural Backpressure (Shen-Backpressure)
- HN frontpage (104pts): "Formal Verification Gates for AI Coding Loops"
- Thesis: type checkers, proof checkers, and linters as **structural constraints** beat **behavioral instructions** (prompts). Instead of telling the model "remember to check auth", arrange code so auth violations fail to compile.
- 35⭐, Go, by pyrex41. 2 months old.
- **Relevant insight**: we already do this informally (lint/test gates in workloop). The formalization of "structural backpressure" as a design principle for AI coding loops is worth naming.

### agents-best-practices (902⭐, 6 days)
No code (lang: null), pushed only on creation day. Likely just a SKILL.md/prompt collection riding the "agent skills" wave. 900+ stars for a static doc = the space is oversaturated with template repos.

### Qwen3.7-Max: The Agent Frontier
599pts on HN. Major model release positioned as agent-optimized. Couldn't extract blog content (JS-rendered).

### DCP (Device Context Protocol)
25⭐, 3 days old. Bridge LLM agents to physical devices. Sub-50-byte frames, <16KB MCU footprint. Complementary to MCP. Early but interesting direction — agents controlling hardware.
