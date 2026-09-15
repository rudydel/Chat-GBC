# Fine-tuning the Game Boy LLM

The model is trained in two phases by `llm/train.py`:

1. **Pre-training** – next-character prediction on the prose corpus and on
   the question/answer pairs formatted as conversations. Teaches spelling,
   the chat format and the vocabulary of the domain.
2. **Supervised fine-tuning (SFT)** – conversations only, loss on the answer
   characters (and a small weight on the question). Makes the model answer.

Both phases use *quantization-aware training*: every weight and activation
is rounded exactly as the Game Boy will round it (int7 values, power-of-two
scales, an int16 residual stream), so the exported integer model behaves
like the trained one (`llm/model.py`).

## 1. Train the shipped model from scratch

```bash
make train                     # == the command below
python3 -m llm.train --config configs/tiny.json --out models/tiny \
    --text data/gameboy/corpus --chat data/gameboy/facts.jsonl \
    --pretrain-steps 8000 --sft-steps 6000
```

Takes about 8 minutes on a 4-core laptop CPU (no GPU needed). The log and a
"fact recall" score (exact-match rate on training questions with greedy
decoding) are written to `models/tiny/train_log.txt`.

## 2. Add facts and fine-tune

Edit `data/gameboy/facts.jsonl` (or create your own file with the same
format) and continue from the existing checkpoint:

```bash
make finetune CHAT=data/gameboy/facts.jsonl SFT_STEPS=3000
# == python3 -m llm.train --init models/tiny/ckpt.pt --out models/tiny \
#        --text data/gameboy/corpus --chat data/gameboy/facts.jsonl --pretrain-steps 0 --sft-steps 3000
```

Tips

* Keep answers short (the Game Boy prints ~1 character per 2.5 s) and use
  several question phrasings per fact; the model generalises across the
  phrasings it has seen.
* Only `a-z 0-9 space . , ? ! ' - : ( ) / & " ;` exist in the vocabulary;
  `llm/tokenizer.py` lower-cases and strips accents, everything else is dropped.
* A 48k parameter model memorises a few hundred short facts. If recall
  drops when you add many more facts, use `configs/micro.json` (115k
  parameters; needs a 64 KiB SRAM cartridge, slower on a DMG) or train
  longer.
* `--question-loss 0.2` trains lightly on the questions too, which helps
  the model stay on topic when a user types something it has not seen.

## 3. Pre-train on Game Boy history from the web

`data/gameboy/scripts/fetch_web.py` downloads ~40 Wikipedia articles about
the Game Boy family, its designers, its games and its competitors through
the MediaWiki API and writes cleaned plain text to `data/gameboy/wiki/`:

```bash
python3 data/gameboy/scripts/fetch_web.py
python3 -m llm.train --config configs/tiny.json --out models/tiny \
    --text data/gameboy/corpus data/gameboy/wiki --chat data/gameboy/facts.jsonl \
    --pretrain-steps 20000 --sft-steps 6000 --chat-weight 0.3
```

With ~1 MB of text, use more pre-training steps and a lower `--chat-weight`
so the model sees mostly prose during pre-training. The SFT phase then
teaches it the answer format. (Wikipedia text is CC BY-SA 4.0.)

Turning web text into new question/answer pairs is a manual or LLM-assisted
step: extract facts from `wiki/*.txt`, write them as short answers with a
few question variants each, and append them to a `.jsonl` file.

## 4. Check the result before flashing

```bash
python3 -m llm.chat models/tiny/ckpt.pt -q "who designed the game boy"          # float model
python3 -m llm.chat models/tiny/ckpt.pt --int -q "who designed the game boy"    # what the Game Boy computes
make rom && make test                                                          # build + run in PyBoy
```

The integer simulator (`llm/simulate.py`) is bit-exact with the ROM; if the
answer looks right there, it will look the same on the console.

## 5. Model configurations

| config | params | d_model | layers | heads | d_ff | ctx | SRAM | s/char on DMG (approx.) |
|--------|--------|---------|--------|-------|------|-----|------|------------------------|
| nano   | 23k    | 32      | 2      | 2     | 64   | 96  | 32 KiB | ~1.2 |
| tiny   | 48k    | 48      | 2      | 3     | 96   | 128 | 32 KiB | ~2.5 |
| micro  | 114k   | 64      | 3      | 4     | 128  | 128 | 64 KiB | ~6 |

Constraints (checked by `ModelConfig.validate`): head size is 16, `d_model`,
`d_ff` and `ctx` are multiples of 16, `ctx` ≤ 256, at most 8 layers.

## 6. Hyper-parameters

| flag | default | meaning |
|------|---------|---------|
| `--pretrain-steps` | 3000 | phase 1 steps (batch × ctx characters each) |
| `--sft-steps` | 2000 | phase 2 steps |
| `--batch` | 32 | sequences per step |
| `--lr`, `--sft-lr` | 3e-3, 1.5e-3 | peak learning rates (cosine decay, 100 warm-up steps) |
| `--chat-weight` | 0.5 | share of conversation windows during pre-training |
| `--question-loss` | 0.2 | loss weight on question characters during SFT |
