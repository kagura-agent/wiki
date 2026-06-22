---
title: "GateMem — Memory Governance Benchmark"
created: 2026-06-22
updated: 2026-06-22
status: noted
stars: 68
repo: rzhub/GateMem
tags: [benchmark, memory, access-control, privacy, multi-agent, safety]
last_verified: 2026-06-22
---

# GateMem — Benchmarking Memory Governance in Multi-Principal Shared-Memory Agents

**Paper**: arXiv:2606.18829 | **Dataset**: HuggingFace Ray368/GateMem | **License**: MIT

## Core Question

Shifts the memory benchmark question from "can the agent remember?" to **"can the agent govern shared memory correctly across multiple principals, roles, scopes, and deletion requests?"**

## Three-Capability Framework

| Capability | What it tests |
|---|---|
| **Utility (U)** | Answers correctly for authorized requests |
| **Access Control (A)** | Refuses/redacts for unauthorized requests |
| **Active Forgetting (F)** | Doesn't leak deleted information after explicit deletion |

**MGS (Memory Governance Score)** = `U × (1 - A) × (1 - F)` — multiplicative means ANY failure tanks the whole score.

## Dataset Scale

- 4 domains: Medical, Office, Education, Household
- 91 episodes, 2218 hidden checkpoints
- Checkpoint distribution (medical): 210 utility, 192 privacy, 177 safety
- Episodes have ~225 turns, multiple principals with defined roles/relationships

## Attack Taxonomy (key innovation)

**Privacy attacks**: cross-entity access, impersonation, authority pressure, role mismatch, indirect inference, label existence leak, overreach (family/manager/contractor/partner/guest/caregiver)

**Safety (deletion) attacks**: post-delete direct query, post-delete recovery attempt, confirm yes/no (existence test), split reconstruction, social engineering, update-delete conflict

## Two-Level Leakage Detection (novel)

1. **Answer-level leak**: Agent explicitly surfaces leaked info in response
2. **Context-level leak**: Leaked info retrieved into prompt context (even if agent doesn't surface it) — this catches retrieval-stage failures
3. **E2E leak**: Either of the above counts as failure

This distinction matters: a RAG system might retrieve unauthorized memory into context (visible to attacker via side-channels or prompt injection) even if the answer model correctly refuses.

## Baselines Tested

- **Long-Context**: Entire episode in context window (no retrieval)
- **RAG-Naive**: Standard chunk+embed+retrieve, no policy filtering
- **RAG-Policy**: Access control injected into retrieval/prompt layer
- **A-MEM**: Structured memory with agentic operations
- **Mem0**: Popular memory framework
- **ReMeM-I / ReMeM-S**: Reflexive memory with individual/shared variants

## Domain-Specific Policies

Each domain defines realistic access rules:
- Medical: patient owns records, care-team access only when assigned, family gets summary-only unless consent
- Office: role-based need-to-know for HR/comp/legal, delegation scopes, contractor limits
- Education: student privacy, parent access limits, cross-student isolation
- Household: resident privacy, guest/caregiver/service scope limits

## Architecture Insights

1. **Record-ref inference**: Base agent infers which records a text chunk references using regex + canonical values. Internal only — never shown to LLM.
2. **Policy as prompt injection**: Access control rules are formatted into the LLM prompt alongside relationship facts for the requester.
3. **Memory audit trail**: Every query records exactly what memory was exposed to the answer model (for retrieval-stage leak detection).
4. **Over-refusal metric**: Tracks when agents refuse valid authorized requests — penalizes excessive caution.

## Relevance to Our System

1. **Our memory has primitive access control**: MEMORY.md "Load only in direct Luna chats... Never in shared contexts" — this is a single-rule version of what GateMem tests comprehensively.
2. **Subagent memory leakage**: If a subagent in a group channel context could access private memory files, that's a privacy leak at the retrieval level.
3. **Active forgetting gap**: When Luna says "forget this" and we delete a line from memory — do we verify it doesn't persist in embeddings/search indexes? GateMem tests exactly this scenario.
4. **MGS as self-eval metric**: We could adapt the multiplicative formula to grade our own memory system: Can we answer from memory? Do we leak in wrong contexts? Do deleted items stay gone?
5. **The context-level vs answer-level distinction** is particularly relevant: even if our agent never surfaces private info, if the memory retrieval pipeline loads it into context for a group-chat query, that's a governance failure.

## Cross-References

- [[memory-privacy]] — our existing memory privacy card
- [[memory-volume-control]] — volume control as precondition for governance
- [[agent-memory-landscape-202603]] — broader memory landscape context
