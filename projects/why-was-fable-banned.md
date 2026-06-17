# why-was-fable-banned — Spec-Gate Enforcement for AI Coding Agents

> SihyeonJeon/why-was-fable-banned | 44⭐ (2026-06-13, 4 days old) | MIT | Python stdlib only

## What

A deterministic gate that **hard-blocks** AI coding agent edits until the agent writes a structured spec (`.wfb/spec.json`) and the spec passes form validation. The agent literally cannot edit implementation files until it declares intent, rejected alternatives, risks, and runnable acceptance criteria.

Works on **Claude Code** (native hooks, PreToolUse exit 2) and **Codex** (worktree-accept: worker runs in throwaway git worktree, diff applied to real repo only if gate passes).

## Architecture — Three Layers

| Layer | What | Cost | When |
|---|---|---|---|
| `wfb_gate.py` (form) | Fields present, real paths, forbidden edits, type checks | Free, deterministic | Every task |
| `wfb_judge.py` (semantics) | LLM scores spec quality against rubric (0-2 per dim) | Model call | HEAVY tasks / promotion |
| Acceptance commands | Actually runs tests, verifies behavior | Runtime | Done gate |

The gate engine (`wfb_gate.py`) is ~500 lines, stdlib-only Python. No network, no dependencies. Exit codes: 0=pass, 1=fail, 2=usage error. Subcommands: scaffold, validate, active, status, close, classify, contract, toggle, state.

## Grade-Scaling — The Token Lever

**Novel insight**: not all tasks need full spec overhead. Grade determines enforcement depth:

- **LIGHT** (typo/comment/rename/format): just `restated_goal` + 1 runnable acceptance check (~150 tokens)
- **STANDARD** (default work): full decision spec — non_goals, must_read, rejected_alternatives (≥2), risks (≥1 real), constraints.invariant
- **HEAVY** (auth/payments/migration/security): everything + architectural constraints with evidence_ref, similar_implementations, validation loop observations

**Dynamic escalation** (structural, not model-assessed):
- Change touches ≥2 files → auto-escalate to STANDARD minimum
- Change touches auth/migration/schema/secret paths → auto-escalate to HEAVY
- GRADE lock file prevents mid-task downgrade; loss of lock → fail closed to HEAVY

This means trivial fixes stay cheap (the common case), and only spreading/dangerous changes pay full enforcement. The model cannot self-classify down to avoid the spec.

## Anti-Weakening — Monotonic Spec Lock

`spec.lock` monotonically merges approved promises:
- `forbidden_paths` can only grow (adding is fine, removing is blocked)
- Approved acceptance checks cannot be removed/altered (only new evidence added)
- A spec that passed cannot be weakened to pass done against softer criteria

This prevents the "soften spec then declare done" attack pattern.

## Enforcement Mechanisms

**Claude Code** (in-session, confirmed working):
- PreToolUse hook intercepts every edit tool (Edit/Write/MultiEdit/NotebookEdit)
- Exit 2 blocks the edit, stderr message tells model what's missing
- PostToolUse logs edited files for forbidden_paths verification at done
- Protected state: model cannot edit .wfb/GRADE, ACTIVE, edits.txt (only spec.json)

**Codex** (headless, worktree-accept — the PRIMARY path):
```
git worktree add --detach $WT $BASE     # disposable copy
wfb_gate scaffold --root $WT --goal "$TASK"
codex exec -s workspace-write -C $WT "$TASK"    # ONE pass
git diff --name-only $BASE > .wfb/edits.txt     # real edit set
wfb_gate validate --root $WT --gate done        # full validation
# PASS → apply diff to real repo; FAIL → discard, repo untouched
```

**Honest caveat**: Codex native hooks do NOT fire in headless `codex exec` (file_change bypasses PreToolUse). Worktree-accept is the only confirmed headless enforcement.

## Token Cost (Measured, Honest)

| Scenario | Ratio (gross) | Ratio (cost) | Ratio (real-tokens) |
|---|---|---|---|
| Claude Code in-session (sonnet, small STANDARD) | 2.99× | 2.22× | 1.64× |
| Claude Code in-session (opus, small STANDARD) | 9.2× | 5.57× | 3.34× |
| Codex wrapper (3-pass, gpt-5.5) | 14.2× | 11.1× | — |

**Honest conclusion**: misses the <2× target for STANDARD+ tasks. The overhead is not the spec text (~2k tokens) but the **extra turns** the gate forces (write spec → get blocked → implement → verify). Each turn re-bills growing context.

Small tasks are the worst case (fixed gate cost ÷ tiny baseline). Large tasks should amortize to ~1× but this is **unmeasured, not claimed**.

## Quality Finding

**No measurable quality lift** on their benchmark tasks. Both strong (gpt-5.5) and weak (gpt-5.4-mini) models produce correct code naked on simple tasks.

The gate enforces **process**, not **capability**. Value = enforcement + evidence + auditability + "no unspeced work reaches repo."

## Relation to Our Work

| Our pattern | wfb equivalent | Difference |
|---|---|---|
| Phase 0 spec pushback (AGENTS.md prompt) | PreToolUse hard block | Ours is **behavioral** (model can ignore), theirs is **structural** (model cannot proceed) |
| [[guard-spec-format]] card (theorized formalization) | `wfb_gate.py` | They built what we theorized |
| YAGNI 6-rung ladder (minimize code) | Grade-scaling (minimize enforcement) | Same principle applied to process instead of code |
| `workflow-guard.sh` (structural fix for bypass) | PreToolUse exit 2 | Same insight: structural > behavioral for recidivist patterns |
| FlowForge (phase-gated workflow) | SPEC → IMPLEMENT → VERIFY pipeline | Similar phase gates but at different granularity (task-level vs workflow-level) |

## Key Takeaways

1. **Grade-scaling is the right approach**: don't pay full enforcement on trivial changes. Dynamic escalation from file-spread is elegant.
2. **Structural enforcement beats behavioral prompting** for recidivist patterns — confirmed by both our experience (workflow-bypass 4-day recidivist) and their design.
3. **Monotonic spec lock** prevents weakening attacks — we don't have this for our beliefs/DNA system.
4. **Honest measurement matters**: they retracted their initial "+3% overhead" claim after real measurement showed 2-9×. "Measure, don't assert" aligns with our data discipline.
5. **The shell-write bypass** (model uses bash echo instead of edit tools) means in-session hooks are best-effort, not hard sandbox. Only worktree-accept is truly hard. Similar to our realization that behavioral rules aren't hard enforcement.

## Applicability Assessment

- **Direct adoption**: Unlikely for us. We use `claude --print --permission-mode bypassPermissions` which bypasses hooks entirely. Our enforcement point is different (FlowForge workflow nodes, not per-edit).
- **Pattern adoption**: Grade-scaling + dynamic escalation could inform how we calibrate Claude Code prompts (don't force full spec pushback on trivial one-file fixes).
- **Conceptual validation**: Confirms the [[structural-fix-over-behavioral-rule]] direction. The gap between "rule exists in DNA" and "rule is enforced" is exactly what our recidivism alerts show.

## Status
- Deep read: 2026-06-17
- Track: Following (architecture patterns relevant)
- Revisit: 2026-06-24 (check community traction, any new benchmarks)

Links: [[guard-spec-format]], [[structural-fix-over-behavioral-rule]], [[fable-mode]], [[architect-loop]], [[ponytail-yagni-skill]], [[flowforge]], [[mechanism-vs-evolution]]
