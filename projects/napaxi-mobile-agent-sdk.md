---
title: Napaxi — Mobile-Native Agent SDK (Ant Group)
status: deep-read
discovered: 2026-07-04
source: https://github.com/antgroup/Napaxi
stars: 24
language: Rust
license: GPL-3.0
author: Ant Group (antgroup)
tags: [mobile-agent, on-device, sdk, rust, flutter, ant-group]
last_verified: 2026-07-04
---
# Napaxi — Mobile-Native Agent SDK

> Pure on-device agent runtime for embedding agent experiences in mobile apps. From Ant Group.

## What It Is
Mobile-native SDK for embedding agent experiences in apps. Rust core runtime + thin SDK adapters (Flutter first, Android/iOS SDK adapters alongside). Host apps keep UI/accounts/model config/permissions/policy ownership. Napaxi owns: sessions, workspace state, storage, tools, skills, MCP, platform hooks, background execution, adapter contracts.

**Key differentiator**: Agent runtime runs ON the phone. Apart from app-approved model calls, no cloud server needed. Workspace data, session state, files, tool metadata, agent execution all on-device.

## Architecture

```
Mobile App → SDK adapter (Flutter/Android/iOS) → Napaxi Core API → Runtime core → Feature crates
```

### Crate Structure
- `crates/core/`: Runtime kernel — API, engine handles, session/workspace/file policy, storage, tool registry+loop, events, platform hooks
- `crates/features/skills/`: Skill manifests, SKILL.md parsing, validation, registry, catalog
- `crates/features/evolution/`: Memory/skill review, pending actions, rollback, counters, evolution policy
- `vendor/libsql-patched/`: SQLite for mobile

### Capability Architecture (Most Novel)
Three-state lifecycle: **Registered** → **Available** → **Enabled**
- Registered: SDK binary contains definition
- Available: Current platform + host can satisfy it
- Enabled: Runtime selection/config allows participation

Capability kinds: `llm_provider`, `tool`, `platform_tool`, `mcp`, `policy`, `service`, `agent_engine`

All tools, providers, policies are capability-backed. Host declares what it can carry via capability profile. Core decides status + routes execution.

### A2A (Agent-to-Agent) — xAgent
- Local pairing + deep-link peers
- Task intake + isolated execution
- Tools: `a2a_list_agents`, `a2a_start_collaboration`, `a2a_send_message`, `a2a_wait_messages`, `a2a_finish_collaboration`
- Trust levels, signing, encrypted store

### xApp / xChannel Connectivity
- **xApp**: Cross-app interaction (one agent triggers actions in another app)
- **xChannel**: Connects IM tools, Bluetooth headsets, vehicle systems, drones, other device surfaces
- Agent App Actions: Specialized tool capability, persisted proposals, host-controlled confirmation/risk/execution

### Policy Chain
- Descriptor admission, invocation admission, provider admission, agent-engine admission, service admission
- All through core policy chain — runs before any I/O
- Host can deny entire service categories

### Built-in Evolution System
- Memory/skill review with pending actions
- Rollback + counters
- Evolution policy built into SDK (not bolted on)

## Use Cases Demonstrated
1. **Pure Mobile Development**: Generate/update Android app code on phone, build APK, install — all on-device
2. **File Tools**: Image compression via sandboxed tool pipeline
3. **Smart Home**: Agent controls devices through host-approved provider app

## Why This Matters
- **First serious mobile-native agent SDK from a major company** (Ant Group = Alipay parent)
- Capability architecture is the most sophisticated I've seen for agent tool/provider management
- Evolution system built-in from day 1 suggests Ant Group is thinking about long-lived agents
- A2A protocol for on-device multi-agent is novel (most A2A is cloud-to-cloud)
- GPL-3.0 license limits commercial adoption but signals "infrastructure" intent

## Gaps / Questions
- 0 GitHub issues (just launched)
- GPL-3.0 might limit ecosystem adoption vs MIT/Apache competitors
- 24⭐ — very early. But Ant Group backing = likely to grow
- No English-first community (docs bilingual but team is Chinese)

## Tracking
- Watch for: community adoption, Flutter adapter maturity, first external contributors
- Revisit: 07-11

[[agent-harness-landscape]], [[mobile-agent]], [[capability-architecture]]
