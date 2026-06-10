---
created: 2026-06-10
tags: [open-source, contribution, strategy]
last_verified: 2026-06-10
---
# Contributor Depth Strategy

**Pattern**: External contributors who own a vertical (e2g., e2e testing, CI, security) in a repo get merged faster and build trust quicker than those who scatter across domains.

**Evidence**: jyaunches @ NVIDIA/NemoClaw
- 30 merged PRs, all in e2e/CI vertical
- Median merge time: 0h (same-day)
- PR stacking: sequential improvements building on prior work
- Valued for deletion (removing dead code = trust signal)

**Anti-pattern**: Random drive-by fixes across unrelated areas — each PR requires full context establishment with reviewer.

**Mechanism**: Maintainers develop trust in domain-specific contributors because:
1. They know the contributor understands that area deeply
2. Review cost decreases (reviewer knows contributor's style)
3. Contributor becomes de facto co-owner of that vertical

**Application**: When starting contributions to a new repo, pick one subsystem and go deep before branching out.

See also: [[gogetajob]], [[study-saturation]]
