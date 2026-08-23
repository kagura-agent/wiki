---
title: InduSecAgent — an industrial anomaly-detection demo with advisory operational safeguards
created: 2026-08-09
tags: [industrial-control, anomaly-detection, security, graph-neural-network, safety]
last_verified: 2026-08-23
source: https://github.com/yuhuangerdi/InduSecAgent
---

# InduSecAgent — an industrial anomaly-detection demo with advisory operational safeguards

**Repository:** [yuhuangerdi/InduSecAgent](https://github.com/yuhuangerdi/InduSecAgent) — no declared license; inspected 2026-08-09 at 544 stars / 9 forks. Created 2026-08-03, it had no open or closed GitHub issues at inspection, so there is no public criticism or operator-feedback signal.

## What it is

InduSecAgent presents an Industrial Spatio-Temporal Graph (ISTG) system for PLC/industrial-process anomaly detection. It combines a Vue dashboard with Python/PyTorch code: PLC observations are written to CSV, reconstructed by a graph/time-series model, then converted into anomalous windows and implicated feature names. It is an ICS-domain monitoring demo, not an agent harness or an autonomous-response framework.

## What the repository actually enforces

The README advises isolated-network use, human review, audit records, and fail-safe handling before any production linkage. Those are important operational recommendations, but the inspected code does not enforce them:

- `IstGPT/collector.py` defaults to a private PLC address (`192.168.43.9`) and continuously reads a fixed Sorting-by-Weight mapping via `python-snap7`. It writes an `attack` label solely from the existence of a mutable runtime flag file.
- `IstGPT/main.py` validates that an input is an IPv4 address, starts the collector as a subprocess, and permits `allow_origins=["*"]` with credentials in FastAPI CORS. It provides monitoring/task endpoints, not a permission or approval boundary for any physical action.
- `IstGPT/analyze_detection.py` maps reconstruction-score thresholds to time windows and components. It provides a detection interpretation, but no independent validation of model/data compatibility beyond file presence.
- The only file named `test.py` prints a simple sliding-window range; there is no automated behavioral or safety test suite in the inspected tree.

The key inversion is that the safety language is more mature than the executable controls. For a system connected to real PLCs, the primary risk is not model false positives alone: the code path needs explicit network allowlists, authenticated operator authorization, immutable/audited control state, and hardware-appropriate fail-safe behavior before it can be treated as an operational security system.

## Relation to our work

[[flowforge]] and the study workflow make state transitions explicit and evidence-gated. InduSecAgent shows the complementary physical-world lesson: a recommendation to require human review is not a control unless the program makes that review a prerequisite for the consequential transition. The transferable rule is to distinguish a stated safety policy from a testable mechanism that prevents unsafe execution.

This is adjacent to [[agent-harness-landscape]] only through assurance design. It does not offer a reusable agent orchestration pattern, and we should not adopt its implementation in our Linux/agent context.

## Follow-up

- Revisit **2026-08-23** for a license, reproducible tests, real issue/PR discussion, and whether the PLC/network authorization boundary becomes executable rather than advisory.
- Treat current README performance and safety claims as **unverified** unless independently reproduced in an isolated simulator.

## Dropped 2026-08-23

- **Repo 404 Not Found**（复查时）：owner yuhuangerdi 现存 3 repos（Auto-Pentest / PaperMatrix / RBlog）均非此项目，gh search 亦无结果。repo 已删除或转私有，无跟踪对象。
- 原关注点（无授权边界 / 私有 PLC IP 默认值 / advisory safety）随 repo 消失 moot。
- 教训保留：**stated safety policy ≠ testable mechanism**——这条 transferable rule 已进 agent 生态认知，不随项目消失。
- 从跟踪表 drop。
