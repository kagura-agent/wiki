---
title: "Quarq Agent OSS"
created: 2026-05-29
updated: 2026-05-29
status: scout
last_verified: 2026-05-29
---

# Quarq Agent OSS

**Repo**: [quarqlabs/agent-oss](https://github.com/quarqlabs/agent-oss) | 171⭐ (2026-05-29, created 05-24) | Python | MIT
**Status**: 🔭 Scout. 5 days old, 171⭐, 14 forks. Solo project.

## Core Idea

Memory-first personal AI agent using LangGraph orchestration + FAISS vector storage. Positions itself as "open alternative to [[Hermes]] or [[OpenClaw]]" — interesting that they name us as competition.

Claims 99.6% recall on LongMemEval-S (256/257 correct at checkpoint, full 500-question run in progress).

## Architecture

- **LangGraph** state graph (StateGraph → START → END)
- **FAISS** local vector memory with OpenAI embeddings
- **Three memory types**: semantic, episodic, procedural (separated)
- **HyDE-style query expansion** for retrieval
- **Hybrid retrieval**: vector + keyword
- **Temporal guardrails**: distinguishes storage time vs event time
- **Numeric attribution**: scope checks to prevent cross-entity number confusion
- **Self-correcting fallback**: re-searches when evidence is incomplete
- **Background memory consolidation**
- **Tool system**: calendar (gcal), email (gmail), PDF generator, identity manager — each with its own SKILL.md

## Assessment

Standard RAG pipeline with thoughtful refinements rather than architectural innovation. The four failure modes they attack (wrong memory, wrong entity, wrong time, wrong numbers) are real and well-articulated, but the solutions are incremental (guardrails, checks) not paradigmatic.

Single-file architecture (agent.py ~1200+ lines) is readable but monolithic. LangGraph adds structure but also complexity.

**Not tracking** — architecture too familiar, solo project, and the claimed benchmark results need independent verification. Note the competitive positioning against us though.

## Connection to Our Work

- We're named as a direct competitor — worth monitoring how they frame the comparison
- Their memory type separation (semantic/episodic/procedural) mirrors what [[TencentDB-Agent-Memory]] does at larger scale
- The temporal guardrails are a real concern we should think about — [[memex]] doesn't currently distinguish storage time from event time

---
*First read: 2026-05-29*
