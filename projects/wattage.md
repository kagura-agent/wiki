# Wattage — Token-Spend Profiler & Cost-Regression Gate

Links: [[ccglass]], [[agentacct]], [[cron-observability-metrics]], [[agent-harness-landscape]], [[taco-context-compression]]

- **Repo**: faizannraza/wattage
- **Stars**: 20 (2026-07-29, 11 days old)
- **Language**: Python (PyPI: `wattage`, npm shim: `wattage-cli`)
- **License**: Apache 2.0
- **Status**: Active (pushed 2026-07-26), solo dev

## What It Does

"Kill-A-Watt meter for AI agents." Takes an OpenTelemetry trace (OTLP JSON), prices every LLM call against a vendored pricing snapshot, runs 8 waste detectors, and outputs a scored report. Has a CI gate that fails builds when an agent change makes it measurably more expensive.

## Core Architecture

**Normalized data model**: `Session → Task → Loop → Iteration → Call`
Every adapter/detector/scorer/renderer operates on one shape. Ingestion is pluggable (currently OTel file adapter only).

**8 Detectors**:
| Detector | Catches |
|---|---|
| `prefix_churn` | Stable context re-sent instead of cached |
| `cache_gap` | Caching attempted but under-redeemed |
| `verbosity` | Output far beyond what the step needed |
| `redundant_tool_calls` | Same tool call repeated (exact or fuzzy) |
| `nonconvergence` | Loops that thrash, oscillate, or stall |
| `retrieval_thrash` | Repeated retrieval without relevant results |
| `model_mismatch` | Pricier model doing cheap work |
| `reasoning_overspend` | Heavy reasoning on simple steps |

**Convergence Engine** (flagship feature, doc §5):
5 per-iteration signals combined into a progress score:
- E (evidence_gain, 0.40w): novelty of tool/retrieval results vs cumulative history
- S (state_delta, 0.20w): behavioral change vs immediately prior iteration
- P (goal_proximity, 0.20w): placeholder (neutral 0.5, needs explicit goal signal)
- O (oscillation, -0.15w): cycle detection via tool-name-based action symbols (period ≥2, requires 2+ full cycles)
- G (growth_penalty, -0.05w): tokens paid vs information gained

Classification: trailing streak of sub-threshold iterations → productive / thrashing / oscillating / stalled. Key insight: only looks at *trailing* bad stretch (current state), not historical dips that recovered.

**Embedder design** — Graceful degradation:
1. sentence-transformers (if `wattage[embeddings]` installed) — best quality
2. HashEmbedder (dependency-free fallback) — character n-gram → fixed-dim signed vector → cosine
3. NullEmbedder (off mode) — neutral 0.5 everywhere

## Design Principles (Worth Noting)

1. **Never fabricates a number**: Unknown model → warn (exit 4), don't guess. Cost fields left at 0, never estimated.
2. **Quality-risk tiering**: Findings tagged none/low/review. Score only counts quality-safe savings → cheap-but-wrong agent can't score well.
3. **Recoverable vs gross**: `wasted_dollars` is the achievable savings (accounts for cache_read_mult), not the full resent cost. Conservative, correct.
4. **Exit codes are semantic**: 0=pass, 1=fail(threshold), 2=config error, 3=ingestion error, 4=pricing error. CI reads exit code alone.
5. **Explicit approximation documentation**: Every detector documents what it *can't* measure and what proxy it uses instead.
6. **min_cacheable_prefix_tokens**: Won't flag "enable caching" on a prefix below the model's own minimum. Advice must be actionable.

## Relation to Our Work

| Our tool/practice | Wattage equivalent | Gap/opportunity |
|---|---|---|
| TACO compression | Addresses prefix_churn from agent side (compress before send) | Complementary: TACO reduces what Wattage would flag |
| cron-observability-metrics | CI gate concept | Our tracking is duration/success, not per-call waste profiling |
| FlowForge loop termination | nonconvergence detector | Wattage's trailing-streak approach is more principled than naive exact-match |
| Model routing (floway) | model_mismatch detector | We route manually; Wattage would quantify our choices |

## Anti-patterns the Convergence Engine Catches

- **Thrashing**: Agent tries different approaches rapidly without learning from results (state changes but evidence doesn't accumulate)
- **Oscillating**: Agent flip-flops between two strategies (period-2+ cycles in action symbols, ignoring args so timestamp changes don't defeat detection)
- **Stalled**: Evidence flat AND state flat AND context keeps growing — "productive-looking" because everything is unique, but nothing is actually learned. This is the *hardest* to catch (SHA-256 exact-match gets 0.14 recall on this)

## Adoption Potential

**For our cron-observability-metrics**: Could integrate Wattage's scoring concept (efficiency grade per session) into our existing cost tracking. Currently we track total cost; adding waste-ratio would surface *actionable* cost reduction.

**For OpenClaw sessions**: If OpenClaw emitted OTel traces (it doesn't yet), Wattage could gate on per-PR agent cost regression. The pattern: baseline.json committed to repo → every PR compared against it.

**Practical barrier**: We don't emit OTel traces. Would need an adapter (or our own session-log → Wattage-normalized-model converter). The normalized model (Session/Task/Loop/Iteration) is clean enough that this is tractable.

## Predictions

- Will grow to 100+ stars within 30 days (novel positioning, clear value prop, good documentation)
- Will get picked up by at least one agent framework as optional integration within 60 days
- The convergence engine approach (trailing-streak + 5-signal combine) will be referenced/adopted by other tools

## 2026-07-29 — Deep Read (Initial)

Scout found via GitHub API (topic:ai-agent, created:>2026-07-22). 20⭐ at discovery. HN post (6pts, "Wattage: A token-spend profiler and cost-regression gate"). Read: full source of models.py, convergence/ (classify, signals, embed), detectors/prefix_churn.py, ci.py, scoring/score.py, pricing/registry.py. Tests use hypothesis property testing. CI via GitHub Actions. No issues filed yet (too new).
