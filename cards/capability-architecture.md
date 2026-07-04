---
title: Capability Architecture
created: 2026-07-04
tags: [capability, agent-architecture, lifecycle, napaxi]
last_verified: 2026-07-04
---

# Capability Architecture

The pattern of managing agent capabilities through lifecycle states rather than static feature flags. Everything an agent can do — call a model, use a tool, enforce a policy — is modeled as a capability with a defined lifecycle.

## Three-State Model (Napaxi)

Napaxi (Ant Group) provides the clearest implementation:

| State | Meaning |
|-------|---------|
| **Registered** | SDK binary contains the capability definition. It exists in code. |
| **Available** | Current platform + host can satisfy the capability's requirements. |
| **Enabled** | Runtime selection and configuration allow the capability to execute. |

A capability must pass through all three gates before it runs. This prevents silent failures from missing platform support or disabled-but-present features.

## Capability Kinds

`llm_provider`, `tool`, `platform_tool`, `mcp`, `policy`, `service`, `agent_engine` — all tools, providers, and policies are capability-backed. The host declares a capability profile; the core runtime decides status and routes execution accordingly.

## Policy Chain

Policy capabilities run before any I/O capability executes. This makes guardrails structural rather than advisory — a policy capability in the Enabled state gates all downstream tool and provider capabilities.

## Links

[[agent-harness-landscape]], [[mobile-agent]]
