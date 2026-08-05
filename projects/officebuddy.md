---
title: "OfficeBuddy — render-verified Office document agent"
source: "https://github.com/richardChenzhihui/OfficeBuddy"
stars: 50
studied: 2026-08-05
status: following
last_verified: 2026-08-05
---

# OfficeBuddy — Render-Verified Office Document Agent

## What it is

A macOS-only Python agent for editing `.docx` and `.xlsx` files. Its differentiator is **verification through the real Microsoft Word/Excel rendering pipeline**, rather than treating a successful `python-docx` or `openpyxl` write as proof that a human will see the intended result.

## Architecture observed in code

The central loop in `src/office_agent/agent/loop.py` is:

> plan → tool edit → render via Word/Excel → page diff against the last *verified* baseline → stateless multimodal verifier → targeted repair or pass.

Important controls:

- A verifier receives the screenshot plus step description rather than the executor's history, reducing self-confirmation bias. This mirrors the independent-auditor boundary in [[longhorizon-harness]], but applies it to rendered document appearance.
- The baseline only advances after a passed verdict. Failed renders cannot silently become the comparison baseline.
- `BudgetTracker` normalizes failure signatures: the second identical failure tells the model to change strategy; the third escalates to the user. `tests/loop/test_loop_offline.py` verifies both transitions.
- Writes occur in working copies with byte snapshots; overwrite needs an explicit interactive confirmation or `--yes`.
- Excel uses a ZIP-part inventory before save. The fidelity guard blocks output when `openpyxl` would lose unmodelled parts (for example threaded comments, slicers, or custom XML) unless the user explicitly accepts that loss. `tests/unit/test_excel_fidelity_guard.py` checks both the block and that the warned parts really disappear after a consented save.

## Why the renderer is the trust boundary

A byte-level test can validate OOXML structure but not Office's font fallback, pagination, or visual layout. The repository documents a concrete CJK fallback-font defect that left document XML apparently correct while Word's PDF output looked uneven. Rendering with the target application catches that class of failure; it is the same "outcome over claimed action" principle as [[longhorizon-harness]], adapted for visual artifacts.

The project does **not** rely solely on visual checks: pure data mutations such as formula edits and freeze panes are listed as non-visual because PDF output cannot establish their correctness. This is a useful anti-pattern guard: every verifier has a scope, and applying it outside that scope creates false failures.

## Ecosystem position and relation to us

OfficeBuddy is agent-first application tooling, alongside [[officecli]] and the broader [[agent-infrastructure-trend]] shift from generic agent frameworks to reliable execution surfaces. Unlike generic computer-use agents, it combines structured document adapters with a real-app render loop: structured operations retain controllability, while rendering validates the human-facing result.

For [[OpenClaw]] and [[FlowForge]], the portable insight is not the macOS/AppleScript implementation. It is the control-loop shape:

1. preserve the original artifact;
2. execute through the narrowest structured operation that fits;
3. verify at the consumer-facing surface;
4. carry only passed state forward;
5. make repeated failure change strategy or request a human decision.

That reinforces our existing verification discipline and provides a concrete pattern for artifact-producing skills (documents, slides, diagrams) where internal success is weaker evidence than rendered output.

## Boundaries / cautions

- The repo is alpha, macOS-only, and requires installed Microsoft Word/Excel plus MiniMax credentials. It is not directly portable to our Linux host.
- It declares no GitHub issues at the time of study, so there was no issue-history critique to validate the project’s claimed weak points.
- Its broad `except Exception` tool-result envelope preserves tool-call/result pairing, but can reduce error specificity; the system depends on later error normalization to recover useful escalation signals.
- The repository’s README candidly limits Excel round-tripping (existing charts/images), Word tracked changes/comments/footnotes, and certain formatting-sensitive find/replace cases. The fidelity guard is therefore a disclosure and consent mechanism, not a guarantee of lossless editing.
