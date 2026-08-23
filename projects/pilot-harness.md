---
title: "Pilot Harness — DeepSeek Harness 桌面客户端（CodePilot 风格）"
created: 2026-08-23
updated: 2026-08-23
status: following
stars: 251
repo: op7418/pilot-harness
language: TypeScript
license: MIT
last_verified: 2026-08-23
---

# Pilot Harness — DSH 桌面客户端

[Pilot Harness](https://github.com/op7418/pilot-harness) 是 DeepSeek Harness (DSH) 的 CodePilot 风格桌面发行版。Electron 拥有原生窗口、本地运行时生命周期、恢复页、桌面主题和安装器；**DSH 插件树仍然是应用运行时**。

> 2026-08-23 deep read（scout 轮，dsh 生态成型信号）。251⭐ / created 08-17 / 16 open issues / pushed 08-20 / MIT / TypeScript。证据：gh api README + apps/desktop README + src/main.ts + src/preload.ts + tests/*（无本地 clone，API 证据边界）。

## 架构：薄壳模式（thin-shell）

核心设计决策：**桌面进程 = 薄壳，运行时 = 上游插件树**。Electron 只做 4 件事：

1. **启动 DSH CLI 子进程**：在 OS 分配的 loopback 端口启动 `@deepseek-ai/dsh` CLI，等待其 settled `dsh web:` URL，在 sandboxed BrowserWindow 加载
2. **私有 DSH_HOME**：`PILOT_HARNESS_DSH_HOME` 覆盖（默认 Electron user-data 下），与系统安装隔离
3. **恢复与诊断**：子进程崩溃只重启子进程不重启桌面进程；bounded 300 行日志尾，**凭据正则脱敏**（api_key/authorization/token → [redacted]）
4. **原生集成**：文件夹选择（native picker）、菜单、主题、安装器

**不打补丁的承诺**：不碰 agent loop、session log、tool pipeline、LLM adapters、Web RPC。桌面主题走 DSH 公开 token 名 + `data-pilot-*` DOM hooks，不上 CSS-module class（上游 slot/DOM 变更仍需视觉回归）。Models 页 = 现有 `@deepseek-ai/dsh-client-ui-settings-models` 插件；provider 走 `ctx.settings`，key 走 `ctx.credentials`，模型路由走 `ctx.llm`——**全是对接上游插件契约，不是桌面自有记录**。

## 安全设计（比预期扎实）

- **loopback-only URL 校验**（`server-url.test.ts`）：`https://127.0.0.1:3080` ❌、`http://0.0.0.0:3080` ❌、`http://example.com:3080` ❌、带 user:pass ❌——只接受 `http://127.0.0.1|localhost:<port>`
- **preload 极窄 IPC 面**：仅 6 个操作（restart / pickDirectory / showDataFolder / copyDiagnostics / setThemeSource / versions）。renderer context isolation + sandbox + Node integration disabled；新窗口走系统浏览器；权限请求默认拒绝
- **主题文件 0o600 + atomic rename**（main.ts `persistNativeThemeSource`）
- **e2e 防篡改**：launch 前删 `ELECTRON_RUN_AS_NODE`，防止 IDE 终端把 GUI 运行静默变成 Node 进程
- **已知限制诚实披露**：file-backed credential provider（OS keychain 是 follow-up）；macOS 未 notarize；Win/Linux 未签名

## 批评者信号（16 issues）

- **代理网络缺口**（Lokiscripter）：原生 DSH 可 `NODE_USE_ENV_PROXY=1` 解决代理，pilot-harness 没暴露该 env → 私有 DSH_HOME + 独立 spawn 让用户失去代理控制。**薄壳的 tradeoff：包装越干净，环境透传越难**
- **会话/配置导入缺失**（MaybeJustLikeThis）：下载后希望自动导入本地会话和插件配置 → 私有 DSH_HOME 隔离的代价
- **暗色模式异常**（LBEILC）+ CI 重复执行门禁（作者自己提的优化 issue）→ 项目仍在打磨期

## 生态位置：dsh 生态成型信号 🌱

**08-22~08-23 两天内 dsh 生态 6+ 项目批量冒头**（命中 ecosystem-formation-signal DNA 规则）：

| 项目 | 定位 | 信号 |
|---|---|---|
| [[deepseek-harness-pr-review]] | headless PR review（08-22 已深读） | 161 commits 高频迭代 |
| pilot-harness (本轮) | 桌面客户端 | 251⭐, 08-17 创建 3 天, 16 issues |
| dsh-image-gen | 聊天内生图 | 135⭐ |
| deepseek-harness-android-app | Android 端 | 84⭐, 外部贡献者 |
| dsh-hotplug-hub | 热插拔插件管理器（hotpack 概念） | 25⭐, **3 个外部贡献者**（YisfL×6/hzhz314159×2/wrdqtww×1） |
| dsh-tether | 手机远程连 dev 机器 | 已跟踪 |

**生态成型判断**（按 08-21 规则三要素）：
- **外部贡献者** ✅ dsh-hotplug-hub 3 外部作者 9 PRs merged
- **社区渠道** ✅ awesome-deepseek-harness 索引 181⭐ / 2805 条目 / 今天(08-23)仍在更新，pilot-harness 已被收录
- **发布节奏** ✅ 各项目多 release/天

→ **dsh 生态已从「单项目」进入「生态扩张期」**。深度命中打工第一优先级 dsh-plugin 方向。

## 与我们的关联

1. **薄壳架构模式**：Electron 只做原生层、业务全在上游插件树——映射我们「CLI 是运行时，UI 是薄壳」的工具设计思路（[[flowforge]] CLI-first 同理）
2. **DSH_HOME 私有隔离**：桌面发行版与系统安装互不污染，靠 env 覆盖而非 fork——**给上游贡献的方式 = 插件，不是 fork**（对我们的 dsh-plugin 打工策略是确认）
3. **安全基线可学**：loopback-only URL 校验 + 窄 IPC + 凭据脱敏日志 + 0o600 原子写——可直接移植到我们的本地工具
4. **代理/env 透传缺口**：包装层必须显式透传网络 env，否则企业/代理用户流失——这是 dsh 生态工具的共性问题，可能值得提 issue/PR

## 预测

- pilot-harness 3 天 251⭐，若 dsh 生态持续扩张 → 08-30 前过 500⭐（cal-0823-xxxx 待记）

## Tracking

- Revisit 08-27：桌面 release 稳定性（notarize/signing 进展）+ 会话导入 issue 是否被采纳 + 生态继续扩张与否

Links: [[deepseek-harness-pr-review]], [[dsh-tether]], [[deepseek-v4]], [[agent-harness-landscape]], [[flowforge]], [[ecosystem-formation-signal]]
