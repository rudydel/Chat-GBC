/* Interface to the hand-written helpers in mathasm.s (arguments via globals). */
#ifndef MATHASM_H
#define MATHASM_H
#include <stdint.h>

extern uint16_t mv_row, mv_stride, mv_sq, mv_entry, mv_out;
extern uint8_t mv_sqstride, mv_sq16, mv_rows, mv_mode, mv_shift;
extern int8_t mv_lo;
extern uint32_t mv_xsq;
void mv_run(void);

extern int16_t mul_a;
extern uint16_t mul_b;
extern int32_t mul_r;
void mul16s(void);
#define MUL16S(a, b) (mul_a = (a), mul_b = (b), mul16s(), mul_r)

/* SQ table (gen/dot_gen.s): SQ[k] = (k - 126)^2, low bytes at 0x3E00, high bytes at 0x3F00 */
#define SQ_LO ((const uint8_t *)0x3E00)
#define SQ_HI ((const uint8_t *)0x3F00)
/* x^2 for x in [-63, 63] */
#define SQ7(x) ((uint16_t)(((uint16_t)SQ_HI[(uint8_t)((x) + (x) + 126)] << 8 | SQ_LO[(uint8_t)((x) + (x) + 126)]) >> 2))



/* nbuf[i] = clamp(round_shift(h[i] * ns_inv, ns_shift), -63, 63) for i < ns_n */
extern uint16_t ns_inv;
extern uint8_t ns_shift, ns_n;
void norm_scale(void);

/* dq_res = clamp(round(dq_num / dq_den), -63, 63); |dq_num| <= 63 * dq_den < 2^23 */
extern int32_t dq_num;
extern uint16_t dq_den;
extern int8_t dq_res;
void divq(void);
#endif
