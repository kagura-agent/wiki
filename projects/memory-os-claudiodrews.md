# Memory OS (ClaudioDrews) — 7-Layer Memory Infrastructure for Hermes

- **Repo**: ClaudioDrews/memory-os
- **Stars**: 173⭐ (2026-06-02, 2 days old — explosive growth)
- **Stack**: Python + Docker (Qdrant + Redis + ARQ Worker) + Hermes Agent
- **License**: MIT

## What It Is

A complete memory operating system for Hermes Agent — 7 layers from flat files to vector DB, with surgical context injection and a self-curating wiki pipeline.

## Architecture: 7 Layers

1. **Workspace** — MEMORY.md, USER.md, CREATIVE.md (injected every turn)
2. **Sessions** — SQLite + FTS5 full-text search across conversation history
3. **Structured Facts** — SQLite with entity resolution + trust scoring + automatic feedback loop
4. **Fabric (Cross-session)** — Heavily forked Icarus plugin, 16 tools, LLM-powered extraction
5. **Vector DB** — Qdrant (4096d cosine + BM25 sparse), 4-level fallback, weekly decay scanner, semantic dedup (cosine >0.92 → merge)
6. **LLM Wiki** — Auto-curated vault (concepts/entities/comparisons), continuously ingested into Qdrant
7. **Ground Truth Hierarchy** — SOUL.md + rulebook.md that tells the agent injected memory is authoritative

## Key Insight: Layer 7 (Ground Truth Hierarchy)

**The most important layer.** Without it, memory injection is useless.

Problem: Memory OS successfully injected context (`[qdrant]`, `[fabric]`, `[sessions]`, `[facts]` blocks in prompt), but the agent **ignored them** — running search tools to rediscover information already in the prompt.

Root cause: The agent's identity documents had a 3-level source hierarchy (terminal > docs > training) but **injected memory was not listed**. No rank = no authority = treated as optional suggestion.

Fix: Expanded to 4-level hierarchy:
```
1. Terminal output → Ground Truth for system state
2. Injected memory → Ground Truth for documented knowledge
3. Official docs → Authoritative for APIs/configs
4. Training knowledge → Reference only
```

Key instruction: *"When injected memory contradicts your assumptions, injected memory wins. Never treat a question as novel when the answer is already in your prompt."*

## Relevance to Us

**We partially have this.** Our AGENTS.md says "Read files. Update them. They're how you persist." but doesn't explicitly rank injected context in a trust hierarchy. Our `memory_search` results and wiki content are used but not explicitly elevated above model training knowledge.

**Do we need a formal Layer 7?** Probably not yet — our context is manually curated (MEMORY.md, wiki, AGENTS.md) and small enough that the model naturally trusts it. But as context grows (more wiki, more memory), the re-verification waste memory-os describes could emerge. Worth monitoring.

**Transfer value**: The conflict resolution table (terminal vs memory vs docs vs training) is a clean mental model. If we ever see symptoms of "agent re-verifying its own context," this is the fix.

## Comparison with Other Memory Projects

| Project | Approach | Our Relevance |
|---|---|---|
| memory-os | 7-layer + ground truth hierarchy | Layer 7 insight is novel |
| [[ai-memory]] | Cross-agent handoff, 4-tier, git-backed | Cross-agent focus |
| [[hermes-memory-system]] | Plugin-based, selective recall | Similar to memory-os L4 |
| [[quarq-agent-oss]] | Evidence-gated, benchmark-first | Quality gate focus |
| Our approach | Manual-first (MEMORY.md + wiki + beliefs) | Control over automation |

## Technical Notes

- Uses DeepSeek v4 Flash for extraction (cheap LLM for memory processing)
- Docker-based infra: Qdrant + Redis + Python worker
- Weekly decay scanner archives low-importance aged content
- Semantic dedup at cosine >0.92 threshold
- No tests/issues yet (2 days old), solo developer project
- Icarus plugin is a heavily forked version of an existing Hermes memory plugin

## Risk Assessment

- Solo developer, 2 days old — too early for community health assessment
- Heavy infrastructure (Docker, Qdrant, Redis) for what could be simpler
- 173⭐ in 2 days suggests viral README/concept more than proven solution
- No test coverage visible

**Verdict**: Architecturally interesting for the Layer 7 insight. Not a project to track (too early, solo), but the ground truth hierarchy concept has direct transfer value.

---
*Deep read: 2026-06-02 13:50 CST*
