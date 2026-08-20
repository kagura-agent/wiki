---
title: SkillForge — Local-First Executable Skill Runtime
created: 2026-08-06
source: GitHub HaddenHunter/SkillForge
status: deep-read
last_verified: 2026-08-20
tags: [agent-skills, mcp, sandboxing, registry, rust]
---

# SkillForge — Local-First Executable Skill Runtime

## What it is

SkillForge is a Phase-1 Rust runtime plus TypeScript registry prototype that packages agent skills as a strict `skill.yml` manifest, `SKILL.md`, and `eval.md`. It attempts to turn the prompt-only skill convention into installable, versioned units with declared permissions, MCP exposure, local evaluation, and GitHub Release distribution.

## Verified architecture

- **Manifest as contract:** `core/src/skill.rs` uses Serde `deny_unknown_fields`; a manifest declares model, tools, MCP metadata, an allowlist, and evaluation fixtures. The loader also rejects a manifest name that differs from its directory.
- **Permission envelope:** `Sandbox` resolves paths under the repository root and checks separate `read_paths` / `write_paths` allowlists. macOS can additionally wrap file operations in Seatbelt; Linux currently remains `logical_only`. `net_hosts` is manifest data only, not an enforced network policy.
- **Runtime is still sample-specific:** despite the generic manifest, `execute_skill()` dispatches only `fix-ci`, `grep-ts`, and `doc-gen`; all other manifest-valid skills fail as unimplemented. The LLM makes a plan and reflection, but does not select or execute arbitrary declared tools.
- **Evaluation is structural rather than outcome-based:** `eval` copies allowlisted paths into a temporary directory, invokes the same built-in executor, then checks fixture existence, expected `eval.md` headings, declared-tool alignment, no writes for read-only skills, and that at least one action occurred. It does not independently validate a task-specific result.
- **Distribution:** the registry is a local SQLite index plus package/archive snapshots. It can publish/install locally and mirror GitHub Release metadata/assets; its remote-service document is explicitly future design, not implementation.
- **MCP shape:** `serve` exposes one skill at one HTTP endpoint. The caller can override the model name and attach arbitrary JSON context, which is embedded into the planner and reflector prompts.

## Evidence

- Read `registry/src/index.test.ts` before implementation code. Tests cover latest-version selection, local publish/install, and import of release assets; they do not cover package signing, dependency resolution, or a remote registry.
- Read `core/src/{skill,agent,eval,sandbox,mcp}.rs`, all sample manifests, and authoring/registry documents.
- Ran `cargo test -p skillforge-core` on 2026-08-06: **12 passed, 0 failed**. This validates the current core unit suite, not the claimed general-purpose skill runtime.
- `gh issue list -R HaddenHunter/SkillForge --state all --limit 20 ...` returned no issues at check time, so there was no external design critique to assess.

## Position in the ecosystem

SkillForge sits between the portable instruction convention described by [[agent-skill-standard-convergence]] and a real executable package system. It shares the "code as the executable skill body" direction of [[agentfactory]], but starts from a narrow, policy-constrained runtime instead of generating task-specific subagents. Its strict schema and package metadata also instantiate part of [[skill-compilation-pattern]].

## Key insight and trade-off

The counterintuitive result is that a detailed manifest does not yet make this a general skill runtime: the effective capability boundary is the hard-coded executor switch, not the `tools` field. That makes the MVP safer and more auditable than an arbitrary tool runner, but prevents third-party packages from becoming executable merely by passing validation.

For OpenClaw, the transferable idea is **separating three contracts** that are often conflated in `SKILL.md`: an instruction contract, a least-privilege capability contract, and an outcome/evaluation contract. OpenClaw already has rich instruction and tool-allowlist mechanisms; adopting a package registry would only be justified after a real need for versioned, independently testable executable skills emerges. A manifest-only layer would add ceremony without closing the execution or evaluation gaps.

## Watch

**Prediction (medium confidence):** without a generic executor plus stronger process/network isolation, SkillForge will remain an example-runtime or internal toolkit rather than a broadly installable agent-skill ecosystem by 2026-11-06. Check releases, supported executor count, and external package adoption then.

## 2026-08-20 Follow-up

- **108⭐** (+145% from 44 in 14d), 4 forks, 1 open issue (ghost "能不能解释一下？" — no substantive criticism).
- **Major pivot 08-09/10:** main branch converted to content-only repo; built skill tarballs + CLI binary now published to Pages at skillforge.c8.fit (registry UI live, tarballs downloadable). Added signing-chain documentation with fingerprint `SF:c0d444ccdf461a76`.
- Direction change: from hard-coded 3-sample executor → **distributable artifact pipeline**. Distribution problem solved; execution genericity still unverified — implementation moved off the main branch, so the earlier executor claim can't be re-verified from default branch.
- Key open items unchanged: generic executor dispatch + process/network isolation still not demonstrated externally.
- Revisit **2026-08-27** for generic-executor evidence + isolation + external package adoption (does anyone actually install from the registry?).
