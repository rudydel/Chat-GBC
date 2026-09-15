"""Datasets for pre-training (plain text) and chat fine-tuning (question/answer pairs).

Text corpus:   any *.txt files (UTF-8). Documents are normalised to the
               character vocabulary and separated by <eos>.
Chat data:     JSON lines with {"q": "...", "a": "..."} or
               {"q": ["variant 1", "variant 2"], "a": "..."} (every question
               variant becomes one training example).

Sequences are *packed*: several conversations are concatenated into one
context window exactly like the ROM keeps a multi-turn conversation in its
KV cache, so every position embedding gets trained.
"""
import glob
import json
import os
import random

import torch

from . import tokenizer as tok


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


def load_chat_files(paths):
    pairs = []
    for p in paths:
        files = sorted(glob.glob(os.path.join(p, "**", "*.jsonl"), recursive=True)) if os.path.isdir(p) else glob.glob(p)
        for f in files:
            with open(f, encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    d = json.loads(line)
                    qs = d["q"] if isinstance(d["q"], list) else [d["q"]]
                    for q in qs:
                        pairs.append((tok.normalize(q), tok.normalize(d["a"])))
    return pairs


class PackedStream:
    """Infinite stream of (input, target, loss_mask) windows of length ctx."""

    def __init__(self, docs, chats, ctx, chat_weight=0.5, answer_only=False, question_loss=0.0, seed=0):
        """
        docs        : list of token-id lists (plain text)
        chats       : list of (question, answer) strings
        chat_weight : probability that the next packed item is a conversation
        answer_only : if True, plain text is never used (fine-tuning)
        question_loss: loss weight on the user part of conversations (0..1)
        """
        self.docs, self.chats, self.ctx = docs, chats, ctx
        self.chat_weight = chat_weight if docs else 1.0
        self.answer_only = answer_only
        self.question_loss = question_loss
        self.rng = random.Random(seed)
        if not docs and not chats:
            raise ValueError("no training data")

    def _next_item(self):
        if self.chats and (self.answer_only or not self.docs or self.rng.random() < self.chat_weight):
            q, a = self.rng.choice(self.chats)
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
