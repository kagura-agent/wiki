# waku-agent (ShenSeanChen)

**Discovered:** 2026-07-16 (scout)
**Repo:** https://github.com/ShenSeanChen/waku-agent
**Stars:** 142⭐ (6d old, 35 forks — strong early traction)
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

### Eval Separation — Deterministic vs Judge

The explicit separation of "did the right tool fire?" (unit test) from "was the reply good?" (LLM judge) is a clean pattern. They call conflating the two "the most common eval mistake." Their `make gate` requires both suites to pass before release.

### Memory Self-Management Tools

The agent has tools to manage its own memory: `manage_memory` (correct/forget), `update_soul` (preferences → SOUL.md), `create_skill` (procedural). Similar to our MEMORY.md updates but formalized as tool calls.

### The "Valley" Is Missing Here

Unlike [[memraw]], waku-agent doesn't do importance-based ordering. Its memory is structured (SQL tables) rather than flat text, so the "lost in the middle" problem is less relevant — memories are retrieved by query, not dumped whole.

## Tradeoffs

- **Strengths**: Extremely readable, well-documented, multi-provider, good eval story
- **Weaknesses**: SQLite FTS5 is keyword-only (no semantic search without Supabase upgrade), single-agent only (sub-agents are skeleton), Anthropic-first API (other providers via adapter)
- **Scale**: Not designed for production load — teaching codebase

## Position in Ecosystem

Sits in the "educational reference" tier alongside projects like [[fable-mode]] — designed to teach agent patterns, not to be deployed. Competes with blog posts and courses more than with tools. The YouTube-first distribution strategy is notable — code as video companion.

## Links

- [[memraw]] — contrasting memory approach (whole-in-prompt vs retrieval)
- [[agent-harness-landscape]] — waku fits the "readable harness" subcategory
- [[agent-memory-strategies]] — retrieval gate pattern
