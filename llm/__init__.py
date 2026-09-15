"""Chat-GBC: a nano transformer language model that runs on a Game Boy.

Sub-modules:
  tokenizer  - fixed character-level vocabulary shared with the ROM
  quant      - integer inference specification (shared constants + helpers)
  model      - PyTorch quantization-aware training model
  data       - corpus / chat dataset loading and formatting
  train      - pre-training and fine-tuning CLI
  export     - checkpoint -> C sources for the Game Boy ROM
  simulate   - bit-exact integer reference of the ROM inference code
  chat       - talk to a checkpoint from the terminal
"""
