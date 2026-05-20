# claude-soul — Self-Correcting Learning Engine for Claude Code

- **repo**: DomDemetz/claude-soul
- **stars**: 75 (created 2026-05-16, 4 days old)
- **lang**: TypeScript (monorepo: CLI + MCP server)
- **license**: MIT
- **status**: active | deep-read | ✓2026-05-20

## What It Is

A persistent identity + behavioral learning system for Claude Code. MCP server + hooks that run automatically. One `npx claude-soul init --starter` installs everything.

Three core capabilities:
1. **Cross-session memory** — SQLite + optional Ollama embeddings, semantic search
2. **Correction tracking** — regex-based signal extraction from transcripts, tracks behavioral patterns through lifecycle stages (new → active → improving → internalized)
3. **Framework evolution** — behavioral "frameworks" (beliefs/strategies) that accumulate evidence and get promoted/retired/merged automatically

## Architecture — The Learning Loop

```
session signals → reflection → framework evolution → better context → better sessions
```

### Signal Extraction (Local, Zero LLM)
- Runs on Claude Code's `on-stop` hook
- Regex-based detection: correction, gratitude, confusion, disengagement, rephrasing, topic_shift, success, depth_change
- Signals are lightweight `{ type, confidence, context, timestamp }`
- **Key insight**: No LLM needed for signal extraction — pure heuristics on transcript text

### Reflection (Tiered, LLM-powered)
- **Quick** (Haiku, ~$0.002): after ~20 signals. Can adjust confidence, cannot retire.
- **Deep** (Sonnet, ~$0.01): after ~100 signals. Can discover/merge/retire frameworks, generate lessons.
- **Meta** (Sonnet): audits the system itself — are reflections useful? Are frameworks being applied?
- Uses `claude -p` (Claude Code CLI), runs on user's subscription. No API key.

### Framework Engine (Core Innovation)
Each framework = a learned behavioral principle with:
- **Evidence tiers**: hypothesis → observed (1 external confirm) → validated (3+ external confirms)
- **Status lifecycle**: questioning → active → retired/merged
- **Auto-retirement**: confidence < 0.2 with 10+ evidence → auto-retire
- **Self-referential discount**: Evidence from the soul system itself counts at 0.5x weight. Only external (user) evidence advances tiers. **This prevents bootstrap confidence inflation.**

### Tension Detection
- Detects conflicting frameworks in same domain with divergent evidence
- Tracks context preferences (Framework A wins in context X, B wins in context Y)
- Tensions are valued, not bugs — they represent genuine complexity

### Meta-Optimizer (Learning Phases)
- **Apprentice** (0-50 sessions): Wide net, frequent reflection, high churn OK
- **Creative** (50-200): Refine & merge, lower churn
- **Mastery** (200+): Distill, meta-optimize, fewer but stronger frameworks
- Phase transitions driven by framework survival rate + evidence velocity
- Oscillation detection: framework discovered → retired → re-discovered → flagged as inconclusive

### Shadow Transform
- Behavioral tendencies reframed as "pulls" not "flaws"
- "Tends to X" → "You have a tendency to X. Notice when this happens."
- Philosophical: "Don't resolve tensions — hold them." (Jungian shadow influence)

## Comparison with Our System (Kagura/OpenClaw)

| Aspect | claude-soul | Kagura (OpenClaw) |
|--------|------------|-------------------|
| Identity | SOUL.md + SHADOW.md + FRAMEWORKS.md | SOUL.md + IDENTITY.md + beliefs-candidates.md |
| Learning unit | "Framework" (auto-discovered) | "Belief candidate" (manual + gradient) |
| Evidence model | Tiered (hypothesis→observed→validated) | Triple Verification (cross-context ≥3, predictive, non-obvious) |
| Self-ref discount | 0.5x weight | Not explicit (but Triple Verification partially covers) |
| Signal extraction | Regex on transcript (automatic) | Nudge hooks (every N sessions) |
| Reflection | LLM-driven (Haiku/Sonnet) | FlowForge reflect workflow |
| Phase model | 3 phases (apprentice→creative→mastery) | None explicit |
| Tension tracking | Automated detection + context preferences | Not formalized |
| Memory | SQLite + embeddings | memory/*.md + MEMORY.md files |

### Key Differences
1. **claude-soul is fully automated** — signals extracted by regex, reflection triggered by thresholds, frameworks promoted/retired by evidence rules. We rely on manual nudge + workflow triggers.
2. **Their "self-referential evidence discount" is elegant** — prevents the system from confirming its own beliefs. We should formalize this in our beliefs-candidates pipeline.
3. **Their tiered evidence model** (hypothesis → observed → validated) maps cleanly to our Triple Verification but is more granular and automatic.
4. **They separate "quick" vs "deep" reflection** — we don't. Our reflect is always "deep" which may waste tokens on shallow sessions.
5. **Phase model is interesting** — adapting reflection frequency based on maturity. We could use this for beliefs-candidates review cadence.

### Architectural Insights
- **Monotonic tier advancement** (tiers never go down, only retirement handles bad frameworks) — prevents oscillation better than bidirectional scoring
- **Oscillation detection** is a meta-pattern we should adopt — if a belief keeps being added and removed, flag it as inconclusive rather than cycling
- **Token budget context assembly** with priority tiers — similar to how OpenClaw assembles system prompts but more explicit about what gets cut

## Ecosystem Position

Competes with: [[engram]] (identity layer for Claude Code), OpenClaw DNA system, native Claude Code CLAUDE.md
Complements: Claude Code (uses its hooks + CLI)
Related concepts: [[self-evolving-landscape]], [[elephant-agent]] (Personal Model), [[metaclaw]]

## Takeaways for Us

1. **Self-referential evidence discount**: Formalize in beliefs-candidates.md evaluation — evidence we generate about ourselves counts less than external validation
2. **Oscillation detection**: If a candidate keeps appearing and being rejected, mark as "inconclusive" and stop cycling
3. **Tiered reflection**: Quick (low-cost) vs Deep (high-cost) reflection based on signal accumulation — could split our nudge into lightweight check + periodic deep review
4. **Signal extraction heuristics**: Their regex patterns for correction/gratitude/confusion are reusable — we could detect these in our own session transcripts
5. **Phase-adaptive parameters**: Adjust review cadence and discovery thresholds based on system maturity

## Industry Signal

**Karpathy joined Anthropic** (2026-05-20, 1156pts on HN). After 15 days of silence (last activity: nanochat on 05-05). This is the biggest talent acquisition signal in the agent space — Karpathy's focus areas (education, local models, agent infrastructure) now directly feed into Claude's development. Implications for our direction: Anthropic's agent infrastructure investment is accelerating.

**Gemini 3.5 Flash** released (552pts on HN). Google's model competition continues.

## Other Scout Findings

- **engram** (34⭐, 2 days old): AI identity layer for Claude Code/Codex/Cursor. Python, MCP-compatible. Less sophisticated than claude-soul (no framework evolution or reflection) but identity-focused.
- **zerostack** (804⭐): Rust coding agent, minimalistic memory footprint. Fast growing.
- **scope-recall** (23⭐): Hermes memory provider with SQLite + LanceDB + scope isolation. Interesting hybrid storage.
- **shokunin** (83⭐): 62 agent skills for OpenCode/Claude Code/Cursor. ChromaDB memory, declarative self-updates.
