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
* **`llm/`** – the Python side: character tokenizer, quantization-aware
  training (`train.py`), export to C (`export.py`), a bit-exact integer
  simulator of the ROM (`simulate.py`), and a terminal chat.
* **`data/gameboy/`** – a curated Game Boy fact base (405 question/answer
  pairs), prose for pre-training, and a script that pulls related Wikipedia
  articles for more text.
* **`tools/`** – emulator based tests that type on the virtual keyboard and
  compare the ROM's answer with the simulator, character for character.

The shipped model (`models/tiny`, 48k parameters) answers questions about
the history and hardware of the Game Boy, one character every ~2.5 seconds
on an original Game Boy (half that on a Game Boy Color).

## Quick start

```bash
make setup                # pip install -r requirements.txt, download GBDK-2020 to tools/gbdk
make rom                  # export models/tiny/ckpt.pt -> gb/gen/*, build gb/build/chatgbc.gb
make test                 # run the ROM in PyBoy, type a question, check it against the simulator
```

Load `gb/build/chatgbc.gb` in any Game Boy emulator (SameBoy, BGB, mGBA,
Gambatte, PyBoy) or on a flash cartridge.

Controls: **D-pad** move over the keyboard, **A** press a key, **B**
backspace (or stop a reply), **START** send, **SELECT** toggle greedy /
sampled replies.

## Rebuilding after the model changed

The ROM is regenerated from a checkpoint in one step:

```bash
python3 -m llm.export models/tiny/ckpt.pt   # writes gb/gen/* and models/tiny/model_int.json
make -C gb                                  # -> gb/build/chatgbc.gb
```

or simply `make rom` (`MODEL=nano` / `MODEL=micro` for the other configs).
`make test` then drives the ROM in an emulator and verifies that the
Game Boy produces exactly the same characters as the Python simulator.

## Training and fine-tuning

```bash
make train                       # pre-train + fine-tune configs/tiny.json on data/gameboy
make finetune CHAT=my_facts.jsonl   # continue from models/tiny/ckpt.pt on new facts
python3 -m llm.chat models/tiny/ckpt.pt --int      # talk to it on the host
```

See [docs/FINETUNING.md](docs/FINETUNING.md) for the full recipe, including
how to pull Game Boy articles from the web into the training corpus, and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how a transformer fits into
8 KiB of RAM and runs without a multiplier.

## Repository layout

```
configs/         model sizes (nano / tiny / micro)
data/gameboy/    dataset: facts.jsonl, corpus/*.txt, scripts/fetch_web.py
docs/            ARCHITECTURE.md, BUILD.md, FINETUNING.md
gb/              ROM sources: src/ (C + asm), gen/ (generated from the model), build/chatgbc.gb
llm/             tokenizer, quant spec, model, data, train, export, simulate, chat
models/tiny/     shipped checkpoint, config, integer model (model_int.json), training log
tools/           gbdk_setup.sh, fontgen.py, emu_test.py, selftest.py, check_map.py
```

## Honest expectations

A 48k parameter character-level model is about the size of a single
attention head of a modern LLM. It memorises the facts it was fine-tuned on
and answers paraphrased questions reasonably, but it does not reason, and
off-topic questions produce Game-Boy-flavoured nonsense. That is the point:
the whole model and its inference engine fit in a 128 KiB cartridge from 1989.
