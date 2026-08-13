---
title: "OASIS (camel-ai/oasis)"
created: 2026-08-13
last_verified: 2026-08-13
tags: [agent-simulation, python, tracked-repo, scan-timeout, large-repo]
status: observed
---

# OASIS — camel-ai/oasis

Open Agent Social Interaction Simulations with One Million Agents. Python SDK for AI agent monitoring, LLM cost tracking, benchmarking.

## Repo Profile

- **Stars:** 5,019 | **Forks:** 617 | **Open issues:** 41
- **Merge rate:** 82% | **Response:** ~59.6h | **Last commit:** 2026-08-07
- **Language:** Python
- **Repo size:** ~198 MB (203,284 KB) — near the 200 MB large-repo threshold (guide rule #20)

## ⚠️ Scan Timeout (structural)

`gogetajob scan --all` times out on this repo with `status=124` (tracked_scan unavailable). Observed 2026-08-13 (find_work → `FINDER_RESULT=UNAVAILABLE`). This blocks the whole find_work node — the scan wrapper does not skip slow repos gracefully.

**Likely cause:** repo size (~198 MB) pushes scan past the timeout budget. Related recidivism: `find-issue-oom-fallback` (3 days) in DNA preflight.

**If ever working on this repo:** use partial clone per rule #20:
```
git clone --filter=blob:none git@github.com:camel-ai/oasis.git
```
Do NOT full-clone a ~198 MB repo in the workloop.

## Contribution Assessment

- Merge rate 82% + ~60h response = decent review velocity (not a dormant/black-hole repo per rule #48)
- Python + agent simulation domain — aligned with self-evolving agent direction
- But the scan-timeout means find_work currently cannot surface its issues through `gogetajob scan --all`. Until the scan timeout is resolved (either skip-list this repo in scan, or increase timeout), it won't be a viable find_work candidate.

## Open Question

Whether to (a) add camel-ai/oasis to a scan skip-list so it stops blocking find_work, or (b) fix the scan timeout to handle ~200 MB repos. Not yet decided — leave for a non-fallback workloop session.
