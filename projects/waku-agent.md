# waku-agent (ShenSeanChen)

**Discovered:** 2026-07-16 (scout)
**Repo:** https://github.com/ShenSeanChen/waku-agent
**Stars:** 355⭐ (142→355 in 5d, +150%)
**License:** MIT
**Language:** Python
**Status:** Teaching repo / reference implementation, not a production framework

## What It Is

A "readable blueprint" personal AI agent — explicitly positioned as the educational counterpart to production systems like OpenClaw/Hermes. The entire agent loop is ~95 lines of plain Python. No frameworks (no LangGraph, no LangChain). Built for a YouTube channel (Sean's AI Stories).

## Architecture — Four Pillars

1. **Harness**: Gateway (CLI/Telegram/voice/dashboard) → Working Memory → Loop → Reply
2. **Loop**: Classic reason→act→repeat with two guardrails (natural end + max_iterations)
3. **Memory**: Three-pillar model:
   - **Semantic** (durable facts, profile) — SQLite + FTS5
   - **Episodic** (dated events, past chats) — SQLite
   - **Procedural** (SKILL.md, SOUL.md — "how to act") — markdown files
4. **Eval/LLM-Ops**: Deterministic tests (0/1) vs LLM-as-judge (scored %), separate suites. Release gate requires both to pass.

## Key Insights

### Retrieval Gate — The Most Interesting Pattern

A cheap small model answers one question before every turn: *"does this message need memory at all?"* This prevents:
- **Latency**: no unnecessary memory search
- **Bias**: irrelevant memories don't pollute answers ("over-interpretation")

Implementation is ~40 lines. The model returns `{retrieve: true/false, query: "...", reason: "..."}`. Fails open (if gate errors, retrieve anyway).

**Relevance to us:** We currently load MEMORY.md on every direct chat with Luna. A gate could save tokens on turns that don't need personal context (math, technical questions, etc.). But our memory loading is at session start, not per-turn, so the tradeoff is different. Worth tracking if we move to per-turn retrieval. See [[agent-memory-strategies]].

### Compare Arena — Model Evaluation (NEW 07-19)

A dashboard-integrated model comparison arena:
- **Race multiple models** on the same task, streaming responses in parallel columns
- **LLM-as-referee** grades responses (switchable neutral referee model, e.g. K3)
- **Cost-vs-quality scatter plot** for quantitative comparison
- Per-card re-grading, "re-grade all" for batch evaluation
- Apple Calendar integration (opt-in)

### delegate_task Through the Loop (NEW 07-19)

Initially, coding tasks bypassed the harness — just shelled out to `pi` per card. Rebuilt to run coding through the FULL agent loop:
- Model DECIDES to call `delegate_task` tool (not hardcoded)
- `delegate_task` spawns a pi sub-agent on THAT card's model (kimi→moonshotai, etc.)
- Loop continues autonomously until model finalizes
- Real cost/token tracking per delegation

This is architecturally the same pattern as our Claude Code subagent integration — the harness delegates coding to a sub-agent but keeps the orchestration loop running. Their implementation is cleaner in model-specific delegation and automatic cost tracking per delegation.

**Key implementation detail**: Under headless (dashboard server, no TTY), `pi` needed `stdin=subprocess.DEVNULL` to avoid hanging on inherited stdin. Universal lesson for spawning coding agents headless.

### Eval Separation — Deterministic vs Judge

The explicit separation of "did the right tool fire?" (unit test) from "was the reply good?" (LLM judge) is a clean pattern. They call conflating the two "the most common eval mistake." Their `make gate` requires both suites to pass before release. Test count: 147 hermetic tests.

### Memory Self-Management Tools

The agent has tools to manage its own memory: `manage_memory` (correct/forget), `update_soul` (preferences → SOUL.md), `create_skill` (procedural). Similar to our MEMORY.md updates but formalized as tool calls.

## Community Health (07-21)

- **6/6 THRIVING**: 9 unique issue authors, 12 external PRs/30d, 4 unique merged PR authors
- **Open PRs**: Discord gateway (#14), Notion episodic memory (#18), memory snapshot CLI (#17), JSONL trace renderer (#15)
- **Discussions enabled** but 0 activity so far
- YouTube-first distribution driving growth (code as video companion)

## Testing Patterns (from test code deep read)

### Hermetic Coding Eval
Tests monkeypatch `subprocess.run` and `shutil.which` — pi is NEVER actually spawned. The test pins behavior through:
- File seeding (test provides starting code files)
- Verify command (deterministic exit code = verdict)
- Provider/model passthrough (asserts `kimi → moonshotai` mapping)
- Error paths (missing key, bad cwd, timeout, stderr surfacing)

### Verify-Driven Scoring
Score is the `verify` command's exit code, not model prose. Free-form tasks (no verify) get `passed=None` — honest, not fake. This separates "did the code work?" from "was the explanation good?" — same philosophy as their deterministic vs LLM-judge eval split.

### Experimental Feature Gating
`WAKU_EXPERIMENTAL=1` env var gates `delegate_task` tool registration. The arena can set it per-race without flipping the global flag. Test verifies: flag off → tool not in registry; flag on → tool present.

## Tradeoffs

- **Strengths**: Extremely readable, well-documented, multi-provider, good eval story, active community
- **Weaknesses**: SQLite FTS5 is keyword-only (no semantic search without Supabase upgrade), single-agent only (sub-agents are skeleton), Anthropic-first API (other providers via adapter)
- **Scale**: Not designed for production load — teaching codebase

## Position in Ecosystem

Sits in the "educational reference" tier alongside projects like [[fable-mode]] — designed to teach agent patterns, not to be deployed. Growing community suggests demand for "readable agent" reference implementations. The Compare Arena feature bridges toward eval tooling territory.

## Links

- [[memraw]] — contrasting memory approach (whole-in-prompt vs retrieval)
- [[agent-harness-landscape]] — waku fits the "readable harness" subcategory
- [[agent-memory-strategies]] — retrieval gate pattern
