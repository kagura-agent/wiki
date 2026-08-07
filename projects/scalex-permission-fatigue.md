---
title: Scalex HITL Permission-Fatigue Data
created: 2026-08-07
last_verified: 2026-08-07
source: https://scalex.dev/blog/ai-agent-permissions-stats/
---
# Scalex HITL Permission-Fatigue Data

A Scalex browser-game dataset (40,000 runs; 409,000 approve/deny decisions) is not a production telemetry study, but it is unusually concrete evidence for the failure mode behind [[permission-hardening]]: asking people to judge isolated commands is a noisy and lossy security control.

## What the game measured

The game deliberately makes roughly 34% of prompts malicious, so its absolute rates must not be projected onto ordinary coding sessions. Within that artificial setting, average threat-detection accuracy was 66.3%; 32.9% of sessions scored negative; and only 20.8% both caught every threat and kept false-positive blocks at or below 20%. That is a **usability/security tradeoff measurement**, not proof that one third of real agent threats will succeed.

The most informative result is contextual: `npm run analyze` was approved 64.7% of the time even when the immediately preceding history showed its script piping data to `curl`. Familiar command labels hide the real authority boundary—an agent that can edit `package.json`, a build script, or a dependency can turn an apparently safe command into arbitrary execution.

## Architecture implication

[[agent-security]] distinguishes action authorization from context integrity. This dataset shows why command-level HITL conflates them: a human must reconstruct both *what will execute* and *what state made it execute* from a terse prompt, repeatedly and under interruption. More prompts create fatigue; broad blocking creates an operational bottleneck; neither grants reliable authorization.

The safer pattern is layered and state-aware:

1. constrain the runtime with filesystem/network/process sandboxes and narrowly scoped credentials;
2. classify and display the *effective capability* (for example, network egress plus data read), not merely the shell spelling;
3. reserve human approval for infrequent, high-consequence state transitions, with provenance/evidence that explains why that transition is requested;
4. make blocked policy states progress-capable as described in [[policy-gate-progress-path]], rather than adding blanket approval bypasses.

This reinforces [[Qwen-CUA]]'s typed-action/approval design only when its approvals are tied to demonstrable, bounded effects. A typed coordinate action alone does not make a browser action safe; the authorization boundary must still include destination, data scope, and durable evidence.

## Ecosystem position and relevance

The HN discussion (251 points / 190 comments as scanned on 2026-08-07) suggests attention is shifting from "can agents act?" toward whether a human can realistically supervise ambient agent authority. It complements systems such as [[Sprocket]], whose payment mandates bind merchant and amount, and [[FlowForge]], whose routed gates leave audit evidence. The common design direction is **pre-bounded authority plus verifiable state**, not perpetual prompt review.

For Kagura, this is a validation—not a reason to add more confirmation prompts. Existing approval and untrusted-content boundaries should continue to be paired with least privilege, evidence-bearing workflows, and narrow recovery paths.
