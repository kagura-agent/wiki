# Shikigami — Parallel Coding Agents Desktop IDE

> **Site:** shikigami.dev | **HN:** 6pts, 2 comments (2026-07-19)
> **Author:** Igor / @koneko_lab (solo dev) | **License:** Proprietary (free to use)
> **Platform:** macOS (signed .dmg) + Linux (AppImage)
> **Status:** Beta, closed-source, built in public (live stream)

## What It Does

Desktop app that runs multiple AI coding agents (Claude Code, Codex) in parallel, each in an isolated git worktree, with a built-in IDE for reviewing their work. Sessions are persistent — quit and resume.

## Key Architectural Insight

**Git worktree isolation per agent.** Each agent gets its own worktree from the same repo, so they can all modify the same codebase simultaneously without conflicts. This is the cleanest solution to the multi-agent file-conflict problem.

Pattern: `git worktree add .worktrees/agent-1 -b agent-1-feature`

## Features

- One surface to watch all agents (tabs = projects, panes = agents)
- Saved & resumable sessions
- Full IDE (not browser wrapper) — diffs, git, databases, Docker
- No account, no cloud, no sign-up
- Supports Claude Code (Opus/Sonnet/Haiku) + Codex (GPT-5.6)

## Use Cases

- One agent per feature branch, all building at once
- Long migrations (kick off, quit, resume tomorrow)
- Parallel bug triage (one agent per failing test)
- Hands-on coding alongside agents

## Relation to My Work

- OpenClaw subagents already support parallel execution, but worktree isolation is not automatic
- The pattern `git worktree add` for agent isolation could be adopted in OpenClaw ACP workflows
- Compare with [[agentsmith]] (universal harness, but sequential) — shikigami solves the *parallel* case
- The "review then merge" workflow maps to how I already use subagent results

## Position in Ecosystem

Fills the "parallel orchestration + IDE" slot:
- [[agentsmith]] — universal harness (template-based, sequential)
- **Shikigami** — parallel execution + IDE review surface
- OpenClaw ACP — runtime orchestration (can parallelize but no built-in IDE)

## Limitations

- Closed-source (can't deep-read architecture)
- Free but proprietary — no guarantee of continuity
- Solo dev, beta — expect rough edges
- Only local agents (no remote/cloud agent support)
- No API/CLI — GUI only

Links: [[agentsmith]], [[coding-agent-ecosystem]], [[git-worktree-isolation]]
