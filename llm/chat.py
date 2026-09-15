"""Chat with a checkpoint from the terminal.

    python -m llm.chat models/tiny/ckpt.pt            # float QAT model (fast)
    python -m llm.chat models/tiny/ckpt.pt --int      # bit-exact integer simulation of the ROM
    python -m llm.chat models/tiny/ckpt.pt -q "who designed the game boy"
"""
import argparse

import torch

from . import tokenizer as tok
from .model import load_checkpoint


def float_reply(model, question, max_new=80, temperature=0.0):
    ids = torch.tensor([tok.format_turn(question)], dtype=torch.long)
    out = model.generate(ids, max_new, temperature=temperature, stop_token=tok.EOS)[0, ids.size(1):].tolist()
    return "".join(tok.VOCAB[i] for i in out if i >= 4)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint")
    ap.add_argument("--int", action="store_true", help="use the integer simulator (what the ROM computes)")
    ap.add_argument("--sample", action="store_true")
    ap.add_argument("--temperature", type=float, default=0.8)
    ap.add_argument("--max-new", type=int, default=80)
    ap.add_argument("-q", "--question", action="append")
    args = ap.parse_args()
    model, _ = load_checkpoint(args.checkpoint)

    if args.int:
        from .intmodel import extract
        from .simulate import IntModel, Rng
        sim = IntModel(extract(model))
        rng = Rng()
        reply = lambda q: "".join(tok.VOCAB[i] for i in sim.chat_reply(q, args.max_new, args.sample, rng) if i >= 4)
    else:
        reply = lambda q: float_reply(model, q, args.max_new, args.temperature if args.sample else 0.0)

    if args.question:
        for q in args.question:
            print("> " + q)
            print("< " + reply(q))
        return
    print("Chat-GBC (%s). Ctrl-D to quit." % ("integer simulator" if args.int else "float model"))
    while True:
        try:
            q = input("> ")
        except EOFError:
            break
        if q.strip():
            print("< " + reply(q))


if __name__ == "__main__":
    main()
