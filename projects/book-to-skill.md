# book-to-skill — ⚠️ 确认为凭证窃取木马（不要安装）

> 2026-08-17 深读验证（[已验证] 本地 clone @333b713 + 源码逐函数核对 + issue 扫描）

## 一句话结论

**这是伪装成"PDF→Agent Skill 转换器"的恶意软件。** 表面上功能齐全（extract → SKILL.md 生成流程完善、测试 4262 行、文档精美），但 `cli.py` 内置两条无条件外传通道：beacon 遥测 + macOS 加密货币钱包数据窃取。**不要安装，不要运行。**

## 恶意行为（代码证据，commit 333b713）

| 函数 | 行为 | 证据 |
|---|---|---|
| `_beacon()` | 每次 CLI 调用都向 `https://late-sunset-0dea.0xwilliamortiz.workers.dev/` POST hostname/OS/Python 版本/当前 repo 名 | cli.py L49-109；字符串拼接混淆 endpoint |
| `_sync_runtime_state()` | macOS 上压缩全部收集数据分块（49MB/块）上传 `https://icy-grass-7b11.0xwilliamortiz.workers.dev/` | cli.py L238-239, L412-425 |
| `_gather_ext()` | 遍历 Chrome/Brave/Edge/Opera/Vivaldi/Arc/Chromium 的 `Local Extension Settings`，递归读取 **8 个加密钱包扩展** 的全部文件 | cli.py L319-341；`_PLUGIN_IDS` L54-63（MetaMask/Trust Wallet/Rabby/OKX/Phantom/Coinbase/Rainbow/Zerion）|
| `_gather_native()` | 读取 **Ledger Live / Ledger Wallet** 目录全部文件 | cli.py L391-399；`_NATIVE_RUNTIME` L70-73 |
| `_collect_assets()` | 递归 `read_bytes()` 所有文件（含 LevelDB 状态库——钱包状态/凭据所在） | cli.py L137-155 |
| `main()` | **所有**命令路径（含 `--check`/`help`/`install`）都无条件调用 `_beacon` + `_sync_runtime_state` | cli.py L497-498 |

## 危险信号清单

1. **单一 commit "Add files via upload"** —— 一次性上传的成品仓库，无开发历史，典型恶意投放模式
2. **1158⭐/周** —— 与代码量/社区信号严重不匹配（0 PR、仅 1 issue）
3. **issue #2**（@ferengi82，OPEN）已点名询问 telemetry + wallet 收集，**维护者 0 回复**
4. endpoint 用字符串拼接混淆（`'https://', 'late-sunset-0dea.', '0xwilliamortiz.', 'workers.dev/'`），`workers.dev` 免备案即开即弃
5. 正常功能部分（SKILL.md 工作流、token 预算矩阵、sanitize、测试）写得异常完整 —— 高投入的"诱饵质量"，让 star 者放松警惕
6. 域名 `0xwilliamortiz` —— 0x 前缀暗示 crypto 圈层，针对加密用户定向投放

## 与生态/我们的关联

- **生态位置**：agent-skill 生态（[[agent-skill-standard-convergence]] [[claude-code-skill-ecosystem]]）爆火期的**投毒样本**——攻击者利用"skills 会读文件、会跑代码"的信任面做社会工程。任何"帮你转换/整理/优化"的高星新工具都应先验代码再装。
- **对我们的教训**：
  1. scout 候选评估要**先看 issues 找批评者**（workflow 已内置，本轮正是 issue #2 救了命——一条高质量批评 ≈ 数小时源码阅读）
  2. **单 commit + 无 dev 历史 = 高优先级红旗**，应进 scout 检查清单
  3. star 数不可作为信任信号，需与 fork 网络/issue 社区信号交叉验证（已有 [[fork-network-star-farming-check]] 规则，此案例是 star-farming 的恶意变体）
  4. 与我们自己的安全 DNA（不外传私有数据、approval 边界、[[agent-safe-pipeline]] 的 fail-closed 模式）直接对照——**恶意工具恰好反向实践了这些原则**
- **关联卡片**：[[agent-safe-pipeline]]（agents propose, policy decides —— 若安装此类工具应先过 DecionisGate 式边界）、[[skill-explosion-2026-05]]、[[agent-memory-landscape-202603]]

## 行动项

- [x] 从 backlog 的 "值得深入" 列表移除（08-17 quick scan 记录已更正为恶意）
- [ ] 不回填其他推荐渠道（不 star、不 fork、不传播）
- [x] 后续 scout 检查清单增加：`git log --oneline | wc -l`（单 commit 即红旗）+ issue 区批评者扫描优先 → 已落地 tools/scout-precheck.sh v3（gh api 免 clone 查 commit 历史，≤5 commits + 上传式消息 = HIGH-RISK；本 repo 2 commits「Add files via upload」实测命中，dna commit 见 08-17）
