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

By default 20% of the question variants of every fact (--heldout 0.2) never
enter training; the final report shows exact match and character error rate
on the training questions (memorisation) and on those held-out phrasings
(generalisation). Questions are augmented on the fly (--augment, augment.py).

Every run writes <out>/ckpt.pt, <out>/config.json, <out>/heldout.jsonl and
<out>/train_log.txt.
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
from .data import load_text_files, load_chat_groups, flatten_groups, split_heldout, pairs, PackedStream, describe
from .evaluate import float_replier, int_replier, score, report
from .model import NanoGPT, ModelConfig, save_checkpoint, load_checkpoint


def lr_at(step, total, base, warmup=100, final_ratio=0.1):
    if step < warmup:
        return base * (step + 1) / warmup
    p = (step - warmup) / max(1, total - warmup)
    return base * (final_ratio + (1 - final_ratio) * 0.5 * (1 + math.cos(math.pi * p)))


def make_optimizer(model, base_lr, wd):
    decay, no_decay = [], []
    for n, p in model.named_parameters():
        (no_decay if n.endswith("gain") or "emb" in n else decay).append(p)
    return torch.optim.AdamW([{"params": decay, "weight_decay": wd}, {"params": no_decay, "weight_decay": 0.0}],
                             lr=base_lr, betas=(0.9, 0.95))


def run_phase(model, stream, steps, batch, base_lr, log, name, wd=0.01, grad_clip=1.0, log_every=100):
    """One training phase with cosine LR decay and a divergence guard: if the
    smoothed loss climbs well above its best value, the best weights are
    restored and the learning rate is halved (tiny quantized models can blow
    up at the high learning rates they otherwise need)."""
    if steps <= 0:
        return
    opt = make_optimizer(model, base_lr, wd)
    model.train()
    t0 = time.time()
    ema, best_ema, best_state = None, None, None
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
        li = loss.item()
        ema = li if ema is None else 0.98 * ema + 0.02 * li
        if step % log_every == 0 or step == steps - 1:
            msg = f"[{name}] step {step:5d}/{steps} loss {li:.3f} (ema {ema:.3f}) lr {lr:.2e} {time.time() - t0:.0f}s"
            print(msg)
            log.write(msg + "\n")
            log.flush()
            if step >= 200:
                if best_ema is None or ema < best_ema:
                    best_ema = ema
                    best_state = {k: v.detach().clone() for k, v in model.state_dict().items()}
                elif ema > best_ema * 1.3 + 0.2:
                    base_lr *= 0.5
                    model.load_state_dict(best_state)
                    opt = make_optimizer(model, base_lr, wd)
                    ema = best_ema
                    msg = f"[{name}] divergence detected (ema {ema:.3f} vs best {best_ema:.3f}): restored best weights, lr -> {base_lr:.1e}"
                    print(msg)
                    log.write(msg + "\n")
    if best_state is not None and best_ema is not None and ema > best_ema * 1.3 + 0.2:
        model.load_state_dict(best_state)
    model.eval()


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
    ap.add_argument("--augment", type=float, default=0.5,
                    help="probability that a training question is rephrased on the fly (0 disables)")
    ap.add_argument("--heldout", type=float, default=0.2,
                    help="share of the question variants of each fact kept out of training for evaluation (0 disables)")
    ap.add_argument("--heldout-chat", nargs="*", default=[], help="extra *.jsonl files used only for evaluation")
    ap.add_argument("--eval-n", type=int, default=80, help="training questions to sample for the final report")
    ap.add_argument("--eval-int", action="store_true", help="also evaluate the bit-exact integer simulator")
    args = ap.parse_args()

    if args.threads:
        torch.set_num_threads(args.threads)
    torch.manual_seed(args.seed)
    random.seed(args.seed)
    os.makedirs(args.out, exist_ok=True)

    docs = load_text_files(args.text)
    train_items, held_items = split_heldout(load_chat_groups(args.chat), args.heldout, args.seed)
    held_items += flatten_groups(load_chat_groups(args.heldout_chat))
    chats, chat_weights = pairs(train_items), [it["w"] for it in train_items]

    if args.init:
        model, _ = load_checkpoint(args.init)          # installs the checkpoint's vocabulary
        cfg = model.cfg
        print(f"loaded {args.init}")
    else:
        cfg = ModelConfig.load(args.config) if args.config else ModelConfig()
        if cfg.n_extra_tokens > 0:
            # subword tokens learned from the prose and (weighted) from the conversations
            texts = docs + [q for q, _ in chats] * 3 + [a for _, a in chats] * 3
            t0 = time.time()
            tok.learn_vocab(texts, cfg.n_extra_tokens)
            print(f"learned {cfg.n_extra_tokens} subword tokens in {time.time() - t0:.0f}s: "
                  + " ".join(repr(t) for t in tok.extra_vocab()[:24]) + " ...")
        else:
            tok.set_vocab([])
        model = NanoGPT(cfg)
    with open(os.path.join(args.out, "vocab.json"), "w") as f:
        json.dump(tok.extra_vocab(), f)
    print(f"model {cfg.name}: {model.num_params()} parameters, ctx {cfg.ctx}, vocabulary {cfg.vocab_size} tokens")
    print("data:", describe(docs, chats), f"+ {len(held_items)} held-out questions")
    with open(os.path.join(args.out, "heldout.jsonl"), "w") as f:
        for it in held_items:
            f.write(json.dumps({"q": it["q"], "a": it["a"], "src": it["src"]}) + "\n")

    log = open(os.path.join(args.out, "train_log.txt"), "a")
    log.write(f"# {time.strftime('%Y-%m-%d %H:%M:%S')} {vars(args)}\n")

    if args.pretrain_steps > 0:
        stream = PackedStream(docs, chats, cfg.ctx, chat_weight=args.chat_weight, question_loss=1.0, seed=args.seed,
                              augment=args.augment, chat_weights=chat_weights)
        run_phase(model, stream, args.pretrain_steps, args.batch, args.lr, log, "pretrain")
        save_checkpoint(model, os.path.join(args.out, "ckpt.pt"))
    if args.sft_steps > 0 and chats:
        stream = PackedStream(docs, chats, cfg.ctx, answer_only=True, question_loss=args.question_loss, seed=args.seed + 1,
                              augment=args.augment, chat_weights=chat_weights)
        run_phase(model, stream, args.sft_steps, args.batch, args.sft_lr, log, "sft")
    save_checkpoint(model, os.path.join(args.out, "ckpt.pt"))
    cfg.save(os.path.join(args.out, "config.json"))

    def emit(lines):
        for line in lines:
            print(line)
            log.write(line + "\n")

    for tag, make_reply in [("float", float_replier)] + ([("int", int_replier)] if args.eval_int else []):
        reply = make_reply(model)
        emit(report(f"[{tag}] train questions", score(reply, train_items, args.eval_n, args.seed)))
        if held_items:
            emit(report(f"[{tag}] held-out questions", score(reply, held_items), only_bad=True))
    log.close()
    print(f"saved {args.out}/ckpt.pt")


if __name__ == "__main__":
    main()
