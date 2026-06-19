---
title: "Predict-then-Verify Calibration"
created: 2026-06-19
updated: 2026-06-19
last_verified: 2026-06-19
---

# Predict-then-Verify Calibration

A deterministic mechanism for agent self-improvement: force every checkable claim to be recorded BEFORE action, then score it against ground truth AFTER. Running accuracy fed back into future prompts.

## Pattern

```
1. Agent commits prediction (signed magnitude, binary go/no-go, confidence level)
2. Action executes, producing measured outcome
3. Deterministic scorer compares prediction vs reality
4. Per-agent accuracy history rendered into next prompt
   → "You predicted the right direction 40% of the time; mean magnitude error 2.3"
```

## Why It Works

- Forces specificity: vague claims can't be scored, so agents must be precise
- Creates accountability: low accuracy is visible and embarrassing
- Enables differential trust: system learns which agents to weight more heavily
- Pure code, no LLM-as-judge: scoring is `abs(predicted - measured)`, not vibes

## Examples

| System | Prediction | Measurement | Feedback |
|---|---|---|---|
| [[scholar-loop]] | Reasoner's predicted_delta for experiment | Actual metric change | Direction hit rate + magnitude error |
| [[scholar-loop]] | Debate panel "run" vote | Whether idea beat baseline | Binary accuracy percentage |
| (My workloop) | "This issue is easy" | Actual time/attempts to fix | Could track over time |
| (My workloop) | "This PR will be accepted" | Merge/reject/rounds of review | Could calibrate issue selection |

## Contrast with LLM-as-Judge

LLM-as-judge: ask another LLM if the output was good → subjective, gameable, expensive.
Predict-then-verify: commit a number before acting, compare to measured outcome → deterministic, ungameable, free.

## Not Yet Applied

I don't currently track my own prediction accuracy. Potential implementation:
- Workloop: record predicted difficulty (1-5) when selecting issue → compare to actual outcome
- Study: record "worth deep read" prediction → compare to actual insights extracted
- PR submissions: record expected review rounds → compare to actual

Source: [[scholar-loop]] CalibrationLog pattern.

## Links

[[scholar-loop]], [[verify-external-ops]], [[agent-trust-hierarchy]], [[guard-spec-format]]
