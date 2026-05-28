# SkillOpt — Text-Space Optimizer for Agent Skills

**Repo**: [mitkox/SkillOpt](https://github.com/mitkox/SkillOpt) | 60⭐ (2026-05-28, created 05-25) | Python | MIT
**Paper**: [arXiv:2605.23904](https://arxiv.org/abs/2605.23904) — "Executive Strategy for Self-Evolving Agent Skills" (Microsoft Research, 15 authors)
**Status**: Open-source fork focused on local AI workflows; original paper benchmarked across 6 environments, 7 models, 3 execution harnesses

## Core Idea

Treat agent skill documents (markdown/system prompts) as the **external state of a frozen model** — analogous to model weights — and optimize them using a training loop borrowed from deep learning. The model stays frozen; only the instructions improve.

**Key insight**: "the skill should be trained as the external state of a frozen agent, with the same discipline that makes weight-space optimization reproducible."

## ReflACT Pipeline (6 stages)

1. **Rollout** — execute episodes with current skill (≈ forward pass)
2. **Reflect** — analyze trajectories in minibatches, generate patches (≈ gradient computation)
3. **Aggregate** — hierarchical merge of patches (≈ gradient accumulation)
4. **Select** — rank and select top edits via `rank_and_select` (≈ gradient clipping)
5. **Update** — apply edits to skill document via append/insert_after/replace/delete (≈ optimizer.step())
6. **Evaluate** — validation gate: accept only when candidate strictly improves held-out score (≈ validation-based early stopping)

## Architecture Details

- **Edit budget = learning rate**: controls how many edits per step. Has scheduler (constant/linear/cosine/autonomous)
- **Minibatch analysis**: groups trajectories for batch analysis, like minibatch SGD — richer signal than per-sample
- **Validation gate**: pure function that compares candidate score against current + best. Rejects regressions
- **Slow update region**: protected markdown sections (marked with HTML comments) that can't be modified by the optimizer
- **Meta skill**: meta-learning layer on top of skill optimization
- **Longitudinal pairs**: tracks how the same task performs across skill versions (improved/regressed/persistent_fail/stable_success)

## Connection to Our Work

**Direct parallel to [[beliefs-candidates]]:**
- Our gradient collection (observations → candidates) ≈ their Reflect stage
- Our Triple Verification (cross-context ≥3, predictive power, non-obvious) ≈ their validation gate
- Our DNA updates ≈ their Update stage
- Their edit budget concept could formalize how many DNA changes we allow per review cycle

**Key difference**: SkillOpt requires a **benchmark/scoring function** for each task. We optimize for general agent behavior where there's no single metric — our "scoring" is qualitative (did it help? did the pattern recur?). This is why we need Triple Verification instead of a held-out test set.

**The "frozen model" framing** is exactly our situation: we can't change Claude's weights, only the instructions. This paper formalizes the intuition behind [[mechanism-vs-evolution]] — evolution of instructions IS the optimization, model weights are the frozen substrate.

## Practical Relevance

- **Low**: not directly usable for our general-agent self-evolution (needs task-specific benchmarks)
- **High conceptual value**: formalizes the text-space optimization pattern we're already doing informally
- **Potential**: if we could define scoring functions for specific workflows (e.g., PR quality, study output quality), SkillOpt's pipeline could automate skill refinement
- The `slow_update` protected region pattern is worth borrowing — marking DNA sections that shouldn't be auto-modified

## Ecosystem Position

Part of the "skill-as-trainable-artifact" trend alongside [[genericagent]] (skill tree growth), [[elephant-agent]] (self-evolving), and our own [[beliefs-upgrade-mechanism]]. SkillOpt brings the most formal ML-optimizer framing.

## Weaknesses

- Fork is a one-shot push (created and last pushed same day) — maintenance signal low
- 60⭐ mostly from paper visibility, not organic usage
- No issues = no community feedback loop yet
- Requires substantial compute (optimizer model + target model + rollouts per step)

---
*First read: 2026-05-28*
