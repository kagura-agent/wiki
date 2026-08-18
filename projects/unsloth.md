# unslothai/unsloth

- **方向**: LLM fine-tuning 库 + Unsloth Studio 桌面应用（Tauri + Python backend + React frontend）
- **语言**: Python (backend/studio) + TS (frontend) + Rust (src-tauri)
- **活跃度**: 极高（每日多 commit），maintainer danielhanchen 主导 merge
- **Merge rate**: gogetajob 记录 88% (50 PRs analyzed)，但最近 50 merged PRs 中 47 个是 danielhanchen 自己的 — 外部 PR 能 merge（有 3 个外部例子），但主要靠 maintainer 自产
- **外部 PR 现状**: Studio app 有活跃外部贡献潮（2026-08-17~18 大量外部 PR open 中），说明 Studio 子项目接受外部 PR

## Contribution Flow

- 无 DCO/CLA/changeset 要求（CONTRIBUTING.md 只有"focused single change + link issue"）
- 无 claim issue 流程要求
- PR 描述: 简洁 + motivation + link issue
- 首次 PR 需 AI disclosure（见 guide）

## 代码结构（Studio）

- `studio/backend/` — Python FastAPI backend
- `studio/backend/utils/hardware/` — GPU 检测: `hardware.py`（主模块）、`nvidia.py`、`amd.py`（amd-smi）、`apple.py`、`vram_estimation.py`
- `studio/backend/core/training/worker.py` — `_rocm_classify_unified_memory()`（APU 分类器: is_integrated → gfx1150/51/52 → 名称表）
- `studio/frontend/src/features/settings/tabs/about-tab.tsx` — About 页硬件显示（gpus 列表）
- `/api/system/hardware?include_details=true` → `get_backend_visible_gpu_info()` → `_torch_get_device_inventory()`

## 关键机制（VRAM 检测）

- **ROCm APU carve-out vs GTT**: `props.total_memory` = 专用 carve-out（小）；`mem_get_info` total = GTT/shared pool（大）。`_torch_get_device_inventory` 对 unified-memory APU 用 GTT total（避免 Strix Halo 128GB 被预算成 8GB）
- **Hybrid 主机陷阱（#8942 教训）**: dGPU + iGPU 并存时，iGPU 被分类为 unified（is_integrated）→ 显示 GTT 池（= 系统内存份额，虚高）。修复: hybrid 集合（同时有 integrated + discrete）中 integrated 设备保留 carve-out（真实专用显存）。2026-08-18 提 PR
- **测试**: `tests/test_system_poll_no_cuda_context.py`（inventory 测试，含 ROCm hybrid/APU-only/discrete 用例）；`tests/test_amd_apu_unified_memory.py`；`tests/test_rocm_oom_guard.py`
- **本地测试**: `cd studio/backend && python3 -m pytest tests/<file> -q`（需 loggers/structlog stub，test_system_poll 自带；structlog 本机未装）

## 踩过的坑

- 本机无 GPU/structlog 不完整 → 部分测试（transformers AutoModel 类）环境性失败，与改动无关
- 仓库 200MB → 用 `git clone --filter=blob:none`（rule #20）
- ruff format 与本地 0.16.1 默认不一致（repo 用 `key = value` 风格）→ 跟随 repo 风格，不跑 format

## 状态

- 2026-08-18: #8942 AMD iGPU VRAM overinflated — hybrid ROCm fix（`_torch_get_device_inventory`），PR 待 review
