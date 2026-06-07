---
title: Abort-Masks-Sink Pattern
created: 2026-06-07
source: ironcurtain PR #281
tags: [agent-reliability, testing-patterns, security]
last_verified: 2026-06-07
---

# Abort-Masks-Sink Pattern

**Pattern**: When a sanitizer/check aborts execution at an early stage (e.g., integer overflow), it prevents discovering a more serious downstream bug (e.g., heap buffer overflow from the undersized allocation).

**Fix**: Default sanitizer checks to **recover/warn-only mode** so execution continues with the wrapped value (matching production behavior), surfacing both root-cause diagnostic AND downstream impact in a single run.

**Specifics from ironcurtain**:
- Integer overflow → undersized allocation → OOB write
- Sanitizer abort at the overflow site = execution never reaches the OOB write
- Zero-size guard catches `wrap-to-zero` but misses `wrap-to-small-positive`
- Solution: sweep small-positive wrap residues, not just power-of-two that wraps to zero

**Generalization**: Any multi-stage bug chain where an early check (abort, guard, exception) prevents observing the downstream consequence. The early check may itself be correct behavior, but reporting "bug doesn't fire" based on it is misleading.

## Related
- [[invariant-gated-verdict]] — general pattern of circular self-assessment
