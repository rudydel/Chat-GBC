# Game Boy dataset

Everything the shipped model knows about the Game Boy comes from this folder.

| Path | What it is | Used for |
|------|------------|----------|
| `facts.jsonl` | ~145 facts as `{"q": [question variants], "a": "answer"}` (~440 question/answer pairs), including a few chit-chat lines (hello, thanks, who are you) | fine-tuning (and pre-training) |
| `offtopic.jsonl` | ~215 generic questions (geography, maths, weather, recipes, code, ...) that all get the fallback answer "sorry, i only know about the game boy" | fine-tuning: teaches the model the limit of its knowledge |
| `corpus/*.txt` | prose about the history, hardware, models and games of the Game Boy | pre-training |
| `scripts/fetch_web.py` | downloads ~40 related Wikipedia articles as plain text into `wiki/` | optional extra pre-training text |
| `wiki/` | output of the fetch script (not committed, CC BY-SA 4.0) | pre-training |

Answers are deliberately short: the Game Boy prints roughly one character
every two seconds, so a 40 character answer already takes over a minute.

## Adding facts

Append lines to `facts.jsonl`:

```json
{"q": ["when was the game boy camera released", "game boy camera release date"], "a": "february 21, 1998 in japan"}
```

Only lower-case letters, digits, space and `.,?!'-:()/&";` survive
normalisation (see `llm/tokenizer.py`), everything else is folded or dropped.
Then retrain or fine-tune (see `docs/FINETUNING.md`).

Give at least three phrasings per fact: the trainer holds one of them out to
measure how well the model answers phrasings it has not seen, and augments the
rest on the fly (key words only, typos, framing words added or dropped). A
line may carry `"weight": 0.5` to be sampled half as often per variant; the
off-topic lines use this so the fallback answer does not dominate training.

## Getting more text from the web

```
python3 data/gameboy/scripts/fetch_web.py          # -> data/gameboy/wiki/*.txt
python3 -m llm.train ... --text data/gameboy/corpus data/gameboy/wiki ...
```

The fetch script uses the public MediaWiki API. Wikipedia text is
CC BY-SA 4.0; keep the attribution if you redistribute a model trained on it.
