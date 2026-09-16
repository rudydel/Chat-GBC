# Models

Each sub-directory holds one trained model:

| File | Content |
|------|---------|
| `ckpt.pt` | PyTorch checkpoint (config + quantization-aware weights) |
| `config.json` | the model configuration it was trained with |
| `model_int.json` | the integer model as exported for the ROM (used by `llm/simulate.py` and the emulator tests) |
| `train_log.txt` | training log with the final evaluation (exact match / char error rate on training and held-out questions) |
| `heldout.jsonl` | the question variants that were kept out of training and used for the held-out evaluation |
| `vocab.json` | the learned subword tokens (ids 54..), also stored inside `ckpt.pt` and `model_int.json` |

`models/tiny` is the model built into `gb/build/chatgbc.gb`. Build a ROM
from any other model with `make rom MODEL=<name>`.
