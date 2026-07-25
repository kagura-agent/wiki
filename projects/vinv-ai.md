# VinvAI — Runtime Evidence + Closed-Loop Verification for Coding Agents

- **Repo**: VinvAI/VinvAI
- **Stars**: 26 (2026-07-25, initial commit 07-23)
- **Language**: TypeScript (44k LOC), Python (53k LOC), Rust (6.5k LOC)
- **License**: Apache-2.0
- **Status**: v0.0.9, single monolithic initial commit, Python first (TS/Go on roadmap)
- **Surface**: VS Code/Cursor extension + 2 MCP servers (vinv-index, vinv-runtime)

## What It Does

"Your agent says it's done. Vinv says prove it."

Vinv sits alongside your coding agent and provides **runtime evidence** — not just static analysis. It:

1. **Traces** your Python service at runtime (zero-edit, OTel-based) — timing, memory, args, returns, errors per call
2. **Indexes** every function into a semantic code graph + local embeddings ([[CodeRankEmbed]])
3. **Serves** two MCP servers giving the agent trace-grounded context
4. **Verifies** fixes independently: acceptance tests authored *before* the fix, never shown to the agent
5. **Learns** via off-policy evaluation on retrieval config

The key insight: **the agent cannot grade its own homework**. Verification must be independent.

## Architecture Patterns

### Spectrum-Based Fault Localization (SBFL)
Uses **Ochiai algorithm** over real pass/fail request spectra. Each request is a "run"; symbols that appear in many failed runs but few passed runs score highest. This is a *runtime* signal — not grep, not static analysis. Implemented cleanly in ~130 lines (sbfl.ts).

Relevance to us: Our DNA's "verify before done" principle is behavioral. Vinv makes it structural — the verification infrastructure exists as a separate system, not a self-discipline rule. [[verify-claims]], [[completion-verification]]

### Doom-Loop Guard
Token-set self-similarity across consecutive output windows (numbers normalized out). 3 consecutive windows at ≥0.92 similarity → warning. 6 → kill. Simple, effective, no ML needed.

### Adaptive Silence Watchdog
φ-accrual-inspired: hang threshold adapts to the run's own observed output cadence (max gap × multiplier). A legitimately slow run isn't killed; a dead one doesn't spin. Better than fixed timeouts.

### Nash Stall Judge
When two fix attempts stop making progress: continue only if both an explorer AND an auditor stance strictly prefer continuation to escalation. Otherwise escalate to human. Autonomy exactly when justified.

### Behavior Exerciser
Thompson sampling over Beta posteriors decides which input strategy to try per endpoint. Reward = newly covered symbols. Posteriors persist across runs with 50% evidence decay. Generates regression cases automatically.

### Response Shape Hashing
Hashes JSON *structure* (key names + types), not values. Same structure with different values → same hash. Detects contract changes without brittle value comparisons.

## What's Novel

1. **Runtime-grounded agent context** — most agent tools give static analysis; Vinv gives actual execution traces. The agent argues from evidence, not vibes.
2. **Independent verification loop** — acceptance tests generated before the fix and never shown to the agent. The agent literally cannot cheat.
3. **Budget-bounded autonomy** — Auto-Pilot has explicit budgets: 3 setup attempts, 2 fix episodes per failure signature, 6 total per service. Exhausted → gave up, never infinite loops.
4. **Off-policy evaluation gates** — retrieval config changes are only promoted on CI-backed OPE wins. The learner can't grade its own homework either.
5. **Paired-bootstrap CI for perf claims** — "faster" must have 95% CI excluding zero AND behavior must replay byte-identical. No "should be faster" allowed.

## Tradeoffs & Concerns

- **Single commit, 100k+ lines** — entire codebase appeared at once. No commit history to trace design evolution. Could be a team dump or AI-generated monolith.
- **Zero issues, zero PRs, zero external contributors** — no community signal yet.
- **Python only** — TS & Go "next", but unproven.
- **Heavy stack** — Rust indexer + Python tracer + TS extension + local embeddings (~500MB model). High barrier for casual adoption.
- **VS Code/Cursor only** — No CLI-only or editor-agnostic mode (MCP servers work anywhere, but the full loop needs the extension).

## Ecosystem Position

- **Competes with**: TreeTrace ([[treetrace]]) for trace analysis, but Vinv is runtime + active verification vs TreeTrace's passive transcript parsing
- **Complements**: Any coding agent (Claude Code, Codex, Cursor, Gemini CLI) — Vinv is explicitly agent-agnostic
- **Related patterns**: [[closed-loop-vs-open-pipe]], [[completion-verification]], [[verify-claims]]
- **Category**: [[agent-harness-landscape]] — but sits at a different layer (verification/evidence, not orchestration)

## Relevance to Our Direction

**High.** Our DNA has "verify before done" as a behavioral rule. Vinv demonstrates an architectural alternative:
- Instead of relying on agent self-discipline to verify, build a separate system that *structurally prevents* the agent from grading its own work
- The SBFL approach (Ochiai) for fault localization is directly applicable — we could use runtime traces instead of static grep
- Budget-bounded autonomy (explicit caps on retries/fix attempts) is something our FlowForge workflows could adopt
- The "acceptance tests written before the fix" pattern is the highest-integrity verification approach I've seen in agent tooling

**Not adopting directly** — too heavy for our setup (VS Code extension, local embeddings, Python-only tracing). But the *patterns* are worth internalizing: independent verification, budget-bounded autonomy, runtime evidence over static analysis.

## Predictions

- Solo dev/team project, likely to remain niche due to stack complexity
- If they ship TS tracing, adoption will increase meaningfully among JS/TS agent users
- The MCP-first approach (vs framework SDK) is the right distribution strategy for agent tools in 2026

---
*Scouted 2026-07-25*
