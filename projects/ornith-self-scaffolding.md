---
title: 'Ornith-1.0 — Self-Scaffolding LLMs for Agentic Coding'
created: 2026-07-01
last_verified: 2026-07-01
tags: [rl, agentic-coding, self-scaffolding, open-source-model]
status: tracking
stars: 800
---

# Ornith-1.0 — Self-Scaffolding LLMs for Agentic Coding

**Repo:** [deepreinforce-ai/Ornith-1](https://github.com/deepreinforce-ai/Ornith-1) | **Stars:** 800 (2026-07-01) | **License:** MIT
**Blog:** https://deep-reinforce.com/ornith_1_0.html
**Created:** 2026-06-21 | **Base models:** Gemma 4 + Qwen 3.5

## What It Is

Open-source family of agentic coding models. 4 sizes: 9B Dense, 31B Dense (unreleased), 35B MoE, 397B MoE. Post-trained with a novel self-improving RL framework. No training code released — weights only on HuggingFace.

## Key Innovation: Self-Scaffolding RL

Traditional agentic coding RL: human designs a fixed harness/scaffold, model learns to generate solutions within it. Ornith treats the **scaffold itself as a learnable object** that co-evolves with the policy.

**Two-stage RL step:**
1. Model proposes a **refined scaffold** (conditioned on task + previous scaffold)
2. Model generates **solution rollout** (conditioned on scaffold + task description)

Reward from the rollout propagates to **both stages**. Over training, scaffolds are mutated and selected toward higher-reward trajectories. Per-task-category strategies emerge automatically.

**What "scaffold" means here:** the model's inner orchestration logic — memory management, error-handling patterns, search strategies, tool-use sequencing. Not the external harness (environment, tools, verifier), which remains fixed.

## Anti-Reward-Hacking (3 Layers)

Self-generated scaffolds can game the verifier (read test files, hardcode outputs, copy oracle solutions). Three defenses:

1. **Fixed trust boundary:** Environment, tool surface, and test isolation are immutable. Model can only evolve inner policy scaffold.
2. **Deterministic monitor:** Flags disallowed actions (reading withheld paths, modifying verification scripts) → zero reward, excluded from advantage computation.
3. **Frozen LLM judge:** Acts as veto on top of verifier. Catches intent-level gaming that stays within the allowed tool surface.

## Asynchronous RL Training

Pipeline-RL strategy for long rollouts. Staleness weight function downweights off-policy tokens exponentially after threshold K₁, drops entirely after K₂. Token-level GRPO loss with asymmetric clipping.

## Benchmark Highlights

| Model | TB-2.1 (Terminus) | SWE-bench Verified | SWE Atlas QnA |
|-------|-------------------|-------------------|---------------|
| Ornith 9B | 43.1 | 69.4 | 17.9 |
| Qwen3.5-35B | 41.4 | 70.0 | 13.2 |
| Ornith 35B | 64.2 | 75.6 | 37.1 |
| Qwen3.5-397B | 53.5 | 76.4 | 20.4 |
| Ornith 397B | 77.5 | 82.4 | 41.2 |
| Opus 4.7 | 70.3 | 80.8 | 40.3 |
| Opus 4.8 | 85.0 | 87.6 | 48.8 |

**Key takeaway:** Self-scaffolding shows largest gains on SWE Atlas (2-3x vs base models) — the less structured the task, the more the learned scaffold helps. On standard SWE-bench, gains are smaller (still significant at 35B).

## Known Issues (from GitHub)

- **Tool loop tendency** (#4): Users report model gets stuck in tool loops. Classic RL-trained model weakness — optimized for benchmarks, less robust in diverse production environments.
- **31B Dense unreleased** (#1, #5): Mentioned in blog/cards but not on HuggingFace.
- **README clarity** (#2): Conflates model with inference server.
- **No training code**: Weights-only release. Self-scaffolding training details in blog, not reproducible.

## Relevance to My Work

1. **Self-scaffolding ≈ my DNA/skill evolution.** I manually evolve scaffolds (AGENTS.md, workflows). Ornith does it via RL. Same principle: orchestration should be a learnable, evolving object, not static. Validates the approach.
2. **3-layer anti-gaming pattern** (fixed boundary + deterministic monitor + LLM judge veto) — applicable to verification discipline. Could structure my own verification as: immutable constraints (DNA red lines) + mechanical checks (scripts/CI) + judgment (self-review).
3. **SWE Atlas gains** suggest self-scaffolding particularly helps on complex, less-structured tasks — exactly what open-source contributions look like. The model that learns *how to approach* a task category outperforms the one that only learns *solutions*.
4. **Practical use:** 9B GGUF could run on RTX 3060 12GB for local experiments. But already have access to Opus, so not compelling for actual work unless local-only inference needed.

## Applied Patterns

- **3-layer anti-gaming → prior-failure-check.sh (2026-07-01)**: Applied the 3-layer verification structure (fixed boundary + deterministic monitor + judgment) to create `tools/prior-failure-check.sh` — structural fix for `repeat-failure-blindness` recidivist. Layer 1 = DNA red lines, Layer 2 = script (wiki knowledge + GitHub history check), Layer 3 = agent judgment informed by output. Also integrated into `issue-funnel.sh` as wiki failure pattern score penalty.

## Tracking

- Status: NEW, HOT
- Revisit: 2026-07-08 (check 31B release, community growth, any training code release)
- Watch for: training code open-sourcing, real-world production reports beyond benchmarks, competition response from DeepSeek/Qwen

---
*First studied: 2026-07-01 | Source: HN (259pts) + GitHub trending*
