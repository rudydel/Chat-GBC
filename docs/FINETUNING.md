# Fine-tuning the Game Boy LLM

The model is trained in two phases by `llm/train.py`:

1. **Pre-training** – next-character prediction on the prose corpus and on
   the question/answer pairs formatted as conversations. Teaches spelling,
   the chat format and the vocabulary of the domain.
2. **Supervised fine-tuning (SFT)** – conversations only, loss on the answer
   characters (and a small weight on the question). Makes the model answer.

In both phases the questions are *augmented* on the fly (rephrased, shortened
to key words, typos, framing words added or dropped; `llm/augment.py`) and a
share of the hand written question variants is *held out* so the log can
report how the model does on phrasings it has never seen (section 3).

Both phases use *quantization-aware training*: every weight and activation
is rounded exactly as the Game Boy will round it (int7 values, power-of-two
scales, an int16 residual stream), so the exported integer model behaves
like the trained one (`llm/model.py`).

## 1. Train the shipped model from scratch

```bash
make train                     # == the command below
python3 -m llm.train --config configs/tiny.json --out models/tiny \
    --text data/gameboy/corpus --chat data/gameboy \
    --pretrain-steps 6000 --sft-steps 12000 --augment 0.5 --heldout 0.2 --eval-int
```

`--chat data/gameboy` picks up every `*.jsonl` in the folder: `facts.jsonl`
and `offtopic.jsonl` (generic questions that all map to "sorry, i only know
about the game boy", so the model learns where its knowledge ends instead of
inventing an answer).

Takes about 8 minutes on a 4-core laptop CPU (no GPU needed). The log ends
with the evaluation described in the next section, for the float model and
(`--eval-int`) for the bit-exact integer simulator.

## 2. Add facts and fine-tune

Edit `data/gameboy/facts.jsonl` (or create your own file with the same
format) and continue from the existing checkpoint:

```bash
make finetune SFT_STEPS=3000                 # all of data/gameboy/*.jsonl
make finetune CHAT="data/gameboy my_facts.jsonl" SFT_STEPS=3000
# == python3 -m llm.train --init models/tiny/ckpt.pt --out models/tiny --text data/gameboy/corpus \
#        --chat data/gameboy my_facts.jsonl --pretrain-steps 0 --sft-steps 3000 --augment 0.5 --heldout 0.2 --eval-int
```

Tips

* Keep answers short (the Game Boy prints ~1 character per 2.5 s) and use
  several question phrasings per fact; the model generalises across the
  phrasings it has seen, and the augmentation multiplies them.
* Keep `offtopic.jsonl` in the mix when you fine-tune on your own facts,
  otherwise the model forgets its fallback answer. A line can carry
  `"weight": 0.5` to be sampled half as often per variant (the off-topic
  lines do, so they make up about a fifth of the SFT samples).
* Only `a-z 0-9 space . , ? ! ' - : ( ) / & " ;` exist as characters;
  `llm/tokenizer.py` lower-cases and strips accents, everything else is dropped.
  On top of these characters the trainer learns `n_extra_tokens` subword
  tokens (words, word pieces, short phrases) from the corpus and the
  conversations before training starts; they are stored in the checkpoint,
  written to `<out>/vocab.json` and exported into the ROM. A fine-tuning run
  (`--init`) keeps the checkpoint's vocabulary.
* A 48k parameter model memorises a few hundred short facts. If recall
  drops when you add many more facts, use `configs/micro.json` (115k
  parameters; needs a 64 KiB SRAM cartridge, slower on a DMG) or train
  longer.
* `--question-loss 0.1` trains lightly on the questions too, which helps
  the model stay on topic when a user types something it has not seen.

## 3. Measure generalisation, not just recall

A model this small memorises whatever it is trained on, so the exact-match
rate on training questions says little about how it handles a question typed
by a user. The trainer therefore splits the question variants:

* `--heldout 0.2` keeps 20% of the variants (at least one) of every fact
  that has three or more variants out of training. The split is derived from
  `--seed`, so fine-tuning runs keep the same held-out questions. They are
  written to `<out>/heldout.jsonl`.
* `--heldout-chat test.jsonl` adds files that are used only for evaluation.

The final report (also in `train_log.txt`) shows, per source file:

```
[int] train questions: exact match 100%, char error rate 0.00 (80 questions)
    facts.jsonl          exact 100%  cer 0.00  (47)
    offtopic.jsonl       exact 100%  cer 0.00  (33)
[int] held-out questions: exact match 44%, char error rate 0.60 (144 questions)
    facts.jsonl          exact  32%  cer 0.74  (103)
    offtopic.jsonl       exact  73%  cer 0.24  (41)
  BAD q: release date of the game boy
      got: 12,500 yen in japan and 89.99 dollars in the us
      exp: april 21, 1989 in japan
```

*exact match* is the share of answers that equal the expected answer
character for character; *char error rate* is the edit distance divided by
the expected length (0 = perfect, about 1 = unrelated text) and gives partial
credit for near misses. Any checkpoint can be scored the same way, with the
float model or the integer simulator, and with `--bad` to list only the
failures:

```bash
make eval                                   # models/tiny, integer model, wrong answers only
python3 -m llm.evaluate models/tiny/ckpt.pt --chat data/gameboy --heldout 0.2 --int --bad
```

When you change the recipe, compare the held-out numbers between runs. The
question augmentation (`--augment`, default 0.5: the probability that a
training question is rephrased) exists for exactly this metric. Measured on
the character-level `tiny` model with the same split (float model): without
augmentation 12% of the held-out fact phrasings were answered exactly (char
error rate 1.12), with it 22% (0.83); the fallback on unseen off-topic
questions went from 78% to 85% and training recall stayed at 95-96%.
Switching to the 192-token subword vocabulary (same network, 12000 instead
of 6000 pre-training steps on the enlarged corpus) then took the held-out
facts to 32% in the integer model, with 100% training recall. The integer
model can be worse off-distribution than the float model because its
softmax and rounding are approximations that quantization-aware training
does not model, so judge with `--eval-int` before flashing.

## 4. Pre-train on Game Boy history from the web

`data/gameboy/scripts/fetch_web.py` downloads ~40 Wikipedia articles about
the Game Boy family, its designers, its games and its competitors through
the MediaWiki API and writes cleaned plain text to `data/gameboy/wiki/`:

```bash
python3 data/gameboy/scripts/fetch_web.py
python3 -m llm.train --config configs/tiny.json --out models/tiny \
    --text data/gameboy/corpus data/gameboy/wiki --chat data/gameboy \
    --pretrain-steps 20000 --sft-steps 6000 --chat-weight 0.3
```

With ~1 MB of text, use more pre-training steps and a lower `--chat-weight`
so the model sees mostly prose during pre-training. The SFT phase then
teaches it the answer format. (Wikipedia text is CC BY-SA 4.0.)

Turning web text into new question/answer pairs is a manual or LLM-assisted
step: extract facts from `wiki/*.txt`, write them as short answers with a
few question variants each, and append them to a `.jsonl` file.

## 5. Check the result before flashing

```bash
python3 -m llm.chat models/tiny/ckpt.pt -q "who designed the game boy"          # float model
python3 -m llm.chat models/tiny/ckpt.pt --int -q "who designed the game boy"    # what the Game Boy computes
make rom && make test                                                          # build + run in PyBoy
```

The integer simulator (`llm/simulate.py`) is bit-exact with the ROM; if the
answer looks right there, it will look the same on the console.

## 6. Model configurations

| config | params | d_model | layers | heads | d_ff | ctx | vocab | ROM / SRAM | s/char on DMG | exact match train / held-out (int) |
|--------|--------|---------|--------|-------|------|-----|-------|------------|---------------|------------------------------------|
| nano   | 28k    | 32      | 2      | 2     | 64   | 96  | 128   | 128 KiB / 32 KiB | ~0.5 | (not trained) |
| tiny   | 62k    | 48      | 2      | 3     | 96   | 128 | 192   | 128 KiB / 32 KiB | ~0.9 | 100% / 44% (facts 32%, off-topic 73%) |
| micro  | 146k   | 64      | 3      | 4     | 128  | 112 | 255   | 256 KiB / 128 KiB | ~2 | (retraining with the 238-token vocabulary) |

`vocab` is the base of 54 characters plus `n_extra_tokens` learned subword
tokens; with ~2.4 characters per token, the seconds per character are about
a third of what the same network needs with a character vocabulary (measured
in PyBoy: the tiny reply "april 21, 1989 in japan" takes 17.6 s of Game Boy
time including the question, against 37 s for the shorter "hello! ask me
about the game boy" with the old character-level tiny model).

`micro` needs 6 SRAM banks; the cartridge header declares 128 KiB because
the header only encodes 8, 32 or 128 KiB. Both trained models are in
`models/`; `gb/build/chatgbc-micro.gb` is the prebuilt micro ROM.

Constraints (checked by `ModelConfig.validate`): head size is 16, `d_model`,
`d_ff` and `ctx` are multiples of 16, at most 8 layers, and one layer's K or
V cache plus its row sums must fit an 8 KiB SRAM bank (`ctx * d_model` ≤
roughly 7.5 KiB, e.g. ctx 128 at d_model 48, ctx 112 at d_model 64).

## 7. Hyper-parameters

| flag | default | meaning |
|------|---------|---------|
| `--pretrain-steps` | 3000 | phase 1 steps (batch × ctx characters each) |
| `--sft-steps` | 2000 | phase 2 steps |
| `--batch` | 32 | sequences per step |
| `--lr`, `--sft-lr` | 1e-2, 6e-3 | peak learning rates (cosine decay, 100 warm-up steps) |
| `--chat-weight` | 0.5 | share of conversation windows during pre-training |
| `--question-loss` | 0.1 | loss weight on question characters during SFT |
| `--augment` | 0.5 | probability that a training question is rephrased on the fly (`llm/augment.py`) |
| `--heldout` | 0.2 | share of each fact's question variants kept out of training for evaluation |
| `--heldout-chat` | – | extra `*.jsonl` files used only for evaluation |
| `--eval-int` | off | also evaluate the bit-exact integer simulator (what the ROM prints) |

These tiny models want a *high* learning rate: with 3e-3 the same model
plateaus at ~1.0 nats/character and answers with gibberish, with 1e-2 it
memorises the fact base (measured: 0% vs 60–70% exact recall after 2500
fine-tuning steps for `tiny`; `micro` reaches 95%; the un-quantized `tiny`
architecture 100%). If recall is low, raise the learning rate or train
longer before enlarging the model.
