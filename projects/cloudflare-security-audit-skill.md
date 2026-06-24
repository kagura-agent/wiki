---
title: "Cloudflare Security Audit Skill"
created: 2026-06-24
updated: 2026-06-24
source: https://github.com/cloudflare/security-audit-skill
stars: 499
status: active
tags: [security, skill-architecture, agent-orchestration, multi-agent, cloudflare]
last_verified: 2026-06-24
---

# Cloudflare Security Audit Skill

## What It Is

Cloudflare's open-source skill for turning a coding agent into a multi-phase security auditor. **6 files, 0 code dependencies** — entirely prompt-driven orchestration of sub-agents through markdown methodology docs.

This is the seed of Cloudflare's internal vulnerability harness (see blog: "Build your own vulnerability harness"). The harness grew into fleet-wide multi-stage system; this is the single-repo starting point.

## Architecture — 6-Phase Pipeline

1. **Recon** (3 parallel research agents → `architecture.md`)
2. **Hunt** (N parallel general agents per attack class, can spawn sub-research agents)
3. **Validate** (adversarial research agents try to DISPROVE each finding)
4. **Report** (REPORT.md + FINDINGS-DETAIL.md)
5. **Structured Output** (findings.json + schema validation via Node.js script)
6. **Independent Verification** (fresh agents verify every factual claim in findings.json)

### Key Design Decisions

1. **Agent separation for adversarial validation**: The agent that finds a bug is NEVER the one that validates it. This is the core insight — confirmation bias is structural.

2. **Schema-enforced output**: `report-schema.json` with `additionalProperties: false` + a validator script. Forces structured thinking, prevents hand-waving.

3. **Platform-agnostic vocabulary**: Uses "Task tool", "research agent", "general agent" — not platform-specific terms. Works on any agent with sub-agent capability.

4. **Multi-run additive coverage**: Explicitly designed for repeated runs. Each run reads prior `findings.json` to skip known issues and target gaps. "A single run finds roughly half total vulnerabilities."

5. **Capability-scoped agents**: `research` agents do focused investigation, `general` agents can spawn their own sub-agents. Two-level hierarchy matches investigation depth.

6. **Dynamic baselining**: Don't compare to a hardcoded standard — identify what comparable software exists for THIS app and calibrate severity against real-world norms.

## Novel Patterns Worth Noting

### Adversarial Validation (Phase 3 + 6)

Two separate adversarial passes:
- Phase 3: Validation agents try to DISPROVE findings (immediate post-hunt)
- Phase 6: Independent verification agents check every FACTUAL CLAIM (post-schema)

The two-pass structure catches different error types:
- Phase 3 catches: false positives, misunderstood code flows, defense-in-depth confusion
- Phase 6 catches: wrong file paths, incorrect line numbers, hallucinated function names, broken payloads

### "Anti-Patterns to Avoid" as Skill Guard

Section 10 explicitly lists what NOT to do — this is calibration material that prevents over-reporting. Notable:
- "Listing everything that deviates from OWASP as a finding" — OWASP is a checklist, not a bug list
- "Treating designed behavior as a bug" — understand trust model first
- "Constructing exploits from incorrect parser/runtime assumptions" — if exploit depends on parser behavior, CITE THE SPEC

### Hunting Methodology — 12 Angles

Not a checklist but a thinking framework:
1. Attack sad paths (error handlers, fallbacks, catch blocks)
2. What happens at boundaries (empty, max, null, zero, negative, exactly-at-limit)
3. Component trust assumptions (does B re-validate after A validated?)
4. Wrong operation order (call step 3 before step 1)
5. Concurrency (two requests same resource simultaneously)
6. Parser disagreements (URL parsed differently by router vs app)
7. Round-trip corruption (does data survive store→retrieve unchanged?)
8. Configuration as attack surface (missing config, env var overrides security)
9. Privilege trace (for every state change, trace back to permission check)
10. Leaked context (timing differences, error messages, response sizes)
11. Parameter overrides (user-supplied param changes security-relevant default)
12. Unverified claims driving trust (self-declared identity → access decision)

## Relevance to Our Direction

### Direct Applicability

1. **Adversarial validation pattern**: Our FlowForge workflows could use adversarial validation — where a separate agent tries to break what another agent built. Currently our PR review uses multi-model but not adversarial framing.

2. **Schema-enforced output as quality gate**: The `findings.json` + validator pattern is exactly what structured skill output should look like. Machine-readable, validated, separate from prose.

3. **Multi-run additive design**: Reading prior run outputs to skip known work is a pattern our study/workloop workflows could use more explicitly.

4. **Platform-agnostic skill design**: Their use of generic "Task tool" / "research agent" / "general agent" vocabulary makes the skill portable. Our skills are too OpenClaw-specific.

### Ecosystem Position

- **Validates skill-as-methodology**: This isn't code — it's 6 markdown files and a JSON schema. The value is entirely in the orchestration instructions. Confirms that skills = prompts + structure, not code.
- **Enterprise adoption signal**: Cloudflare using skill-based agent orchestration for security means the pattern has production credibility.
- **Competitor to scanner-based security**: Positions agent-based auditing as superior to automated scanners for logic bugs, business logic, chained attacks.

## Limitations / Criticism

1. **Zero community engagement**: No issues, no PRs, no discussions. This is a "code drop" — Cloudflare published it but isn't actively iterating in public.
2. **Only one push (Jun 18)**: No updates in 6 days. May remain a static artifact.
3. **No test suite for the skill itself**: No way to verify the skill works except by running it (expensive).
4. **Agent cost is unconstrained**: Running 8-12+ general agents + research sub-agents + validation agents + verification agents = potentially massive token usage. No budget guidance.
5. **Assumes strong sub-agent support**: Requires platform with parallel task spawning and result collection. Not all agent runtimes support this well.

## Takeaways

- **Adversarial validation is the key insight**: Apply to our own quality gates
- **Schema-enforced structured output**: Apply to any skill that produces machine-readable artifacts
- **Multi-run additive**: Apply to recurring workflow runs
- **Anti-patterns section**: Every skill should include "what NOT to do" as calibration

Links: [[agent-skill-survey-2026]], [[skill-trust-landscape-2026-04]], [[agent-security]]
