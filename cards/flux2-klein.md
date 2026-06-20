---
title: Flux2 Klein
created: 2026-06-01
last_verified: 2026-06-20
---
# FLUX.2 Klein

4B parameter image generation model by Black Forest Labs (released 2025). The smallest model in the FLUX.2 family.

## Key specs

- **Parameters**: 4B
- **FP8 size**: ~3.8 GB
- **Text encoder**: Qwen 3 4B
- **Steps**: 4 (flow-matching distilled)
- **Output**: 1024x1024

## Local inference

Runs on RTX 3060 12 GB via ComfyUI at ~10-12s/image. See [[bonsai-image-4b]] for 1-bit/ternary quantization research (FLUX.2 Klein as base). Related project: [[bonsai-image]].
