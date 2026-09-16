;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Linux)
;--------------------------------------------------------
	.module llm
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _dbg_sync
	.globl _divq
	.globl _norm_scale
	.globl _mul16s
	.globl _mv_run
	.globl _memset
	.globl _evec
	.globl _scores
	.globl _f
	.globl _a
	.globl _o
	.globl _v
	.globl _k
	.globl _q
	.globl _nbuf
	.globl _h
	.globl _logits
	.globl _dot_acc
	.globl _dot_ptr
	.globl _xvec
	.globl _dbg_prod
	.globl _dbg_r
	.globl _dbg_inv
	.globl _dbg_ss
	.globl _llm_seed
	.globl _llm_reset
	.globl _llm_init
	.globl _llm_pos
	.globl _llm_feed
	.globl _llm_pick
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_dbg_ss::
	.ds 4
_dbg_inv::
	.ds 4
_dbg_r::
	.ds 2
_dbg_prod::
	.ds 4
_xvec::
	.ds 96
_dot_ptr::
	.ds 2
_dot_acc::
	.ds 4
_logits::
	.ds 512
_h::
	.ds 64
_nbuf::
	.ds 32
_q::
	.ds 32
_k::
	.ds 32
_v::
	.ds 32
_o::
	.ds 32
_a::
	.ds 32
_f::
	.ds 64
_scores::
	.ds 384
_evec::
	.ds 96
_pos:
	.ds 1
_llm_pick_ev_20000_236:
	.ds 128
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
_norm_k_v:
	.ds 4
_rng_state:
	.ds 2
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;src/llm.c:65: static uint16_t isqrt32(uint32_t n)
;	---------------------------------
; Function isqrt32
; ---------------------------------
_isqrt32:
	add	sp, #-20
	ldhl	sp,	#12
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:67: uint32_t res = 0, bit = 1UL << 30;
	xor	a, a
	ldhl	sp,	#0
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), a
	xor	a, a
	ldhl	sp,	#16
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), #0x40
;src/llm.c:68: while (bit > n) bit >>= 2;
00101$:
	ldhl	sp,	#12
	ld	e, l
	ld	d, h
	ldhl	sp,	#16
	ld	a, (de)
	inc	de
	sub	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	sbc	a, (hl)
	jr	NC, 00107$
	ld	a, #0x02
00147$:
	ldhl	sp,	#19
	srl	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	a
	jr	NZ, 00147$
	jr	00101$
;src/llm.c:69: while (bit) {
00107$:
	ldhl	sp,	#19
	ld	a, (hl-)
	or	a, (hl)
	dec	hl
	or	a, (hl)
	dec	hl
	or	a, (hl)
	jp	Z, 00109$
;src/llm.c:70: if (n >= res + bit) { n -= res + bit; res = (res >> 1) + bit; }
	pop	de
	push	de
	ld	a, e
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#7
	ld	(hl-), a
	ld	a, e
	ld	(hl-), a
	dec	hl
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#20
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#7
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,	#0
	ld	a, (hl)
	ldhl	sp,	#8
	ld	(hl), a
	ldhl	sp,	#1
	ld	a, (hl)
	ldhl	sp,	#9
	ld	(hl), a
	ldhl	sp,	#2
	ld	a, (hl)
	ldhl	sp,	#10
	ld	(hl), a
	ldhl	sp,	#3
	ld	a, (hl)
	ldhl	sp,	#11
	ld	(hl), a
	srl	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	ldhl	sp,	#12
	ld	e, l
	ld	d, h
	ldhl	sp,	#4
	ld	a, (de)
	inc	de
	sub	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	sbc	a, (hl)
	jr	C, 00105$
	ldhl	sp,#12
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#4
	sub	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	push	af
	ldhl	sp,	#15
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#16
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#8
	pop	af
	ld	a, e
	sbc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	ldhl	sp,	#15
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#16
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#3
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#12
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#20
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#3
	ld	(hl-), a
	ld	(hl), e
	jr	00106$
00105$:
;src/llm.c:71: else res >>= 1;
	ldhl	sp,	#8
	ld	d, h
	ld	e, l
	ldhl	sp,	#0
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
00106$:
;src/llm.c:72: bit >>= 2;
	ld	a, #0x02
00151$:
	ldhl	sp,	#19
	srl	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	a
	jr	NZ, 00151$
	jp	00107$
00109$:
;src/llm.c:74: return (uint16_t)res;
	pop	bc
	push	bc
;src/llm.c:75: }
	add	sp, #20
	ret
;src/llm.c:78: static uint32_t load_x(const int8_t *x, uint8_t n)
;	---------------------------------
; Function load_x
; ---------------------------------
_load_x:
	add	sp, #-12
	ldhl	sp,	#6
	ld	(hl), e
	inc	hl
	ld	(hl), d
	ld	c, a
;src/llm.c:80: uint8_t *dst = xvec + (M_NMAX - n);
	ld	de, #_xvec+0
	ld	b, c
	ld	h, #0x00
	ld	a, #0x60
	sub	a, b
	ld	l, a
	sbc	a, a
	sub	a, h
	ld	h, a
	add	hl, de
	ld	b, l
	ld	a, h
	ldhl	sp,	#0
	ld	(hl), b
	inc	hl
	ld	(hl), a
;src/llm.c:81: uint32_t sq = 0;
	xor	a, a
	ldhl	sp,	#8
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:83: for (i = 0; i < n; i++) {
	ld	b, #0x00
00103$:
	ld	a, b
	sub	a, c
	jr	NC, 00101$
;src/llm.c:84: int8_t xi = x[i];
	ldhl	sp,#6
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	l, b
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#5
	ld	(hl), a
;src/llm.c:85: dst[i] = (uint8_t)(xi + M_BIAS);
	pop	de
	push	de
	ld	l, b
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#5
	ld	a, (hl)
	add	a, #0x3f
	ld	(de), a
;src/llm.c:86: sq += SQ7(xi);
	ld	a, (hl)
	add	a, a
	add	a, #0x7e
	ld	l, a
	ld	e, l
	ld	d, #0x3f
	ld	a, (de)
	ld	d, a
	ld	h, #0x3e
	ld	e, (hl)
	srl	d
	rr	e
	srl	d
	rr	e
	ldhl	sp,	#2
	ld	a, e
	ld	(hl+), a
	ld	a, d
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#2
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#11
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#12
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#6
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#11
	ld	(hl-), a
	ld	(hl), e
;src/llm.c:83: for (i = 0; i < n; i++) {
	inc	b
	jr	00103$
00101$:
;src/llm.c:88: return sq;
	ldhl	sp,	#8
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl+)
	ld	b, a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
;src/llm.c:89: }
	add	sp, #12
	ret
;src/llm.c:92: static void matvec(const mat_t *mt, uint8_t rows, uint8_t n, uint32_t xsq, uint8_t shift, int8_t *out, int8_t lo)
;	---------------------------------
; Function matvec
; ---------------------------------
_matvec:
	dec	sp
	ld	c, e
	ld	b, d
	ldhl	sp,	#0
	ld	(hl), a
;src/llm.c:94: SWITCH_ROM(mt->bank);
	ld	hl, #0x0004
	add	hl, bc
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldh	(__current_bank + 0), a
	ld	a, (de)
	ld	(#_rROMB0),a
;src/llm.c:95: mv_row = (uint16_t)mt->w;
	ld	l, c
	ld	h, b
	ld	a,	(hl+)
	ld	h, (hl)
	ld	e, a
	ld	d, h
	ld	hl, #_mv_row
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:96: mv_stride = n;
	ldhl	sp,	#3
	ld	a, (hl)
	ld	hl, #_mv_stride
	ld	(hl+), a
	ld	(hl), #0x00
;src/llm.c:97: mv_sq = (uint16_t)mt->sq;
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl)
	ld	hl, #_mv_sq
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:98: mv_sqstride = 4;
	ld	hl, #_mv_sqstride
	ld	(hl), #0x04
;src/llm.c:99: mv_sq16 = 0;
	xor	a, a
	ld	(#_mv_sq16),a
;src/llm.c:100: mv_xsq = xsq;
	ldhl	sp,	#4
	ld	d, h
	ld	e, l
	ld	hl, #_mv_xsq
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/llm.c:101: mv_entry = (uint16_t)dot_entries[(M_NMAX - n) >> 4];
	ldhl	sp,	#3
	ld	c, (hl)
	ld	b, #0x00
	ld	a, #0x60
	sub	a, c
	ld	l, a
	sbc	a, a
	sub	a, b
	ld	h, a
	sra	h
	rr	l
	sra	h
	rr	l
	sra	h
	rr	l
	sra	h
	rr	l
	add	hl, hl
	ld	de, #_dot_entries
	add	hl, de
	ld	a, (hl+)
	ld	c, (hl)
	ld	hl, #_mv_entry
	ld	(hl+), a
	ld	(hl), c
;src/llm.c:102: mv_rows = rows;
	ldhl	sp,	#0
	ld	a, (hl)
	ld	(#_mv_rows),a
;src/llm.c:103: mv_mode = 0;
	xor	a, a
	ld	(#_mv_mode),a
;src/llm.c:104: mv_shift = shift;
	ldhl	sp,	#8
	ld	a, (hl)
	ld	(#_mv_shift),a
;src/llm.c:105: mv_lo = lo;
	ldhl	sp,	#11
	ld	a, (hl)
	ld	(#_mv_lo),a
;src/llm.c:106: mv_out = (uint16_t)out;
	ldhl	sp,	#9
	ld	a, (hl)
	ld	(#_mv_out),a
	ldhl	sp,	#10
	ld	a, (hl)
	ld	(#_mv_out + 1),a
;src/llm.c:107: mv_run();
	call	_mv_run
;src/llm.c:108: }
	inc	sp
	pop	hl
	add	sp, #9
	jp	(hl)
;src/llm.c:110: static uint16_t abs16(int16_t x)
;	---------------------------------
; Function abs16
; ---------------------------------
_abs16:
	ld	c, e
	ld	b, d
;src/llm.c:112: uint16_t ax = (x < 0) ? (uint16_t)(-x) : (uint16_t)x;
	ld	h, b
	bit	7, h
	jr	Z, 00103$
	xor	a, a
	sub	a, c
	ld	c, a
	sbc	a, a
	sub	a, b
	ld	b, a
00103$:
;src/llm.c:113: return (ax > 32767U) ? 32767U : ax;
	ld	e, c
	ld	d, b
	ld	a, #0xff
	cp	a, e
	ld	a, #0x7f
	sbc	a, d
	ret	NC
	ld	bc, #0x7fff
;src/llm.c:114: }
	ret
;src/llm.c:119: static void rmsnorm_q(void)
;	---------------------------------
; Function rmsnorm_q
; ---------------------------------
_rmsnorm_q:
	add	sp, #-12
;src/llm.c:121: uint32_t ss = 0, inv;
	xor	a, a
	ldhl	sp,	#3
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:122: uint16_t m = 0, r, ax;
	ld	bc, #0x0000
;src/llm.c:124: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	ld	(hl), #0x00
00113$:
;src/llm.c:125: ax = abs16(h[i]);
	ldhl	sp,	#11
	ld	e, (hl)
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	ld	de, #_h
	add	hl, de
	ld	a, (hl+)
	ld	l, (hl)
	push	bc
	ld	e, a
	ld	d, l
	call	_abs16
	ld	e, c
	ld	d, b
	pop	bc
;src/llm.c:126: if (ax > m) m = ax;
	ld	a, c
	sub	a, e
	ld	a, b
	sbc	a, d
	jr	NC, 00114$
	ld	c, e
	ld	b, d
00114$:
;src/llm.c:124: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jr	C, 00113$
;src/llm.c:128: while ((m >> s) > M_QMAX) s++;
	ld	e, #0x00
00104$:
	ld	a, e
	push	af
	ld	d, c
	ld	l, b
	pop	af
	inc	a
	jr	00193$
00192$:
	srl	l
	rr	d
00193$:
	dec	a
	jr	NZ, 00192$
	ld	a, #0x3f
	cp	a, d
	ld	a, #0x00
	sbc	a, l
	jr	NC, 00129$
	inc	e
	jr	00104$
00129$:
	ldhl	sp,	#0
	ld	(hl), e
;src/llm.c:129: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	ld	(hl), #0x00
00115$:
;src/llm.c:130: ax = abs16(h[i]) >> s;
	ldhl	sp,	#11
	ld	c, (hl)
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	ld	de, #_h
	add	hl, de
	ld	a, (hl+)
	ld	c, (hl)
	ld	e, a
	ld	d, c
	call	_abs16
	ldhl	sp,	#0
	ld	a, (hl)
	inc	a
	jr	00195$
00194$:
	srl	b
	rr	c
00195$:
	dec	a
	jr	NZ, 00194$
	ldhl	sp,	#9
	ld	a, c
	ld	(hl+), a
;src/llm.c:131: ss += SQ7((int8_t)ax);
	ld	a, b
	ld	(hl-), a
	ld	a, (hl)
	add	a, a
	add	a, #0x7e
	ld	c, a
	ld	b, c
	ld	h, #0x3f
	ld	l, b
	ld	b, (hl)
	ld	l, c
	ld	h, #0x3e
	ld	c, (hl)
	srl	b
	rr	c
	srl	b
	rr	c
	ldhl	sp,	#7
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
	ldhl	sp,#3
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#7
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#6
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#7
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#11
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#6
	ld	(hl-), a
	ld	(hl), e
;src/llm.c:129: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jr	C, 00115$
;src/llm.c:133: r = isqrt32(ss);
	ldhl	sp,	#3
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl+)
	ld	b, a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	call	_isqrt32
;src/llm.c:134: if (r == 0) r = 1;
	ld	a, b
	or	a, c
	jr	NZ, 00109$
	ld	bc, #0x0001
00109$:
;src/llm.c:135: inv = norm_k_v / r;
	ld	e, c
	ld	d, b
	ld	hl, #0x0000
	push	bc
	push	hl
	push	de
	ld	a, (_norm_k_v)
	ld	c, a
	ld	hl, #_norm_k_v + 1
	ld	a, (hl+)
	ld	b, a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
;src/llm.c:136: while (inv > 0xFFFFUL) { inv >>= 1; e++; }
	call	__divulong
	ldhl	sp,	#9
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
	pop	bc
	ldhl	sp,	#11
	ld	(hl), #0x00
00110$:
	ldhl	sp,	#7
	ld	a, #0xff
	sub	a, (hl)
	inc	hl
	ld	a, #0xff
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	jr	NC, 00112$
	ldhl	sp,	#10
	srl	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	dec	hl
	rr	(hl)
	ldhl	sp,	#11
	inc	(hl)
	jr	00110$
00112$:
;src/llm.c:138: dbg_ss = ss; dbg_r = r; dbg_inv = inv; dbg_prod = M_NORM_K_BITS + s - e;
	ldhl	sp,	#3
	ld	d, h
	ld	e, l
	ld	hl, #_dbg_ss
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ld	hl, #_dbg_r
	ld	a, c
	ld	(hl+), a
	ld	(hl), b
	ldhl	sp,	#7
	ld	d, h
	ld	e, l
	ld	hl, #_dbg_inv
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#0
	ld	c, (hl)
	ld	b, #0x00
	ld	hl, #0x0010
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#3
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#2
	ld	(hl), a
	ldhl	sp,	#11
	ld	a, (hl)
	ldhl	sp,	#3
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	dec	hl
	dec	hl
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	ld	a, e
	sub	a, l
	ld	e, a
	ld	a, d
	sbc	a, h
	ldhl	sp,	#6
	ld	(hl-), a
	ld	(hl), e
	ld	a, (hl)
	ld	(#_dbg_prod),a
	ldhl	sp,	#6
	ld	a, (hl)
	ld	hl, #_dbg_prod + 1
	ld	(hl+), a
	rlca
	sbc	a, a
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:140: ns_inv = (uint16_t)inv;
	ldhl	sp,	#7
	ld	a, (hl)
	ld	(#_ns_inv),a
	ldhl	sp,	#8
	ld	a, (hl)
	ld	(#_ns_inv + 1),a
;src/llm.c:141: ns_shift = M_NORM_K_BITS + s - e;
	ldhl	sp,	#0
	ld	a, (hl)
	add	a, #0x10
	ldhl	sp,	#11
	ld	c, (hl)
	sub	a, c
	ld	(#_ns_shift),a
;src/llm.c:142: ns_n = M_D;
	ld	hl, #_ns_n
	ld	(hl), #0x20
;src/llm.c:143: norm_scale();
	call	_norm_scale
;src/llm.c:144: }
	add	sp, #12
	ret
;src/llm.c:147: static void residual_add(const int8_t *src, uint8_t rs)
;	---------------------------------
; Function residual_add
; ---------------------------------
_residual_add:
	add	sp, #-12
	ldhl	sp,	#9
	ld	(hl), e
	inc	hl
	ld	(hl), d
	dec	hl
	dec	hl
	ld	(hl), a
;src/llm.c:150: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	ld	(hl), #0x00
00110$:
;src/llm.c:151: int16_t t = (int16_t)src[i] << rs;
	ldhl	sp,#9
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ld	c, a
	rlca
	sbc	a, a
	ldhl	sp,	#8
	ld	b, (hl)
	inc	b
	jr	00151$
00150$:
	sla	c
	adc	a, a
00151$:
	dec	b
	jr	NZ,00150$
	ldhl	sp,	#0
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:152: int16_t x = h[i];
	ldhl	sp,	#11
	ld	c, (hl)
	xor	a, a
	ld	b, a
	sla	c
	rl	b
	ld	hl, #_h
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#4
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#3
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	c, a
	inc	de
	ld	a, (de)
	ld	b, a
;src/llm.c:153: if (t > 0 && x > (int16_t)(32767 - t)) x = 32767;
	ldhl	sp,	#0
	ld	a, (hl)
	ldhl	sp,	#4
	ld	(hl), a
	ldhl	sp,	#1
	ld	a, (hl)
	ldhl	sp,	#5
	ld	(hl-), a
	xor	a, a
	sub	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	ld	a, #0x00
	ld	d, a
	bit	7, (hl)
	jr	Z, 00153$
	bit	7, d
	jr	NZ, 00154$
	cp	a, a
	jr	00154$
00153$:
	bit	7, d
	jr	Z, 00154$
	scf
00154$:
	jr	NC, 00106$
	ld	de, #0x7fff
	pop	hl
	push	hl
	ld	a, e
	sub	a, l
	ld	e, a
	ld	a, d
	sbc	a, h
	ldhl	sp,	#7
	ld	(hl-), a
	ld	(hl), e
	ld	a, (hl+)
	sub	a, c
	ld	a, (hl)
	sbc	a, b
	ld	d, (hl)
	ld	a, b
	bit	7,a
	jr	Z, 00155$
	bit	7, d
	jr	NZ, 00156$
	cp	a, a
	jr	00156$
00155$:
	bit	7, d
	jr	Z, 00156$
	scf
00156$:
	jr	NC, 00106$
	ld	bc, #0x7fff
	jr	00107$
00106$:
;src/llm.c:154: else if (t < 0 && x < (int16_t)(-32768 - t)) x = -32768;
	ldhl	sp,	#5
	bit	7, (hl)
	jr	Z, 00102$
	ld	de, #0x8000
	pop	hl
	push	hl
	ld	a, e
	sub	a, l
	ld	e, a
	ld	a, d
	sbc	a, h
	ldhl	sp,	#7
	ld	(hl-), a
	ld	(hl), e
	ld	a, c
	sub	a, (hl)
	inc	hl
	ld	a, b
	sbc	a, (hl)
	ld	a, b
	ld	d, a
	bit	7, (hl)
	jr	Z, 00157$
	bit	7, d
	jr	NZ, 00158$
	cp	a, a
	jr	00158$
00157$:
	bit	7, d
	jr	Z, 00158$
	scf
00158$:
	jr	NC, 00102$
	ld	bc, #0x8000
	jr	00107$
00102$:
;src/llm.c:155: else x += t;
	pop	hl
	push	hl
	add	hl, bc
	ld	c, l
	ld	b, h
00107$:
;src/llm.c:156: h[i] = x;
	ldhl	sp,	#2
	ld	a, (hl+)
	ld	h, (hl)
	ld	l, a
	ld	a, c
	ld	(hl+), a
	ld	(hl), b
;src/llm.c:150: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#11
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jp	C, 00110$
;src/llm.c:158: }
	add	sp, #12
	ret
;src/llm.c:161: static void attention(uint8_t l, const layer_cfg_t *cfg)
;	---------------------------------
; Function attention
; ---------------------------------
_attention:
	add	sp, #-33
	ldhl	sp,	#26
	ld	(hl-), a
	dec	hl
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:164: uint8_t p = pos;
	ld	a, (#_pos)
	ldhl	sp,	#8
	ld	(hl), a
;src/llm.c:167: SWITCH_RAM(2 * l);
	ldhl	sp,	#26
	ld	a, (hl)
	add	a, a
	ldhl	sp,	#9
	ld	(hl), a
	ld	a, (hl)
	ld	(#_rRAMB),a
;src/llm.c:169: uint8_t *krow = KCACHE + (uint16_t)p * M_D;
	ldhl	sp,	#8
	ld	c, (hl)
	ld	b, #0x00
	ld	a, c
	ld	d, b
	add	a, a
	rl	d
	add	a, a
	rl	d
	add	a, a
	rl	d
	add	a, a
	rl	d
	add	a, a
	rl	d
	ld	e, a
	ld	hl, #0xa000
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#33
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#32
	ld	(hl), a
;src/llm.c:170: uint16_t *ksq = KSQ + (uint16_t)p * M_H;
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	ld	bc, #0xac00
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#24
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#23
	ld	(hl), a
;src/llm.c:171: for (i = 0; i < M_D; i++) krow[i] = (uint8_t)(k[i] + M_BIAS);
	ld	c, #0x00
00117$:
	ldhl	sp,#31
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	l, c
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	hl, #_k
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
	add	a, #0x3f
	ld	(de), a
	inc	c
	ld	a, c
	sub	a, #0x20
	jr	C, 00117$
;src/llm.c:172: for (hh = 0; hh < M_H; hh++) {
	ldhl	sp,	#31
	ld	(hl), #0x00
00121$:
;src/llm.c:173: uint16_t s = 0;
	ld	bc, #0x0000
;src/llm.c:174: const int8_t *kh = k + hh * M_HD;
	ldhl	sp,	#31
	ld	e, (hl)
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	add	a, #<(_k)
	ld	e, a
	ld	a, h
	adc	a, #>(_k)
	ldhl	sp,	#28
	ld	(hl), e
	inc	hl
	ld	(hl), a
;src/llm.c:175: for (i = 0; i < M_HD; i++) s += SQ7(kh[i]);
	ldhl	sp,	#32
	ld	(hl), #0x00
00119$:
	ldhl	sp,#28
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#32
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	add	a, a
	add	a, #0x7e
	ldhl	sp,	#30
	ld	(hl), a
	ld	l, (hl)
	ld	e, l
	ld	d, #0x3f
	ld	a, (de)
	ld	d, a
	ld	h, #0x3e
	ld	l, (hl)
	ld	h, d
	srl	h
	rr	l
	srl	h
	rr	l
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#32
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x10
	jr	C, 00119$
;src/llm.c:176: ksq[hh] = s;
	dec	hl
	ld	a, (hl)
	ld	d, #0x00
	add	a, a
	rl	d
	ld	e, a
	ldhl	sp,	#22
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, c
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a
;src/llm.c:172: for (hh = 0; hh < M_H; hh++) {
	ldhl	sp,	#31
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x02
	jr	C, 00121$
;src/llm.c:180: SWITCH_RAM(2 * l + 1);
	ldhl	sp,	#26
	ld	a, (hl)
	add	a, a
	inc	a
	ldhl	sp,	#10
	ld	(hl), a
	ld	a, (hl)
	ld	(#_rRAMB),a
;src/llm.c:182: uint8_t *vt = VTCACHE + (M_T - 1 - p);
	ldhl	sp,	#8
	ld	c, (hl)
	ld	b, #0x00
	ld	de, #0x005f
	ld	a, e
	sub	a, c
	ld	e, a
	ld	a, d
	sbc	a, b
	ldhl	sp,	#32
	ld	(hl-), a
	ld	a, e
	ld	(hl+), a
	dec	hl
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #0xa000
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#30
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#29
;src/llm.c:185: for (i = 0; i < M_D; i++) {
	ld	(hl+), a
	ld	(hl), #0x00
00123$:
;src/llm.c:186: int8_t vi = v[i];
	ld	de, #_v
	ldhl	sp,	#30
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ldhl	sp,	#27
	ld	(hl), a
;src/llm.c:187: *vt = (uint8_t)(vi + M_BIAS);
	ld	a, (hl+)
	add	a, #0x3f
	ld	e, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, e
	ld	(hl), a
;src/llm.c:188: vt += M_T;
	ldhl	sp,#28
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #0x0060
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#30
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#29
;src/llm.c:189: vsq[i] += SQ7(vi);
	ld	(hl+), a
	ld	a, (hl)
	ldhl	sp,	#6
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	a, (hl)
	add	a, a
	add	a, a
	ld	c, a
	ld	b, #0xac
	ld	e, c
	ld	d, b
	ld	a, (de)
	ldhl	sp,	#12
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#27
	ld	a, (hl)
	add	a, a
	add	a, #0x7e
	ld	l, a
	ld	e, l
	ld	d, #0x3f
	ld	a, (de)
	ld	d, a
	ld	h, #0x3e
	ld	e, (hl)
	srl	d
	rr	e
	srl	d
	rr	e
	ldhl	sp,	#16
	ld	a, e
	ld	(hl+), a
	ld	a, d
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
	ldhl	sp,#12
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#16
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#23
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#16
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#20
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#23
	ld	(hl-), a
	ld	a, e
	ld	(hl-), a
	dec	hl
	ld	a, (hl+)
	ld	(bc), a
	inc	bc
	ld	a, (hl+)
	ld	(bc), a
	inc	bc
	ld	a, (hl+)
	ld	(bc), a
	inc	bc
	ld	a, (hl)
	ld	(bc), a
;src/llm.c:190: vsum[i] += vi;
	ldhl	sp,	#6
	ld	a, (hl)
	ld	b, #0x00
	add	a, a
	rl	b
	add	a, #0x80
	ld	c, a
	ld	a, b
	adc	a, #0xac
	ld	b, a
	ld	e, c
	ld	d, b
	ld	a, (de)
	ldhl	sp,	#20
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#27
	ld	a, (hl)
	ldhl	sp,	#22
	ld	(hl+), a
	rlca
	sbc	a, a
	ld	(hl), a
	ldhl	sp,	#20
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	ld	(bc), a
;src/llm.c:185: for (i = 0; i < M_D; i++) {
	ldhl	sp,	#30
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jp	C, 00123$
;src/llm.c:194: for (hh = 0; hh < M_H; hh++) {
	ldhl	sp,#24
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #0x0008
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#13
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#12
	ld	(hl), a
	ldhl	sp,	#31
	ld	a, (hl)
	ldhl	sp,	#13
	ld	(hl), a
	ldhl	sp,	#32
	ld	a, (hl)
	ldhl	sp,	#14
	ld	(hl), a
	sra	(hl)
	dec	hl
	rr	(hl)
	inc	hl
	sra	(hl)
	dec	hl
	rr	(hl)
	inc	hl
	sra	(hl)
	dec	hl
	rr	(hl)
	inc	hl
	sra	(hl)
	dec	hl
	rr	(hl)
	ldhl	sp,	#27
	ld	(hl), #0x00
00137$:
;src/llm.c:196: uint16_t E = 0;
	xor	a, a
	ldhl	sp,	#15
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:197: uint32_t esq = 0;
	xor	a, a
	ldhl	sp,	#28
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:200: SWITCH_RAM(2 * l);
	ldhl	sp,	#9
	ld	a, (hl)
	ld	(#_rRAMB),a
;src/llm.c:201: mv_xsq = load_x(q + hh * M_HD, M_HD);
	ldhl	sp,	#27
	ld	a, (hl)
	ldhl	sp,	#22
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	b, (hl)
	ld	c, #0x00
	sla	b
	rl	c
	sla	b
	rl	c
	sla	b
	rl	c
	sla	b
	rl	c
	ld	a, b
	add	a, #<(_q)
	ld	e, a
	ld	a, c
	adc	a, #>(_q)
	ld	d, a
	push	bc
	ld	a, #0x10
	call	_load_x
	ld	l, c
	ld	h, b
	pop	bc
	ld	a, l
	ld	(_mv_xsq), a
	ld	a, h
	ld	(_mv_xsq + 1), a
	ld	hl, #_mv_xsq + 2
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:202: mv_row = (uint16_t)(KCACHE + hh * M_HD);
	ld	a, #0xa0
	ld	hl, #_mv_row
	ld	(hl), b
	inc	hl
	ld	(hl), a
;src/llm.c:203: mv_stride = M_D;
	ld	hl, #_mv_stride
	ld	a, #0x20
	ld	(hl+), a
	xor	a, a
	ld	(hl), a
;src/llm.c:204: mv_sq = (uint16_t)(KSQ + hh);
	ldhl	sp,	#22
	ld	a, (hl)
	add	a, a
	ld	c, a
	ld	a, #0xac
	ld	hl, #_mv_sq
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:205: mv_sqstride = 2 * M_H;
	ld	hl, #_mv_sqstride
	ld	(hl), #0x04
;src/llm.c:206: mv_sq16 = 1;
	ld	hl, #_mv_sq16
	ld	(hl), #0x01
;src/llm.c:207: mv_entry = (uint16_t)dot_entries[(M_NMAX - M_HD) >> 4];
	ld	hl, #(_dot_entries + 10)
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl)
	ld	hl, #_mv_entry
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:208: mv_rows = p + 1;
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#23
	ld	(hl), a
	ld	a, (hl)
	inc	a
	ld	(#_mv_rows),a
;src/llm.c:209: mv_mode = 1;
	ld	hl, #_mv_mode
	ld	(hl), #0x01
;src/llm.c:210: mv_out = (uint16_t)scores;
	ld	hl, #_mv_out
	ld	a, #<(_scores)
	ld	(hl+), a
	ld	(hl), #>(_scores)
;src/llm.c:211: mv_run();
	call	_mv_run
;src/llm.c:213: mx = scores[0];
	ld	de, #_scores
	ld	a, (de)
	ldhl	sp,	#4
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/llm.c:214: for (pp = 1; pp <= p; pp++) if (scores[pp] > mx) mx = scores[pp];
	ldhl	sp,	#32
	ld	(hl), #0x01
00126$:
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#32
	sub	a, (hl)
	jr	C, 00107$
	ld	c, (hl)
	xor	a, a
	sla	c
	adc	a, a
	sla	c
	adc	a, a
	ldhl	sp,	#19
	ld	(hl), c
	inc	hl
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_scores
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#23
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#22
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ldhl	sp,	#19
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#4
	ld	e, l
	ld	d, h
	ldhl	sp,	#19
	ld	a, (de)
	inc	de
	sub	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	sbc	a, (hl)
	ld	a, (de)
	ld	d, a
	bit	7, (hl)
	jr	Z, 00312$
	bit	7, d
	jr	NZ, 00313$
	cp	a, a
	jr	00313$
00312$:
	bit	7, d
	jr	Z, 00313$
	scf
00313$:
	jr	NC, 00127$
	ldhl	sp,	#19
	ld	d, h
	ld	e, l
	ldhl	sp,	#4
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
00127$:
	ldhl	sp,	#32
	inc	(hl)
	jr	00126$
00107$:
;src/llm.c:216: for (pp = 0; pp <= p; pp++) {
	ld	c, #0x00
00128$:
;src/llm.c:217: int32_t d = mx - scores[pp];
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	de, #_scores
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#0
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,#4
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#0
	sub	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	push	af
	ldhl	sp,	#22
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#4
	pop	af
	ld	a, e
	sbc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	ldhl	sp,	#22
	ld	(hl-), a
;src/llm.c:220: if (d > M_MAX_LOGIT_DIFF) d = M_MAX_LOGIT_DIFF;
	ld	a, e
	ld	(hl-), a
	dec	hl
	ld	a, #0xff
	sub	a, (hl)
	inc	hl
	ld	a, #0x7f
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	ld	a, #0x00
	ld	d, a
	bit	7, (hl)
	jr	Z, 00314$
	bit	7, d
	jr	NZ, 00315$
	cp	a, a
	jr	00315$
00314$:
	bit	7, d
	jr	Z, 00315$
	scf
00315$:
	jr	NC, 00109$
	ldhl	sp,	#19
	ld	a, #0xff
	ld	(hl+), a
	ld	a, #0x7f
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
00109$:
;src/llm.c:221: u = (uint16_t)((uint32_t)MUL16S((int16_t)d, cfg->att_mul) >> M_SCALE_SHIFT);
	ldhl	sp,	#19
	ld	a, (hl)
	ld	(#_mul_a),a
	ldhl	sp,	#20
	ld	a, (hl)
	ld	(#_mul_a + 1),a
	ldhl	sp,#11
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	hl, #_mul_b
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	push	bc
	call	_mul16s
	pop	bc
	ld	a, (_mul_r)
	ld	hl, #_mul_r + 1
	ld	a, (hl+)
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
;src/llm.c:222: if (u > 255) u = 255;
	ld	b, e
	ld	l, d
	ld	a, #0xff
	cp	a, b
	ld	a, #0x00
	sbc	a, l
	jr	NC, 00111$
	ld	de, #0x00ff
00111$:
;src/llm.c:223: e = exp_tbl[u];
	ld	hl, #_exp_tbl
	add	hl, de
	ld	e, (hl)
;src/llm.c:224: evec[pp] = e;
	ld	hl, #_evec
	ld	b, #0x00
	add	hl, bc
	ld	(hl), e
;src/llm.c:225: E += e;
	ldhl	sp,	#15
	ld	a, (hl+)
	ld	b, (hl)
	dec	hl
	ld	d, #0x00
	add	a, e
	ld	e, a
	ld	a, b
	adc	a, d
	ld	(hl), e
	inc	hl
	ld	(hl), a
;src/llm.c:216: for (pp = 0; pp <= p; pp++) {
	inc	c
	ldhl	sp,	#8
	ld	a, (hl)
	sub	a, c
	jp	NC, 00128$
;src/llm.c:228: j = (uint8_t)(((M_NMAX - 1 - p) >> 4) << 4);
	ldhl	sp,	#13
	ld	a, (hl)
	swap	a
	and	a, #0xf0
	ldhl	sp,	#17
	ld	(hl), a
;src/llm.c:229: for (i = j; i < (uint8_t)(M_NMAX - 1 - p); i++) xvec[i] = M_BIAS;
	ld	a, #0x5f
	ldhl	sp,	#23
	sub	a, (hl)
	ldhl	sp,	#32
	ld	(hl), a
	ldhl	sp,	#17
	ld	c, (hl)
00131$:
	ldhl	sp,	#32
	ld	a, c
	sub	a, (hl)
	jr	NC, 00113$
	ld	hl, #_xvec
	ld	b, #0x00
	add	hl, bc
	ld	(hl), #0x3f
	inc	c
	jr	00131$
00113$:
;src/llm.c:230: for (pp = 0; pp <= p; pp++) {
	ldhl	sp,	#32
	ld	(hl), #0x00
00133$:
;src/llm.c:231: int8_t x = (int8_t)(evec[pp] - M_BIAS);
	ld	de, #_evec
	ldhl	sp,	#32
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#24
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#23
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ldhl	sp,	#18
	ld	(hl), a
	ld	a, (hl+)
	add	a, #0xc1
	ld	(hl), a
;src/llm.c:232: xvec[M_NMAX - 1 - pp] = evec[pp];
	ldhl	sp,	#32
	ld	a, #0x5f
	sub	a, (hl)
	ldhl	sp,	#23
	ld	(hl), a
	ld	a, (hl)
	ldhl	sp,	#20
	ld	(hl+), a
	rlca
	sbc	a, a
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_xvec
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#24
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#23
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#18
;src/llm.c:233: esq += SQ7(x);
	ld	a, (hl+)
	ld	(de), a
	ld	a, (hl)
	add	a, a
	add	a, #0x7e
	ldhl	sp,	#23
	ld	(hl), a
	ld	e, (hl)
	ld	d, #0x00
	ld	hl, #0x3f00
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ldhl	sp,	#22
	ld	(hl), a
	ld	a, (hl-)
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	a, (hl-)
	dec	hl
	ld	(hl-), a
	ld	(hl), #0x00
	ldhl	sp,	#23
	ld	e, (hl)
	ld	d, #0x00
	ld	hl, #0x3e00
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#24
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#23
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ldhl	sp,	#20
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	a, (hl+)
	inc	hl
	ld	(hl), a
	ldhl	sp,	#19
	ld	a, (hl)
	ldhl	sp,	#23
	ld	(hl), a
	srl	(hl)
	dec	hl
	rr	(hl)
	inc	hl
	srl	(hl)
	dec	hl
	rr	(hl)
	ld	a, (hl-)
	dec	hl
	ld	(hl), a
	ldhl	sp,	#23
	ld	a, (hl-)
	dec	hl
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
	ldhl	sp,#28
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ldhl	sp,	#20
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ldhl	sp,	#31
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#32
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#24
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ldhl	sp,	#31
	ld	(hl-), a
;src/llm.c:230: for (pp = 0; pp <= p; pp++) {
	ld	a, e
	ld	(hl+), a
	inc	hl
	inc	(hl)
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#32
	sub	a, (hl)
	jp	NC, 00133$
;src/llm.c:236: SWITCH_RAM(2 * l + 1);
	ldhl	sp,	#10
	ld	a, (hl)
	ld	(#_rRAMB),a
;src/llm.c:237: mv_xsq = esq;
	ldhl	sp,	#28
	ld	d, h
	ld	e, l
	ld	hl, #_mv_xsq
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/llm.c:238: mv_row = (uint16_t)(VTCACHE + (uint16_t)(hh * M_HD) * M_T + (j - (M_NMAX - M_T)));
	ldhl	sp,	#27
	ld	c, (hl)
	xor	a, a
	sla	c
	adc	a, a
	sla	c
	adc	a, a
	sla	c
	adc	a, a
	sla	c
	adc	a, a
	ldhl	sp,	#31
	ld	(hl), c
	inc	hl
	ld	(hl-), a
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	a, h
	add	a, #0xa0
	ld	b, a
	ldhl	sp,	#17
	ld	a, (hl)
	add	a, c
	ld	c, a
	ld	a, #0x00
	adc	a, b
	ld	hl, #_mv_row
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:239: mv_stride = M_T;
	ld	hl, #_mv_stride
	ld	a, #0x60
	ld	(hl+), a
	xor	a, a
	ld	(hl), a
;src/llm.c:240: mv_sq = (uint16_t)(VSQ + hh * M_HD);
	ldhl	sp,	#31
	ld	a, (hl)
	add	a, a
	add	a, a
	ld	b, a
	ld	a, #0xac
	ld	hl, #_mv_sq
	ld	(hl), b
	inc	hl
	ld	(hl), a
;src/llm.c:241: mv_sqstride = 4;
	ld	hl, #_mv_sqstride
	ld	(hl), #0x04
;src/llm.c:242: mv_sq16 = 0;
	xor	a, a
	ld	(#_mv_sq16),a
;src/llm.c:243: mv_entry = (uint16_t)dot_entries[j >> 4];
	ldhl	sp,	#17
	ld	a, (hl)
	swap	a
	and	a, #0x0f
	ld	h, #0x00
	ld	l, a
	add	hl, hl
	ld	de, #_dot_entries
	add	hl, de
	ld	a, (hl+)
	ld	c, (hl)
	ld	hl, #_mv_entry
	ld	(hl+), a
	ld	(hl), c
;src/llm.c:244: mv_rows = M_HD;
	ld	hl, #_mv_rows
	ld	(hl), #0x10
;src/llm.c:245: mv_mode = 1;
	ld	hl, #_mv_mode
	ld	(hl), #0x01
;src/llm.c:246: mv_out = (uint16_t)scores;
	ld	hl, #_mv_out
	ld	a, #<(_scores)
	ld	(hl+), a
	ld	(hl), #>(_scores)
;src/llm.c:247: mv_run();
	call	_mv_run
;src/llm.c:249: const int16_t *vsum = VSUM + hh * M_HD;
	ldhl	sp,	#31
	ld	c, (hl)
	ld	b, #0x00
	sla	c
	rl	b
	ld	hl, #0xac80
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#32
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#31
	ld	(hl), a
;src/llm.c:250: dq_den = E;
	ldhl	sp,	#15
	ld	a, (hl)
	ld	(#_dq_den),a
	ldhl	sp,	#16
	ld	a, (hl)
	ld	(#_dq_den + 1),a
;src/llm.c:251: for (i = 0; i < M_HD; i++) {
	ldhl	sp,	#32
	ld	(hl), #0x00
00135$:
;src/llm.c:252: dq_num = scores[i] + MUL16S(vsum[i], M_BIAS);
	ldhl	sp,	#32
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	ld	de, #_scores
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#20
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	sla	c
	rl	b
	ldhl	sp,	#30
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	ld	a, (de)
	ld	hl, #_mul_a
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ld	hl, #_mul_b
	ld	a, #0x3f
	ld	(hl+), a
	xor	a, a
	ld	(hl), a
	call	_mul16s
	ldhl	sp,#20
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, e
	ld	hl, #_mul_r
	add	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	push	af
	ld	hl, #_dq_num + 1
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#24
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_mul_r + 2
	pop	af
	ld	a, e
	adc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	adc	a, (hl)
	ld	hl, #_dq_num + 3
	ld	(hl-), a
	ld	(hl), e
;src/llm.c:253: divq();
	call	_divq
;src/llm.c:254: o[hh * M_HD + i] = dq_res;
	ldhl	sp,	#27
	ld	a, (hl)
	swap	a
	and	a, #0xf0
	ldhl	sp,	#32
	ld	c, (hl)
	add	a, c
	ld	l, a
	ld	h, #0x00
	ld	de, #_o
	add	hl, de
	ld	a, (_dq_res)
	ld	(hl), a
;src/llm.c:251: for (i = 0; i < M_HD; i++) {
	ldhl	sp,	#32
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x10
	jp	C, 00135$
;src/llm.c:194: for (hh = 0; hh < M_H; hh++) {
	ldhl	sp,	#27
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x02
	jp	C, 00137$
;src/llm.c:258: }
	add	sp, #33
	ret
;src/llm.c:261: void llm_seed(uint16_t seed)
;	---------------------------------
; Function llm_seed
; ---------------------------------
_llm_seed::
;src/llm.c:263: rng_state = seed ? seed : 1;
	ld	a, d
	or	a, e
	jr	NZ, 00104$
	ld	de, #0x0001
00104$:
	ld	hl, #_rng_state
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:264: }
	ret
;src/llm.c:266: void llm_reset(void)
;	---------------------------------
; Function llm_reset
; ---------------------------------
_llm_reset::
;src/llm.c:269: for (l = 0; l < M_L; l++) {
	ld	c, #0x00
00105$:
;src/llm.c:270: SWITCH_RAM(2 * l + 1);
	ld	a, c
	add	a, a
	inc	a
	ld	(#_rRAMB),a
;src/llm.c:271: memset(VTCACHE, M_BIAS, (uint16_t)M_D * M_T);
	ld	de, #0x0c00
	push	de
	ld	de, #0x003f
	push	de
	ld	de, #0xa000
	push	de
	call	_memset
	add	sp, #6
;src/llm.c:272: for (i = 0; i < M_D; i++) { VSQ[i] = 0; VSUM[i] = 0; }
	ld	b, #0x00
00103$:
	ld	e, b
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, hl
	ld	h, #0xac
	xor	a, a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl+), a
	ld	(hl), a
	ld	l, e
	ld	h, d
	add	hl, hl
	ld	de, #0xac80
	add	hl, de
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
	inc	b
	ld	a, b
	sub	a, #0x20
	jr	C, 00103$
;src/llm.c:269: for (l = 0; l < M_L; l++) {
	inc	c
	ld	a, c
	sub	a, #0x02
	jr	C, 00105$
;src/llm.c:274: pos = 0;
	xor	a, a
	ld	(#_pos),a
;src/llm.c:275: }
	ret
;src/llm.c:277: void llm_init(void)
;	---------------------------------
; Function llm_init
; ---------------------------------
_llm_init::
;src/llm.c:279: ENABLE_RAM;
	ld	hl, #_rRAMG
	ld	(hl), #0x0a
;src/llm.c:280: llm_reset();
;src/llm.c:281: }
	jp	_llm_reset
;src/llm.c:283: uint8_t llm_pos(void)
;	---------------------------------
; Function llm_pos
; ---------------------------------
_llm_pos::
;src/llm.c:285: return pos;
	ld	a, (_pos)
;src/llm.c:286: }
	ret
;src/llm.c:288: void llm_feed(uint8_t t)
;	---------------------------------
; Function llm_feed
; ---------------------------------
_llm_feed::
	add	sp, #-11
	ld	e, a
;src/llm.c:293: SWITCH_ROM(TOK_EMB_BANK);
	ld	a, #0x02
	ldh	(__current_bank + 0), a
	ld	hl, #_rROMB0
	ld	(hl), #0x02
;src/llm.c:295: const int8_t *te = tok_emb + (uint16_t)t * M_D;
	ld	bc, #_tok_emb+0
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, bc
	ld	c, l
	ld	a, h
	ldhl	sp,	#8
	ld	(hl), c
	inc	hl
;src/llm.c:296: for (i = 0; i < M_D; i++) h[i] = (int16_t)te[i] << M_TOK_SHIFT;
	ld	(hl+), a
	ld	(hl), #0x00
00104$:
	ldhl	sp,	#10
	ld	a, (hl-)
	dec	hl
	ld	b, #0x00
	add	a, a
	rl	b
	add	a, #<(_h)
	ld	c, a
	ld	a, b
	adc	a, #>(_h)
	ld	b, a
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ld	l, a
	rlca
	sbc	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
	ldhl	sp,	#10
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jr	C, 00104$
;src/llm.c:298: SWITCH_ROM(POS_EMB_BANK);
	ld	a, #0x02
	ldh	(__current_bank + 0), a
	ld	hl, #_rROMB0
	ld	(hl), #0x02
;src/llm.c:300: const int8_t *pe = pos_emb + (uint16_t)pos * M_D;
	ld	bc, #_pos_emb+0
	ld	a, (_pos)
	ld	h, #0x00
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, bc
	ld	c, l
	ld	a, h
	ldhl	sp,	#6
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:301: for (i = 0; i < M_D; i++) h[i] += (int16_t)pe[i] << M_POS_SHIFT;
	ldhl	sp,	#10
	ld	(hl), #0x00
00106$:
	ldhl	sp,	#10
	ld	a, (hl-)
	dec	hl
	ld	b, #0x00
	add	a, a
	rl	b
	add	a, #<(_h)
	ld	c, a
	ld	a, b
	adc	a, #>(_h)
	ld	b, a
	ld	e, c
	ld	d, b
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl-), a
	dec	hl
	dec	hl
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#10
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ld	l, a
	rlca
	sbc	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	e, l
	ld	d, h
	ldhl	sp,	#8
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	ld	(bc), a
	ldhl	sp,	#10
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x20
	jr	C, 00106$
;src/llm.c:303: DBG(1);
	ld	a, #0x01
	call	_dbg_sync
;src/llm.c:304: for (l = 0; l < M_L; l++) {
	ldhl	sp,	#10
	ld	(hl), #0x00
00108$:
;src/llm.c:305: const layer_cfg_t *cfg = &layer_cfg[l];
	ldhl	sp,	#10
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	ld	a, l
	add	a, #<(_layer_cfg)
	ld	c, a
	ld	a, h
	adc	a, #>(_layer_cfg)
	ldhl	sp,	#0
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:306: rmsnorm_q();
	call	_rmsnorm_q
;src/llm.c:307: DBG(10 * l + 11);
	ldhl	sp,	#10
	ld	a, (hl)
	ld	c, a
	add	a, a
	add	a, a
	add	a, c
	add	a, a
	ldhl	sp,	#2
	ld	(hl), a
	ld	a, (hl)
	add	a, #0x0b
	call	_dbg_sync
;src/llm.c:308: xsq = load_x(nbuf, M_D);
	ld	a, #0x20
	ld	de, #_nbuf
	call	_load_x
	ldhl	sp,	#3
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:309: matvec(&mat_wq[l], M_D, M_D, xsq, cfg->s_q, q, -M_QMAX);
	pop	de
	push	de
	ld	a, (de)
	ldhl	sp,	#7
	ld	(hl), a
	ldhl	sp,	#10
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#10
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#9
	ld	(hl), a
	ld	de, #_mat_wq
	ld	a, (hl-)
	ld	l, (hl)
	ld	h, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, #0xc1
	push	af
	inc	sp
	ld	bc, #_q
	push	bc
	ldhl	sp,	#10
	ld	a, (hl-)
	dec	hl
	push	af
	inc	sp
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#9
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x20
	push	af
	inc	sp
	ld	a, #0x20
	call	_matvec
;src/llm.c:310: matvec(&mat_wk[l], M_D, M_D, xsq, cfg->s_k, k, -M_QMAX);
	pop	hl
	push	hl
	inc	hl
	ld	b, (hl)
	ld	de, #_mat_wk
	ldhl	sp,	#8
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, #0xc1
	push	af
	inc	sp
	ld	hl, #_k
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#9
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#9
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x20
	push	af
	inc	sp
	ld	a, #0x20
	call	_matvec
;src/llm.c:311: matvec(&mat_wv[l], M_D, M_D, xsq, cfg->s_v, v, -M_QMAX);
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	b, (hl)
	ld	de, #_mat_wv
	ldhl	sp,	#8
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, #0xc1
	push	af
	inc	sp
	ld	hl, #_v
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#9
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#9
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x20
	push	af
	inc	sp
	ld	a, #0x20
	call	_matvec
;src/llm.c:312: DBG(10 * l + 12);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x0c
	call	_dbg_sync
;src/llm.c:313: attention(l, cfg);
	pop	de
	push	de
	ldhl	sp,	#10
	ld	a, (hl)
	call	_attention
;src/llm.c:314: DBG(10 * l + 13);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x0d
	call	_dbg_sync
;src/llm.c:315: xsq = load_x(o, M_D);
	ld	a, #0x20
	ld	de, #_o
	call	_load_x
	ldhl	sp,	#4
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:316: matvec(&mat_wo[l], M_D, M_D, xsq, cfg->s_ao, a, -M_QMAX);
	pop	hl
	push	hl
	inc	hl
	inc	hl
	inc	hl
	ld	b, (hl)
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_mat_wo
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, #0xc1
	push	af
	inc	sp
	ld	hl, #_a
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x20
	push	af
	inc	sp
	ld	a, #0x20
	call	_matvec
;src/llm.c:317: DBG(10 * l + 14);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x0e
	call	_dbg_sync
;src/llm.c:318: residual_add(a, cfg->rs_a);
	pop	de
	push	de
	ld	hl, #0x0004
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ld	de, #_a
	call	_residual_add
;src/llm.c:319: DBG(10 * l + 15);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x0f
	call	_dbg_sync
;src/llm.c:320: rmsnorm_q();
	call	_rmsnorm_q
;src/llm.c:321: DBG(10 * l + 16);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x10
	call	_dbg_sync
;src/llm.c:322: xsq = load_x(nbuf, M_D);
	ld	a, #0x20
	ld	de, #_nbuf
	call	_load_x
	ldhl	sp,	#4
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:323: matvec(&mat_w1[l], M_F, M_D, xsq, cfg->s_f, f, 0);
	pop	de
	push	de
	ld	hl, #0x0005
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ld	b, a
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_mat_w1
	add	hl, de
	ld	e, l
	ld	d, h
	xor	a, a
	push	af
	inc	sp
	ld	hl, #_f
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x20
	push	af
	inc	sp
	ld	a, #0x40
	call	_matvec
;src/llm.c:324: DBG(10 * l + 17);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x11
	call	_dbg_sync
;src/llm.c:325: xsq = load_x(f, M_F);
	ld	a, #0x40
	ld	de, #_f
	call	_load_x
	ldhl	sp,	#4
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:326: matvec(&mat_w2[l], M_D, M_F, xsq, cfg->s_fo, a, -M_QMAX);
	pop	de
	push	de
	ld	hl, #0x0006
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ld	b, a
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	hl, #_mat_w2
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, #0xc1
	push	af
	inc	sp
	ld	hl, #_a
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ldhl	sp,	#10
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	push	bc
	ld	a, #0x40
	push	af
	inc	sp
	ld	a, #0x20
	call	_matvec
;src/llm.c:327: DBG(10 * l + 18);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x12
	call	_dbg_sync
;src/llm.c:328: residual_add(a, cfg->rs_f);
	pop	de
	push	de
	ld	hl, #0x0007
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	ld	de, #_a
	call	_residual_add
;src/llm.c:329: DBG(10 * l + 19);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x13
	call	_dbg_sync
;src/llm.c:304: for (l = 0; l < M_L; l++) {
	ldhl	sp,	#10
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x02
	jp	C, 00108$
;src/llm.c:331: rmsnorm_q();
	call	_rmsnorm_q
;src/llm.c:332: DBG(100);
	ld	a, #0x64
	call	_dbg_sync
;src/llm.c:333: xsq = load_x(nbuf, M_D);
	ld	a, #0x20
	ld	de, #_nbuf
	call	_load_x
	ldhl	sp,	#7
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl+), a
	ld	a, e
	ld	(hl+), a
	ld	(hl), d
;src/llm.c:334: SWITCH_ROM(mat_lm.bank);
	ld	a, (#(_mat_lm + 4) + 0)
	ldh	(__current_bank + 0), a
	ld	(#_rROMB0),a
;src/llm.c:335: mv_row = (uint16_t)mat_lm.w;
	ld	hl, #_mat_lm
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl)
	ld	hl, #_mv_row
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:336: mv_stride = M_D;
	ld	hl, #_mv_stride
	ld	a, #0x20
	ld	(hl+), a
	xor	a, a
	ld	(hl), a
;src/llm.c:337: mv_sq = (uint16_t)mat_lm.sq;
	ld	hl, #_mat_lm + 2
	ld	a, (hl+)
	ld	c, (hl)
	ld	hl, #_mv_sq
	ld	(hl+), a
	ld	(hl), c
;src/llm.c:338: mv_sqstride = 4;
	ld	hl, #_mv_sqstride
	ld	(hl), #0x04
;src/llm.c:339: mv_sq16 = 0;
	xor	a, a
	ld	(#_mv_sq16),a
;src/llm.c:340: mv_xsq = xsq;
	ldhl	sp,	#7
	ld	d, h
	ld	e, l
	ld	hl, #_mv_xsq
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/llm.c:341: mv_entry = (uint16_t)dot_entries[(M_NMAX - M_D) >> 4];
	ld	hl, #(_dot_entries + 8)
	ld	a, (hl+)
	ld	c, a
	ld	a, (hl)
	ld	hl, #_mv_entry
	ld	(hl), c
	inc	hl
	ld	(hl), a
;src/llm.c:342: mv_rows = M_V;
	ld	hl, #_mv_rows
	ld	(hl), #0x80
;src/llm.c:343: mv_mode = 1;
	ld	hl, #_mv_mode
	ld	(hl), #0x01
;src/llm.c:344: mv_out = (uint16_t)logits;
	ld	hl, #_mv_out
	ld	a, #<(_logits)
	ld	(hl+), a
	ld	(hl), #>(_logits)
;src/llm.c:345: mv_run();
	call	_mv_run
;src/llm.c:346: DBG(101);
	ld	a, #0x65
	call	_dbg_sync
;src/llm.c:347: pos++;
	ld	hl, #_pos
	inc	(hl)
;src/llm.c:348: }
	add	sp, #11
	ret
;src/llm.c:350: static uint16_t rng_next(void)
;	---------------------------------
; Function rng_next
; ---------------------------------
_rng_next:
;src/llm.c:352: uint16_t x = rng_state;
	ld	a, (_rng_state)
	ld	hl, #_rng_state + 1
	ld	b, (hl)
;src/llm.c:353: x ^= x << 7;
	ld	l, a
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	xor	a, l
	ld	c, a
	ld	a, b
	xor	a, h
;src/llm.c:354: x ^= x >> 9;
	ld	b, a
	srl	a
	ld	e, a
	ld	a, c
	xor	a, e
;src/llm.c:355: x ^= x << 8;
	ld	c, a
	xor	a, b
	ld	b, a
;src/llm.c:356: rng_state = x;
	ld	hl, #_rng_state
	ld	a, c
	ld	(hl+), a
	ld	(hl), b
;src/llm.c:357: return x;
;src/llm.c:358: }
	ret
;src/llm.c:360: uint8_t llm_pick(uint8_t sample)
;	---------------------------------
; Function llm_pick
; ---------------------------------
_llm_pick::
	add	sp, #-17
	ldhl	sp,	#16
	ld	(hl), a
;src/llm.c:362: uint8_t i, best = 0;
	ldhl	sp,	#11
	ld	(hl), #0x00
;src/llm.c:363: int32_t mx = logits[0];
	ld	de, #_logits
	ld	a, (de)
	ldhl	sp,	#0
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/llm.c:364: for (i = 1; i < M_V; i++) if (logits[i] > mx) { mx = logits[i]; best = i; }
	ld	c, #0x01
00118$:
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	de, #_logits
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#12
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#0
	ld	e, l
	ld	d, h
	ldhl	sp,	#12
	ld	a, (de)
	inc	de
	sub	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	inc	de
	sbc	a, (hl)
	inc	hl
	ld	a, (de)
	sbc	a, (hl)
	ld	a, (de)
	ld	d, a
	ld	e, (hl)
	bit	7, e
	jr	Z, 00219$
	bit	7, d
	jr	NZ, 00220$
	cp	a, a
	jr	00220$
00219$:
	bit	7, d
	jr	Z, 00220$
	scf
00220$:
	jr	NC, 00119$
	ldhl	sp,	#12
	ld	d, h
	ld	e, l
	ldhl	sp,	#0
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl+),	a
	inc	de
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#11
	ld	(hl), c
00119$:
	inc	c
	ld	a, c
	sub	a, #0x80
	jr	C, 00118$
;src/llm.c:365: if (!sample) return best;
	ldhl	sp,	#16
	ld	a, (hl)
	or	a, a
	jr	NZ, 00105$
	ldhl	sp,	#11
	ld	a, (hl)
	jp	00124$
00105$:
;src/llm.c:368: uint16_t total = 0, r, acc = 0;
	xor	a, a
	ldhl	sp,	#4
	ld	(hl+), a
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/llm.c:369: for (i = 0; i < M_V; i++) {
	ld	c, #0x00
00120$:
;src/llm.c:370: int32_t d = mx - logits[i];
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	de, #_logits
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#8
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
	pop	de
	push	de
	ld	a, e
	ldhl	sp,	#8
	sub	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	push	af
	ldhl	sp,	#15
	ld	(hl-), a
	ld	(hl), e
	ldhl	sp,#4
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#12
	pop	af
	ld	a, e
	sbc	a, (hl)
	inc	hl
	ld	e, a
	ld	a, d
	sbc	a, (hl)
	ldhl	sp,	#15
	ld	(hl-), a
;src/llm.c:373: if (d > M_MAX_LOGIT_DIFF) d = M_MAX_LOGIT_DIFF;
	ld	a, e
	ld	(hl-), a
	dec	hl
	ld	a, #0xff
	sub	a, (hl)
	inc	hl
	ld	a, #0x7f
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	inc	hl
	ld	a, #0x00
	sbc	a, (hl)
	ld	a, #0x00
	ld	d, a
	bit	7, (hl)
	jr	Z, 00221$
	bit	7, d
	jr	NZ, 00222$
	cp	a, a
	jr	00222$
00221$:
	bit	7, d
	jr	Z, 00222$
	scf
00222$:
	jr	NC, 00107$
	ldhl	sp,	#12
	ld	a, #0xff
	ld	(hl+), a
	ld	a, #0x7f
	ld	(hl+), a
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
00107$:
;src/llm.c:374: u = (uint16_t)((uint32_t)MUL16S((int16_t)d, M_LM_MUL) >> M_SCALE_SHIFT);
	ldhl	sp,	#12
	ld	a, (hl)
	ld	(#_mul_a),a
	ldhl	sp,	#13
	ld	a, (hl)
	ld	(#_mul_a + 1),a
	ld	hl, #_mul_b
	ld	a, #0x40
	ld	(hl+), a
	ld	(hl), #0x01
	push	bc
	call	_mul16s
	pop	bc
	ld	hl, #_mul_r + 1
	ld	a, (hl+)
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
;src/llm.c:375: if (u > 255) u = 255;
	ld	b, e
	ld	l, d
	ld	a, #0xff
	cp	a, b
	ld	a, #0x00
	sbc	a, l
	jr	NC, 00109$
	ld	de, #0x00ff
00109$:
;src/llm.c:376: e = exp_tbl[u];
	ld	hl, #_exp_tbl
	add	hl, de
	ld	e, (hl)
;src/llm.c:377: if (i == TOK_PAD || i == TOK_USR || i == TOK_BOT) e = 0;
	ld	a, c
	or	a, a
	jr	Z, 00110$
	ld	a,c
	cp	a,#0x02
	jr	Z, 00110$
	sub	a, #0x03
	jr	NZ, 00111$
00110$:
	ld	e, #0x00
00111$:
;src/llm.c:378: ev[i] = e;
	ld	hl, #_llm_pick_ev_20000_236
	ld	b, #0x00
	add	hl, bc
;src/llm.c:379: total += e;
	ld	a,e
	ld	(hl),a
	ldhl	sp,	#4
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	ld	b, #0x00
	add	a, e
	ld	e, a
	ld	a, b
	adc	a, d
	ld	(hl), e
	inc	hl
	ld	(hl), a
;src/llm.c:369: for (i = 0; i < M_V; i++) {
	inc	c
	ld	a, c
	sub	a, #0x80
	jp	C, 00120$
;src/llm.c:381: r = rng_next() % total;
	call	_rng_next
	ld	e, c
	ld	d, b
	ldhl	sp,	#4
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
;src/llm.c:382: for (i = 0; i < M_V; i++) {
	call	__moduint
	ldhl	sp,	#14
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
00122$:
;src/llm.c:383: acc += ev[i];
	ld	de, #_llm_pick_ev_20000_236
	ldhl	sp,	#15
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#6
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	l, a
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#6
	ld	a, e
	ld	(hl+), a
;src/llm.c:384: if (r < acc) return i;
	ld	a, d
	ld	(hl-), a
	ld	a, c
	sub	a, (hl)
	inc	hl
	ld	a, b
	sbc	a, (hl)
	jr	NC, 00123$
	ldhl	sp,	#14
	ld	a, (hl)
	jr	00124$
00123$:
;src/llm.c:382: for (i = 0; i < M_V; i++) {
	ldhl	sp,	#15
	inc	(hl)
	ld	a, (hl-)
	ld	(hl+), a
	ld	a, (hl)
	sub	a, #0x80
	jr	C, 00122$
;src/llm.c:386: return M_V - 1;
	ld	a, #0x7f
00124$:
;src/llm.c:388: }
	add	sp, #17
	ret
	.area _CODE
	.area _INITIALIZER
__xinit__norm_k_v:
	.byte #0x7a, #0x82, #0x5a, #0x00	; 5931642
__xinit__rng_state:
	.dw #0x1234
	.area _CABS (ABS)
