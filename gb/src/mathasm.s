; Hand-written SM83 helpers for the inference engine (see llm.c for the C side).
;
;   _mv_run   : matrix-vector row loop around the generated dot product
;   _mul16s   : int16 * uint16 -> int32
;
; All arguments are passed through global variables so that no assumptions
; about the SDCC calling convention are needed.

        .area _DATA
_mv_row::       .ds 2   ; address of the first weight row
_mv_stride::    .ds 2   ; bytes between rows
_mv_sq::        .ds 2   ; address of the first per-row sum of squares
_mv_sqstride::  .ds 1   ; bytes between sum-of-squares entries
_mv_sq16::      .ds 1   ; 1: sums are uint16, 0: uint32 (low 24 bits used)
_mv_xsq::       .ds 4   ; sum of squares of the activation vector
_mv_entry::     .ds 2   ; address of the dot_from_N entry to call
_mv_rows::      .ds 1   ; number of rows
_mv_mode::      .ds 1   ; 0: int8 requantized output, 1: int32 output
_mv_shift::     .ds 1   ; requant shift (mode 0)
_mv_lo::        .ds 1   ; requant lower clamp (mode 0), upper clamp is 63
_mv_out::       .ds 2   ; output pointer
_mul_a::        .ds 2   ; int16 multiplicand
_mul_b::        .ds 2   ; uint16 multiplier
_mul_r::        .ds 4   ; int32 product
_mul_sign:      .ds 1

        .area _CODE
        .globl _dot_ptr
        .globl _dot_acc

; ---------------------------------------------------------------------------
; for each row: dot = (S - sq[row] - xsq) >> 1, then store as int32 or as
; requantized int8:  clamp( (dot + 2^(shift-1)) >> shift , lo, 63 )
; ---------------------------------------------------------------------------
_mv_run::
        ld      a,(_mv_rows)
        or      a
        ret     z
mv_loop:
        ; _dot_ptr = _mv_row ; call *_mv_entry
        ld      a,(_mv_row)
        ld      (_dot_ptr),a
        ld      a,(_mv_row+1)
        ld      (_dot_ptr+1),a
        ld      hl,#mv_ret
        push    hl
        ld      a,(_mv_entry)
        ld      l,a
        ld      a,(_mv_entry+1)
        ld      h,a
        jp      (hl)
mv_ret:
        ; e:b:c = sq[row] (24 bits)
        ld      a,(_mv_sq)
        ld      l,a
        ld      a,(_mv_sq+1)
        ld      h,a
        ld      a,(hl+)
        ld      c,a
        ld      a,(hl+)
        ld      b,a
        ld      a,(_mv_sq16)
        or      a
        jr      nz,mv_sq_is16
        ld      a,(hl)
        jr      mv_sq_done
mv_sq_is16:
        xor     a
mv_sq_done:
        ld      e,a
        ; d:h:l = dot_acc - e:b:c
        ld      a,(_dot_acc)
        sub     c
        ld      l,a
        ld      a,(_dot_acc+1)
        sbc     b
        ld      h,a
        ld      a,(_dot_acc+2)
        sbc     e
        ld      d,a
        ; d:h:l -= xsq
        ld      a,(_mv_xsq)
        ld      c,a
        ld      a,l
        sub     c
        ld      l,a
        ld      a,(_mv_xsq+1)
        ld      c,a
        ld      a,h
        sbc     c
        ld      h,a
        ld      a,(_mv_xsq+2)
        ld      c,a
        ld      a,d
        sbc     c
        ld      d,a
        ; >> 1 (arithmetic)
        sra     d
        rr      h
        rr      l
        ld      a,(_mv_mode)
        or      a
        jr      z,mv_requant
        ; ---- mode 1: store int32 (sign-extended 24-bit value)
        ld      a,(_mv_out)
        ld      c,a
        ld      a,(_mv_out+1)
        ld      b,a
        ld      a,l
        ld      (bc),a
        inc     bc
        ld      a,h
        ld      (bc),a
        inc     bc
        ld      a,d
        ld      (bc),a
        inc     bc
        ld      a,d
        add     a,a
        sbc     a,a
        ld      (bc),a
        inc     bc
        ld      a,c
        ld      (_mv_out),a
        ld      a,b
        ld      (_mv_out+1),a
        jr      mv_next
mv_requant:
        ld      a,(_mv_shift)
        or      a
        jr      z,mv_clamp
        ld      b,a
        dec     b
        jr      z,mv_round
mv_shift_loop:                  ; acc >>= (shift-1)
        sra     d
        rr      h
        rr      l
        dec     b
        jr      nz,mv_shift_loop
mv_round:                       ; acc = (acc + 1) >> 1
        ld      a,l
        add     a,#1
        ld      l,a
        ld      a,h
        adc     a,#0
        ld      h,a
        ld      a,d
        adc     a,#0
        ld      d,a
        sra     d
        rr      h
        rr      l
mv_clamp:
        bit     7,d
        jr      nz,mv_neg
        ld      a,d
        or      h
        jr      nz,mv_hi
        ld      a,l
        cp      #64
        jr      c,mv_store
mv_hi:
        ld      a,#63
        jr      mv_store
mv_neg:
        ld      a,d
        and     h
        inc     a
        jr      nz,mv_lo_clamp          ; high bytes not all ones -> below lo
        bit     7,l
        jr      z,mv_lo_clamp           ; -256 <= acc < -128 -> below lo
        ld      a,(_mv_lo)
        ld      c,a
        ld      a,l
        sub     c                       ; l - lo, negative -> below lo
        bit     7,a
        jr      nz,mv_lo_clamp
        ld      a,l
        jr      mv_store
mv_lo_clamp:
        ld      a,(_mv_lo)
mv_store:
        ld      c,a
        ld      a,(_mv_out)
        ld      l,a
        ld      a,(_mv_out+1)
        ld      h,a
        ld      (hl),c
        inc     hl
        ld      a,l
        ld      (_mv_out),a
        ld      a,h
        ld      (_mv_out+1),a
mv_next:
        ; row += stride
        ld      a,(_mv_row)
        ld      l,a
        ld      a,(_mv_row+1)
        ld      h,a
        ld      a,(_mv_stride)
        ld      c,a
        ld      a,(_mv_stride+1)
        ld      b,a
        add     hl,bc
        ld      a,l
        ld      (_mv_row),a
        ld      a,h
        ld      (_mv_row+1),a
        ; sq += sqstride
        ld      a,(_mv_sq)
        ld      l,a
        ld      a,(_mv_sq+1)
        ld      h,a
        ld      a,(_mv_sqstride)
        ld      c,a
        ld      b,#0
        add     hl,bc
        ld      a,l
        ld      (_mv_sq),a
        ld      a,h
        ld      (_mv_sq+1),a
        ld      a,(_mv_rows)
        dec     a
        ld      (_mv_rows),a
        jp      nz,mv_loop
        ret

; ---------------------------------------------------------------------------
; _mul_r = (int32)_mul_a * _mul_b       (int16 * uint16)
; ---------------------------------------------------------------------------
_mul16s::
        ld      a,(_mul_a+1)
        ld      d,a
        ld      a,(_mul_a)
        ld      e,a
        ld      a,(_mul_b+1)
        ld      b,a
        ld      a,(_mul_b)
        ld      c,a
        ld      a,d
        and     #0x80
        ld      (_mul_sign),a
        jr      z,mul_pos
        xor     a
        sub     e
        ld      e,a
        ld      a,#0
        sbc     d
        ld      d,a
mul_pos:
        ld      hl,#0
        ld      a,#16
mul_loop:                       ; DE:HL = DE * BC (classic shift-add)
        add     hl,hl
        rl      e
        rl      d
        jr      nc,mul_skip
        add     hl,bc
        jr      nc,mul_skip
        inc     de
mul_skip:
        dec     a
        jr      nz,mul_loop
        ld      a,(_mul_sign)
        or      a
        jr      z,mul_store
        xor     a
        sub     l
        ld      l,a
        ld      a,#0
        sbc     h
        ld      h,a
        ld      a,#0
        sbc     e
        ld      e,a
        ld      a,#0
        sbc     d
        ld      d,a
mul_store:
        ld      a,l
        ld      (_mul_r),a
        ld      a,h
        ld      (_mul_r+1),a
        ld      a,e
        ld      (_mul_r+2),a
        ld      a,d
        ld      (_mul_r+3),a
        ret

; ---------------------------------------------------------------------------
; RMSNorm scaling: for i < _ns_n:
;     _nbuf[i] = clamp( round_shift( (int32)_h[i] * _ns_inv, _ns_shift ), -63, 63 )
; _ns_shift is in [9, 25].
; ---------------------------------------------------------------------------
        .area _DATA
_ns_inv::       .ds 2
_ns_shift::     .ds 1
_ns_n::         .ds 1
_ns_src:        .ds 2
_ns_dst:        .ds 2
_ns_cnt:        .ds 1

        .area _CODE
        .globl _h
        .globl _nbuf
_norm_scale::
        ld      hl,#_h
        ld      a,l
        ld      (_ns_src),a
        ld      a,h
        ld      (_ns_src+1),a
        ld      hl,#_nbuf
        ld      a,l
        ld      (_ns_dst),a
        ld      a,h
        ld      (_ns_dst+1),a
        ld      a,(_ns_n)
        ld      (_ns_cnt),a
ns_loop:
        ; de = h[i]
        ld      a,(_ns_src)
        ld      l,a
        ld      a,(_ns_src+1)
        ld      h,a
        ld      a,(hl+)
        ld      e,a
        ld      a,(hl+)
        ld      d,a
        ld      a,l
        ld      (_ns_src),a
        ld      a,h
        ld      (_ns_src+1),a
        ; bc = inv
        ld      a,(_ns_inv+1)
        ld      b,a
        ld      a,(_ns_inv)
        ld      c,a
        ; sign
        ld      a,d
        and     #0x80
        ld      (_mul_sign),a
        jr      z,ns_pos
        xor     a
        sub     e
        ld      e,a
        ld      a,#0
        sbc     d
        ld      d,a
ns_pos:
        ld      hl,#0
        ld      a,#16
ns_mul:                         ; DE:HL = DE * BC
        add     hl,hl
        rl      e
        rl      d
        jr      nc,ns_skip
        add     hl,bc
        jr      nc,ns_skip
        inc     de
ns_skip:
        dec     a
        jr      nz,ns_mul
        ld      a,(_mul_sign)
        or      a
        jr      z,ns_shift
        xor     a
        sub     l
        ld      l,a
        ld      a,#0
        sbc     h
        ld      h,a
        ld      a,#0
        sbc     e
        ld      e,a
        ld      a,#0
        sbc     d
        ld      d,a
ns_shift:
        ; drop the low byte (8 of the shift-1 steps): value = d:e:h
        ld      a,(_ns_shift)
        sub     #9
        jr      z,ns_round
        ld      b,a
ns_shift_loop:
        sra     d
        rr      e
        rr      h
        dec     b
        jr      nz,ns_shift_loop
ns_round:                       ; (v + 1) >> 1
        ld      a,h
        add     a,#1
        ld      h,a
        ld      a,e
        adc     a,#0
        ld      e,a
        ld      a,d
        adc     a,#0
        ld      d,a
        sra     d
        rr      e
        rr      h
        ; clamp d:e:h to [-63, 63]
        bit     7,d
        jr      nz,ns_neg
        ld      a,d
        or      e
        jr      nz,ns_hi
        ld      a,h
        cp      #64
        jr      c,ns_store
ns_hi:
        ld      a,#63
        jr      ns_store
ns_neg:
        ld      a,d
        and     e
        inc     a
        jr      nz,ns_lo
        ld      a,h
        cp      #0xC1                  ; -63
        jr      nc,ns_store
ns_lo:
        ld      a,#0xC1
ns_store:
        ld      c,a
        ld      a,(_ns_dst)
        ld      l,a
        ld      a,(_ns_dst+1)
        ld      h,a
        ld      (hl),c
        inc     hl
        ld      a,l
        ld      (_ns_dst),a
        ld      a,h
        ld      (_ns_dst+1),a
        ld      a,(_ns_cnt)
        dec     a
        ld      (_ns_cnt),a
        jp      nz,ns_loop
        ret

; ---------------------------------------------------------------------------
; Small-quotient rounded division for the attention output:
;     _dq_res = clamp( sign(num) * floor((|num| + den/2) / den), -63, 63 )
; Requires |num| < 2^23 and |num| <= 63 * den (quotient fits in 7 bits).
; ---------------------------------------------------------------------------
        .area _DATA
_dq_num::       .ds 4
_dq_den::       .ds 2
_dq_res::       .ds 1
_dq_sign:       .ds 1
_dq_mask:       .ds 1

        .area _CODE
_divq::
        ld      a,(_dq_num)
        ld      l,a
        ld      a,(_dq_num+1)
        ld      h,a
        ld      a,(_dq_num+2)
        ld      e,a
        and     #0x80
        ld      (_dq_sign),a
        jr      z,dq_pos
        xor     a
        sub     l
        ld      l,a
        ld      a,#0
        sbc     h
        ld      h,a
        ld      a,#0
        sbc     e
        ld      e,a
dq_pos:
        ; n += den >> 1
        ld      a,(_dq_den+1)
        ld      b,a
        ld      a,(_dq_den)
        ld      c,a
        srl     b
        rr      c
        ld      a,l
        add     a,c
        ld      l,a
        ld      a,h
        adc     a,b
        ld      h,a
        ld      a,e
        adc     a,#0
        ld      e,a
        ; d:b:c = den << 6
        ld      a,(_dq_den+1)
        ld      b,a
        ld      a,(_dq_den)
        ld      c,a
        ld      d,#0
        sla     c
        rl      b
        rl      d
        sla     c
        rl      b
        rl      d
        sla     c
        rl      b
        rl      d
        sla     c
        rl      b
        rl      d
        sla     c
        rl      b
        rl      d
        sla     c
        rl      b
        rl      d
        xor     a
        ld      (_dq_res),a
        ld      a,#0x40
        ld      (_dq_mask),a
dq_loop:
        ld      a,l
        sub     c
        ld      a,h
        sbc     b
        ld      a,e
        sbc     d
        jr      c,dq_next
        ld      a,l
        sub     c
        ld      l,a
        ld      a,h
        sbc     b
        ld      h,a
        ld      a,e
        sbc     d
        ld      e,a
        push    hl
        ld      hl,#_dq_res
        ld      a,(_dq_mask)
        or      (hl)
        ld      (hl),a
        pop     hl
dq_next:
        srl     d
        rr      b
        rr      c
        ld      a,(_dq_mask)
        srl     a
        ld      (_dq_mask),a
        jr      nz,dq_loop
        ld      a,(_dq_res)
        cp      #64
        jr      c,dq_sign
        ld      a,#63
dq_sign:
        ld      c,a
        ld      a,(_dq_sign)
        or      a
        ld      a,c
        jr      z,dq_store
        cpl
        inc     a
dq_store:
        ld      (_dq_res),a
        ret
