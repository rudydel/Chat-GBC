# Chat-GBC: a nano LLM that runs on a Game Boy

Chat-GBC is a complete pipeline for putting a (very) small transformer
language model on an original 1989 Game Boy and chatting with it through an
on-screen keyboard:

```
   PyTorch                       Python                         GBDK-2020
 ┌──────────────┐  ckpt.pt   ┌──────────────┐  gen/*.c, *.s  ┌───────────────┐
 │ llm/train.py │ ─────────► │ llm/export.py│ ─────────────► │ gb/ (C + asm) │ ──► chatgbc.gb
 │ QAT nano-GPT │            │ int7 weights │                │ SM83 inference│
 └──────────────┘            └──────────────┘                └───────────────┘
        ▲                            │ model_int.json                 │
  data/gameboy/                      ▼                               ▼
  facts.jsonl, corpus/        llm/simulate.py  ◄── bit-exact ──►  PyBoy emulator
                             (integer reference)                 (tools/emu_test.py)
```

* **`gb/`** – the Game Boy ROM: a 2-layer transformer with int7 weights, a
  table-lookup dot product in hand written SM83 assembly (the CPU has no
  multiply instruction), a KV cache in cartridge SRAM, and a chat UI with a
  D-pad keyboard. Runs on a DMG, Game Boy Pocket/Light/Color and any
  emulator; uses an MBC5 + RAM cartridge (flash carts are fine).
* **`llm/`** – the Python side: subword tokenizer (learned from the data,
  greedy longest match, mirrored in C), quantization-aware
  training (`train.py`), export to C (`export.py`), a bit-exact integer
  simulator of the ROM (`simulate.py`), and a terminal chat.
* **`data/gameboy/`** – a curated Game Boy fact base (405 question/answer
  pairs), prose for pre-training, and a script that pulls related Wikipedia
  articles for more text.
* **`tools/`** – emulator based tests that type on the virtual keyboard and
  compare the ROM's answer with the simulator, character for character.

The shipped model (`models/tiny`, 62k parameters, 192-token subword
vocabulary) answers questions about the history and hardware of the Game
Boy at roughly one second per character on an original Game Boy (a token of
two or three characters every ~2 s; half that on a Game Boy Color). It
reproduces 100% of its training questions verbatim, answers 32% of held-out
phrasings it never saw and declines 73% of unseen off-topic questions with
"sorry, i only know about the game boy" (`models/tiny/train_log.txt`), and
the emulator test confirms the console prints exactly what the Python
simulator predicts.

```
> who designed the game boy          > what cpu does the game boy use
< gunpei yokoi and nintendo r&d1     < a sharp lr35902, an 8-bit chip similar to the z80
```

## Quick start

```bash
make setup                # pip install -r requirements.txt, download GBDK-2020 to tools/gbdk
make rom                  # export models/tiny/ckpt.pt -> gb/gen/*, build gb/build/chatgbc.gb
make test                 # run the ROM in PyBoy, type a question, check it against the simulator
```

Load `gb/build/chatgbc.gb` in any Game Boy emulator (SameBoy, BGB, mGBA,
Gambatte, OpenEmu, PyBoy) or on a flash cartridge. It runs in Game Boy Color
mode on a GBC / GBC emulator and in monochrome on an original Game Boy.

The ROM starts on a title screen with a small menu: **new chat**, **chat
history** (every question and answer of the session, scrollable) and
**credits**; **D-pad** up/down and **A** or **START** pick an entry.

Controls in the chat: **D-pad** move over the keyboard, **A** press a key,
**B** backspace (or stop a reply; with an empty prompt: back to the menu),
**START** send, **SELECT** toggle greedy / sampled replies. Each question
starts a fresh context (build with `make -C gb EXTRA_CFLAGS=-Wf-DKEEP_CONTEXT`
for multi-turn conversations).

## Rebuilding after the model changed

The ROM is regenerated from a checkpoint in one step:

```bash
python3 -m llm.export models/tiny/ckpt.pt   # writes gb/gen/* and models/tiny/model_int.json
make -C gb                                  # -> gb/build/chatgbc.gb
```

or simply `make rom` (`MODEL=micro` for the larger 136k-parameter model,
prebuilt as `gb/build/chatgbc-micro.gb`: 40% of held-out phrasings and 80%
of unseen off-topic questions right against 32% / 73% for tiny, about twice
as slow, needs a 128 KiB-SRAM cartridge; `MODEL=nano` for the smallest).
`make test` then drives the ROM in an emulator and verifies that the
Game Boy produces exactly the same characters as the Python simulator.

## Training and fine-tuning

```bash
make train                       # pre-train + fine-tune configs/tiny.json on data/gameboy
make finetune CHAT="data/gameboy my_facts.jsonl"   # continue from models/tiny/ckpt.pt on new facts
make eval                        # exact match / char error rate on training and held-out questions
python3 -m llm.chat models/tiny/ckpt.pt --int      # talk to it on the host
```

Training augments the questions on the fly (key words only, typos, framing
words) and holds 20% of the hand written phrasings out to report how the
model does on questions it has never seen; `data/gameboy/offtopic.jsonl`
teaches it to answer "sorry, i only know about the game boy" instead of
inventing something. See [docs/FINETUNING.md](docs/FINETUNING.md) for the
full recipe, including
how to pull Game Boy articles from the web into the training corpus, and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how a transformer fits into
8 KiB of RAM and runs without a multiplier.

## Repository layout

```
configs/         model sizes (nano / tiny / micro)
data/gameboy/    dataset: facts.jsonl, offtopic.jsonl, corpus/*.txt, scripts/fetch_web.py
docs/            ARCHITECTURE.md, BUILD.md, FINETUNING.md
gb/              ROM sources: src/ (C + asm, intro screen, chat UI), gen/ (generated from the model), build/chatgbc.gb
llm/             tokenizer, quant spec, model, data, augment, train, evaluate, export, simulate, chat
models/          tiny (shipped) and micro checkpoints, configs, integer models, training logs
tools/           gbdk_setup.sh, fontgen.py, introgen.py, emu_test.py, selftest.py, check_map.py
```

## Honest expectations

A 48k parameter character-level model is about the size of a single
attention head of a modern LLM. It memorises the facts it was fine-tuned on,
copes with some rephrasing (key words, typos, missing question words) thanks
to the training augmentation, and usually says "sorry, i only know about the
game boy" when asked something else. It does not reason, a phrasing far from
anything it has seen still produces Game-Boy-flavoured nonsense, and the
held-out numbers in `docs/FINETUNING.md` are the honest measure. That is the
point: the whole model and its inference engine fit in a 128 KiB cartridge
from 1989.
