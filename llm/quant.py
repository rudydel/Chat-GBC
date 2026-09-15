"""Integer inference specification shared by export.py, simulate.py and the ROM.

Everything the Game Boy does is integer arithmetic. This module is the single
source of truth for the fixed-point formats, so the exporter, the bit-exact
Python simulator and (through the generated header) the C code agree.

Number formats
--------------
* int7 activations / weights: integers in [-QMAX, QMAX] with QMAX = 63.
  A tensor with "exponent" e represents real value  int * 2**-e.
  In memory they are stored *biased*:  byte = int + QMAX  (0..126), which is
  what the SM83 dot-product routine expects.
* Residual stream: int16 with exponent E_RES.
* Accumulators: 24/32-bit integers.

Dot product on the Game Boy
---------------------------
The SM83 CPU has no multiply instruction. The ROM computes
    S = sum_i SQ[wb_i + xb_i]          (one table lookup per element)
with SQ[k] = (k - 2*QMAX)**2 = (w_i + x_i)**2, and then
    dot = (S - sum(w_i**2) - sum(x_i**2)) / 2
The sums of squares of weight rows are precomputed at export time; the sum of
squares of the activation vector is computed once per vector.
"""
import math

QMAX = 63                # int7 symmetric range [-63, 63]
BIAS = QMAX              # biased byte = value + BIAS  (0..126)
SQ_TABLE_LEN = 4 * QMAX + 1   # indices 0..126+126 = 0..252 -> we allocate 256
EMB_QMAX = 127           # embeddings are plain int8 (not used by the dot routine)

E_NORM = 4               # RMSNorm output exponent: value = x/rms * 2**E_NORM
NORM_K_BITS = 16         # NORM_K = 2**E_NORM * sqrt(D) * 2**NORM_K_BITS (see rmsnorm in simulate.py)
SCALE_SHIFT = 16         # exp-table index = (d * mul) >> 16 for attention and LM sampling

EXP_TABLE_LEN = 256
EXP_STEP = 16            # exp table index unit = 1/EXP_STEP nats
EXP_MAX = 126            # e values are int7 after removing the bias: e - 63 in [-63, 63]

MAX_LOGIT_DIFF = 32767   # attention/lm score differences are clamped to this before scaling


def sq_table():
    """SQ[i] = (i - 2*QMAX)**2 for i in 0..255 (entries > 4*QMAX are unused)."""
    return [(i - 2 * QMAX) ** 2 if i <= 4 * QMAX else 0 for i in range(256)]


def exp_table():
    """EXP[i] = round(EXP_MAX * exp(-i / EXP_STEP)), i in 0..255."""
    return [int(round(EXP_MAX * math.exp(-i / EXP_STEP))) for i in range(EXP_TABLE_LEN)]


def isqrt(n: int) -> int:
    return math.isqrt(int(n))


def round_shift(x: int, s: int) -> int:
    """Round-half-up arithmetic right shift (matches the C implementation)."""
    if s <= 0:
        return int(x) << (-s)
    return (int(x) + (1 << (s - 1))) >> s


def clamp(x: int, lo: int, hi: int) -> int:
    return lo if x < lo else hi if x > hi else x


def div_round(num: int, den: int) -> int:
    """Round-to-nearest division with sign symmetric rounding (C-compatible)."""
    if num >= 0:
        return (num + (den >> 1)) // den
    return -((-num + (den >> 1)) // den)


def norm_constant(d_model: int) -> int:
    """NORM_K for the integer RMSNorm (see simulate.rmsnorm_q):
        s   = smallest shift with max|h| >> s <= QMAX
        ss  = sum((|h_i| >> s)**2)            ~ rms**2 * D / 4**s
        inv = NORM_K // isqrt(ss)             ~ 2**E_NORM * 2**NORM_K_BITS * 2**s / rms
        n_i = (h_i * inv) >> (NORM_K_BITS + s)  (inv normalised into 16 bits first)
    """
    k = int(round((2 ** E_NORM) * math.sqrt(d_model) * (2 ** NORM_K_BITS)))
    assert k < (1 << 24)
    return k


def attn_scale(head_dim: int, e_q: int, e_k: int):
    """Return (mul, SCALE_SHIFT) so that (d * mul) >> SCALE_SHIFT ~= d * EXP_STEP / (sqrt(hd) * 2**(e_q+e_k)).
    d is an integer score difference (>= 0). mul is capped to 16 bits."""
    factor = EXP_STEP / (math.sqrt(head_dim) * (2 ** (e_q + e_k)))
    mul = min(0xFFFF, int(round(factor * (2 ** SCALE_SHIFT))))
    return mul, SCALE_SHIFT


def lm_scale(e_logit: int, temperature: float):
    """Same as attn_scale for sampling from the LM head: index ~= d * EXP_STEP / (T * 2**e_logit)."""
    factor = EXP_STEP / (temperature * (2 ** e_logit))
    mul = min(0xFFFF, int(round(factor * (2 ** SCALE_SHIFT))))
    return mul, SCALE_SHIFT


def exp_index(d: int, mul: int, shift: int) -> int:
    """Map a non-negative score difference to an EXP table index (bit-exact with the C code)."""
    if d > MAX_LOGIT_DIFF:
        d = MAX_LOGIT_DIFF
    u = (d * mul) >> shift
    return u if u < EXP_TABLE_LEN - 1 else EXP_TABLE_LEN - 1


def dot_via_table(wb, xb, w_sq: int, x_sq: int) -> int:
    """Reference implementation of the ROM dot product from biased bytes."""
    sq = sq_table()
    s = 0
    for a, b in zip(wb, xb):
        s += sq[a + b]
    return (s - w_sq - x_sq) >> 1
