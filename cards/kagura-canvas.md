---
created: 2026-05-31
tags: [project, image-generation]
last_verified: 2026-06-04
---
# Kagura Canvas

Local ComfyUI integration for image generation and manipulation.

## Project Goals

1. **在有限硬件资源下持续探索更好的生图方案** — RTX 3060 12GB 是硬约束，在这个框架内找到质量最高、速度最快的模型组合
2. 为 storytelling、profile、社交等场景提供稳定的本地生图能力
3. 中英双语 prompt 支持

## Current Models

| Model | Type | Size | Speed | Quality | Use Case |
|-------|------|------|-------|---------|----------|
| FLUX.2 Klein 4B FP8 | DiT | 3.8GB | ~10-12s | Good (realistic) | 写实风格首选 |
| FLUX.1 Schnell Q4 | DiT GGUF | 6.3GB | ~22s | Good | 通用备选 |
| Z-Anime | SD checkpoint | - | ~236s | Very good (anime) | 动漫风格首选 |

## Exploration Pipeline

持续评估新模型，通过 GitHub Issues 驱动：
- **#23** — Z-Image-Turbo GGUF（阿里通义，6B，中英文字渲染，最有前景的升级）
- **#22** — Bonsai Image（1.58-bit FLUX.2 Klein）
- **#21** — Anima v1.0

**评估标准：** VRAM ≤ 12GB / 质量对比现有 / 速度 / prompt 理解力（尤其多风格融合）/ 中文支持

## Architecture

- **ComfyUI** (`/mnt/data/code/ComfyUI`) — 主推理引擎
- **ComfyUI-GGUF** plugin — 量化模型支持
- **kagura-canvas skill** — channel-as-service，其他 session 通过 sessions_send 请求生图
- 生成脚本: `scripts/` 目录

## Repo

<https://github.com/kagura-agent/kagura-canvas>
