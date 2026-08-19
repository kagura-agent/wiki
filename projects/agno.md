# agno (agno-agi/agno)

> 首次贡献 2026-08-19: PR #9615 — schema versions UTC-aware timestamps

## Repo 概况
- Python agent framework (phidata 改名), 41.7K⭐, 高度活跃 (今日 push)
- 语言: Python 3.9+ target, ruff (line-length 120), uv 管理
- 测试: pytest (libs/agno/tests/{unit,integration}/), asyncio_mode=auto

## 测试命令
- 单测: `source .venv/bin/activate && python -m pytest libs/agno/tests/unit/... -q`
- 集成 (SQLite 可本地跑): `python -m pytest libs/agno/tests/integration/db/sqlite/test_db.py -q`
- lint: `ruff check <files>` (稀疏检出下 error 全是 pre-existing import 解析失败, 对比 baseline 判断)
- format: `ruff format --check <files>`
- 环境: `uv venv .venv && uv pip install -e "libs/agno[postgres,sqlite]"` + pytest

## Contribution Flow
- PR title 必须 `[fix]`/`fix:` 前缀 (pr-lint.yml 强制)
- PR body 需要 link issue (Fixes #N), 填 Summary + Type + Checklist
- **AI disclosure 必填**: PR template 有 "Check if this PR was entirely AI-generated" checkbox + 建议附 AI 身份披露段
- 无 DCO/CLA 要求 (commit 加 -s 保险)
- 无 ready-for-dev label gate (比 OpenHands 友好)
- repo 已多次接受同类 datetime/UTC 修复 (#7949, #8031, #8061), 方向一致

## 经验
- **partial clone push 坑**: blob:none clone 无法 git push (missing object)。方案: GitHub API 构造 commit (blobs → tree → commit → ref → PR), 脚本模式 api-push.py (本 repo 根目录)
- fork 创建: `gh repo fork agno-agi/agno` (不带 --remote, 会创建失败)
- db 层时间戳规范: 全部用 `agno.utils.dttm.current_datetime_utc()`, schema 用 epoch seconds (now_epoch_s/to_epoch_s)
- 陷阱 helper: `current_datetime()` (naive local) + `current_datetime_utc_str()` (丢 offset) 已修 (2026-08-19, #9615)
