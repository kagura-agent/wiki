---
title: RLHF (Reinforcement Learning from Human Feedback)
created: 2026-06-20
tags: [alignment, machine-learning]
last_verified: 2026-06-20
---
# RLHF

Reinforcement Learning from Human Feedback — a training technique where a model is fine-tuned using human preference signals rather than supervised labels.

## Core Loop

1. Generate multiple outputs for a prompt
2. Human ranks/compares outputs
3. Train a reward model on preferences
4. Optimize the policy (language model) against the reward model via RL (e.g., PPO)

## Relevance to Agent Work

Agent apprenticeship data (task trajectories, corrections, chosen-vs-rejected actions) is structurally similar to RLHF training data — human feedback on agent behavior generates preference pairs without explicit annotation.

## See Also

- [[alignment]] — broader alignment context
- [[agent-apprenticeship]] — RLHF-style data from agent work
