---
title: eval-view (hidai25)
type: project
status: active
updated: 2026-05-21
links:
  - "[[eval-driven-self-improvement]]"
  - "[[evolution-needs-eval]]"
  - "[[agent-memory-benchmark]]"
  - "[[mechanical-verification]]"
  - "[[immutable-evaluation]]"
last_verified: 2026-05-21
---

# eval-view — Agent Regression Testing

**Repo**: https://github.com/hidai25/eval-view
**Stars**: 105⭐ (05-21) | **Forks**: 20 | **License**: Apache-2.0

## What It Is

Regression testing framework for AI agents. Snapshot tool-call trajectories, diff across runs, detect regressions. Think "visual regression testing" but for agent behavior.

Supports 9 adapters: http, langgraph, crewai, openai-assistants, anthropic, huggingface, goose, tapescope, mcp.

## v0.8.0 Architecture Expansion (2026-05-15)

Massive update — 7 new pure modules, each with deterministic baseline + LLM judge plug-in slot:

### Goal-Drift Detection (`goal_drift.py`)
- Jaccard token overlap between stated goal and trajectory-derived intent
- Catches when agent wanders from user's request (e.g., asked to cancel subscription, ends up discussing pricing)
- Conservative threshold (0.2) to minimize false positives
- **Relevance to us**: Could detect when FlowForge workflows drift from their stated purpose

### Retrieval Lineage (`retrieval_lineage.py`)
- Per-chunk attribution: which retrieved chunks actually influenced the output?
- Token-overlap baseline, plug-in slot for smarter methods (embeddings, mechanistic interp)
- Identifies dead-weight chunks (never influence) and dominant chunks (overfit risk)
- **Relevance to us**: Could evaluate wiki/memory retrieval effectiveness — which notes actually get used?

### Chaos Injection (`chaos.py`)
- Controlled disruption for agent simulation: tool failures, latency spikes, goal interruptions
- Seed-based deterministic chaos — same suite + seed = same disruptions
- Three modes: `tool_failure`, `latency_spike`, `goal_interruption`
- **Relevance to us**: Testing agent resilience to tool failures (API timeouts, rate limits)

### Other New Modules
- **Freshness** (`freshness.py`, 500 lines): Detect stale cached responses
- **Fleet** (`fleet.py`, 442 lines): Multi-agent coordination eval
- **Root-Cause Hint** (`root_cause_hint.py`, 485 lines): Auto-diagnose why a trajectory failed
- **OTel Semconv** (`otel_semconv.py`, 307 lines): OpenTelemetry semantic conventions for agent spans

### CLI Auth Unification
- `/cli-auth` loopback flow unifies CLI and SaaS auth

## Architecture Pattern: Deterministic Baseline + Judge Slot

Every module follows the same pattern:
1. Pure Python, no I/O, no network, no LLM by default
2. Deterministic baseline (usually token overlap / Jaccard)
3. Callable `judge` parameter for LLM-powered upgrades
4. Contributor recipe in `docs/agent-recipes/`

This is a clean extensibility pattern — ship something useful without dependencies, let contributors upgrade the brains.

## Dogfood Practice

eval-view dogfoods itself daily — wraps its own chat mode as an HTTP agent and runs the eval suite against it. Rolling issue auto-opens on failure, auto-closes on recovery. This is a good example of [[mechanical-verification]] — the tool tests itself mechanically, no human in the loop.

## Community Health (05-21)
- 🟢 THRIVING (5/6)
- 8 external PRs in 30 days
- 5 unique issue authors
- 28/30 PRs merged (93%)
- 2 core maintainers
- Uses Claude Code for development (visible in issue comments)

## Applied

### Goal-Drift Check (2026-05-21)
Adapted `goal_drift.py` Jaccard baseline into `tools/goal-drift-check.sh` for [[FlowForge]] subagent output validation. Dual-pass: jaccard ≥ 0.15 OR task_coverage ≥ 0.40. Integrated into FlowForge SKILL.md step 3b. Zero LLM cost. See also [[mechanical-verification]].

## Takeaways
1. **Goal-drift detection** — Applied ✅. `tools/goal-drift-check.sh` adapts Jaccard baseline for FlowForge subagent drift detection.
2. **Retrieval lineage** could be adapted to evaluate our wiki/memory system — which notes are actually influential? Connects to [[agent-memory-benchmark]].
3. **"Pure module + judge slot"** pattern is a good template for extensible agent tooling — ship deterministic baseline, let contributors upgrade.
4. **Chaos injection** with seed-based determinism — reproducible fault testing. Relevant for [[eval-driven-self-improvement]].
5. **Dogfood-as-CI** — they run their own tool against itself daily. Applied ✅: `tools/tool-selftest.sh` (10 tests), integrated into review.yaml step 0.
