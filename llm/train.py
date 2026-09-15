"""Train / fine-tune the quantization-aware nano GPT.

Examples
--------
Pre-train on text and chat data, then fine-tune on the answers:
    python -m llm.train --config configs/tiny.json --out models/tiny \
        --text data/gameboy/corpus --chat data/gameboy/facts.jsonl \
        --pretrain-steps 4000 --sft-steps 3000

Continue fine-tuning an existing checkpoint on new facts:
    python -m llm.train --init models/tiny/ckpt.pt --out models/tiny \
        --chat data/my_facts.jsonl --pretrain-steps 0 --sft-steps 1500

Every run writes <out>/ckpt.pt, <out>/config.json and <out>/train_log.txt.
Export the result for the Game Boy with `python -m llm.export <out>/ckpt.pt`.
"""
import argparse
import json
import math
import os
import random
import time

import torch

from . import tokenizer as tok
from .data import load_text_files, load_chat_files, PackedStream, describe
from .model import NanoGPT, ModelConfig, save_checkpoint, load_checkpoint


def lr_at(step, total, base, warmup=100, final_ratio=0.1):
    if step < warmup:
        return base * (step + 1) / warmup
    p = (step - warmup) / max(1, total - warmup)
    return base * (final_ratio + (1 - final_ratio) * 0.5 * (1 + math.cos(math.pi * p)))


def run_phase(model, stream, steps, batch, base_lr, log, name, wd=0.01, grad_clip=1.0, log_every=100):
    if steps <= 0:
        return
    decay, no_decay = [], []
    for n, p in model.named_parameters():
        (no_decay if n.endswith("gain") or "emb" in n else decay).append(p)
    opt = torch.optim.AdamW([{"params": decay, "weight_decay": wd}, {"params": no_decay, "weight_decay": 0.0}],
                            lr=base_lr, betas=(0.9, 0.95))
    model.train()
    t0 = time.time()
    ema = None
    for step in range(steps):
        lr = lr_at(step, steps, base_lr)
        for g in opt.param_groups:
            g["lr"] = lr
        x, y, m = stream.batch(batch)
        _, loss = model(x, y, m)
        opt.zero_grad(set_to_none=True)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), grad_clip)
        opt.step()
        ema = float(loss) if ema is None else 0.98 * ema + 0.02 * float(loss)
        if step % log_every == 0 or step == steps - 1:
            msg = f"[{name}] step {step:5d}/{steps} loss {float(loss):.3f} (ema {ema:.3f}) lr {lr:.2e} {time.time() - t0:.0f}s"
            print(msg)
            log.write(msg + "\n")
            log.flush()
    model.eval()


@torch.no_grad()
def recall_eval(model, chats, n=40, seed=0, max_new=80):
    """Ask n random training questions with greedy decoding; report exact-match rate."""
    if not chats:
        return 0.0, []
    rng = random.Random(seed)
    sample = rng.sample(chats, min(n, len(chats)))
    hits, examples = 0, []
    for q, a in sample:
        ids = torch.tensor([tok.format_turn(q)], dtype=torch.long)
        out = model.generate(ids, max_new, temperature=0.0, stop_token=tok.EOS)[0, ids.size(1):].tolist()
        text = "".join(tok.VOCAB[i] for i in out if i >= 4)
        ok = text.strip() == a.strip()
        hits += ok
        examples.append((q, text, a, ok))
    return hits / len(sample), examples


def main():
    ap = argparse.ArgumentParser(description="train the Chat-GBC nano LLM")
    ap.add_argument("--config", help="model config JSON (ignored when --init is given)")
    ap.add_argument("--init", help="checkpoint to start from (fine-tuning)")
    ap.add_argument("--out", required=True, help="output directory")
    ap.add_argument("--text", nargs="*", default=[], help="text corpus dirs/files (*.txt)")
    ap.add_argument("--chat", nargs="*", default=[], help="chat data dirs/files (*.jsonl)")
    ap.add_argument("--pretrain-steps", type=int, default=3000)
    ap.add_argument("--sft-steps", type=int, default=2000)
    ap.add_argument("--batch", type=int, default=32)
    ap.add_argument("--lr", type=float, default=1e-2)
    ap.add_argument("--sft-lr", type=float, default=6e-3)
    ap.add_argument("--chat-weight", type=float, default=0.5, help="share of conversations during pre-training")
    ap.add_argument("--question-loss", type=float, default=0.1, help="loss weight on question tokens during SFT")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--threads", type=int, default=0)
    ap.add_argument("--eval-n", type=int, default=40)
    args = ap.parse_args()

    if args.threads:
        torch.set_num_threads(args.threads)
    torch.manual_seed(args.seed)
    random.seed(args.seed)
    os.makedirs(args.out, exist_ok=True)

    if args.init:
        model, _ = load_checkpoint(args.init)
        cfg = model.cfg
        print(f"loaded {args.init}")
    else:
        cfg = ModelConfig.load(args.config) if args.config else ModelConfig()
        model = NanoGPT(cfg)
    print(f"model {cfg.name}: {model.num_params()} parameters, ctx {cfg.ctx}")

    docs = load_text_files(args.text)
    chats = load_chat_files(args.chat)
    print("data:", describe(docs, chats))

    log = open(os.path.join(args.out, "train_log.txt"), "a")
    log.write(f"# {time.strftime('%Y-%m-%d %H:%M:%S')} {vars(args)}\n")

    if args.pretrain_steps > 0:
        stream = PackedStream(docs, chats, cfg.ctx, chat_weight=args.chat_weight, question_loss=1.0, seed=args.seed)
        run_phase(model, stream, args.pretrain_steps, args.batch, args.lr, log, "pretrain")
        save_checkpoint(model, os.path.join(args.out, "ckpt.pt"))
    if args.sft_steps > 0 and chats:
        stream = PackedStream(docs, chats, cfg.ctx, answer_only=True, question_loss=args.question_loss, seed=args.seed + 1)
        run_phase(model, stream, args.sft_steps, args.batch, args.sft_lr, log, "sft")
    save_checkpoint(model, os.path.join(args.out, "ckpt.pt"))
    cfg.save(os.path.join(args.out, "config.json"))

    rate, examples = recall_eval(model, chats, n=args.eval_n, seed=args.seed)
    msg = f"fact recall (exact match, greedy, {len(examples)} training questions): {rate * 100:.0f}%"
    print(msg)
    log.write(msg + "\n")
    for q, text, a, ok in examples[:8]:
        line = f"  {'OK ' if ok else 'BAD'} q: {q}\n      got: {text}\n      exp: {a}"
        print(line)
        log.write(line + "\n")
    log.close()
    print(f"saved {args.out}/ckpt.pt")


if __name__ == "__main__":
    main()
