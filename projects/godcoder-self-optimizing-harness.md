# Godcoder — Self-Optimizing Agent Harness

> eli-labz/Godcoder | 245⭐ (06-27→06-29, 2 days) | Rust + Tauri 2 | MIT | Solo dev

## What It Is

Local-first desktop coding agent (Rust core, Tauri 2 React app) with a novel **Harness mode**: the agent autonomously builds, improves, and optimizes its own agent harness in real time.

## Key Architectural Pattern: Route-Log-Recall-Optimize

The self-optimizing loop is backed by a Python bridge (`godcoder_harness.py`) over a local SQLite memory store:

1. **`route`** — Before task: classify instruction + pull most relevant past lessons (top-K from memory)
2. **`recall`** — Fetch recent lessons/patterns for context injection
3. **`log`** — After task: record outcome (success/failure/partial) + one-line summary with stable tag
4. **`optimize`** — Periodically: aggregate outcomes per tag, rank by success rate → bias future runs

```
success_rate = (successes + 0.5 * partials) / total
ranked by: (success_rate DESC, sample_count DESC)
```

## Novel Insights

- **One decisive, verifiable change per iteration** — keep if improvement, discard otherwise. Clean binary selection signal.
- **Consistent tag taxonomy** — same tag for same kind of work enables quantitative approach ranking.
- **Sandboxed self-improvement** — `harness-build/` workspace. Agent reads rest of repo for reference but confines all new code there.
- **No weight training** — this is purely control-surface optimization (which approaches to prefer), not model fine-tuning.
- **CoWork mode** — GUI/OS automation that executes "human-action tasks" (clicking, typing, e-signing) through computer-use surface. Digital Cognitive Labor classifier splits tasks into digital/actuatable/physical segments.

## Comparison to OpenClaw/Kagura's Approach

| Aspect | Godcoder | Kagura/OpenClaw |
|--------|----------|-----------------|
| Memory format | SQLite patterns w/ success_rate | Prose beliefs + wiki cards |
| Selection signal | Quantitative (% success per tag) | Qualitative (triple-verification gate) |
| Optimization | Automated `optimize` command | Manual reflection workflow |
| Sandbox | `harness-build/` directory | FlowForge workflow isolation |
| Self-improvement trigger | Every iteration automatically | Periodic reflection (daily review) |

## Applicability

- **Quantitative outcome tracking** — Could add success/failure logging to study/workloop outcomes and rank approaches by effectiveness. Currently only qualitative.
- **Tag-based approach ranking** — "Prefer scout on Mondays" or "followup-with-api-check has 80% signal rate" — data-driven mode selection.
- **Binary keep/discard** — Cleaner than "log everything and hope reflection catches it." Could apply to beliefs-candidates: promote only if success_rate > threshold.

## Health Assessment

- Solo dev, extreme velocity (245⭐ in 48h)
- 0 external contributors, 1 self-merged PR
- Fragile but architecturally interesting
- Track at warm interval (14d)

## Decision

**Track, don't invest.** The route-log-recall-optimize pattern is the main takeaway. Already noted in comparison table. Revisit to see if community develops.

## Connections

- [[self-evolution-architecture]] — Godcoder's approach is fully automated quantitative optimization vs our qualitative reflection
- [[hermes-self-evolution]] — Hermes uses DSPy/GEPA for evolutionary improvement; Godcoder uses simple success_rate ranking
- [[agent-harness-landscape]] — New entrant in the harness space, differentiated by self-building capability
- [[beliefs-candidates]] — Our equivalent of their `log` + `optimize`; could adopt quantitative scoring
- [[flowforge]] — Our workflow isolation is analogous to their `harness-build/` sandbox

---
*Deep-read: 2026-06-29 | Source: GitHub scout*
