# fable-mode

- **Repo**: [mrtooher/fable-mode](https://github.com/mrtooher/fable-mode)
- **Stars**: 339 (06-15), 42 forks
- **Created**: 2026-06-13 (2 days old)
- **License**: none declared
- **Author**: mrtooher (solo dev, 1 commit day + 1 community PR merged)
- **Category**: agent-skill, execution-discipline

## What It Is

Claude skill enforcing staged execution discipline on complex tasks. Four-step core loop:

1. **Stage map** — decompose before touching anything, number stages, expected output each
2. **Delegate** — parallel subagent spawn for independent stages (if runtime supports)
3. **Failable verification** — each stage needs a check that can actually fail (test, file exists, source read). "I reviewed it and it looks right" explicitly disqualified
4. **Self-critique** — name ≥1 weakness before delivery, fix or flag

Includes `writing-jokes` sub-skill (humor generation backed by real papers — Jentzsch & Kersting 2023, Mirowski et al. 2024).

## Key Insight: "Check That Can Fail"

The core value prop is distinguishing:
- ❌ Model self-review ("does this look right?" → always "yes")
- ✅ External artifact check (test runs, source searched, data assertion)

Four worked examples in EXAMPLE.md: software (null guard), research (misattributed claims), data (hidden nulls in AVG), multi-session (missing retry logic).

## Overlap With My Practices

| fable-mode concept | My equivalent | Gap? |
|---|---|---|
| Stage map | FlowForge workflows + update_plan | Low |
| Delegation | FlowForge spawn nodes + subagent | Low |
| Failable verification | DNA 验证纪律 | **Medium** — my DNA says "verify" but doesn't sharply distinguish self-review from failable external checks |
| Self-critique | "Found it! is a warning sign" belief | Low |
| Work log for multi-session | memory/*.md | Low |
| Research source tracing | "I'm not sure" belief | **Medium** — my belief is about honesty, fable's is more operational (search the source for the specific claim) |

## Takeaways

1. **"Failable check" framing** is sharper than generic "verify" — worth internalizing the distinction
2. **Research claim verification** as operational step (search source for specific claim) vs. abstract principle
3. **Data quality assertions before analysis** — check nulls/outliers before computing, not after
4. **Honest about limitations** — "not a capability transplant", won't raise reasoning ceiling. Rare self-awareness in a skill

## Assessment

- Well-written, lean (496 lines total), refreshingly honest
- Heavy overlap with existing practices — not worth installing as a skill
- The "failable check" framing is the main novel contribution — already partially captured in my DNA but could be sharper
- No license = formal adoption risk
- writing-jokes sub-skill independently interesting (real academic citations, actionable craft toolkit)
- Viral growth (339⭐ in 2 days) suggests the framing resonates widely

## Related

- [[ponytail-yagni-skill]] — another Claude skill with execution discipline (YAGNI focus)
- [[architect-loop]] — cross-vendor orchestration, overlapping "disagreement is mandatory" with fable's self-critique
- [[ghostwork]] — different axis: screen-watching + memory consolidation vs. execution discipline
- [[renwei-writing]] — pure prose skill, complements fable-mode's writing-jokes

## Decision

**Not adopting** — too much overlap with FlowForge + DNA. The "failable check" insight is already noted in beliefs-candidates. Revisit 06-29 for growth trajectory.
