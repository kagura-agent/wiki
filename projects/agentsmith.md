---
title: "AgentSmith — Universal Agent Operating Harness"
slug: agentsmith
created: 2026-07-18
updated: 2026-07-25
status: active
tags: [agent-harness, coding-agent, claude-code, discipline, self-improving, security]
links: [[coding-agent-ecosystem]], [[model-native-vs-model-agnostic]], [[self-evolving-agent-landscape]]
last_verified: 2026-07-25
---

# AgentSmith — Universal Agent Operating Harness

**Repo:** PromptPartner/agentsmith | **Stars:** 255 (100→255 in 7d, +155%) | **License:** MIT
**Author:** PromptPartner (solo dev, 6+ months real production use)

## What It Is

A portable, battle-tested "operating system" for AI coding agents (Claude Code primarily, but model-agnostic via CLAUDE.md/AGENTS.md/GEMINI.md assembly). Not a runtime — it's a **harness template**: core rules + swappable work-type profiles assembled into a single instruction file via `setup.sh`.

## Core Architecture

**Static/Dynamic context split** (first-class design decision):
- **Static** = assembled `CLAUDE.md` = `core/` (universal rules, ~6 files) + chosen `profile(s)` — lean, paid every turn
- **Dynamic** = skills, templates, docs, memory — loaded on demand
- **600 line leanness budget** — hard cap for assembled instructions, measured precisely (max software-dev at 88%)

**Core modules (6 files, ~60-70 lines each):**
1. `00-identity` — operator identity template, explain-WHY-before-HOW
2. `10-operating-model` — plan→do→verify→finalize→handoff, conductor vs orchestrator modes, three-case pause rule
3. `20-principle-rules` — 10 rigid rules from real failures. Chesterton's Fence, prove-it (failing test first), verify whole chain, atomic commits, finish-including-docs, never delete research, keep surface small
4. `30-anti-rationalization` — STOP table mapping rationalizing thoughts to the rule being skipped
5. `40-subagents-and-tools` — routing rules, tool discipline, failure recovery (stop after 2 identical failures)
6. `50-git-and-handoff` — handoff protocol: safe-state → write memory → emit kickoff block
7. `60-evolving-the-harness` — meta-rule: fix the system not the symptom, feedback loop

**10 Profiles:** software-dev, devops-setup, marketing-outreach, document-creation, data-crunching, deep-research, creative-design, general-admin, autonomous-loops, **security-audit** (new)

## Key Insights

### 1. Anti-Rationalization Table (STOP table)
Maps internal thought patterns that precede rule violations to the specific rule being rationalized away. Addresses the **metacognitive layer** — not just "what to do" but "what you'll think right before not doing it."

### 2. Two-Axis Security Model (NEW — PR#10, 2026-07-23)
The most significant architectural insight from the July update:
- **Axis 1: Agent safety** — can the agent hurt ME? (blast radius, sandboxing, secret-scan, leak-gate, pause-list)
- **Axis 2: Product security** — is the code the agent WRITES safe? (IDOR, injection, authz, CVEs)

Most harnesses (including ours) only cover axis 1. "A perfectly sandboxed agent will happily write an IDOR."

**Implementation:** Two security checkboxes + two STOP rows per code profile, integrated into ordinary feature work rather than separate security ceremonies. The authz STOP row targets the HANDLER not the caller: "internal-only is the rationalization that survives exactly until the next routing change."

### 3. Deterministic Fix > Prose Reminder (core/60 principle)
"A rule the model can skip isn't a guard." Mechanically detectable issues (CVE in deps, credentials in tracked files) belong in `verify.conf` where scripts enforce them, not in prose rules. The judgment call stays a checkbox; the detectable parts become automated guards.

### 4. Security-Audit Profile: "A grep hit is a lead, not a finding"
When security IS the deliverable (audit, pentest, threat model):
- Reproduce findings, impact-rate for THIS deployment (not advisory CVSS), check remediation against breakage
- Two rules stricter than core: (1) Authorization earlier than first-write line — "in this domain, reading is not free" (2) R8 > R7 in reports — "rotate first, name the resource, never the value"
- A report of unreproduced scanner output costs more engineering time than it saves

### 5. RED-by-Default Verify
Fresh install's `verify.conf` uses an `unwired` phase that FAILS (exit 1) with a pointer, not a placeholder that passes. "A verify that lies is worse than no verify." This inverts the usual default-green pattern.

### 6. Design System Awareness (PR#6)
`DESIGN.md` as durable artifact for UI work. Once-per-session PreToolUse nudge hook (self-gating on DESIGN.md presence — backend projects stay silent). Three paths: bring brand, pick from catalog (awesome-design-md), generate with ui-ux-pro-max.

### 7. Profile Stacking Budget Discipline
Attempted stacking software-dev+security-audit → 635 lines, over 600 budget. Trimming didn't close the gap. Changed guidance instead: re-assemble for audit mode rather than stack. "Finding and shipping are different modes, carrying both rule sets contradicts it."

### 8. rtk Integration (CLI Output Compression)
[rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer, ~71k⭐) — binary that compresses noisy CLI output 60-90% before it hits context window. Similar concept to our compress-output.sh but as a proper maintained tool. Auto-installed for code profiles.

## Relationship to Our Setup

**What they have that we should consider:**
- **Two-axis security model** — our DNA covers blast radius but doesn't ask about output security
- **STOP table** — explicit "thought → rule being skipped" mapping. We have beliefs-candidates but no rationalization-interception
- **RED-by-default verify** — our ad-hoc checking has no "fail until wired" safety net
- **rtk** — proper tool vs our bash script. Worth evaluating as replacement for compress-output.sh

**What we have that they don't:**
- **Runtime** — they're a static template; we have OpenClaw (cron, heartbeat, multi-session, tools)
- **Memory system** — daily notes + MEMORY.md + wiki. They have handoff notes only
- **Self-evolution pipeline** — beliefs-candidates → DNA promotion with frequency tracking
- **Study/learning loop** — systematic knowledge acquisition

## Growth Trajectory

- 07-18: 100⭐ → 07-25: 255⭐ (+155% in 7 days)
- 11 forks, 0 open issues (all closed)
- Solo dev but extreme commit quality (every PR has detailed evidence, verification, multiple commits)
- Community: NASCENT (1/6) — no external PRs yet, but 2 unique issue authors
- GitHub star velocity suggests reaching 500+ within 2 weeks if sustained

## Verdict

High-quality, rapidly growing reference implementation of agent discipline. The two-axis security model and STOP table are the most directly applicable ideas. PR#10's security work demonstrates mature systems thinking about where rules belong (prose vs guards vs deterministic checks).

Links: [[coding-agent-ecosystem]], [[model-native-vs-model-agnostic]], [[self-evolving-agent-landscape]]
