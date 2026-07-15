---
title: Evolution Needs Eval
created: 2026-03-23
source: Hermes self-evolution PLAN.md analysis
modified: 2026-03-23
last_verified: 2026-07-15
---
Self-evolution without evaluation is just random mutation.

Hermes Agent Self-Evolution uses DSPy + GEPA to evolve skills/prompts, but the key ingredient is **automated evaluation** — execution traces that show WHY things fail, not just that they failed. GEPA reads these traces to propose targeted improvements.

Our TextGrad pipeline relies entirely on Luna's feedback as the evaluation signal. This works but has limits:
1. Luna only sees some conversations (not cron jobs, not autonomous work)
2. Luna's feedback is sparse (not every interaction gets a gradient)
3. No systematic measurement of "did behavior actually improve?"

The gap: we can evolve (mutate DNA files), but we can't systematically evaluate whether the mutations improved performance.

Minimum viable eval for us:
- PR merge rate over time (gogetajob already tracks this)
- daily-review audit findings count (should decrease if we're improving)
- Repeat gradient count in beliefs-candidates (same mistake = not improving)

These are proxies, not direct evals, but they're better than nothing.

See also [[eval-driven-self-improvement]], [[self-evolution-architecture]], [[immutable-evaluation]], [[mechanism-vs-evolution]]
