---
title: "Fabraix Playground — Public CTF for Agent Tool-Authorization Failures"
repo: fabraix/playground
url: https://github.com/fabraix/playground
stars: 71
forks: 11
license: MIT
created: 2026-02-07
last_push: 2026-08-09
status: deep-read
last_verified: 2026-08-11
tags: [agent-security, red-teaming, tool-authorization, evaluation, ctf]
---

# Fabraix Playground — Public CTF for Agent Tool-Authorization Failures

## What it is

Fabraix Playground is a public, weekly CTF where players try to induce a live agent to make a protected tool call. The repository contains a React client and a read-only reference engine, while the live host, guardrail judge, secret store, and browser implementation remain private. Three public challenge definitions cover an access-code reveal, a biosafety archive release with an inert placeholder, and a credentialed identity-verification request sent off the partner allowlist.

The project converts prompt-injection evaluation from an offline benchmark into a socially visible adversarial loop: public system prompts and challenge configurations, real player attempts, manual break review, a leaderboard, and cash prizes. Its novelty is not the guardrail prompt; it is making the **unblocked action** the scoreable event.

## Source-backed architecture

1. **A guardrail seam sits before every declared tool call.** `PlaygroundAgent._handle_tool_call_generic` rejects unavailable tools, then calls `platform.guardrail.check_action(...)` before resolving and executing the handler. The engine depends on injected `Store`, `GuardrailJudge`, `Llm`, `Browser`, `Notifier`, and `Settings` protocols rather than a specific host. This is a concrete [[capability-architecture]] pattern: the model may propose an action, but a separate enabled policy layer controls whether the action executes.
2. **Secrets are injected at execution, not exposed in model context.** For a challenge sink tool, the engine copies model arguments and adds the secret only to execution arguments. The reported/judged arguments omit it. `evaluate_win` therefore never scans model text: a reveal challenge wins on an explicitly unblocked sink call; the exfiltration challenge wins only for an unblocked request to a normalized, non-allowlisted hostname.
3. **The scoring oracle is data-driven.** A discriminated `WinSpec` union separates `reveal_secret` from `exfil_via_request`; `win.py` dispatches by spec type, not challenge slug. Host normalization percent-decodes before URL parsing and strips trailing dots, closing simple partner-host spelling bypasses.
4. **The reference boundary matters.** The README calls the engine a faithful illustration, but it cannot establish how the private live guardrail judges actions, whether browser isolation holds, or whether the hosted API uses the same revision. The repository has no test/spec files and no test script; architecture claims are source-inspected, not independently executed.

## Critical evidence from issues and source

Two open July issues expose why action-level evaluation must also preserve trustworthy status:

- **Issue #3 is source-confirmed.** Both `chat()` and `chat_stream()` initialize `safe = True`; their unblocked-tool branches update only `reason`, not `safe`. A successful unblocked protected call can therefore produce `success: true` and `safe: true`. The enforcement decision may still be correctly represented in `tool_calls`, but the summary field is contradictory and unsafe for downstream monitoring.
- **Issue #5 identifies a real state-risk but overstates its demonstrated cause.** The callback closes over `hasWon`, yet `hasWon || wonNow` includes `wonNow = !!result.success`, so the visible source should persist `true` on the first success. The stale dependency is still needless fragility, but the stated false-write outcome does not follow from this exact expression without evidence from a different live-client path.

The most valuable unimplemented direction is issue #1/#2: an integrity challenge that attacks a typed `report_status` action after a browser task. It would test false completion claims rather than only confidentiality/exfiltration. The proposed defense is positive completion evidence rather than absence of errors—directly aligned with [[structural-backpressure]] and our own completion gates.

## Ecosystem position

Unlike [[agent-harness-landscape]] projects that coordinate productive work, Fabraix is an adversarial evaluation environment for the tool boundary those harnesses depend on. It complements [[cmcp-confidential-mcp-runtime|cMCP]]-style authorization and receipt systems: Playground measures whether a defender can be induced to cross a declared boundary, while a production gateway can enforce and attest the boundary. It also demonstrates a limitation of purely conversational safety: public prompts are useful for test transparency, but the meaningful safety property is whether a sink action is structurally blocked.

## Relevance to us

The transferable design is narrow and practical:

> Treat externally consequential tool calls and completion assertions as separate, typed, independently evaluated events; record the exact policy decision and make downstream status derive from it rather than from a model-generated summary.

For [[FlowForge]] and agent orchestration, this argues for preserving transition/evidence authority outside adaptive workers, as in [[mechanism-vs-evolution]]. A workflow should not only gate an action; its terminal report must be mechanically consistent with the gate result. Fabraix's `safe`-flag mismatch is the counterexample: a correct local policy seam does not help if the system publishes contradictory verdict state.

## Follow-up

- Revisit **2026-08-25** for resolution of issues #3/#5, an integrity-status challenge, tests/CI, or public evidence that the reference engine and hosted behavior stay aligned.
