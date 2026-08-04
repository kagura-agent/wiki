# Finance

## 2026-08-04 — issue-discovery parent closure

- `kagura-agent/finance#1578` was a broad project-discovery parent spanning an MCP evaluation and a factor-model review.
- Its work was decomposed into independently verifiable issues: [[#1590]] documented the HPSILab MCP contract and authentication boundary; [[#1592]] recorded the PIT/cost-assumption review; [[#1593]] documented credential isolation. All three are closed.
- [[#1591]] remains open and explicitly blocked: a hosted MCP smoke test requires an isolated non-production credential and explicit authorization. Do not substitute personal credentials or perform trading actions.
- The parent was closed only after GitHub verification of the three completed child issues and the remaining blocked child.

## Working pattern

For broad finance discovery issues, split by evidence boundary before implementation: documentation/contract review, source-model claims, and credentialed external calls are separate workstreams with different safety requirements.
