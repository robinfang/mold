---
version: 1
default_provider: codex-cli
default_quality: 2k
default_aspect_ratio: "16:9"
default_image_size: null
default_image_api_dialect: null
default_model:
  google: null
  openai: null
  azure: null
  openrouter: null
  dashscope: null
  zai: null
  minimax: null
  replicate: null
  codex-cli: "codex-image-gen"
batch:
  max_workers: 1
  provider_limits:
    codex-cli:
      concurrency: 1
      start_interval_ms: 2000
---
