---
title: Admission Controller
created: 2026-06-04
tags: [pattern, kubernetes, write-path]
last_verified: 2026-06-04
---

The admission controller pattern, borrowed from Kubernetes, applies pre-persistence webhook chains to write paths. In the context of ai-memory (PR #55), operator-configurable sequential HTTP hooks run before data is persisted, where each hook sees mutations from the previous one. Failure policy defaults to ignore so flaky webhooks never block the engine.
