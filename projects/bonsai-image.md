# Bonsai Image 4B — 1-bit/Ternary Image Generation

> PrismML's extreme quantization of [[flux2-klein]] for local devices. Announced June 2026. 336pts on HN.

## What It Is

Binary and ternary quantized versions of FLUX.2 Klein 4B, the same model I use for local image generation. Compresses the diffusion transformer from 7.75GB (FP16) to 0.93GB (1-bit) or 1.21GB (ternary).

## Key Numbers

| Model | Transformer Size | vs FP16 | Mean Active Memory (1024×1024) |
|---|---|---|---|
| FLUX.2 Klein 4B (FP16) | 7.75 GB | 1.0× | 14.39 GB |
| Ternary Bonsai | 1.21 GB | 6.4× smaller | 2.38 GB |
| 1-bit Bonsai | 0.93 GB | 8.3× smaller | 1.95 GB |

Full deployment payload (including text encoder + VAE): 3.42GB (1-bit) / 3.88GB (ternary) on Apple Silicon.

## How It Works

- Binary weights: {-1, +1} with FP16 group-wise scaling (1.125 effective bits/weight)
- Ternary weights: {-1, 0, +1} with FP16 group-wise scaling (1.71 effective bits/weight)
- ~5% of precision-sensitive projection layers remain FP16
- Architecture is unchanged from [[flux2-klein]] — only weight representation changes

## Deployment Stack

- **Apple Silicon**: MLX with low-bit kernels
- **CUDA GPU**: Gemlite low-bit GEMM kernels (via diffusers pipeline)
- **No ComfyUI integration yet** — requires custom nodes for gemlite quantized models
- HuggingFace: `prism-ml/bonsai-image-ternary-4B-gemlite-2bit`, `prism-ml/bonsai-image-binary-4B-gemlite-1bit`
- Library: diffusers (not GGUF/llama.cpp like their LLM models)

## Performance

- iPhone 17 Pro Max: 512×512 in 9.4s
- Mac M4 Pro: 512×512 in ~6s, up to 5.6× faster than stock FLUX.2 Klein
- CUDA benchmarks: not published yet

## Relevance to My Setup

I run [[flux2-klein]] FP8 (3.8GB) on RTX 3060 12GB via ComfyUI:
- Current: ~10-12s/image (1024×1024, 4 steps)
- Bonsai ternary would drop transformer from 3.8GB to 1.21GB — major VRAM savings
- **Blocker**: No ComfyUI integration. Model uses diffusers + gemlite, not GGUF
- **Action**: Worth testing via diffusers pipeline when ComfyUI or GGUF support appears
- Could free VRAM for larger batch sizes or higher resolution

## Ecosystem Position

- Part of PrismML's broader Bonsai family (also has 1-bit LLMs: 1.7B, 4B, 8B)
- LLM Bonsai models: 842⭐ demo repo, llama.cpp Q1_0 support merged upstream
- Image Bonsai: brand new (0 HF downloads), ecosystem integration nascent
- Trend: extreme quantization moving from LLMs → diffusion models
- Related: [[mechanism-vs-evolution]] — this is mechanism-level compression, enables evolution of where models can run

## Assessment

**Signal strength: High.** This is infrastructure-level change — making FLUX.2 Klein viable on phones. For me specifically: could significantly improve my local image gen workflow once ComfyUI/GGUF integration exists.

**Watch for**: ComfyUI custom nodes, GGUF format support (their LLM models already have GGUF, image model format may follow), community benchmarks on CUDA.

---
*Created: 2026-06-01 | Source: prismml.com, GitHub PrismML-Eng/Bonsai-demo*
