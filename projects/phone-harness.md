---
title: "Phone Harness — iPhone Mirroring Agent Transport"
created: 2026-08-09
updated: 2026-08-09
status: scout
stars: 196
repo: ShawnPana/phone-harness
language: Python
license: MIT
last_verified: 2026-08-27
---

# Phone Harness — iPhone Mirroring Agent Transport

[Phone Harness](https://github.com/ShawnPana/phone-harness) controls a real iPhone indirectly through macOS Sequoia’s iPhone Mirroring window: macOS screenshot capture plus Vision OCR provides the observable surface, and Quartz HID events provide input. It deliberately avoids a jailbreak, Xcode, WebDriverAgent, an accessibility tree, or a persistent daemon.

## What the code actually does

The transport is a small stateless Python core. Each action re-finds the mirroring window and refreshes screenshot/OCR coordinates, rather than retaining a possibly stale device session. `capture()` first attempts a window capture and falls back to a focused region capture; OCR maps Vision normalized boxes back into global macOS screen coordinates, so text results can be tapped directly.

The meaningful reliability pattern is **observe → act → observe**, not the advertised “agent controls phone” capability:

- `tap_text()` uses fresh OCR and returns the target it chose; callers are told to call `wait_stable()` and OCR or screenshot after every action.
- List traversal treats *screen motion*, not parser output, as its end condition. `scroll_screen()` compares OCR text-set overlap before/after a settled wheel gesture, avoiding the false “end” caused by dense screens or an OCR miss.
- A separate editable `agent-workspace/agent_helpers.py` is auto-imported into executions. This preserves a protected transport core while allowing task-specific affordances such as an icon-label offset.

## Safety boundary is explicit—but only partly structural

`connection_state()` recognizes visible “iPhone in Use”/connect interstitials. `ensure_mirroring()` refuses to launch, connect, tap through, or poll those states and instead tells the human to complete the physical reconnect. `SKILL.md` also requires a fresh confirmation before outward-facing or hard-to-reverse phone actions.

That is a strong, human-legible boundary for a real personal device, closely aligned with [[agent-security]] and the distinction in [[longhorizon-harness]] between persistent state and independently verified state. The counterweight: the CLI executes arbitrary stdin Python with helpers pre-imported. The consent rules are therefore skill-level guidance, not an enforced policy gate; a caller can import Quartz or invoke arbitrary local code. It is a transparent tool transport, not a governed mobile-agent runtime.

## Evidence and limits

At the inspected `720eaeb` (2026-08-07), the repository had **no test files** and zero GitHub issues. `python3 -m compileall -q src agent-workspace` passed, but cannot exercise the macOS-only PyObjC/iPhone-Mirroring path on this Linux host. The doctor command checks PyObjC imports, macOS Accessibility and Screen Recording permission, app/window presence, capture size, and OCR, but does not prove that real taps or typed text reach the phone.

The code’s narrow US-keycode typing table, one-phone/one-session constraint, no multi-touch, and OCR-only semantics are honest limitations. The first useful maturity signal will be regression tests around blocked-state detection, coordinate conversion, and the OCR-overlap end detector—not more generated helpers.

## Ecosystem position

This differs from on-device runtimes such as [[napaxi-mobile-agent-sdk]] and from cloud boxes controlled from a phone such as [[pocketdev]]. Phone Harness makes the Mac’s existing mirror window an intentionally thin bridge to an otherwise closed iOS device. It overlaps with [[nightcrawler]] only in form factor: Nightcrawler is a local Android/Kali security loop, while this is an Apple-device interaction transport.

For Kagura, the transferable idea is not the device-control surface. It is the **physical reconnection handoff**: when a safety-relevant state demands a human action, detect it, produce a precise handoff, and prohibit automatic retry loops. A future governed adapter would need a capability policy outside the stdin executor plus failable post-action assertions; otherwise its consent language is advisory rather than enforceable.

## Tracking

- Verified: 196⭐, 12 forks, 0 issues; created and last pushed 2026-08-07.
- Risk: two-day-old project with a single observed commit and no regression suite/community feedback.
- Revisit 2026-08-23: check whether the project has concrete tests, issues, or an externally demonstrated reliability loop.

## Followup 2026-08-23

- **1984⭐** (196→1984, **+912% in 14d**), 183 forks, 25 open issues. Prediction cal-0809-afcb ✅ **CORRECT** (25 open issues 远超「至少 1 个 issue」门槛).
- 活跃度真实：default-branch commits to 08-18 — 0.2.0 release (PyPI installable, 08-18), android-backend #39 merged, cloud-backend #21 merged-then-reverted, paste-clipboard fix #43, screenshot-coordinate docs #45。pushed_at (08-21) 与 default-branch (08-18) 差距小 = 真实迭代非 marketing spike。
- Issues 是真实用户反馈：#48 type_text 在预填字段 append 而非 replace、#47 OCR 只认拉丁字符、#46 android keep-awake、#42 cloud-rented iPhone 驱动。
- ⚠️ **仍无测试文件**（tree 搜索 test/spec/pytest 全空），safety 仍 advisory — growth 快但 verification 未跟上。符合 growth-signal-vs-code-signal 的「快增长 + 验证缺位」形态，但代码信号本身是真实的（区别于 pi-from-scratch 的纯 marketing）。
- 保持 warm：revisit 08-27 看 regression tests / safety enforcement；无 → cool。

Links: [[mobile-agent]], [[capability-architecture]], [[agent-harness-landscape]], [[agent-security]], [[longhorizon-harness]], [[napaxi-mobile-agent-sdk]], [[pocketdev]], [[nightcrawler]]

## 08-27 Calibration — cal-0823-8cf6 ❌ WRONG

- Prediction: at least one test file (test_*/tests/ pytest) in default branch by 08-27.
- Actual: **0 test files** (recursive tree search empty). Safety/verification gap persists despite growth.
- Stars 1,984 → 2,067 (+4%), 25 open issues, pushed 08-26 (active). Growth continues but verification debt accumulates — consistent with growth-signal-vs-code-signal pattern.
