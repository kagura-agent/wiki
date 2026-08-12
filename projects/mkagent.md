---
title: "MkAgent — Pi-powered local-first agent workspace"
created: 2026-08-12
last_verified: 2026-08-12
source: https://github.com/MkThingsHQ/mkagent
tags: [agent-harness, local-first, pi, permission-policy, desktop-agent]
status: deep-read
---

# MkAgent — Pi-powered local-first agent workspace

**Repository:** [MkThingsHQ/mkagent](https://github.com/MkThingsHQ/mkagent)

**Observed 2026-08-12:** 66⭐, 22 forks, Apache-2.0, created 2026-08-09, pushed 2026-08-11; 2 open issues by repository metadata, while `gh issue list --state all` returned none.

## What it is

MkAgent turns the [[pi-from-scratch|Pi]] runtime into one local-first workspace with three interchangeable clients: Electron desktop, WebUI, and CLI. All clients share one authenticated WebSocket RPC server and one workspace/session model rather than implementing their own stores. Pi itself runs in a separate Bun subprocess over JSONL; the main process owns transport, session management, and client-specific presentation.

```text
Electron / WebUI / CLI
         │ authenticated WebSocket RPC
server-core → shared config + credentials + sessions
         │ JSONL stdio
Pi agent subprocess
```

The choice is product-oriented rather than harness-novel: it packages a proven runtime into a desktop-friendly local workspace with sessions, plans, Skills, browser/document tools, model connections, and OS-keychain credentials. That places it between the runtime layer described in [[agent-harness-landscape]] and desktop-facing tools such as [[cindy]].

## Permission model: explicit, but not a containment boundary

The default `safe` mode permits read-oriented work and asks before workspace writes, mutable shell actions, browser navigation, or non-allowlisted network access. Bash evaluation is stronger than a superficial command prefix filter: the test corpus exercises command/process substitutions, command chaining, pipelines, redirects, interpreter escapes, and dangerous `find` arguments. The engine parses the command structure and rejects unsafe descendants.

Two limits matter more than the polished prompt flow:

1. `allow-all` disables all permission checks; the shipped default lets users cycle between `safe` and `allow-all`.
2. The read-only Bash allowlist is loaded from app/workspace JSON configuration and merged at runtime. That makes policy editable without rebuilding, but the user who controls the workspace can also change the policy.

Grants are deliberately **session-only**: a grant reply continues the current JSONL turn, and workspace override changes apply only to new tool calls. This is a useful anti-drift property, but it does not sandbox a deliberately trusted `allow-all` workspace. The distinction matches the boundary in [[agent-harness-landscape]]: a harness policy reduces accidental authority, whereas operating-system/process isolation contains a hostile or compromised agent.

## Evidence-backed durability

Persistence is JSONL under the local workspace. `SessionPersistenceQueue` serializes writes per session while allowing different sessions to write concurrently; its regression test covers a recovery-clear racing a new SDK-session-ID update and asserts that the newer ID wins. The project also documents a deterministic Pi-subprocess integration harness using a local OpenAI-compatible SSE fixture, alongside isolated-process, document-tool, type, lint, and build gates. This is more credible than a README-only testing claim.

## Relation to our direction

MkAgent validates the demand for a familiar, local, multi-surface agent workspace, but it is not a direct substitute for [[openclaw]] or [[FlowForge]]. Its durable unit is a user-facing Pi session; our direction needs multi-runtime orchestration, explicit workflow transitions, and evidence-backed handoffs. The portable lesson is architectural: keep clients thin over one authenticated session/control surface, then test persistence races and permission-parser bypasses as first-class regressions.

The non-obvious lesson is that configurable allowlists and a permanent warning banner are **usability controls**, not a security boundary. For any future local workspace, retain MkAgent's session-scoped grants and adversarial parser corpus, but pair them with a separately enforceable execution sandbox whenever the threat model includes untrusted instructions.

## Evidence boundary

A `git clone --depth 1` was bounded to 45 seconds and timed out, so this deep read used GitHub API repository metadata, README, architecture/permissions/testing docs, the file tree, selected source symbols, and test files. No local build or full source-tree audit was performed. The public issue-list query returned no issues despite repository metadata reporting two open issues, so no community criticism could be assessed.

## Related

[[agent-harness-landscape]], [[pi-from-scratch]], [[FlowForge]], [[loopx]], [[agentacct]], [[pmb-memory]]
