"""Extract the integer model (weights + exponents + derived constants) from a
quantization-aware checkpoint. The result is a plain dict of Python ints and
numpy int arrays that both simulate.py and export.py consume."""
import json
import numpy as np

from . import quant as Q
from . import tokenizer as tok

# torch is only needed to extract() a checkpoint; load_json() / simulate.py
# (and the emulator tests built on them) must work with numpy alone.


def _int_tensor(t, e, qmax):
    import torch
    return torch.clamp(torch.round(t.detach() * (2.0 ** e)), -qmax, qmax).to(torch.int32).cpu().numpy()


def extract(model) -> dict:
    from .model import ModelConfig
    cfg = model.cfg
    model.eval()
    e_tok, e_pos = model.emb_exponents()
    m = {
        "config": {k: getattr(cfg, k) for k in ModelConfig.__dataclass_fields__},
        "e_res": cfg.e_res,
        "e_norm": Q.E_NORM,
        "e_tok": e_tok,
        "e_pos": e_pos,
        "vocab": tok.extra_vocab(),          # learned subword tokens (ids 54..), see tokenizer.py
        "tok_emb": _int_tensor(model.tok_emb, e_tok, Q.EMB_QMAX),
        "pos_emb": _int_tensor(model.pos_emb, e_pos, Q.EMB_QMAX),
        "layers": [],
    }
    m["norm_k"] = Q.norm_constant(cfg.d_model)
    for blk in model.blocks:
        ex = blk.exponents()
        wq, _ = blk.wq.int_weight(blk.norm1.gain)
        wk, _ = blk.wk.int_weight(blk.norm1.gain)
        wv, _ = blk.wv.int_weight(blk.norm1.gain)
        wo, _ = blk.wo.int_weight()
        w1, _ = blk.w1.int_weight(blk.norm2.gain)
        w2, _ = blk.w2.int_weight()
        att_mul, att_shift = Q.attn_scale(cfg.head_dim, ex["e_q"], ex["e_k"])
        layer = dict(ex)
        layer.update({
            "wq": wq.numpy(), "wk": wk.numpy(), "wv": wv.numpy(), "wo": wo.numpy(),
            "w1": w1.numpy(), "w2": w2.numpy(),
            "s_q": ex["e_wq"] + Q.E_NORM - ex["e_q"],
            "s_k": ex["e_wk"] + Q.E_NORM - ex["e_k"],
            "s_v": ex["e_wv"] + Q.E_NORM - ex["e_v"],
            "s_ao": ex["e_wo"] + ex["e_v"] - ex["e_ao"],
            "rs_a": cfg.e_res - ex["e_ao"],
            "s_f": ex["e_w1"] + Q.E_NORM - ex["e_f"],
            "s_fo": ex["e_w2"] + ex["e_f"] - ex["e_fo"],
            "rs_f": cfg.e_res - ex["e_fo"],
            "att_mul": att_mul, "att_shift": att_shift,
        })
        for k in ("s_q", "s_k", "s_v", "s_ao", "rs_a", "s_f", "s_fo", "rs_f"):
            assert 0 <= layer[k] <= 24, (k, layer[k])
        m["layers"].append(layer)
    lm, e_lm = model.lm_head.int_weight(model.norm_f.gain)
    m["lm_head"] = lm.numpy()
    m["e_lm"] = e_lm
    m["e_logit"] = e_lm + Q.E_NORM
    m["lm_mul"], m["lm_shift"] = Q.lm_scale(m["e_logit"], cfg.temperature)
    return m


def save_json(m: dict, path):
    def conv(v):
        if isinstance(v, np.ndarray):
            return v.tolist()
        if isinstance(v, (np.integer,)):
            return int(v)
        if isinstance(v, dict):
            return {k: conv(x) for k, x in v.items()}
        if isinstance(v, list):
            return [conv(x) for x in v]
        return v
    with open(path, "w") as f:
        json.dump(conv(m), f)


def load_json(path) -> dict:
    with open(path) as f:
        m = json.load(f)
    tok.set_vocab(m.get("vocab", []))       # the integer model carries its vocabulary
    for k in ("tok_emb", "pos_emb", "lm_head"):
        m[k] = np.array(m[k], dtype=np.int64)
    for layer in m["layers"]:
        for k in ("wq", "wk", "wv", "wo", "w1", "w2"):
            layer[k] = np.array(layer[k], dtype=np.int64)
    return m


def summary(m: dict) -> str:
    cfg = m["config"]
    n = m["tok_emb"].size + m["pos_emb"].size + m["lm_head"].size
    for l in m["layers"]:
        n += sum(l[k].size for k in ("wq", "wk", "wv", "wo", "w1", "w2"))
    lines = [f"model {cfg['name']}: d={cfg['d_model']} layers={cfg['n_layers']} heads={cfg['n_heads']} "
             f"ff={cfg['d_ff']} ctx={cfg['ctx']} params={n}",
             f"  e_res={m['e_res']} e_tok={m['e_tok']} e_pos={m['e_pos']} e_logit={m['e_logit']} "
             f"lm_mul={m['lm_mul']}>>{m['lm_shift']} norm_k={m['norm_k']}"]
    for i, l in enumerate(m["layers"]):
        lines.append("  layer %d: " % i + " ".join(f"{k}={l[k]}" for k in
                     ("e_wq", "e_wk", "e_wv", "e_wo", "e_w1", "e_w2", "e_q", "e_k", "e_v", "e_ao", "e_f", "e_fo",
                      "s_q", "s_k", "s_v", "s_ao", "rs_a", "s_f", "s_fo", "rs_f", "att_mul", "att_shift")))
    return "\n".join(lines)
