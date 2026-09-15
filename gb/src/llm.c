/* Integer transformer inference for the Game Boy (SM83 CPU, no multiplier).
 *
 * Reference: llm/simulate.py. Every arithmetic step here has a matching line
 * there; the two must produce identical tokens for identical inputs
 * (tools/selftest.py checks this stage by stage in an emulator).
 *
 * Memory map used by this file
 *   ROM bank 0     : this code, the unrolled dot-product routine (gen/dot_gen.s),
 *                    the SQ lookup table (0x3E00), mathasm.s and descriptor tables.
 *   ROM banks 1..N : weight matrices (biased int7 bytes + per-row sums of squares).
 *   SRAM bank 2l   : K cache of layer l   [M_T][M_D] biased bytes, then ksq[M_T][M_H] (uint16)
 *   SRAM bank 2l+1 : V cache of layer l, transposed and position-reversed
 *                    [M_D][M_T] biased bytes, then vsq[M_D] (uint32), vsum[M_D] (int16)
 *
 * Dot products: the SM83 has no multiply instruction. Weight rows and the
 * activation vector are stored as biased bytes (value + 63) and
 *     sum_i w_i x_i = ( sum_i SQ[w_i + x_i] - sum_i w_i^2 - sum_i x_i^2 ) / 2
 * with SQ a 253-entry table of squares; see gen/dot_gen.s and mathasm.s.
 */
#include <gb/gb.h>
#include <string.h>
#include <stdint.h>
#include "llm.h"
#include "mathasm.h"
#include "../gen/model_weights.h"

#ifdef SELFTEST
void dbg_sync(uint8_t id);
uint32_t dbg_ss, dbg_inv; uint16_t dbg_r; int32_t dbg_prod;
#define DBG(id) dbg_sync(id)
#else
#define DBG(id)
#endif

/* ---- interface with dot_gen.s --------------------------------------------- */
uint8_t xvec[M_NMAX];          /* biased activation vector (right-aligned) */
uint16_t dot_ptr;              /* address of the weight row to consume */
uint32_t dot_acc;              /* sum of SQ[w+x] over the row */
extern const uint8_t exp_tbl[256];

/* SDCC 4.4 miscompiles `CONST32 / uint16` into a signed 16-bit divide when the
 * constant fits in 16 bits; loading the constant from a volatile avoids that. */
static volatile uint32_t norm_k_v = M_NORM_K;

/* ---- working memory (WRAM) ----------------------------------------------- */
int32_t logits[M_V];
int16_t h[M_D];
int8_t nbuf[M_D];
int8_t q[M_D], k[M_D], v[M_D], o[M_D], a[M_D];
int8_t f[M_F];
int32_t scores[M_T];
uint8_t evec[M_T];
static uint8_t pos;
static uint16_t rng_state = 0x1234;

/* ---- SRAM cache layout ---------------------------------------------------- */
#define SRAM ((uint8_t *)0xA000)
#define KCACHE       (SRAM)                                       /* [M_T][M_D] */
#define KSQ          ((uint16_t *)(SRAM + (uint16_t)M_T * M_D))   /* [M_T][M_H] */
#define VTCACHE      (SRAM)                                       /* [M_D][M_T], position p at index M_T-1-p */
#define VSQ          ((uint32_t *)(SRAM + (uint16_t)M_D * M_T))   /* [M_D] */
#define VSUM         ((int16_t *)(SRAM + (uint16_t)M_D * M_T + 4 * M_D)) /* [M_D] */

/* ---- small integer helpers ------------------------------------------------ */
static uint16_t isqrt32(uint32_t n)
{
    uint32_t res = 0, bit = 1UL << 30;
    while (bit > n) bit >>= 2;
    while (bit) {
        if (n >= res + bit) { n -= res + bit; res = (res >> 1) + bit; }
        else res >>= 1;
        bit >>= 2;
    }
    return (uint16_t)res;
}

/* copy x (n values) biased into the tail of xvec, return sum of squares */
static uint32_t load_x(const int8_t *x, uint8_t n)
{
    uint8_t *dst = xvec + (M_NMAX - n);
    uint32_t sq = 0;
    uint8_t i;
    for (i = 0; i < n; i++) {
        int8_t xi = x[i];
        dst[i] = (uint8_t)(xi + M_BIAS);
        sq += SQ7(xi);
    }
    return sq;
}

/* out[r] = requant( W[r] . x ) for r < rows; W rows of n bytes in ROM bank mt->bank */
static void matvec(const mat_t *mt, uint8_t rows, uint8_t n, uint32_t xsq, uint8_t shift, int8_t *out, int8_t lo)
{
    SWITCH_ROM(mt->bank);
    mv_row = (uint16_t)mt->w;
    mv_stride = n;
    mv_sq = (uint16_t)mt->sq;
    mv_sqstride = 4;
    mv_sq16 = 0;
    mv_xsq = xsq;
    mv_entry = (uint16_t)dot_entries[(M_NMAX - n) >> 4];
    mv_rows = rows;
    mv_mode = 0;
    mv_shift = shift;
    mv_lo = lo;
    mv_out = (uint16_t)out;
    mv_run();
}

static uint16_t abs16(int16_t x)
{
    uint16_t ax = (x < 0) ? (uint16_t)(-x) : (uint16_t)x;
    return (ax > 32767U) ? 32767U : ax;
}

/* nbuf = int7( h / rms(h) * 2^E_NORM )
 * rms is estimated from 6-bit mantissas (|h| >> s) squared through the SQ
 * table; the per-vector scale inv/2^shift is then applied by norm_scale(). */
static void rmsnorm_q(void)
{
    uint32_t ss = 0, inv;
    uint16_t m = 0, r, ax;
    uint8_t i, s = 0, e = 0;
    for (i = 0; i < M_D; i++) {
        ax = abs16(h[i]);
        if (ax > m) m = ax;
    }
    while ((m >> s) > M_QMAX) s++;
    for (i = 0; i < M_D; i++) {
        ax = abs16(h[i]) >> s;
        ss += SQ7((int8_t)ax);
    }
    r = isqrt32(ss);
    if (r == 0) r = 1;
    inv = norm_k_v / r;
    while (inv > 0xFFFFUL) { inv >>= 1; e++; }
#ifdef SELFTEST
    dbg_ss = ss; dbg_r = r; dbg_inv = inv; dbg_prod = M_NORM_K_BITS + s - e;
#endif
    ns_inv = (uint16_t)inv;
    ns_shift = M_NORM_K_BITS + s - e;
    ns_n = M_D;
    norm_scale();
}

/* h += src << rs, saturated to int16 (rs <= 8, so src << rs fits in int16) */
static void residual_add(const int8_t *src, uint8_t rs)
{
    uint8_t i;
    for (i = 0; i < M_D; i++) {
        int16_t t = (int16_t)src[i] << rs;
        int16_t x = h[i];
        if (t > 0 && x > (int16_t)(32767 - t)) x = 32767;
        else if (t < 0 && x < (int16_t)(-32768 - t)) x = -32768;
        else x += t;
        h[i] = x;
    }
}

/* ---- attention for one layer at position `pos`: q,k,v -> o ---------------- */
static void attention(uint8_t l, const layer_cfg_t *cfg)
{
    uint8_t hh, i, pp;
    uint8_t p = pos;

    /* append k to the K cache (bank 2l) */
    SWITCH_RAM(2 * l);
    {
        uint8_t *krow = KCACHE + (uint16_t)p * M_D;
        uint16_t *ksq = KSQ + (uint16_t)p * M_H;
        for (i = 0; i < M_D; i++) krow[i] = (uint8_t)(k[i] + M_BIAS);
        for (hh = 0; hh < M_H; hh++) {
            uint16_t s = 0;
            const int8_t *kh = k + hh * M_HD;
            for (i = 0; i < M_HD; i++) s += SQ7(kh[i]);
            ksq[hh] = s;
        }
    }
    /* append v to the transposed V cache (bank 2l+1) */
    SWITCH_RAM(2 * l + 1);
    {
        uint8_t *vt = VTCACHE + (M_T - 1 - p);
        uint32_t *vsq = VSQ;
        int16_t *vsum = VSUM;
        for (i = 0; i < M_D; i++) {
            int8_t vi = v[i];
            *vt = (uint8_t)(vi + M_BIAS);
            vt += M_T;
            vsq[i] += SQ7(vi);
            vsum[i] += vi;
        }
    }

    for (hh = 0; hh < M_H; hh++) {
        int32_t mx;
        uint16_t E = 0;
        uint32_t esq = 0;
        uint8_t j;
        /* scores[pp] = k[pp,head] . q[head] */
        SWITCH_RAM(2 * l);
        mv_xsq = load_x(q + hh * M_HD, M_HD);
        mv_row = (uint16_t)(KCACHE + hh * M_HD);
        mv_stride = M_D;
        mv_sq = (uint16_t)(KSQ + hh);
        mv_sqstride = 2 * M_H;
        mv_sq16 = 1;
        mv_entry = (uint16_t)dot_entries[(M_NMAX - M_HD) >> 4];
        mv_rows = p + 1;
        mv_mode = 1;
        mv_out = (uint16_t)scores;
        mv_run();

        mx = scores[0];
        for (pp = 1; pp <= p; pp++) if (scores[pp] > mx) mx = scores[pp];
        /* softmax weights e[pp] in 0..127 via the exp table */
        for (pp = 0; pp <= p; pp++) {
            int32_t d = mx - scores[pp];
            uint16_t u;
            uint8_t e;
            if (d > M_MAX_LOGIT_DIFF) d = M_MAX_LOGIT_DIFF;
            u = (uint16_t)((uint32_t)MUL16S((int16_t)d, cfg->att_mul) >> M_SCALE_SHIFT);
            if (u > 255) u = 255;
            e = exp_tbl[u];
            evec[pp] = e;
            E += e;
        }
        /* e vector reversed into xvec: position pp at index M_NMAX-1-pp, as biased bytes */
        j = (uint8_t)(((M_NMAX - 1 - p) >> 4) << 4);
        for (i = j; i < (uint8_t)(M_NMAX - 1 - p); i++) xvec[i] = M_BIAS;
        for (pp = 0; pp <= p; pp++) {
            int8_t x = (int8_t)(evec[pp] - M_BIAS);
            xvec[M_NMAX - 1 - pp] = evec[pp];
            esq += SQ7(x);
        }
        /* o[i] = sum_pp e[pp] v[pp][i] / E  */
        SWITCH_RAM(2 * l + 1);
        mv_xsq = esq;
        mv_row = (uint16_t)(VTCACHE + (uint16_t)(hh * M_HD) * M_T + (j - (M_NMAX - M_T)));
        mv_stride = M_T;
        mv_sq = (uint16_t)(VSQ + hh * M_HD);
        mv_sqstride = 4;
        mv_sq16 = 0;
        mv_entry = (uint16_t)dot_entries[j >> 4];
        mv_rows = M_HD;
        mv_mode = 1;
        mv_out = (uint16_t)scores;
        mv_run();
        {
            const int16_t *vsum = VSUM + hh * M_HD;
            dq_den = E;
            for (i = 0; i < M_HD; i++) {
                dq_num = scores[i] + MUL16S(vsum[i], M_BIAS);
                divq();
                o[hh * M_HD + i] = dq_res;
            }
        }
    }
}

/* ---- public API ----------------------------------------------------------- */
void llm_seed(uint16_t seed)
{
    rng_state = seed ? seed : 1;
}

void llm_reset(void)
{
    uint8_t l, i;
    for (l = 0; l < M_L; l++) {
        SWITCH_RAM(2 * l + 1);
        memset(VTCACHE, M_BIAS, (uint16_t)M_D * M_T);
        for (i = 0; i < M_D; i++) { VSQ[i] = 0; VSUM[i] = 0; }
    }
    pos = 0;
}

void llm_init(void)
{
    ENABLE_RAM;
    llm_reset();
}

uint8_t llm_pos(void)
{
    return pos;
}

void llm_feed(uint8_t t)
{
    uint8_t i, l;
    uint32_t xsq;

    SWITCH_ROM(TOK_EMB_BANK);
    {
        const int8_t *te = tok_emb + (uint16_t)t * M_D;
        for (i = 0; i < M_D; i++) h[i] = (int16_t)te[i] << M_TOK_SHIFT;
    }
    SWITCH_ROM(POS_EMB_BANK);
    {
        const int8_t *pe = pos_emb + (uint16_t)pos * M_D;
        for (i = 0; i < M_D; i++) h[i] += (int16_t)pe[i] << M_POS_SHIFT;
    }
    DBG(1);
    for (l = 0; l < M_L; l++) {
        const layer_cfg_t *cfg = &layer_cfg[l];
        rmsnorm_q();
        DBG(10 * l + 11);
        xsq = load_x(nbuf, M_D);
        matvec(&mat_wq[l], M_D, M_D, xsq, cfg->s_q, q, -M_QMAX);
        matvec(&mat_wk[l], M_D, M_D, xsq, cfg->s_k, k, -M_QMAX);
        matvec(&mat_wv[l], M_D, M_D, xsq, cfg->s_v, v, -M_QMAX);
        DBG(10 * l + 12);
        attention(l, cfg);
        DBG(10 * l + 13);
        xsq = load_x(o, M_D);
        matvec(&mat_wo[l], M_D, M_D, xsq, cfg->s_ao, a, -M_QMAX);
        DBG(10 * l + 14);
        residual_add(a, cfg->rs_a);
        DBG(10 * l + 15);
        rmsnorm_q();
        DBG(10 * l + 16);
        xsq = load_x(nbuf, M_D);
        matvec(&mat_w1[l], M_F, M_D, xsq, cfg->s_f, f, 0);
        DBG(10 * l + 17);
        xsq = load_x(f, M_F);
        matvec(&mat_w2[l], M_D, M_F, xsq, cfg->s_fo, a, -M_QMAX);
        DBG(10 * l + 18);
        residual_add(a, cfg->rs_f);
        DBG(10 * l + 19);
    }
    rmsnorm_q();
    DBG(100);
    xsq = load_x(nbuf, M_D);
    SWITCH_ROM(mat_lm.bank);
    mv_row = (uint16_t)mat_lm.w;
    mv_stride = M_D;
    mv_sq = (uint16_t)mat_lm.sq;
    mv_sqstride = 4;
    mv_sq16 = 0;
    mv_xsq = xsq;
    mv_entry = (uint16_t)dot_entries[(M_NMAX - M_D) >> 4];
    mv_rows = M_V;
    mv_mode = 1;
    mv_out = (uint16_t)logits;
    mv_run();
    DBG(101);
    pos++;
}

static uint16_t rng_next(void)
{
    uint16_t x = rng_state;
    x ^= x << 7;
    x ^= x >> 9;
    x ^= x << 8;
    rng_state = x;
    return x;
}

uint8_t llm_pick(uint8_t sample)
{
    uint8_t i, best = 0;
    int32_t mx = logits[0];
    for (i = 1; i < M_V; i++) if (logits[i] > mx) { mx = logits[i]; best = i; }
    if (!sample) return best;
    {
        static uint8_t ev[M_V];
        uint16_t total = 0, r, acc = 0;
        for (i = 0; i < M_V; i++) {
            int32_t d = mx - logits[i];
            uint16_t u;
            uint8_t e;
            if (d > M_MAX_LOGIT_DIFF) d = M_MAX_LOGIT_DIFF;
            u = (uint16_t)((uint32_t)MUL16S((int16_t)d, M_LM_MUL) >> M_SCALE_SHIFT);
            if (u > 255) u = 255;
            e = exp_tbl[u];
            if (i == TOK_PAD || i == TOK_USR || i == TOK_BOT) e = 0;
            ev[i] = e;
            total += e;
        }
        r = rng_next() % total;
        for (i = 0; i < M_V; i++) {
            acc += ev[i];
            if (r < acc) return i;
        }
        return M_V - 1;
    }
}
