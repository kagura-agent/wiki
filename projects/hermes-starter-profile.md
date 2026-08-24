---
title: Hermes Starter Profile — auditable least-privilege onboarding configuration
created: 2026-08-10
tags: [agent-onboarding, least-privilege, tool-policy, configuration-audit]
last_verified: 2026-08-24
source: https://github.com/teknium1/hermes-starter-profile
---

# Hermes Starter Profile

- **Repo:** [teknium1/hermes-starter-profile](https://github.com/teknium1/hermes-starter-profile)
- **Revision examined:** `24dc015efa46` (2026-08-09)
- **Observed 2026-08-10:** 32⭐, 3 forks, no issues; MIT; created 2026-08-09 and pushed the same day.
- **Verification:** shallow clone; repository tree has no test suite; `python3 -m py_compile scripts/audit_profile.py` passed. The audit’s runtime resolver checks were inspected but not executed because Hermes is not installed in this workspace.

## A deliberately small first-agent surface

This is a distribution-owned Hermes profile for new users, rather than a new agent runtime. Every shipped surface—including CLI, chat platforms, webhook/API server, and cron—is declared with the same five toolsets: clarification, web search, vision, image generation, and text-to-speech. It explicitly disables terminal/code/file execution, computer/browser automation, delegation, scheduling, persistent memory, skills, MCP, hooks, and external integrations.

The onboarding decision is notable: it makes a first agent useful for research and creative work while refusing the capabilities that turn beginner mistakes into machine actions. Credentials and model selection remain profile-local, and ordinary session history still follows Hermes’s normal local behavior; this is not a claim of zero retention.

## Two-layer policy plus an executable drift check

`platform_toolsets` provides a per-surface allowlist, while global `agent.disabled_toolsets` supplies a second deny layer for dangerous composites. The included `audit_profile.py` does more than compare YAML strings: it imports Hermes’s platform resolver and toolset expander, subtracts disabled tools, and requires the final resolved names to equal the five permitted tools on all 22 surfaces. It also hard-fails on enabled memory/curator/lazy installs or nonempty MCP, hooks, and quick commands.

That is a stronger configuration pattern than relying on prose or a single denylist: **test the resolved effective authority**, because composite toolsets can otherwise hide an unsafe member. The limitation is equally explicit in `DESIGN.md`: this is an accidental-drift guardrail, not a host sandbox. Anyone able to edit the installed profile can expand its permissions.

## Position and relation to our work

[[hermes-agent]] is a broad, self-improving full-agent system with extensive platform and execution capabilities. This repository takes the opposite product slice: a constrained learning profile that makes capability escalation intentional. It is closest in spirit to our [[tool-execution-policy-enforcement]] and [[default-fail-gate]] patterns—use an allowlist, validate the evaluated configuration, and treat documented restrictions as insufficient without a mechanical check.

The profile also clarifies an onboarding trade-off for OpenClaw-like systems: a general-purpose workspace cannot simply inherit this configuration, but a separate "research/creative only" persona or installation path could reduce initial blast radius without weakening an established power-user profile.

## Transferable lesson

If we ship a reduced-capability mode, define its final allowed tool names for every ingress, then run a resolver-level audit in CI or before activation. Keep the audit fail-closed when the resolver cannot run. Do not describe such a profile as a sandbox: permission files protect against configuration drift, not against users or code that can edit those files.

## Follow-up

Revisit **2026-08-24** for a release, tests or CI that execute the resolver audit, external issues, and evidence that the profile's five-tool baseline remains stable as Hermes adds toolsets.

## 08-24 followup — no movement, downgraded cool

- 37⭐ (32→37, +5, slow organic), 3 forks, 0 open issues, 0 PRs.
- Default branch: only 2 commits, both 08-09 (initial + beginner setup guide); **15 days silent since**.
- No tests/CI, no external feedback, no issue surface — exactly the 08-10 prediction. The resolver-audit pattern remains worth borrowing, but this repo is a static artifact, not an active project.
- **Downgraded cool.** Revisit 09-23; still silent → drop. (calibration: prediction of 
