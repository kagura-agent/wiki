---
title: Mobile Agent
created: 2026-07-04
tags: [mobile, agent, on-device, landscape]
last_verified: 2026-08-12
---

# Mobile Agent

Agents running on mobile devices. The space splits along a key architectural distinction: on-device runtime vs. cloud-hosted agents accessed from a mobile client.

## On-Device Runtime

The agent SDK runs natively on the phone. No cloud server needed beyond model API calls. [[napaxi-mobile-agent-sdk|Napaxi]] (Ant Group) is the first serious mobile-native agent SDK, using a capability architecture to manage what the device can actually support at runtime (see [[capability-architecture]]).

Challenges are substantial:
- **Resource constraints** — limited memory, CPU, and battery for agent loops
- **Permission models** — mobile OSes restrict background access, inter-app communication, and filesystem reach
- **Background execution** — long-running agent tasks conflict with OS process management
- **Cross-app interaction** — orchestrating actions across apps requires accessibility APIs or platform-specific bridges

## Cloud Box + Mobile Access

The alternative pattern: run the agent in a cloud VM, access from the phone. [[pocketdev]] takes this approach — cloud box + Tailscale mesh + phone SSH client. The agent runs with full resources; the phone is a thin terminal.

## Mirrored-device transport

A third pattern treats the phone as a remote-controlled surface rather than the agent’s runtime or client. [[phone-harness]] drives an iPhone through macOS iPhone Mirroring using screenshots/OCR and HID input; its boundary is the Mac host plus a human reconnection handoff.

## Links

[[agent-harness-landscape]], [[capability-architecture]], [[remote-development]], [[napaxi-mobile-agent-sdk]], [[pocketdev]], [[phone-harness]]
