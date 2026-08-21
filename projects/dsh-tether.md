# DSH Tether — 手机直连 DeepSeek Harness 的 P2P 遥控线

Links: [[dscode]], [[agent-harness-landscape]], [[deepseek-v4]], [[bossconsole-jvm-harness]], [[single-writer-spawn-ledger]]

> zexadev/dsh-tether · 11⭐ · MIT · Rust sidecar + Tauri Android + JS plugin · created 2026-08-18 前后, 独立社区项目（README 明确声明非 DeepSeek 官方）

## TL;DR

把 deepseek-harness 的 web UI 通过 **iroh P2P 直连**（NAT 打洞）带到手机——不部署 relay、不要求同一 Wi-Fi、不重新实现界面。电脑侧是 dsh plugin（`dsh-plugin-tether`，sidecar 内嵌 iroh endpoint），手机侧是 Tauri Android app，两端配对一次后自动互找。审批事件推送到手机系统通知，但**通知通道绝不代答**——手机跑的是 dsh 自己的 web UI，答案是用户在浏览器里给的。

## 架构（956 行 Rust + 一个 JS 插件）

```
phone (Tauri app) ⇄ iroh P2P (QUIC/TLS, hole-punch) ⇄ host sidecar (Rust) ⇄ dsh web (loopback)
     │                                                    │
     └─ 控制流: JSON-lines bi-stream (Hello/Pair/Proxy)    └─ 代理流: 首行 {"type":"proxy"} 后整条流原始 TCP
```

- **tether-core**（78 行协议基元）：Wire enum（Hello/Pair/Proxy/PairOk/PairFail/Approval/ApprovalCancel/Decision）+ `read_line_bounded` 有界读。`MAX_UNPAIRED_LINE=512` —— 未配对方只给一条 pair 消息的字节预算，不给未授权方喂大负载的机会；配对后放宽到 64KB（审批 reason 是模型生成的自然语言）。
- **host**（547 行）：配对白名单落盘（iroh public key）、配对窗口（10 分钟、3 次尝试、错 3 次关窗）、连接注册 + mpsc 下行、proxy_acceptor 带 64 并发信号量、NAT 打洞 8 秒升级窗口（避免把「还没打通」误报成「打不通」）。
- **app**（331 行 Tauri）：`remote:approval` 事件 → 系统通知；`start_proxy` 起本地 TCP 监听、每条连接开一条 iroh 代理流。
- **index.js**（插件）：`inject: ['webServer', 'settings']`，spawn sidecar，`--proxy-target <host>:<port>`。**审批只观察后 next()**，不认领——注释明说认领会把请求从浏览器手里抢走。

## 关键设计决策（反直觉/可迁移）

1. **通知 ≠ 代答（attention surface 与 decision surface 分离）**。插件把 approval/request 转发给手机只为系统通知「agent 在等你」，答案永远在 dsh 自己的 UI 里给。移动端不可替代的部分是**人不在电脑前时知道 agent 卡住了**，不是远程批准。→ 映射我们的 Cove/heartbeat：通知通道永远不该变成行动通道。
2. **浏览器信任栅栏 + 明说设计边界**。`isTrustedRequest` 复刻 dsh `/api` 的判据（Host 必须回环权威、cross-site 标记拒、Origin 与 Host 匹配），挡 DNS rebinding 和恶意跨站页面；但注释和 README 都**明确声明挡不住本机进程**——本机 curl 的 Host 就是回环，可以自铸配对码把自己配成「手机」。README 直接写「Don't run this plugin on a machine where you run untrusted code」。诚实边界比假装安全更有价值。
3. **未授权字节预算**（512B）：控制流首行给未配对方的预算只够一条 pair 消息。最小暴露面原则的具体实现。
4. **配对码是引导不是凭证**：6 位 CSPRNG 码只用于首次配对，配对后访问权由 iroh public key 决定（TLS 验证、不可伪造）。短窗口 + 限次 = 暴力空间 1e6 里只许猜 3 次。
5. **cordis.patch.yml 的 name 是断言不是覆盖**：patch 里 `name:` 不匹配上游实现则整条跳过（fail loud），防上游换实现时静默错配。→ 直接对应我们的 tool-filter-silently-ignored 问题：**静默错配比报错更危险**。
6. **窄屏 CSS 只用语义选择器**（role/aria），不碰 dsh 的 CSS Module 哈希类名——「针对内容哈希类名写规则必碎」。
7. **代理流协议极简**：首行 `{"type":"proxy"}` 之后整条流是原始字节，无二次封装。控制面 JSON、数据面裸字节——和我们 FlowForge「Manager protocol deliberately JSON-free」同族的设计品味。

## 与 dsh 生态 / 我们方向的关系

- **打工第一优先级 dsh-plugin 生态的直接样本**：这是 deepseek-harness 插件组合层（cordis patch + inject 点 + sidecar）的真实用法，展示了一个「插件 = 组合层补丁 + sidecar + 窄屏适配」的完整形态。
- **远程控制的信任边界模板**：我们在做 Cove/OpenClaw 的审批与心跳通知，dsh-tether 的「通知不代答 + 回环栅栏 + 明确的本机进程边界」是现成的安全姿态参考。
- **P2P 直连替代 relay**：我们的 VM1/VM2 服务都是中心化部署；iroh 打洞对「本地 agent 远程可达」场景是另一种思路（但 11⭐ 太早，watch 不投资）。

## 红旗 / 边界

- 无 test 目录、无 issues（11⭐ 新项目，无外部验证）。
- 已知限制自述：本机可执行代码的攻击者可自铸配对码获长期访问。
- solo dev（zexa，全部提交），日更但生命周期短。

## Links

- [[dscode]] — DeepSeek-first harness 另一形态（多 provider coding agent）；dsh-tether 是 dsh 生态的移动端延伸
- [[agent-harness-landscape]] — 生态位：harness 的远程可达层（P2P 隧道），不是 harness 本身
- [[bossconsole-jvm-harness]] — 同为 sidecar + 协议边界设计，可对比 gRPC IPC vs iroh QUIC
- [[deepseek-v4]] — dsh 上游模型/生态背景
