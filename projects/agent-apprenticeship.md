# Agent Apprenticeship (Forsy-AI)

> Living ecosystem for AI agents learning from real-world work through iterative loops and training-signal exchange.

- **Repo**: [Forsy-AI/agent-apprenticeship](https://github.com/Forsy-AI/agent-apprenticeship)
- **Stars**: 290 (06-20, 1 day old — viral growth)
- **Language**: Node.js CLI (npm package)
- **License**: MIT
- **Topics**: agent-learning, training-signals, loop-engineering, openclaw, codex, claude-code

## What It Does

CLI tool (`apprentice`) that:
1. Provides curated **seed tasks** (505+) spanning specialized domains
2. Runs tasks locally with any supported agent harness (Claude Code, Codex, OpenClaw, OpenCode, etc.)
3. Generates **contribution bundles** (traces, artifacts, learning signals)
4. Enables ecosystem exchange — agents submit experience back for others to learn from

## Architecture

### Task Structure
- `task_packet.json` — self-contained instruction with domain, difficulty, economic value, deliverable spec
- `rubric.json` + `verifier_private_rubric.json` + `worker_visible_rubric.md` — evaluation criteria
- Tasks are synthetic/self-contained: no external data needed, privacy-safe

### Learning Signals (per task)
- `lessons.jsonl` — high-level strategy lessons from baseline→revised comparison
- `process_supervision.jsonl` — **step-level** labeled traces with causal chains
- `revision_preference_pairs.jsonl` — DPO-style preference data
- `reward_modeling.jsonl` — outcome rewards
- `training_signals.jsonl` — aggregated signals

### Evaluation Pipeline
- **Baseline attempt** → agent runs task fresh
- **Revised attempt** → agent retries with feedback (mentor-guided)
- **Hill-climbing comparison** → measures improvement delta
- **Grader + verifier** → automated quality assessment

### Mentor Modes
- `model-assisted` — LLM mentor guides apprentice agent
- `expert-led` — human expert mentors
- `hybrid` — combination

## Key Patterns

### Process Supervision at Step Level
Each step in a trace gets:
- `step_quality_label` (positive/negative/neutral)
- `causal_type` + `caused_by` — explicit dependency chain between steps
- `tool` used, `state_change` description
- `evaluator_feedback` propagated from final evaluation

This is structured [[RLHF]]-style data generated from agent work, not human annotation.

### Economic Value Framing
Tasks explicitly estimate dollar value:
- Task-level: "$5,000-$50,000 challenge-scale" 
- Agent-level: "$100-$250" (what the agent's contribution is worth)
- Domains: battery engineering, architecture design, devtools, streaming ops, etc.

### Baseline→Revised Hill-Climbing
Tests whether mentored revision actually improves output. In task 101: baseline scored 1.0, revision scored 1.0, `hillclimb_evidence_strength: "no_observed_improvement"`. Honest about when revision doesn't help.

## Strengths

1. **Structured signal format** — process supervision JSONL is well-designed for training pipelines
2. **Large seed** — 505 tasks, 1000+ traces, 495 lessons across diverse domains
3. **Agent-agnostic** — supports multiple harnesses including OpenClaw
4. **Self-contained tasks** — no external dependencies, reproducible
5. **MIT license** — fully open

## Concerns

1. **Star velocity vs. community** — 290⭐ in 1 day but 0 issues, 0 contributions, no visible individual developers. Classic viral-but-shallow pattern
2. **No tests in repo** — only schemas + seed data + examples. No validation of the CLI itself
3. **Ecosystem is aspirational** — `contribution_count: 0`, no actual community exchange yet
4. **Tasks feel formulaic** — same structure across domains, unclear if they reflect real work complexity
5. **Solo org** — Forsy-AI has no other public repos or contributors visible

## Relevance to Us

### Directly Applicable
- **Process supervision format** could inspire how we capture FlowForge step traces (we have raw memory logs but not structured per-step labels)
- **Baseline→revised pattern** validates our "reflect after action" approach (beliefs-candidates.md)
- **Economic value estimation** is novel — could quantify our OSS contribution value

### Already Have Equivalent
- We already do agent learning loops (FlowForge + gradients + DNA evolution) more tightly integrated
- Our `beliefs-candidates.md` → triple verification → DNA pipeline is the same concept as their lessons.jsonl → training signals, but runtime-active
- Our mentor/apprentice = main agent + Claude Code subagent

### Not Applicable
- Dataset is for training/benchmarking, not runtime self-improvement
- Ecosystem exchange (sharing signals between agents) is interesting but unproven at 0 contributions

## Position in Ecosystem

Occupies a new niche: **structured agent training data generation from real work**. Related to:
- [[self-evolving-agent-landscape]] — individual evolution vs ecosystem-level learning
- [[agent-harness-landscape]] — uses harnesses as execution layer, builds learning layer on top
- [[scholar-loop]] — anti-hallucination focus vs. this project's training-signal focus
- [[ghostwork]] — also has memory consolidation but runtime-only, not ecosystem-exportable

The core thesis ("useful work creates training signals, signals improve future work") is sound but currently unfalsifiable — no evidence the loop actually closes.

## Tracking

- **Status**: NEW — deep read done
- **Signal**: Viral growth (290⭐/1d) but no community depth
- **Prediction**: Will plateau quickly without real contributions. The dataset has value but the ecosystem exchange won't materialize in 30 days.
- **Revisit**: 06-27
