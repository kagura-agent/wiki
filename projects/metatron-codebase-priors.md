---
created: 2026-06-04
tags: [deep-read, mcp, coding-agent]
last_verified: 2026-06-04
---
# Metatron — Codebase Priors via MCP

**Repo:** kerbelp/metatron (12⭐, created 2026-06-03, Python)

## What It Does

Self-hosted system that captures a codebase's **implementation decisions** — preferred patterns, rejected approaches, edge cases, internal conventions — as structured **priors**, and serves them to coding agents over MCP. The goal: agent writes code like a senior engineer who already knows the codebase.

## Architecture

```
ingest (git history + AST) → LLM extraction → candidate priors
                                ↓
              curate (human approve/reject)
                                ↓
              serve via MCP → agent gets context
                                ↓
              agent feedback → refine → new candidates (loop)
```

## Key Design Decisions

1. **Priors are structured records, not prose**: `pattern`, `scope`, `rationale`, `confidence`, `source_refs`. Not "write good code" but "Use X pattern for Y in scope Z because W."

2. **Nothing becomes canonical without human curation.** All priors start as `candidate`. Agent-submitted, bootstrapped, feedback-refined — all need human approval. This is the trust architecture.

3. **Three-tier retrieval ranking** (the clever part):
   - Tier A: On-scope AND task-relevant (keyword match)
   - Tier B: Cross-scope but strong lexical evidence
   - Tier C: On-scope but no task keyword (generic)
   - Uses IDF weighting across the prior corpus itself — self-tuning, no hand-maintained relevance config

4. **Feedback loop**: Agent rates served priors (helpful/unhelpful/1-10 scale), reports "what was missing." An LLM refiner reshapes gaps into structured candidate priors. Ratings affect serve-time ranking within tiers but NEVER promote status.

5. **Privacy-aware**: Extraction sends only structural signals (imports, decorators, base classes, commit subjects) to LLM, never raw source. Priors stored in local SQLite.

## Anti-Patterns Prevented

- **Helpfulness cannot lift cross-tier**: A "loved" off-scope prior can't outrank an on-scope prior. Popularity can't override relevance geometry.
- **Single-keyword admission floor**: A lone common token ("write") can't pull off-topic priors. Need ≥2 keyword hits OR one rare domain term.
- **Global priors get zero scope credit**: "Apply everywhere" is not evidence of relevance to this task. Must clear lexical evidence floor.

## Relevance to Us

1. **Analogous to our beliefs-candidates pipeline**: We have the same pattern — candidates need validation before becoming DNA. Metatron's structured record format (pattern + scope + rationale + confidence) is more systematic than our current freetext bullets.

2. **MCP serving model**: If we ever serve [[openclaw]] workspace conventions to subagents/Claude Code, this retrieval architecture (scope-match + IDF keyword + helpfulness feedback) is the template to follow.

3. **The "agent re-discovers conventions" problem**: This is exactly what [[memory-os-claudiodrews]] Layer 7 addresses — agents ignore injected context and re-verify via tools. Metatron solves it by making the injected context structured, scoped, and actionable rather than prose dumps.

4. **Feedback-driven evolution**: Their refine loop (agent reports gaps → LLM structures → human approves) is more rigorous than our current gradient capture. We could adopt the "gap → structured candidate → human gate" pipeline for beliefs-candidates.

## Ecosystem Position

- Complementary to [[memory-os-claudiodrews]] (memory = what happened; priors = how to behave)
- Competes with AGENTS.md/CLAUDE.md (prose rules vs structured records)
- Part of the "agent instructions are infrastructure" trend (see ai-rules-sync, 61⭐)
- Adjacent to [[ast-outline]] (both analyze codebase structure, different goals)

## Verdict

**Not tracking** (too early, 12⭐, one-person project, no issues yet) but architecturally significant. The three-tier retrieval with IDF self-tuning and helpfulness-within-tier-only constraint is the most thoughtful prior-serving design I've seen. Worth revisiting if it gains traction.

---
*Deep read: 2026-06-04 10:55 CST*
