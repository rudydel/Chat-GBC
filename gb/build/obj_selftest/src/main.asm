;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Linux)
;--------------------------------------------------------
	.module main
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _dbg_sync
	.globl _llm_seed
	.globl _llm_pick
	.globl _llm_feed
	.globl _llm_pos
	.globl _llm_reset
	.globl _llm_init
	.globl _ui_kbd_key
	.globl _ui_input_draw
	.globl _ui_log_flush
	.globl _ui_log_newline
	.globl _ui_log_puts
	.globl _ui_help
	.globl _ui_status
	.globl _ui_init
	.globl _wait_vbl_done
	.globl _joypad
	.globl _selftest_go
	.globl _selftest_ntok
	.globl _selftest_tokens
	.globl _selftest_ack
	.globl _selftest_step
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_input:
	.ds 41
_input_len:
	.ds 1
_tokens:
	.ds 40
_cur_row:
	.ds 1
_cur_col:
	.ds 1
_sampling:
	.ds 1
_frame_count:
	.ds 2
_selftest_step::
	.ds 1
_selftest_ack::
	.ds 1
_selftest_tokens::
	.ds 64
_selftest_ntok::
	.ds 1
_selftest_go::
	.ds 1
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
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
;src/main.c:32: static uint8_t tokenize(void)
;	---------------------------------
; Function tokenize
; ---------------------------------
_tokenize:
	add	sp, #-9
;src/main.c:34: uint8_t i = 0, n = 0;
;src/main.c:35: while (i < input_len) {
	ld	bc, #0x0
00110$:
	ld	a, c
	ld	hl, #_input_len
	sub	a, (hl)
	jp	NC, 00112$
;src/main.c:36: uint8_t best = 0, best_len = 0, t;
	ldhl	sp,	#0
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/main.c:37: uint8_t remain = input_len - i;
	ld	a, (#_input_len)
	sub	a, c
	ldhl	sp,	#2
	ld	(hl), a
;src/main.c:38: for (t = 4; t < M_V; t++) {
	ldhl	sp,	#7
	ld	(hl), #0x04
00117$:
;src/main.c:39: uint8_t L = tok_len[t];
	ld	de, #_tok_len
	ldhl	sp,	#7
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#3
;src/main.c:40: if (L > best_len && L <= remain) {
	ld	(hl-), a
	dec	hl
	ld	a, (hl+)
	inc	hl
	sub	a, (hl)
	jr	NC, 00118$
	dec	hl
	ld	a, (hl+)
	sub	a, (hl)
	jr	C, 00118$
;src/main.c:41: const char *ts = tok_str[t];
	ldhl	sp,	#7
	ld	e, (hl)
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	ld	de, #_tok_str
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#4
	ld	(hl+), a
	inc	de
	ld	a, (de)
	ld	(hl), a
;src/main.c:43: for (j = 0; j < L && ts[j] == input[i + j]; j++) ;
	ldhl	sp,	#8
	ld	(hl), #0x00
00115$:
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#3
	sub	a, (hl)
	jr	NC, 00101$
	inc	hl
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#8
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#6
	ld	(hl+), a
	inc	hl
	ld	a, c
	add	a, (hl)
	ld	l, a
	ld	h, #0x00
	ld	de, #_input
	add	hl, de
	ld	e, (hl)
	ldhl	sp,	#6
	ld	a, (hl)
	sub	a, e
	jr	NZ, 00101$
	ldhl	sp,	#8
	inc	(hl)
	jr	00115$
00101$:
;src/main.c:44: if (j == L) { best = t; best_len = L; }
	ldhl	sp,	#3
	ld	a, (hl)
	ldhl	sp,	#8
	sub	a, (hl)
	jr	NZ, 00118$
	ldhl	sp,	#7
	ld	a, (hl)
	ldhl	sp,	#0
	ld	(hl), a
	ldhl	sp,	#3
	ld	a, (hl-)
	dec	hl
	ld	(hl), a
00118$:
;src/main.c:38: for (t = 4; t < M_V; t++) {
	ldhl	sp,	#7
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x80
	jr	C, 00117$
;src/main.c:47: if (best_len == 0) { i++; continue; }     /* character outside the vocabulary: skip it */
	ldhl	sp,	#1
	ld	a, (hl)
	or	a, a
	jr	NZ, 00109$
	inc	c
	jp	00110$
00109$:
;src/main.c:48: tokens[n++] = best;
	ld	a, #<(_tokens)
	add	a, b
	ld	e, a
	ld	a, #>(_tokens)
	adc	a, #0x00
	ld	d, a
	inc	b
	ldhl	sp,	#0
;src/main.c:49: i += best_len;
	ld	a, (hl+)
	ld	(de), a
	ld	a, (hl)
	add	a, c
	ld	c, a
	jp	00110$
00112$:
;src/main.c:51: return n;
	ld	a, b
;src/main.c:52: }
	add	sp, #9
	ret
;src/main.c:54: static void show_mode(void)
;	---------------------------------
; Function show_mode
; ---------------------------------
_show_mode:
;src/main.c:56: ui_help(sampling ? "a:key b:del st:send *" : "a:key b:del st:send");
	ld	a, (#_sampling)
	or	a, a
	jr	Z, 00103$
	ld	de, #___str_0+0
	jp	_ui_help
00103$:
	ld	de, #___str_1+0
;src/main.c:57: }
	jp	_ui_help
___str_0:
	.ascii "a:key b:del st:send *"
	.db 0x00
___str_1:
	.ascii "a:key b:del st:send"
	.db 0x00
;src/main.c:59: static uint8_t wait_key_release(void)
;	---------------------------------
; Function wait_key_release
; ---------------------------------
_wait_key_release:
;src/main.c:62: do { wait_vbl_done(); frame_count++; j = joypad(); } while (j);
00101$:
	call	_wait_vbl_done
	ld	hl, #_frame_count
	inc	(hl)
	jr	NZ, 00120$
	inc	hl
	inc	(hl)
00120$:
	call	_joypad
;src/main.c:63: return j;
	or	a,a
	jr	NZ, 00101$
;src/main.c:64: }
	ret
;src/main.c:66: static void redraw_input(void)
;	---------------------------------
; Function redraw_input
; ---------------------------------
_redraw_input:
;src/main.c:68: ui_input_draw(input, input_len);
	ld	a, (_input_len)
	ld	de, #_input
;src/main.c:69: }
	jp	_ui_input_draw
;src/main.c:72: static void chat(void)
;	---------------------------------
; Function chat
; ---------------------------------
_chat:
	dec	sp
	dec	sp
;src/main.c:75: uint8_t stop = 0;
	ldhl	sp,	#0
	ld	(hl), #0x00
;src/main.c:77: if (input_len == 0) return;
	ld	a, (#_input_len)
	or	a, a
	jp	Z, 00121$
;src/main.c:78: ui_log_puts("> ");
	ld	de, #___str_2
	call	_ui_log_puts
;src/main.c:79: ui_log_puts(input);
	ld	de, #_input
	call	_ui_log_puts
;src/main.c:80: ui_log_newline();
	call	_ui_log_newline
;src/main.c:81: ui_log_flush();
	call	_ui_log_flush
;src/main.c:82: ntok = tokenize();
	call	_tokenize
	ldhl	sp,	#1
	ld	(hl), a
;src/main.c:95: llm_reset();
	call	_llm_reset
;src/main.c:96: ui_status("reading...");
	ld	de, #___str_3
	call	_ui_status
;src/main.c:98: llm_seed(frame_count ^ (uint16_t)DIV_REG);
	ldh	a, (_DIV_REG + 0)
	ld	c, a
	ld	hl, #_frame_count
	ld	a, (hl+)
	xor	a, c
	ld	d, (hl)
	ld	e, a
	call	_llm_seed
;src/main.c:100: llm_feed(TOK_USR);
	ld	a, #0x02
	call	_llm_feed
;src/main.c:101: for (i = 0; i < ntok; i++) {
	ld	c, #0x00
00119$:
	ld	a, c
	ldhl	sp,	#1
	sub	a, (hl)
	jr	NC, 00105$
;src/main.c:102: llm_feed(tokens[i]);
	ld	hl, #_tokens
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
	push	bc
	call	_llm_feed
	pop	bc
;src/main.c:103: if (joypad() & J_B) { stop = 1; break; }
	call	_joypad
	bit	5, a
	jr	Z, 00120$
	ldhl	sp,	#0
	ld	(hl), #0x01
	jr	00105$
00120$:
;src/main.c:101: for (i = 0; i < ntok; i++) {
	inc	c
	jr	00119$
00105$:
;src/main.c:105: if (!stop) {
	ldhl	sp,	#0
	ld	a, (hl)
	or	a, a
	jr	NZ, 00117$
;src/main.c:106: llm_feed(TOK_BOT);
	ld	a, #0x03
	call	_llm_feed
;src/main.c:107: ui_status("thinking...");
	ld	de, #___str_4
	call	_ui_status
;src/main.c:108: ui_log_puts("< ");
	ld	de, #___str_5
	call	_ui_log_puts
;src/main.c:109: while (n < MAX_REPLY && llm_pos() < M_T) {
	ldhl	sp,	#1
	ld	(hl), #0x00
00113$:
	ldhl	sp,	#1
	ld	a, (hl)
	sub	a, #0x60
	jr	NC, 00117$
	call	_llm_pos
	sub	a, #0x60
	jr	NC, 00117$
;src/main.c:110: t = llm_pick(sampling);
	ld	a, (_sampling)
	call	_llm_pick
;src/main.c:111: if (t == TOK_EOS) break;
	ld	c, a
	dec	a
	jr	Z, 00117$
;src/main.c:112: if (t >= 4) {
	ld	a, c
	sub	a, #0x04
	jr	C, 00109$
;src/main.c:113: ui_log_puts(tok_str[t]);        /* a subword token prints several characters */
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	ld	de, #_tok_str
	add	hl, de
	ld	a, (hl+)
	ld	b, (hl)
	push	bc
	ld	e, a
	ld	d, b
	call	_ui_log_puts
;src/main.c:114: ui_log_flush();
	call	_ui_log_flush
	pop	bc
00109$:
;src/main.c:116: n++;
	ldhl	sp,	#1
	inc	(hl)
;src/main.c:117: if (joypad() & J_B) break;
	call	_joypad
	bit	5, a
	jr	NZ, 00117$
;src/main.c:118: llm_feed(t);
	ld	a, c
	call	_llm_feed
	jr	00113$
00117$:
;src/main.c:121: ui_log_newline();
	call	_ui_log_newline
;src/main.c:122: ui_log_flush();
	call	_ui_log_flush
;src/main.c:123: ui_status("ready");
	ld	de, #___str_6
	call	_ui_status
;src/main.c:124: input_len = 0;
	xor	a, a
	ld	(#_input_len),a
;src/main.c:125: input[0] = 0;
	ld	hl, #_input
	ld	(hl), #0x00
;src/main.c:126: redraw_input();
;src/main.c:127: wait_key_release();
	call	_redraw_input
	pop	hl
	jp	_wait_key_release
00121$:
;src/main.c:128: }
	inc	sp
	inc	sp
	ret
___str_2:
	.ascii "> "
	.db 0x00
___str_3:
	.ascii "reading..."
	.db 0x00
___str_4:
	.ascii "thinking..."
	.db 0x00
___str_5:
	.ascii "< "
	.db 0x00
___str_6:
	.ascii "ready"
	.db 0x00
;src/main.c:130: static void press_key(void)
;	---------------------------------
; Function press_key
; ---------------------------------
_press_key:
;src/main.c:132: uint8_t key = ui_kbd_key(cur_row, cur_col);
	ld	a, (_cur_col)
	ld	e, a
	ld	a, (_cur_row)
	call	_ui_kbd_key
;src/main.c:133: if (key == KEY_SEND) { chat(); return; }
	cp	a, #0x03
	jp	Z, _chat
;src/main.c:134: if (key == KEY_DEL) {
	cp	a, #0x02
	jr	NZ, 00108$
;src/main.c:135: if (input_len) input[--input_len] = 0;
	ld	hl, #_input_len
	ld	a, (hl)
	or	a, a
	jp	Z, _redraw_input
	dec	(hl)
	ld	a, #<(_input)
	add	a, (hl)
	ld	c, a
	ld	a, #>(_input)
	adc	a, #0x00
	ld	b, a
	xor	a, a
	ld	(bc), a
	jp	_redraw_input
00108$:
;src/main.c:137: char c = (key == KEY_SPACE) ? ' ' : (char)key;
	cp	a, #0x01
	jr	NZ, 00112$
	ld	c, #0x20
	jr	00113$
00112$:
	ld	c, a
00113$:
;src/main.c:138: if (input_len < INPUT_MAX) { input[input_len++] = c; input[input_len] = 0; }
	ld	hl, #_input_len
	ld	a, (hl)
	sub	a, #0x28
	jp	NC, _redraw_input
	ld	de, #_input+0
	ld	b, (hl)
	inc	(hl)
	ld	l, b
	ld	h, #0x00
	add	hl, de
	ld	(hl), c
	ld	a, e
	ld	hl, #_input_len
	add	a, (hl)
	ld	e, a
	jr	NC, 00155$
	inc	d
00155$:
	xor	a, a
	ld	(de), a
;src/main.c:140: redraw_input();
;src/main.c:141: }
	jp	_redraw_input
;src/main.c:152: void dbg_sync(uint8_t id)
;	---------------------------------
; Function dbg_sync
; ---------------------------------
_dbg_sync::
;src/main.c:154: selftest_step = id;
	ld	l, a
	ld	(_selftest_step), a
;src/main.c:155: while (selftest_ack != id) wait_vbl_done();
00101$:
	ld	a, (_selftest_ack)
	sub	a, l
	ret	Z
	call	_wait_vbl_done
;src/main.c:156: }
	jr	00101$
;src/main.c:158: void main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main::
;src/main.c:161: ui_init();
	call	_ui_init
;src/main.c:162: ui_status("selftest");
	ld	de, #___str_7
	call	_ui_status
;src/main.c:163: llm_init();
	call	_llm_init
;src/main.c:164: while (!selftest_go) wait_vbl_done();
00101$:
	ld	a, (#_selftest_go)
	or	a, a
	jr	NZ, 00103$
	call	_wait_vbl_done
	jr	00101$
00103$:
;src/main.c:165: ui_status("running");
	ld	de, #___str_8
	call	_ui_status
;src/main.c:166: for (i = 0; i < selftest_ntok; i++) {
	ld	c, #0x00
00109$:
	ld	a, c
	ld	hl, #_selftest_ntok
	sub	a, (hl)
	jr	NC, 00104$
;src/main.c:167: llm_feed(selftest_tokens[i]);
	ld	hl, #_selftest_tokens
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
	push	bc
	call	_llm_feed
;src/main.c:168: dbg_sync(200);
	ld	a, #0xc8
	call	_dbg_sync
	pop	bc
;src/main.c:166: for (i = 0; i < selftest_ntok; i++) {
	inc	c
	jr	00109$
00104$:
;src/main.c:170: ui_status("done");
	ld	de, #___str_9
	call	_ui_status
;src/main.c:171: while (1) wait_vbl_done();
00106$:
	call	_wait_vbl_done
;src/main.c:172: }
	jr	00106$
___str_7:
	.ascii "selftest"
	.db 0x00
___str_8:
	.ascii "running"
	.db 0x00
___str_9:
	.ascii "done"
	.db 0x00
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
