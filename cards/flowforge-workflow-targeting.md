---
title: FlowForge Workflow Targeting
created: 2026-06-02
source: beliefs-candidates gradient, 7 hits over 06-02~06-08
modified: 2026-06-08
last_verified: 2026-06-11
---

When running FlowForge with multiple active workflow instances, you must specify which workflow with the `-w` flag. Without it, the command is ambiguous and may target the wrong instance.

This pattern accumulated 7 hits across 6 days (06-02 to 06-08) despite being a known issue. A DNA rule ("remember to use -w") would have been hit #8.

**Resolution**: Structural fix in `engine.ts` (06-08) — the tool now errors when the target workflow is ambiguous. The rule becomes unnecessary because the tool enforces it.

**Why this matters**: [[structural-fix-over-behavioral-rule]] — if a pattern can be enforced by tooling, do that instead of adding another rule to remember. Behavioral rules fail because they depend on recall; structural enforcement eliminates the failure mode at source.

Tool enforcement > behavioral rule > nothing.

See also: [[tool-shapes-behavior]], [[mechanical-verification]], [[habits-as-hooks]]
