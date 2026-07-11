---
title: Agent Bridge Pattern
created: 2026-07-11
tags: [pattern, architecture, agent, real-time]
last_verified: 2026-07-11
---

# Agent Bridge Pattern

An architectural pattern that separates a **thin real-time interface** (voice, video, IoT, AR) from **full-capability agent reasoning** via a bridge call.

## Separation of Concerns

| Layer | Role | Tools |
|-------|------|-------|
| Real-time persona | UX, latency-sensitive interaction | Minimal (DTMF, hangup, display control) |
| Bridge call | Scoped subagent turn with context | `ask_assistant` or equivalent |
| Full agent | Complex reasoning, retrieval, actions | Complete toolset |

The real-time layer owns the modality (speaking, rendering) but never does heavy reasoning itself.

## How It Works

1. User asks something that requires complex reasoning or tool use.
2. Real-time persona acknowledges ("one moment, let me check") to maintain conversational flow.
3. Persona invokes the bridge — a scoped request to the full agent with relevant context.
4. Full agent reasons, uses tools, and returns a structured answer.
5. Persona renders the answer in the appropriate modality (speaks it, displays it, etc.).

## Why It Matters

- **Latency management** — the persona keeps the interaction alive while the agent works.
- **Security boundary** — the real-time layer has minimal permissions; the full agent operates in a controlled scope (see [[agent-security]]).
- **Modality independence** — the same bridge pattern works for phone calls, AR overlays, IoT voice, video assistants.
- **Simpler real-time models** — the interface model can be smaller/faster since it only handles UX, not reasoning.

## Examples

- **Voice calls**: A phone agent uses `ask_assistant` to query a full-toolset agent for account lookups, then speaks the result. See [[openclaw-voice-call-realtime]].
- **AR/heads-up displays**: A lightweight vision model bridges to a planning agent for complex spatial reasoning.
- **IoT**: A device-local model handles wake-word and basic commands, bridges to a cloud agent for multi-step tasks.

## Related

- [[agent-autonomy-models]] — how much the real-time layer can act without bridging
- [[agent-context-portability-approaches]] — passing context across the bridge boundary
