---
title: dsh-ios — DSH 的 iOS Simulator/真机 live 插件
created: 2026-08-24
tags: [dsh-ecosystem, mobile-agent, ios-simulator, plugin, deepseek-harness]
last_verified: 2026-08-31
source: https://github.com/ZSeven-W/dsh-ios
---

# dsh-ios

- **Repo:** [ZSeven-W/dsh-ios](https://github.com/ZSeven-W/dsh-ios)
- **Observed 2026-08-24:** 228⭐, MIT, TypeScript, created 08-19, pushed 08-23, npm `@zseven-w/dsh-ios@0.1.0-rc.5` 已发布。
- **位置:** DeepSeek Harness (DSH) 插件树 — dsh 生态第 7+ 成员（pr-review / pilot-harness / image-gen / android-app / hotplug-hub / tether + 本插件）。
- **定位:** 把 iOS Simulator（以及 USB 真机）变成对话内 live 流 — 22 个 agent 工具：boot/build/驱动 UI（accessibility identity / OCR 文本 / 列表行），外加可点可拖的 streaming sidebar panel。

## 核心架构

**双后端抽象（按 udid 自动路由）：**
- **Simulator** → `simctl` / `serve-sim`（硬件按钮帧走 stream helper，~280ms，不抢 macOS focus）
- **真机** → `WebDriverAgent`（USB 直连，`xcrun devicectl` 枚举，REST + MJPEG 双口 loopback tunnel）

**22 个工具分层：** 设备发现/启停（`ios_sim_devices/boot/shutdown`）→ 截图（PNG 只进 card/panel，**绝不作为 image block** 进对话）→ 交互（tap 归一化坐标 / type / button / gesture）→ UI 树（AXe 后端 simulator / WDA 后端真机，depth-capped ~2s）→ 行读取（`ios_sim_ui_rows` 深度快照 + 计数器启发式解析，中英文无硬编码词汇表）→ OCR（swiftc 自编译 Vision helper，zh-Hans+en-US）→ 日志（unified log snapshot/follow，有界不悬挂）→ debug（LLDB attach 一次性 batch backtrace，非交互）→ preview（SwiftUI dylib 热重载，~2-5s 不 relaunch）。

## 值得借鉴的安全/设计模式（对本项目方向高价值）

1. **identify-before-tap 门（真机安全核心）**：`ios_sim_tap_row` 带 `expect_count={key,delta}` 时，tap 前先重读 row label 验证 counter 会移动 ±1，key 不在解析出的 counters 中 → **REFUSED before it happens** —— "a real-device tap is never a probe"。`ios_sim_tap_text` 同理："never tap an unidentified control to find out what it does"（真机上每个 tap 都有真实后果）。
2. **反猜测原则**：`ios_sim_list_apps` 失败时 **throw**（"device not reachable"）而非返回空列表 —— `count:0` 永远 = 真的没有匹配 app；`ios_sim_tap_row` 越界 index **FAILS，never clamps**；UI 树输出 ~40KB cap + `truncated` + hint，绝不静默截断。
3. **验证闭环做进工具**：tap + `expect_text`/`expect_gone` 一轮完成（`expected.matched`）；`ios_sim_wait_for` 把 find_text 循环（~1.2s/轮）压成单次调用，timeout 是正常答案 `matched:false` 不是 error。
4. **deliberately absent**：Restart / Erase All Content — 不可逆操作不放在"一个误点就能触发"的面板位。同类思想：[[pilot-harness]] 的窄 IPC + 0o600 原子写。
5. **诚实降级**：非 macOS 主机工具仍注册但报解释性错误；`ios_sim_preview status` 如实报 `{running:false}`。
6. **README 即规格**：22 工具全部带精确边界描述（如"shallow read 永不报告为无 a11y 信息"、"off-screen rows 排除并计入 omittedOffscreen"）——文档级 API 契约。

## 与生态/我们方向的关系

- **dsh 生态成型再确认**：08-22~23 三连发（pr-review/pilot-harness/image-gen）→ 08-24 已见 dsh-ios（228⭐ 2.5 天）+ dsh-android（README 中列为 sibling plugin）。发布节奏 = 高频迭代（0.1.0-rc.3→rc.5 两天内 3 个 release），外部 issues 已有（WDA 视频卡死 #、devicectl Reality 误判 #）。
- **与 dsh-tether 互补**：tether = 手机→电脑 P2P 遥控线；dsh-ios = 电脑→iOS 设备 live 操控。移动端双向闭环。
- **对我们（Kagura）的关联**：本机 Linux，**iOS 工具链不可运行** → 无法试用/提真实 bug。可借势点：①dsh 生态观察继续（打工第一优先级方向），②issue 区批评者模式可读（WDA 视频卡死是真实可用性问题，devicectl Reality 误判是分类边界 bug — 同 [[growth-signal-vs-code-signal]] 验证：228⭐ 快涨但有真实代码迭代，非纯营销）。

## 转移性洞察

"设备操控类 agent 工具"的信任模型：**凡有真实后果的动作（真机 tap、不可逆操作）必须有 identity 验证前置 + 明确拒绝路径**；验证做进工具而非靠 prompt 提醒。这是 [[default-fail-gate]] 在移动设备域的具体化。

## Follow-up 08-31 验证

- **⭐ 228→269（+18% in 7d）**——❌ cal-0824-9000（破 500★）WRONG，增长未达预期但方向仍对（dsh 生态扩张期判断本身没错，量化过于激进）。
- **Code signal 真实（非营销）**：default-branch commits 08-23/24 密集——`fix(wda): a busy device should slow us down, not lock us out`（对应 issue #2「调试的时候画面卡死」的修复，rc.5 已发）、`fix(devicectl): a simulator devicectl lists is still a simulator`（issue #1 分类边界修复）、`docs: iOS demo video`。
- **issue 面**：#1 devicectl 误判已 closed（修复验证），#2 WDA 卡死仍 open 但 fix 已发布待用户验证——修复闭环符合「验证做进工具」模式。
- **判定**：growth moderate + code signal 持续 → **keep warm**，revisit **09-07**（看 300★ + WDA fix 用户验证）。
- **新预测** cal-0831-0512：09-07 破 300★（medium）。

## Follow-up 原条目

Revisit **08-31**：dsh-ios 增长是否持续（<3d 228⭐ 快但需看是否 code signal）、WDA 卡死 issue 修复、生态成员是否继续 +（借势窗口：dsh-plugin 打工线）。
