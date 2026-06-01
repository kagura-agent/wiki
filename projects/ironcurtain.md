---
title: IronCurtain
url: https://github.com/provos/ironcurtain
stars: 480
created: 2026-02-21
last_updated: 2026-06-01
depth: 🔭 scout
status: active
last_verified: 2026-06-01
---

# IronCurtain — Constitutional Security for AI Agents

Apache-2.0, 480⭐ (+4.1% in 7d), 60+ forks, by provos (likely Niels Provos, security researcher). Very active (pushing daily). 🟢 THRIVING (5/6).

## Core Idea

**"Agent is untrusted"** as design principle. Security doesn't depend on the model "being good."

Plain-English constitution → LLM-compiled to deterministic rules → validated against test scenarios → enforced at runtime on every tool call. No LLM involvement at enforcement time.

## Architecture

Two execution modes:
1. **Builtin Agent (Code Mode)** — TypeScript in V8 isolate, no direct host access. All tool calls exit as structured MCP requests through policy engine.
2. **Docker Agent Mode** — External agent (Claude Code, Goose, etc.) in Docker container. TLS-terminating MITM proxy for LLM calls (host allowlist, key swap). MCP tool calls through policy engine. Registry proxy for package installs.

Policy engine decisions: **allow / deny / escalate** (to user for approval).

## Key Innovation: Semantic Interposition

All agent interactions go through MCP servers (filesystem, git, etc.). Every tool call passes through the policy engine. This means:
- No raw system access — all actions are semantically meaningful
- Policy can reason about intent, not just syscalls
- Escalation is contextual (e.g., "git push" escalates, "git status" doesn't)

## Smart Approval

Auto-approver concept: user's trusted input from "command mode" (Ctrl-A) provides clear intent, so some escalated actions can be auto-approved. Reduces approval fatigue without reducing security.

## Relevance to OpenClaw

OpenClaw has a simpler approval model (native approvals for elevated commands). IronCurtain's approach is more principled:
- **Constitution-based**: Security intent expressed in English, not code
- **MCP-mediated**: All tool calls are structured, auditable, policy-checkable
- **No ambient authority**: Agent never inherits user privileges directly

The "compile English intent to deterministic rules" pattern could inspire improvements to OpenClaw's permission system.

## v0.11.0 (2026-05-18) — Major Evolution

IronCurtain has evolved from a security layer into a **full agent workflow orchestration platform**:

### Vulnerability Discovery Workflow
Marquee feature: orchestrator-driven FSM that hunts memory-safety and logic bugs in native code. Hub-and-spoke architecture with states: `analyze` → `harness_design` → reviewer loop → `harness_build` → `harness_validate` → `discover`/`triage` → LLM `review` → human `report_review` gate. Uses tiered harnesses (Tier 1 isolated function / Tier 2 multi-component / Tier 3 full build) with libFuzzer/AFL++ coverage-feedback gating. Per-hypothesis investigation journal. This is essentially an **automated security researcher**.

### Workflow Web UI (Svelte 5)
Full lifecycle dashboard: start runs, watch live state-machine graph (dagre+SVG), review gates with artifact browser, handle escalations. The CLI is now secondary — web UI is the intended interface.

### Multi-Agent Workflow Engine
XState v5 FSM with: typed events, guards, agent/gate/deterministic states, `when:` verdict conditions, `maxVisits` caps, crash-resume via on-disk checkpoints, YAML definitions as directory packages.

### Shared-Container Mode
One Docker container + one `ToolCallCoordinator` for all agent states in a run. Hot-swaps active `PolicyEngine` between states via Unix domain control socket. Unified audit trail.

### Agent Skills (SKILL.md)
Drop-in skill packaging at `~/.ironcurtain/skills/<name>/`. Per-state skills in workflow definitions. Read-only bind mount into containers. Compatible with Claude Code and Goose skill discovery.

### Other Notable Additions
- `ironcurtain doctor` — comprehensive setup diagnostics
- Real-time LLM token stream observation (Matrix-style data rain)
- Configurable Docker resource limits with auto-clamp
- Per-persona/per-job memory opt-in
- UID/GID remap for non-default Linux hosts
- Silent builtin fallback removed (explicit mode selection required)

## Architectural Shift

The project has moved from "policy engine that wraps tool calls" to "workflow orchestration platform with constitutional security baked in." The vuln-discovery workflow demonstrates the thesis: multi-hour, multi-agent runs that are both powerful AND auditable. The security layer isn't optional — it's the foundation that makes autonomous long-running workflows trustworthy.

## Post-v0.11.0 (2026-05-28~31) — SFT/RL Training Data Pipeline

New direction: **MITM token-trajectory capture**. IronCurtain's proxy position between agent and LLM provider is leveraged to capture complete (input → output) training pairs as JSONL trajectories.

### Key PRs:
- **PR #273** (+4121 lines): Verbatim, byte/wire-faithful capture of agent↔provider HTTP exchanges. Per-session JSONL trajectories + ordering manifest. Opt-in via `--capture-traces` on `start`, `workflow start`, and `daemon`. This is the raw-input stage for an SFT/RL training-data pipeline.
- **PR #276**: Wire `--capture-traces` into PTY session path (mux → child sessions). Fixes gap where capture worked in batch/workflow mode but not in interactive PTY sessions.
- **PR #277** (+1451 lines): Break runtime import cycle + add `madge --circular` pre-push gate + CI step.

### Insight

IronCurtain's MITM proxy position is uniquely suited for training data capture — it already intercepts all LLM traffic for security enforcement, so adding faithful recording is architecturally cheap. This positions the project at the intersection of **agent security** and **agent training**, which is novel. No other security-focused project is doing this.

The trajectory capture creates a flywheel: run agents → capture data → fine-tune models → run better agents. Combined with the vuln-discovery workflow, this could generate specialized security-researcher training data at scale.

This positions IronCurtain as both a security tool AND a competitor to agent orchestration frameworks. The workflow engine is general-purpose, not limited to security tasks.

## Relevance to OpenClaw (Updated)

- **Workflow engine pattern**: XState FSM with crash-resume, per-state skills, and shared containers is a mature pattern worth studying if OpenClaw ever builds multi-agent workflow orchestration
- **SKILL.md convergence**: IronCurtain now uses SKILL.md natively, validating the format as an industry standard
- **Security-first orchestration**: The thesis that "security enables autonomy" (not "limits it") is proven by the vuln-discovery workflow — you can only run multi-hour unattended agents if every tool call is policy-checked
- **Constitutional approach remains unique**: English intent → deterministic rules → enforcement is now proven at workflow scale, not just single sessions

## Related
- [[opensandbox]] — Alibaba's sandbox approach (container-level isolation)
- [[poco-claw]] — competitor that also sandboxes agents in Docker
- [[self-evolving-agent-landscape]] — security layer for autonomous agents
