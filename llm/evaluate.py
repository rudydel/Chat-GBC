"""Measure what the model answers, on training questions and on held-out phrasings.

Two numbers per set:
  * exact   - share of answers that match the expected answer character for character
  * cer     - character error rate: edit distance / length of the expected answer
              (0 = perfect, ~1 = unrelated text); partial credit for near misses

train.py reports both for a sample of the training questions (memorisation)
and for every held-out question (generalisation to phrasings never seen in
training), per source file. The same numbers can be produced for any
checkpoint, with the float model or the bit-exact integer simulator:

    python -m llm.evaluate models/tiny/ckpt.pt --chat data/gameboy --heldout 0.2
    python -m llm.evaluate models/tiny/ckpt.pt --chat data/gameboy --heldout 0.2 --int
    python -m llm.evaluate models/tiny/ckpt.pt --heldout-chat my_test_questions.jsonl
"""
import argparse
import random
from collections import defaultdict

import torch

from . import tokenizer as tok
from .data import load_chat_groups, split_heldout, flatten_groups


def edit_distance(a: str, b: str) -> int:
    if len(a) < len(b):
        a, b = b, a
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def float_replier(model, max_new=80):
    """Greedy replies from the float QAT model."""
    def reply(q):
        ids = torch.tensor([tok.format_turn(q)], dtype=torch.long)
        out = model.generate(ids, max_new, temperature=0.0, stop_token=tok.EOS)[0, ids.size(1):].tolist()
        return "".join(tok.VOCAB[i] for i in out if i >= 4)
    return reply


def int_replier(model, max_new=80):
    """Greedy replies from the bit-exact integer simulator (what the Game Boy prints)."""
    from .intmodel import extract
    from .simulate import IntModel
    sim = IntModel(extract(model))

    def reply(q):
        return "".join(tok.VOCAB[i] for i in sim.chat_reply(q, max_new, False, None) if i >= 4)
    return reply


@torch.no_grad()
def score(reply, items, n=None, seed=0):
    """Ask every item (or a random sample of n) and return
    {"n", "exact", "cer", "by_src": {src: (n, exact, cer)}, "examples": [(q, got, expected, ok, src)]}."""
    if not items:
        return {"n": 0, "exact": 0.0, "cer": 0.0, "by_src": {}, "examples": []}
    if n is not None and n < len(items):
        items = random.Random(seed).sample(items, n)
    hits, errs, examples = 0, 0.0, []
    per = defaultdict(lambda: [0, 0, 0.0])
    for it in items:
        got = reply(it["q"]).strip()
        exp = it["a"].strip()
        ok = got == exp
        cer = edit_distance(got, exp) / max(1, len(exp))
        hits += ok
        errs += cer
        p = per[it["src"]]
        p[0] += 1
        p[1] += ok
        p[2] += cer
        examples.append((it["q"], got, exp, ok, it["src"]))
    by_src = {s: (p[0], p[1] / p[0], p[2] / p[0]) for s, p in per.items()}
    return {"n": len(items), "exact": hits / len(items), "cer": errs / len(items), "by_src": by_src, "examples": examples}


def report(name, res, show=8, only_bad=False):
    """Human readable summary lines."""
    lines = [f"{name}: exact match {res['exact'] * 100:.0f}%, char error rate {res['cer']:.2f} ({res['n']} questions)"]
    if len(res["by_src"]) > 1:
        for src, (n, ex, cer) in sorted(res["by_src"].items()):
            lines.append(f"    {src:<20} exact {ex * 100:3.0f}%  cer {cer:.2f}  ({n})")
    shown = 0
    for q, got, exp, ok, src in res["examples"]:
        if shown >= show:
            break
        if only_bad and ok:
            continue
        lines.append(f"  {'OK ' if ok else 'BAD'} q: {q}\n      got: {got}\n      exp: {exp}")
        shown += 1
    return lines


def main():
    from .model import load_checkpoint
    ap = argparse.ArgumentParser(description="evaluate a checkpoint on training and held-out questions")
    ap.add_argument("checkpoint")
    ap.add_argument("--chat", nargs="*", default=[], help="chat data dirs/files (*.jsonl) to split into train / held-out")
    ap.add_argument("--heldout", type=float, default=0.2, help="held-out share of the question variants per fact")
    ap.add_argument("--heldout-chat", nargs="*", default=[], help="extra *.jsonl files that are entirely held out")
    ap.add_argument("--seed", type=int, default=0, help="must match the training run for the same split")
    ap.add_argument("--int", action="store_true", help="use the integer simulator instead of the float model")
    ap.add_argument("--train-n", type=int, default=80, help="number of training questions to sample")
    ap.add_argument("--max-new", type=int, default=80)
    ap.add_argument("--show", type=int, default=8)
    ap.add_argument("--bad", action="store_true", help="only print the wrong answers")
    args = ap.parse_args()

    model, _ = load_checkpoint(args.checkpoint)
    reply = int_replier(model, args.max_new) if args.int else float_replier(model, args.max_new)
    train, held = split_heldout(load_chat_groups(args.chat), args.heldout, args.seed)
    held += flatten_groups(load_chat_groups(args.heldout_chat))
    if train:
        print("\n".join(report("train questions", score(reply, train, args.train_n, args.seed), args.show, args.bad)))
    if held:
        print("\n".join(report("held-out questions", score(reply, held), args.show, args.bad)))


if __name__ == "__main__":
    main()
