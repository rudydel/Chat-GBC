"""Bit-exact Python reference of the Game Boy inference code.

Every operation here has a one-to-one counterpart in gb/src/llm.c. If this
simulator and the ROM disagree on a single byte, one of them has a bug.
Use `python -m llm.simulate models/<name>/model_int.json` to chat with the
integer model on the host, or `--compare` to compare it with the float model.
"""
import argparse
import sys
import numpy as np

from . import quant as Q
from . import tokenizer as tok
from .intmodel import load_json

SQ = Q.sq_table()
EXP = Q.exp_table()


def rmsnorm_q(h, norm_k):
    """h: list of int16 -> list of int7 = clamp(h / rms(h) * 2**E_NORM).
    Mirrors rmsnorm_q() + norm_scale() in gb/src/llm.c / mathasm.s exactly."""
    ah = [min(abs(int(x)), 32767) for x in h]
    m = max(ah)
    s = 0
    while (m >> s) > Q.QMAX:
        s += 1
    ss = sum(SQ[2 * (x >> s) + 2 * Q.QMAX] >> 2 for x in ah)      # (|x| >> s)**2 via the SQ table
    r = Q.isqrt(ss)
    if r == 0:
        r = 1
    inv = norm_k // r
    e = 0
    while inv > 0xFFFF:
        inv >>= 1
        e += 1
    shift = Q.NORM_K_BITS + s - e
    return [Q.clamp(Q.round_shift(int(x) * inv, shift), -Q.QMAX, Q.QMAX) for x in h]


def matvec(w, x):
    """Exact integer W @ x (numpy int64). Equivalent to the table dot product."""
    return (np.asarray(w, dtype=np.int64) @ np.asarray(x, dtype=np.int64)).tolist()


def requant(acc, s, lo=-Q.QMAX, hi=Q.QMAX):
    return Q.clamp(Q.round_shift(int(acc), s), lo, hi)


def sat16(x):
    return Q.clamp(int(x), -32768, 32767)


class Rng:
    """16-bit xorshift used for sampling (identical to the C implementation)."""

    def __init__(self, seed=0x1234):
        self.s = seed & 0xFFFF or 1

    def next(self):
        x = self.s
        x ^= (x << 7) & 0xFFFF
        x ^= (x >> 9)
        x ^= (x << 8) & 0xFFFF
        self.s = x & 0xFFFF
        return self.s


class IntModel:
    def __init__(self, m: dict):
        self.m = m
        c = m["config"]
        self.D, self.H, self.HD = c["d_model"], c["n_heads"], c["d_model"] // c["n_heads"]
        self.F, self.T, self.L, self.V = c["d_ff"], c["ctx"], c["n_layers"], c["vocab_size"]
        self.reset()

    def reset(self):
        self.pos = 0
        L, T, D, H = self.L, self.T, self.D, self.H
        self.K = [[[0] * D for _ in range(T)] for _ in range(L)]
        self.ksq = [[[0] * H for _ in range(T)] for _ in range(L)]
        self.VT = [[[0] * T for _ in range(D)] for _ in range(L)]   # value 0 == biased byte 63
        self.vsq = [[0] * D for _ in range(L)]
        self.vsum = [[0] * D for _ in range(L)]

    # -- one transformer step: token t at position self.pos -> logits (list of int)
    def forward(self, t):
        m, p = self.m, self.pos
        assert p < self.T, "context full"
        D, H, HD = self.D, self.H, self.HD
        trace = self.trace = []
        h = [sat16((int(m["tok_emb"][t][i]) << (m["e_res"] - m["e_tok"])) +
                   (int(m["pos_emb"][p][i]) << (m["e_res"] - m["e_pos"]))) for i in range(D)]
        trace.append((1, dict(h=list(h))))
        for l, ly in enumerate(m["layers"]):
            n = rmsnorm_q(h, m["norm_k"])
            trace.append((10 * l + 11, dict(nbuf=list(n))))
            q = [requant(a, ly["s_q"]) for a in matvec(ly["wq"], n)]
            k = [requant(a, ly["s_k"]) for a in matvec(ly["wk"], n)]
            v = [requant(a, ly["s_v"]) for a in matvec(ly["wv"], n)]
            trace.append((10 * l + 12, dict(q=list(q), k=list(k), v=list(v))))
            # append to the caches
            self.K[l][p] = k
            for hh in range(H):
                self.ksq[l][p][hh] = sum(x * x for x in k[hh * HD:(hh + 1) * HD])
            for i in range(D):
                self.VT[l][i][p] = v[i]
                self.vsq[l][i] += v[i] * v[i]
                self.vsum[l][i] += v[i]
            # attention
            o = [0] * D
            for hh in range(H):
                qh = q[hh * HD:(hh + 1) * HD]
                scores = [sum(a * b for a, b in zip(self.K[l][pp][hh * HD:(hh + 1) * HD], qh)) for pp in range(p + 1)]
                mx = max(scores)
                e = [EXP[Q.exp_index(mx - s, ly["att_mul"], ly["att_shift"])] for s in scores]
                E = sum(e)
                for i in range(hh * HD, (hh + 1) * HD):
                    num = sum(ee * self.VT[l][i][pp] for pp, ee in enumerate(e))   # == dot(e-63, v) + 63*vsum
                    o[i] = Q.clamp(Q.div_round(num, E), -Q.QMAX, Q.QMAX)
            trace.append((10 * l + 13, dict(o=list(o))))
            a = [requant(x, ly["s_ao"]) for x in matvec(ly["wo"], o)]
            trace.append((10 * l + 14, dict(a=list(a))))
            h = [sat16(h[i] + (a[i] << ly["rs_a"])) for i in range(D)]
            trace.append((10 * l + 15, dict(h=list(h))))
            n2 = rmsnorm_q(h, m["norm_k"])
            trace.append((10 * l + 16, dict(nbuf=list(n2))))
            f = [requant(x, ly["s_f"], 0, Q.QMAX) for x in matvec(ly["w1"], n2)]
            trace.append((10 * l + 17, dict(f=list(f))))
            a2 = [requant(x, ly["s_fo"]) for x in matvec(ly["w2"], f)]
            trace.append((10 * l + 18, dict(a=list(a2))))
            h = [sat16(h[i] + (a2[i] << ly["rs_f"])) for i in range(D)]
            trace.append((10 * l + 19, dict(h=list(h))))
        n = rmsnorm_q(h, m["norm_k"])
        trace.append((100, dict(nbuf=list(n))))
        logits = matvec(m["lm_head"], n)
        trace.append((101, dict(logits=list(logits))))
        self.debug = dict(h=h, nbuf=n, q=q, k=k, v=v, o=o, a=a2, f=f, logits=logits)
        self.pos += 1
        return logits

    def pick(self, logits, sample=False, rng=None):
        mx = max(logits)
        if not sample:
            return logits.index(mx)
        e = [EXP[Q.exp_index(mx - s, self.m["lm_mul"], self.m["lm_shift"])] for s in logits]
        # never emit <pad>/<usr>/<bot>
        for i in (tok.PAD, tok.USR, tok.BOT):
            e[i] = 0
        total = sum(e)
        r = rng.next() % total
        acc = 0
        for i, ee in enumerate(e):
            acc += ee
            if r < acc:
                return i
        return len(e) - 1

    def feed(self, ids):
        logits = None
        for t in ids:
            logits = self.forward(t)
        return logits

    def generate(self, prompt_ids, max_new=64, sample=False, rng=None, stop=tok.EOS):
        out = []
        logits = self.feed(prompt_ids)
        while len(out) < max_new and self.pos < self.T:
            t = self.pick(logits, sample, rng)
            if t == stop:
                break
            out.append(t)
            logits = self.forward(t)
        return out

    def chat_reply(self, question, max_new=80, sample=False, rng=None, min_reply=16):
        """Same context-management policy as the ROM: keep the conversation in
        the cache while it fits, otherwise start over."""
        ids = tok.format_turn(question)
        if self.pos + len(ids) + min_reply > self.T:
            self.reset()
        return self.generate(ids, max_new=max_new, sample=sample, rng=rng)


def main():
    ap = argparse.ArgumentParser(description="chat with the integer model (bit-exact ROM reference)")
    ap.add_argument("model_json")
    ap.add_argument("--sample", action="store_true", help="sample instead of greedy decoding")
    ap.add_argument("--seed", type=int, default=0x1234)
    ap.add_argument("--max-new", type=int, default=80)
    ap.add_argument("-q", "--question", action="append", help="ask non-interactively (repeatable)")
    args = ap.parse_args()
    model = IntModel(load_json(args.model_json))
    rng = Rng(args.seed)
    questions = args.question
    if questions:
        for qq in questions:
            print("> " + qq)
            print("< " + tok.decode(model.chat_reply(qq, args.max_new, args.sample, rng)))
        return
    print("Chat-GBC integer simulator. Ctrl-D to quit.")
    while True:
        try:
            qq = input("> ")
        except EOFError:
            break
        print("< " + tok.decode(model.chat_reply(qq, args.max_new, args.sample, rng)))


if __name__ == "__main__":
    main()
