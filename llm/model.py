"""Quantization-aware nano GPT whose arithmetic mirrors the Game Boy ROM.

Every tensor that the ROM stores as an integer is fake-quantized here to the
same grid (power-of-two scales, int7 range [-63, 63], int16 residual stream).
Training therefore sees the exact rounding the console will apply, and
export.py can copy the integer values verbatim.

Architecture (pre-norm transformer, no biases, RMSNorm gains folded into the
following linear layer, ReLU feed-forward):

    h   = tok_emb[t] + pos_emb[p]                        (int16 residual)
    for each layer:
        n   = quant7(rmsnorm(h))                         (exponent E_NORM)
        q,k,v = quant7(n @ Wq), quant7(n @ Wk), quant7(n @ Wv)
        o   = quant7(softmax(q k^T / sqrt(hd)) v)        (exponent of v)
        h  += quant7(o @ Wo)
        n2  = quant7(rmsnorm(h))
        f   = quant7(relu(n2 @ W1))
        h  += quant7(f @ W2)
    logits = quant7(rmsnorm(h)) @ Wlm
"""
import json
import math
from dataclasses import dataclass, asdict, field

import torch
import torch.nn as nn
import torch.nn.functional as F

from . import quant as Q
from . import tokenizer as tok

E_MIN, E_MAX = -8, 24          # allowed range for power-of-two exponents


@dataclass
class ModelConfig:
    name: str = "tiny"
    vocab_size: int = tok.BASE_SIZE   # base characters + n_extra_tokens learned subword tokens
    n_extra_tokens: int = 0
    d_model: int = 48
    n_layers: int = 2
    n_heads: int = 3
    d_ff: int = 96
    ctx: int = 128
    e_res: int = 10                # residual stream exponent (int16, value = h * 2**-e_res)
    temperature: float = 0.8       # sampling temperature baked into the ROM's exp scaling
    tie_lm_head: bool = False
    notes: str = ""

    @property
    def head_dim(self):
        return self.d_model // self.n_heads

    def validate(self):
        assert self.d_model % self.n_heads == 0, "d_model must be divisible by n_heads"
        assert self.head_dim == 16, "head_dim must be exactly 16 (n_heads = d_model / 16)"
        assert self.d_model % 16 == 0 and self.d_ff % 16 == 0 and self.ctx % 16 == 0, \
            "d_model, d_ff and ctx must be multiples of 16 (dot-product entry granularity)"
        assert 16 <= self.ctx <= 256
        assert 0 <= self.n_extra_tokens <= tok.MAX_VOCAB - tok.BASE_SIZE, "too many subword tokens (ids are one byte)"
        assert self.vocab_size == tok.BASE_SIZE + self.n_extra_tokens, "vocab_size must be BASE_SIZE + n_extra_tokens"
        assert self.n_layers <= 8, "at most 8 layers (16 SRAM banks of 8 KiB)"
        # per layer: one 8 KiB SRAM bank for K + row sums, one for V + sums (see gb/src/llm.c)
        assert self.ctx * self.d_model + self.ctx * self.n_heads * 2 <= 8192, \
            "K cache (ctx*d_model) + row sums (ctx*n_heads*2) must fit one 8 KiB SRAM bank: reduce ctx"
        assert self.d_model * self.ctx + 6 * self.d_model <= 8192, \
            "V cache (d_model*ctx) + sums (6*d_model) must fit one 8 KiB SRAM bank: reduce ctx"

    @staticmethod
    def load(path):
        with open(path) as f:
            d = json.load(f)
        d = {k: v for k, v in d.items() if k in ModelConfig.__dataclass_fields__}
        d["vocab_size"] = tok.BASE_SIZE + int(d.get("n_extra_tokens", 0))
        cfg = ModelConfig(**d)
        cfg.validate()
        return cfg

    def save(self, path):
        with open(path, "w") as f:
            json.dump(asdict(self), f, indent=2)


# ----------------------------------------------------------------------------
# fake quantization helpers
# ----------------------------------------------------------------------------

def exponent_for(maxabs: float, qmax: int) -> int:
    """Largest e such that maxabs * 2**e <= qmax (power-of-two scale)."""
    if maxabs <= 0 or not math.isfinite(maxabs):
        return E_MAX
    e = math.floor(math.log2(qmax / maxabs))
    return int(max(E_MIN, min(E_MAX, e)))


QUANT_ENABLED = True   # set False to train / evaluate the float architecture without fake quantization


def fake_quant(x, e: int, qmax: int):
    """Round x to the grid 2**-e, clamp to [-qmax, qmax], straight-through gradient."""
    if not QUANT_ENABLED:
        return x
    scale = 2.0 ** e
    # clamp first (differentiable: zero gradient outside the representable range, so
    # activations cannot run away unnoticed), then round with a straight-through estimator
    xc = torch.clamp(x, -qmax / scale, qmax / scale)
    xq = torch.floor(xc * scale + 0.5) / scale
    return xc + (xq - xc).detach()


class ActQuant(nn.Module):
    """Activation quantizer with an EMA of the observed max-abs value.

    The exponent is derived from the running max and optionally capped so that
    the integer pipeline can realise it with a right shift (cap = exponent of
    the accumulator feeding this quantizer).
    """

    def __init__(self, qmax=Q.QMAX, momentum=0.05):
        super().__init__()
        self.qmax = qmax
        self.momentum = momentum
        self.register_buffer("running_max", torch.zeros(()))
        self.register_buffer("initialized", torch.zeros((), dtype=torch.bool))

    def exponent(self, cap=None, floor=None) -> int:
        e = exponent_for(float(self.running_max), self.qmax)
        if cap is not None:
            e = min(e, int(cap))
        if floor is not None:
            e = max(e, int(floor))
        return e

    def forward(self, x, cap=None, floor=None):
        if self.training:
            m = x.detach().abs().max()
            if not bool(self.initialized):
                self.running_max.copy_(m)
                self.initialized.fill_(True)
            else:
                self.running_max.mul_(1 - self.momentum).add_(m * self.momentum)
        e = self.exponent(cap, floor)
        return fake_quant(x, e, self.qmax), e


class QLinear(nn.Module):
    """Linear layer (no bias) with a per-tensor int7 power-of-two weight quantizer.
    `gain` (if given) is the RMSNorm gain of the preceding norm, folded into W."""

    def __init__(self, d_in, d_out):
        super().__init__()
        self.weight = nn.Parameter(torch.empty(d_out, d_in))
        nn.init.normal_(self.weight, std=0.02 * math.sqrt(48 / d_in))

    def effective_weight(self, gain=None):
        w = self.weight
        if gain is not None:
            w = w * gain[None, :]
        return w

    def quantized(self, gain=None):
        """Return (fake-quantized weight, exponent)."""
        w = self.effective_weight(gain)
        e = exponent_for(float(w.detach().abs().max()), Q.QMAX)
        return fake_quant(w, e, Q.QMAX), e

    def int_weight(self, gain=None):
        w, e = self.quantized(gain)
        return torch.round(w.detach() * (2.0 ** e)).to(torch.int32), e

    def forward(self, x, gain=None):
        w, e = self.quantized(gain)
        return F.linear(x, w), e


class RMSNormQ(nn.Module):
    """RMSNorm whose output is quantized to int7 with the fixed exponent E_NORM.
    The learnable gain is not applied here; it is folded into the consumer."""

    def __init__(self, d, eps=1e-6):
        super().__init__()
        self.gain = nn.Parameter(torch.ones(d))
        self.eps = eps

    def forward(self, x):
        rms = torch.sqrt(torch.mean(x * x, dim=-1, keepdim=True) + self.eps)
        return fake_quant(x / rms, Q.E_NORM, Q.QMAX)


class Block(nn.Module):
    def __init__(self, cfg: ModelConfig):
        super().__init__()
        d = cfg.d_model
        self.cfg = cfg
        self.norm1 = RMSNormQ(d)
        self.wq, self.wk, self.wv, self.wo = QLinear(d, d), QLinear(d, d), QLinear(d, d), QLinear(d, d)
        self.aq_q, self.aq_k, self.aq_v, self.aq_o = ActQuant(), ActQuant(), ActQuant(), ActQuant()
        self.norm2 = RMSNormQ(d)
        self.w1, self.w2 = QLinear(d, cfg.d_ff), QLinear(cfg.d_ff, d)
        self.aq_f, self.aq_f2 = ActQuant(), ActQuant()

    def forward(self, h, mask):
        cfg = self.cfg
        B, T, D = h.shape
        H, HD = cfg.n_heads, cfg.head_dim
        n = self.norm1(h)
        q, e_wq = self.wq(n, self.norm1.gain)
        k, e_wk = self.wk(n, self.norm1.gain)
        v, e_wv = self.wv(n, self.norm1.gain)
        q, e_q = self.aq_q(q, e_wq + Q.E_NORM)
        k, e_k = self.aq_k(k, e_wk + Q.E_NORM)
        v, e_v = self.aq_v(v, e_wv + Q.E_NORM)
        q = q.view(B, T, H, HD).transpose(1, 2)
        k = k.view(B, T, H, HD).transpose(1, 2)
        v = v.view(B, T, H, HD).transpose(1, 2)
        att = (q @ k.transpose(-2, -1)) / math.sqrt(HD)
        att = att.masked_fill(mask[:T, :T] == 0, float("-inf"))
        att = F.softmax(att, dim=-1)
        o = (att @ v).transpose(1, 2).reshape(B, T, D)
        o = fake_quant(o, e_v, Q.QMAX)                     # weighted mean of int7 values
        a, e_wo = self.wo(o)
        a, e_ao = self.aq_o(a, min(e_wo + e_v, cfg.e_res), cfg.e_res - 8)
        h = fake_quant(h + a, cfg.e_res, 32767)
        n2 = self.norm2(h)
        f, e_w1 = self.w1(n2, self.norm2.gain)
        f = F.relu(f)
        f, e_f = self.aq_f(f, e_w1 + Q.E_NORM)
        a2, e_w2 = self.w2(f)
        a2, e_fo = self.aq_f2(a2, min(e_w2 + e_f, cfg.e_res), cfg.e_res - 8)
        h = fake_quant(h + a2, cfg.e_res, 32767)
        return h

    def exponents(self):
        """Integer exponents used by the exporter (must mirror forward())."""
        _, e_wq = self.wq.quantized(self.norm1.gain)
        _, e_wk = self.wk.quantized(self.norm1.gain)
        _, e_wv = self.wv.quantized(self.norm1.gain)
        _, e_wo = self.wo.quantized()
        _, e_w1 = self.w1.quantized(self.norm2.gain)
        _, e_w2 = self.w2.quantized()
        e_q = self.aq_q.exponent(e_wq + Q.E_NORM)
        e_k = self.aq_k.exponent(e_wk + Q.E_NORM)
        e_v = self.aq_v.exponent(e_wv + Q.E_NORM)
        e_ao = self.aq_o.exponent(min(e_wo + e_v, self.cfg.e_res), self.cfg.e_res - 8)
        e_f = self.aq_f.exponent(e_w1 + Q.E_NORM)
        e_fo = self.aq_f2.exponent(min(e_w2 + e_f, self.cfg.e_res), self.cfg.e_res - 8)
        return dict(e_wq=e_wq, e_wk=e_wk, e_wv=e_wv, e_wo=e_wo, e_w1=e_w1, e_w2=e_w2,
                    e_q=e_q, e_k=e_k, e_v=e_v, e_ao=e_ao, e_f=e_f, e_fo=e_fo)


class NanoGPT(nn.Module):
    def __init__(self, cfg: ModelConfig):
        super().__init__()
        cfg.validate()
        assert cfg.vocab_size == tok.VOCAB_SIZE, \
            f"model vocabulary ({cfg.vocab_size}) differs from the active tokenizer ({tok.VOCAB_SIZE}): call tokenizer.set_vocab first"
        self.cfg = cfg
        self.tok_emb = nn.Parameter(torch.randn(cfg.vocab_size, cfg.d_model) * 0.3)
        self.pos_emb = nn.Parameter(torch.randn(cfg.ctx, cfg.d_model) * 0.3)
        self.blocks = nn.ModuleList([Block(cfg) for _ in range(cfg.n_layers)])
        self.norm_f = RMSNormQ(cfg.d_model)
        self.lm_head = QLinear(cfg.d_model, cfg.vocab_size)
        self.register_buffer("mask", torch.tril(torch.ones(cfg.ctx, cfg.ctx)), persistent=False)

    # -- embedding quantization (int8, exponent capped by e_res) ------------
    def emb_exponents(self):
        lo, hi = self.cfg.e_res - 7, self.cfg.e_res   # (127 << 7) * 2 still fits int16
        e_tok = max(lo, min(exponent_for(float(self.tok_emb.detach().abs().max()), Q.EMB_QMAX), hi))
        e_pos = max(lo, min(exponent_for(float(self.pos_emb.detach().abs().max()), Q.EMB_QMAX), hi))
        return e_tok, e_pos

    def forward(self, idx, targets=None, loss_mask=None):
        B, T = idx.shape
        assert T <= self.cfg.ctx
        e_tok, e_pos = self.emb_exponents()
        tok = fake_quant(self.tok_emb, e_tok, Q.EMB_QMAX)[idx]
        pos = fake_quant(self.pos_emb, e_pos, Q.EMB_QMAX)[:T][None, :, :]
        h = tok + pos
        for blk in self.blocks:
            h = blk(h, self.mask)
        n = self.norm_f(h)
        logits, _ = self.lm_head(n, self.norm_f.gain)
        loss = None
        if targets is not None:
            l = F.cross_entropy(logits.reshape(-1, logits.size(-1)), targets.reshape(-1), reduction="none")
            if loss_mask is not None:
                m = loss_mask.reshape(-1).float()
                loss = (l * m).sum() / m.sum().clamp(min=1.0)
            else:
                loss = l.mean()
        return logits, loss

    def num_params(self):
        return sum(p.numel() for p in self.parameters())

    @torch.no_grad()
    def generate(self, idx, max_new_tokens, temperature=0.0, stop_token=None):
        """Float-model generation (greedy when temperature == 0)."""
        self.eval()
        for _ in range(max_new_tokens):
            if idx.size(1) >= self.cfg.ctx:
                break
            logits, _ = self(idx)
            logits = logits[:, -1, :]
            if temperature <= 0:
                nxt = logits.argmax(-1, keepdim=True)
            else:
                probs = F.softmax(logits / temperature, dim=-1)
                nxt = torch.multinomial(probs, 1)
            idx = torch.cat([idx, nxt], dim=1)
            if stop_token is not None and int(nxt) == stop_token:
                break
        return idx


def save_checkpoint(model: NanoGPT, path, extra=None):
    torch.save({"config": asdict(model.cfg), "vocab": tok.extra_vocab(), "state_dict": model.state_dict(),
                "extra": extra or {}}, path)


def load_checkpoint(path, map_location="cpu"):
    """Load a checkpoint and install its learned vocabulary in the tokenizer."""
    ck = torch.load(path, map_location=map_location)
    tok.set_vocab(ck.get("vocab", []))
    d = {k: v for k, v in ck["config"].items() if k in ModelConfig.__dataclass_fields__}
    d.setdefault("n_extra_tokens", len(ck.get("vocab", [])))
    cfg = ModelConfig(**d)
    model = NanoGPT(cfg)
    model.load_state_dict(ck["state_dict"])
    model.eval()
    return model, ck.get("extra", {})


if __name__ == "__main__":
    cfg = ModelConfig()
    m = NanoGPT(cfg)
    print("params:", m.num_params())
    x = torch.randint(0, cfg.vocab_size, (2, 16))
    logits, loss = m(x, x)
    print(logits.shape, float(loss))
