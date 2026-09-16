"""Datasets for pre-training (plain text) and chat fine-tuning (question/answer pairs).

Text corpus:   any *.txt files (UTF-8). Documents are normalised to the
               character vocabulary and separated by <eos>.
Chat data:     JSON lines with {"q": "...", "a": "..."} or
               {"q": ["variant 1", "variant 2"], "a": "..."} (every question
               variant becomes one training example). An optional
               "weight" (default 1.0) scales how often each variant of that
               line is sampled relative to the other lines.

Sequences are *packed*: several conversations are concatenated into one
context window exactly like the ROM keeps a multi-turn conversation in its
KV cache, so every position embedding gets trained.

Held-out split: `split_heldout` keeps one or more question variants of every
fact out of training so that generalisation to unseen phrasings can be
measured (see train.py). Questions can also be augmented on the fly
(`PackedStream(augment=...)`, see augment.py).
"""
import glob
import json
import math
import os
import random

import torch

from . import tokenizer as tok
from .augment import augment_question


def load_text_files(paths):
    docs = []
    for p in paths:
        files = sorted(glob.glob(os.path.join(p, "**", "*.txt"), recursive=True)) if os.path.isdir(p) else glob.glob(p)
        for f in files:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                text = fh.read()
            for para in text.split("\n\n"):
                ids = tok.encode(para)
                if len(ids) >= 8:
                    docs.append(ids)
    return docs


def load_chat_groups(paths):
    """Return one dict per JSON line: {"q": [normalised variants], "a": answer, "src": file name, "w": weight}."""
    groups = []
    for p in paths:
        files = sorted(glob.glob(os.path.join(p, "**", "*.jsonl"), recursive=True)) if os.path.isdir(p) else glob.glob(p)
        for f in files:
            src = os.path.basename(f)
            with open(f, encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    d = json.loads(line)
                    qs = d["q"] if isinstance(d["q"], list) else [d["q"]]
                    qs = [tok.normalize(q) for q in qs]
                    qs = [q for q in qs if q]
                    if not qs:
                        continue
                    groups.append({"q": qs, "a": tok.normalize(d["a"]), "src": src, "w": float(d.get("weight", 1.0))})
    return groups


def flatten_groups(groups):
    """Groups -> list of {"q", "a", "src", "w"} with one question per item."""
    return [{"q": q, "a": g["a"], "src": g["src"], "w": g["w"]} for g in groups for q in g["q"]]


def load_chat_files(paths):
    """Flat list of (question, answer) pairs (every variant of every line)."""
    return [(it["q"], it["a"]) for it in flatten_groups(load_chat_groups(paths))]


def split_heldout(groups, frac, seed=0, min_variants=3):
    """Hold out `round(frac * n)` (at least one) question variants of every
    line that has at least `min_variants` variants; lines with fewer variants
    stay entirely in the training set. Returns (train_items, heldout_items)
    as flat item lists (see flatten_groups). Deterministic for a given seed,
    so fine-tuning runs keep the same held-out questions."""
    rng = random.Random(seed)
    train, held = [], []
    for g in groups:
        qs = list(g["q"])
        n_out = 0
        if frac > 0 and len(qs) >= min_variants:
            n_out = min(len(qs) - 1, max(1, int(round(frac * len(qs)))))
        rng.shuffle(qs)
        for i, q in enumerate(qs):
            (held if i < n_out else train).append({"q": q, "a": g["a"], "src": g["src"], "w": g["w"]})
    return train, held


def pairs(items):
    return [(it["q"], it["a"]) for it in items]


class PackedStream:
    """Infinite stream of (input, target, loss_mask) windows of length ctx."""

    def __init__(self, docs, chats, ctx, chat_weight=0.5, answer_only=False, question_loss=0.0, seed=0,
                 augment=0.0, chat_weights=None):
        """
        docs        : list of token-id lists (plain text)
        chats       : list of (question, answer) strings
        chat_weight : probability that the next packed item is a conversation
        answer_only : if True, plain text is never used (fine-tuning)
        question_loss: loss weight on the user part of conversations (0..1)
        augment     : probability that a question is augmented (augment.py)
        chat_weights: optional per-pair sampling weights (same length as chats)
        """
        self.docs, self.chats, self.ctx = docs, chats, ctx
        self.chat_weight = chat_weight if docs else 1.0
        self.answer_only = answer_only
        self.question_loss = question_loss
        self.augment = augment
        self.rng = random.Random(seed)
        if not docs and not chats:
            raise ValueError("no training data")
        self.cum_weights = None
        if chat_weights is not None and chats:
            assert len(chat_weights) == len(chats)
            if any(w != chat_weights[0] for w in chat_weights):
                acc, self.cum_weights = 0.0, []
                for w in chat_weights:
                    acc += max(0.0, float(w))
                    self.cum_weights.append(acc)

    def _pick_chat(self):
        if self.cum_weights is None:
            return self.rng.choice(self.chats)
        return self.rng.choices(self.chats, cum_weights=self.cum_weights, k=1)[0]

    def _next_item(self):
        if self.chats and (self.answer_only or not self.docs or self.rng.random() < self.chat_weight):
            q, a = self._pick_chat()
            if self.augment > 0 and self.rng.random() < self.augment:
                q = augment_question(q, self.rng)
            q_ids = [tok.USR] + tok.encode(q) + [tok.BOT]
            a_ids = tok.encode(a) + [tok.EOS]
            return q_ids + a_ids, [self.question_loss] * len(q_ids) + [1.0] * len(a_ids)
        d = self.rng.choice(self.docs)
        ids = d + [tok.EOS]
        return ids, [1.0] * len(ids)

    def window(self):
        ids, w = [], []
        while len(ids) < self.ctx + 1:
            i, ww = self._next_item()
            ids += i
            w += ww
        start = 0
        ids, w = ids[start:start + self.ctx + 1], w[start:start + self.ctx + 1]
        x = torch.tensor(ids[:-1], dtype=torch.long)
        y = torch.tensor(ids[1:], dtype=torch.long)
        # the loss weight belongs to the *target* token
        m = torch.tensor(w[1:], dtype=torch.float32)
        return x, y, m

    def batch(self, n):
        xs, ys, ms = zip(*[self.window() for _ in range(n)])
        return torch.stack(xs), torch.stack(ys), torch.stack(ms)


def describe(docs, chats):
    ntok = sum(len(d) for d in docs)
    return f"{len(docs)} text paragraphs ({ntok} tokens), {len(chats)} question/answer pairs"
