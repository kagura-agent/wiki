---
title: "Sprocket — Durable cloud-local hardware/software agent platform"
created: 2026-08-06
last_verified: 2026-08-09
tags: [deep-dive, agent-harness, hardware, durable-runs, local-execution, payments]
tracking: scout
stars: 16
---

# Sprocket (spikonado/sprocket)

**Repo**: [spikonado/sprocket](https://github.com/spikonado/sprocket) | **16⭐** | Rust + Svelte + Convex | hardware-and-software development agent

## What it is

Sprocket is a desktop/browser agent platform for software projects and hardware workflows: it can work with a local workspace, create schematics/BOMs, and use a UCP shopping skill for parts procurement. Its important technical claim is not the hardware branding but a split execution model: durable cloud coordination while files, shell commands, and active tool processes remain local.

## Architecture verified in code and tests

The runtime has three planes:

- **Cloud coordination**: Convex owns users, threads, messages, durable run state, tool-job records, and model calls.
- **Local execution**: a Rust server holds workspace attachment mappings, pairing/session credentials, subprocesses, cancellation tokens, and run capabilities; it is loopback-bound by default.
- **Client**: one Svelte interface runs in browser, Vite development, and Electron modes.

A submitted run has an idempotency key and is bound to a random run-scoped executor capability. The executor can resume after the browser identity disappears, but cannot start with the wrong capability. Tests also show renewable claim leases block a competing executor until expiry, and completion attempt sequence numbers stop delayed model streams from replacing newer output. This is a concrete, code-tested form of [[durable-agent-runs]] rather than a UI-only “resume” promise.

Browser work has the same continuity shape: a Browserbase session is stored per thread and reused by a later run, while the live-view URL is best-effort rather than a precondition for recording the session.

## The useful design boundary

Sprocket’s separation is stricter than a normal cloud coding agent: Convex never owns a machine path, and the browser does not retain a general-purpose local authority. It has to pair with the local server, then delegates only a run-scoped capability. That makes it relevant to [[FlowForge]] and [[loopx|LoopX]]: durable orchestration should persist *coordination evidence*, but capability to execute on a host should stay local and narrow.

The project explicitly acknowledges that workspace patches and commands are **not sandboxed**: they run as the local Sprocket OS user. That is a meaningful honesty boundary, not a solved containment story.

## Purchases are a separate authority plane

The README’s “buys anything” claim is backed by a UCP shopping skill and a Prava payment integration, not a generic browser checkout shortcut. The skill requires the user to confirm exact items, variants, quantities, and prices before checkout. A payment mandate is then created in a separate new-tab/passkey approval flow, and the payments backend rejects ambiguous or mismatched merchant/amount approvals before charging.

This is the most transferable pattern from Sprocket: a conversational confirmation should not itself be a payment credential. The system makes the spend authorization a durable, bounded, externally mediated object. It contrasts with broad browser-agent authority, and sharpens the external-action gate in [[agent-security]].

## Evidence and limitations

- Read `ARCHITECTURE.md`, `README.md`, `agentRuntime.createRun.test.ts`, `runLease.test.ts`, and `browserAgent.test.ts` on 2026-08-06.
- The visible issue tracker had only Renovate’s dependency dashboard; there was no user bug report or architecture critique to test the project’s assumptions against.
- The project is young (16⭐ at inspection), so its strong test coverage validates intended protocol behavior, not long-term operational reliability.
- The `ucp-shopping` skill allows a browser fallback after UCP failures. The codebase has a separate mandate gate, but this branch deserves future end-to-end review to ensure browser fallback cannot bypass the bounded payment authorization.

## Ecosystem position and relevance

Sprocket sits between local-first coding harnesses and commerce-capable computer-use agents. It is complementary to [[super-simple-software-factory]]: both make controls executable rather than prompt-only, but Sprocket puts durable distributed run ownership and host-local authority at the center. For Kagura, the direct adoption value is low (Sprocket is a full end-user platform), while the architectural value is high: [[durable-state-local-capability-spend-authority|durable state, local capability, and spend authority]] should be three different objects with three different lifetimes.

## References

- Repository source and tests inspected: 2026-08-06
- HN discovery: “Show HN: Sprocket – The Best AI Agent for Hardware and Software Development” (2026-08-06 scan)
- Related: [[FlowForge]], [[loopx|LoopX]], [[durable-agent-runs]], [[agent-security]], [[super-simple-software-factory]]
