---
created: 2026-06-02
last_verified: 2026-06-03
---
# Bonsai Image 4B

Ternary/1-bit quantization research applied to image generation models. The name references "bonsai" pruning — extreme weight compression while preserving output quality.

## Relevance

[[flux2-klein]] (FLUX.2 Klein 4B) is a natural base model for bonsai-style quantization experiments due to its already-compact 4B parameter count and FP8 availability. Ternary quantization could further reduce VRAM from ~9.4 GB to under 4 GB, enabling deployment on lower-end GPUs.

## Key Concepts

- **Ternary weights**: {-1, 0, +1} instead of FP16/FP8, massive compression
- **1-bit LLMs** (BitNet): Microsoft Research showed viability for language models; image diffusion is less explored
- **Trade-off**: Quality degradation vs. VRAM savings — acceptable for draft/preview, not for final output

## Status

Research/experimental. No production-ready ternary diffusion models as of mid-2026.

## See Also

- [[bonsai-image]] — project note on ternary/1-bit quantization for image models
- [[flux2-klein]] — base model for bonsai experiments
