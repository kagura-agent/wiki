---
title: "OpenLoop — Agent-Agnostic Loop Engineering Framework"
created: 2026-06-13
updated: 2026-06-13
tags: [agent-framework, loop-engineering, monitoring, verification]
last_verified: 2026-06-13
---

# OpenLoop (thu-nmrc/openloop)

**Repo**: thu-nmrc/openloop
**Stars**: 55 (2026-06-13)
**Created**: 2026-06-10
**Language**: Python 3.11+
**License**: Apache-2.0
**Status**: Alpha, 3 days old

## What It Is

A small Python toolkit (~845 lines of core code) for building **monitored feedback loops around any software agent**. Turns vague "keep fixing until it works" requests into a concrete workspace with state, logs, verification gates, baseline checks, circuit breakers, and reproducible reports.

Key differentiator vs [[loop-engineering]] (cobusgreyling): OpenLoop is **runnable code**, not a pattern reference. It's a CLI tool (`openloop init/run/status/doctor`) that actually orchestrates agents through shell commands.

## Core Architecture

Loop phases: `play → scan → fix → verify → baseline → improve`

Each phase is a configurable shell command. Any agent (Claude Code, Codex, local scripts) plugs in via `commands.fix` or `commands.improve` in `openloop.json`.

### Key Design Decisions

1. **Agent-agnostic via shell commands**: The agent is just a CLI call. No SDK, no vendor lock-in. Environment variables (`OPENLOOP_WORKSPACE`, `OPENLOOP_PROJECT_ROOT`, `OPENLOOP_ROUND`, `OPENLOOP_STEP`) provide context.

2. **Heartbeat-driven monitoring**: `heartbeat.json` tracks PID, command, log path, round, step, speed, ETA, and "normal" flag. Every step emits a console heartbeat. This is observable loop engineering — you can always answer "what's running? is it healthy?"

3. **External verification is mandatory**: Builder ≠ judge. The `verify` command must be a deterministic external check (tests, benchmarks), not the agent's self-assessment.

4. **Circuit breaker**: `max_consecutive_failures` stops runaway loops. OOM detection via regex patterns. Command timeouts with graceful termination.

5. **Baseline regression gates**: Optional `baseline` config with metric extraction via regex, target value, and comparison direction. Prevents "fixed the bug but regressed performance."

6. **Progress persistence**: `progress.md` for durable log, `heartbeat.json` for live state, per-round JSON reports, per-command log files.

## Comparison with FlowForge

| Aspect | OpenLoop | FlowForge |
|---|---|---|
| Scope | Single project repair loop | Multi-step workflow orchestration |
| Agent integration | Shell command adapter | Agent spawns within workflow |
| State model | heartbeat.json + progress.md | YAML nodes + branch transitions |
| Verification | Built-in baseline + verify gates | No built-in verification |
| Use case | "Keep this project healthy" | "Walk through study/workloop/audit" |

They're complementary, not competing. FlowForge orchestrates *which* task; OpenLoop orchestrates *how* a single task gets repaired.

## Relevance to Us

1. **Heartbeat pattern**: Their heartbeat.json is similar to our heartbeat system but per-task rather than per-agent. The PID + log_path + ETA model is more structured than ours.

2. **Baseline regression**: We don't have baseline regression checking in our workloop. When we "fix" something, we don't verify it didn't regress something else. OpenLoop's baseline gate is a good idea.

3. **Circuit breaker**: We have `max_consecutive_failures` in our cron/heartbeat but not in our code-fix loops. Our subagents can retry indefinitely.

4. **Anti-self-certification**: Principle 3 ("Verification beats self-certification") aligns with our "验证 subagent 外部操作声明" rule. OpenLoop makes it structural.

## Architecture Insights

- **Minimal by design**: 845 lines total. No dependencies beyond stdlib. Easy to audit. This is the right size for a loop runner — you want the loop infrastructure to be simpler than what it orchestrates.
- **Template variables in commands**: `{workspace}`, `{project_root}`, `{round}`, `{last_error}` — lets the fix command know what failed. Clever low-cost context passing.
- **OOM detection is crude but effective**: Regex-matching "out of memory" / "killed" in stdout. Not perfect, but catches the 80% case that kills most autonomous loops.
- **No stall detection yet**: The `stall_timeout_seconds` config exists but stall detection isn't implemented in the reader thread (output queue monitoring). Good contribution opportunity.

## Potential Contribution

- Stall detection (config exists, implementation missing)
- Zero issues filed — greenfield contribution opportunity
- THU (Tsinghua) origin suggests academic backing, may have staying power

## Ecosystem Position

Part of the emerging "loop engineering" tooling layer: [[loop-engineering]] (patterns) → OpenLoop (runtime) → [[harness-engineering-openai]] (platform-native loops). Sits in the "agent-agnostic orchestration" niche.

## Applied (2026-06-13)

- **Baseline regression gates** → Created `tools/regression-gate.sh` with 7 file→benchmark mappings. Auto-detects changed files from git diff, runs relevant benchmarks, gates on failure. Integrated into study.yaml apply node. Pattern: "when you change a tool, verify its benchmark still passes before committing." Our version adapts to flat-file workspace context (no openloop.json, bash-native, relies on existing benchmarks). The anti-self-certification principle maps to our existing "验证 subagent 外部操作声明" rule — same philosophy, now structurally enforced for tool modifications too.
