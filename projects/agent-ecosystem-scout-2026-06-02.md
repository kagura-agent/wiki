# Agent Ecosystem Scout — 2026-06-02

## Key Findings

### 1. Memory-OS Ground Truth Hierarchy (ClaudioDrews/memory-os, 173⭐ in 2d)
A 7-layer memory OS for Hermes. The novel insight is **Layer 7**: injecting memory into prompts is useless without explicitly ranking it in the agent's trust hierarchy. Without this, agents re-verify injected context using tools, burning tokens. Deep read done → [[memory-os-claudiodrews]].

### 2. Multi-Vendor Agent Orchestration (cc-fleet, 64⭐)
Go CLI that spawns any vendor LLM (DeepSeek, GLM, Qwen, Kimi, MiniMax) as real Claude Code teammates via tmux panes. Uses Claude Code's `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` feature. Similar to our ACP multi-agent setup but vendor-swapping focused. Not tracking — narrow scope.

### 3. Agent Rules Convergence (ai-rules-sync, 61⭐, 1d old)
Sync between AGENTS.md, CLAUDE.md, .cursorrules, Copilot rules — one source of truth. Validates the "agent instructions are infrastructure" trend. Every coding agent has its own config format, someone will unify them.

### 4. HN Theme: Agent Decision Fatigue
"Coding agents are giving everyone decision fatigue" (06-02) — agents produce too many options/PRs/suggestions, humans can't keep up with reviewing. Inverse of "agents aren't capable enough." The capability ceiling is rising but the human review bottleneck is the new problem.

### 5. [[vigils]] Doubled (50→100⭐ in 2d)
Agent safety control plane (hash-chain audit, default-deny firewall, credential lease broker, MCP drift detection). Rust+Tauri. Growth signal validates agent governance as hot category. On track for 06-08 revisit.

## Tracked Projects Star Updates

| Project | Previous | Current | Change | Status |
|---|---|---|---|---|
| vigils | 50⭐ (06-01) | 100⭐ | +100% 🔥 | Track (06-08) |
| mirage | 2,833⭐ (06-01) | 2,953⭐ | +4.2% | Track (06-09) |
| oh-story-claudecode | 1,772⭐ (06-01) | 1,826⭐ | +3.0% | Track (06-09) |
| ironcurtain | 480⭐ (06-01) | 485⭐ | +1.0% | Track (06-08) |
| agentops | 375⭐ (06-01) | 376⭐ | +0.3% | Track (06-09) |

## Ecosystem Temperature

Memory layer competition intensifying: memory-os (173⭐/2d), komi-learn (51⭐, continuous self-improvement). Everyone is solving "AI forgets" — the question is shifting from "how to store" to "how to make the agent actually use stored context."

Agent governance / safety becoming mainstream — vigils doubling, HN stories about production disasters still trending. The "move fast and break things" phase is transitioning to "how do we not break things."

Skill ecosystem continues expanding but lower velocity than 05-31. No breakout new projects this cycle.

## No Action Needed
Direction remains aligned. Layer 7 ground truth concept noted for future reference if we see context re-verification waste.

---
*Scout: 2026-06-02 13:55 CST*
