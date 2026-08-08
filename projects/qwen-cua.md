---
title: "Qwen-CUA — screenshot-only browser-use reference agent"
created: 2026-08-06
tags: [computer-use, browser-agent, safety-gates, replay, verification]
last_verified: 2026-08-08
---

# Qwen-CUA (xlang-ai/Qwen-CUA)

**Repository:** https://github.com/xlang-ai/Qwen-CUA
**Observed 2026-08-06:** 140⭐ in the scan result. The repository contains a technical report and a runnable browser-only reference demo; it does **not** publish model weights.

## What it is

[[Qwen-CUA]] is a model-and-runtime proposal for native computer use: the model receives screenshots and emits typed keyboard/mouse actions on a normalized 0–999 coordinate grid. The demo deliberately withholds the DOM, accessibility tree, shell, and task-specific APIs from the model. It is therefore a browser-use reference implementation, not a full desktop agent despite the broad project title.

## Architecture verified from source and tests

- A FastAPI `RunnerManager` creates a fresh Playwright Chromium context per run, calls an OpenAI-compatible multimodal endpoint, parses XML `computer_use` actions, and persists `run.json`, `events.jsonl`, `replay.json`, screenshots, downloads, and uploads.
- `AgentHistory` retains recent images while replacing older images with a fixed placeholder; it preserves prior action summaries rather than visual evidence. This is a concrete visual-context compression tradeoff, not long-term state recovery.
- The action protocol is typed and rejects malformed, out-of-range, and unknown calls. `test_protocol.py` covers multiple action kinds and ensures typed text can be redacted while keeping the call parseable.
- Custom URLs are URL- and DNS-checked before launch; private, loopback, link-local, reserved, and multicast addresses are blocked unless explicitly enabled. However, this validation happens before navigation and does not establish a continuous network-policy boundary.
- For custom URLs, password typing, file uploads, downloads, form submits, and cross-origin clicks invoke an operator approval gate. Built-in lab scenarios bypass this per-action gate and instead finish through deterministic `verify_scenario` state checks.
- A model's `terminate(success)` does **not** prove a custom task succeeded: custom runs are recorded as `UNVERIFIED`. The tests specifically assert that an approved password-entry run remains unverified.

## The important boundary

The project cleanly separates **agent action safety** from **task-result verification**. Approval protects sensitive browser interactions; scenario verification proves only the two controlled local labs. The replay is useful audit evidence but not an independent proof of a real external outcome. This is closely aligned with [[graded-agent-guardrails]]: hard intervention should track hard evidence, while ambiguous browser actions are escalated to a human.

The counterintuitive limitation is that the demo's “native” interface is implemented through Playwright and its safety decisions inspect DOM metadata (`elementFromPoint`, input type, href, form action) that the model itself cannot see. It is native from the model's perspective, but not a purely pixels-only trust boundary in the runtime.

## Ecosystem position and relevance

[[Qwen-CUA]] complements [[OpenClaw]] rather than replacing it. It supplies a narrowly scoped, replayable browser-execution loop; [[FlowForge]] supplies decision routing and process governance. Its strongest transferable pattern is: classify consequence-bearing actions at execution time, require an explicit operator decision, and make external-task success unverified unless a task-specific verifier exists.

For our workflows, that reinforces the existing distinction between tool output, deterministic checks, and claims. It does **not** justify treating screenshots/replays as proof, nor adopting a browser agent for authenticated or high-stakes work.

## Community signal and limits

The repository had only two visible issues at review time: a Windows executable request and a Papers-with-Code metadata-verification request. Neither provides a substantive architectural critique. The local demo's tests were inspected but not run: the workspace lacks a `python` executable, and the repository's demo dependencies were not installed. No live-model calls are included in its default test suite by design.

## Checkable prediction

If Qwen-CUA is adopted as an agent-runtime reference rather than merely a model release, its demo will gain explicit defenses for post-navigation/DNS-rebinding network policy or document that this is outside scope by **2026-09-06**. **Confidence: low.**
