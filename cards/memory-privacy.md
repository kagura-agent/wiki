---
title: Memory Privacy
created: 2026-06-10
tags: [privacy, memory, governance]
last_verified: 2026-06-10
---

# Memory Privacy

The challenge of controlling what an AI agent remembers, who can access those memories, and how sensitive information is handled across contexts.

## Key concerns

- **Context leakage**: Private information from one chat context (e.g., Feishu DM) appearing in another (e.g., Discord group)
- **Sensitivity labeling**: Marking memories with access levels so retrieval respects boundaries
- **Selective forgetting**: Ability to purge specific memories on request
- **Audit trail**: Knowing what was remembered, when, and from which context

## Our current approach

- `MEMORY.md` loaded only in direct Luna chats (Feishu DM, WhatsApp), never in shared contexts
- Daily memory files (`memory/YYYY-MM-DD.md`) contain raw logs — no sensitivity labels yet
- No receipt-driven replay or governance surfaces

## Prior art

- Statewave's governance surfaces (sensitivity labels, receipt-driven replay) are ahead of our approach
- The gap between "don't load in groups" (access control) and proper sensitivity labeling (data governance) remains open

## Related

- [[verify-external-ops]]
