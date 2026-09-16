;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Linux)
;--------------------------------------------------------
	.module ui
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _memset
	.globl _memmove
	.globl _memcpy
	.globl _set_default_palette
	.globl _set_bkg_tiles
	.globl _set_bkg_data
	.globl _display_off
	.globl _ui_init
	.globl _ui_status
	.globl _ui_help
	.globl _ui_log_newline
	.globl _ui_log_putc
	.globl _ui_log_puts
	.globl _ui_log_flush
	.globl _ui_input_draw
	.globl _ui_kbd_cols
	.globl _ui_kbd_key
	.globl _ui_kbd_draw
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_logbuf:
	.ds 200
_log_line:
	.ds 1
_log_col:
	.ds 1
_tilebuf:
	.ds 20
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
;src/ui.c:22: static void draw_text(uint8_t x, uint8_t y, const char *s, uint8_t inverted)
;	---------------------------------
; Function draw_text
; ---------------------------------
_draw_text:
	add	sp, #-5
	ldhl	sp,	#3
	ld	(hl-), a
	ld	(hl), e
;src/ui.c:25: uint8_t off = inverted ? FONT_INV_OFFSET : 0;
	ldhl	sp,	#9
	ld	a, (hl)
	or	a, a
	ld	a, #0x39
	jr	NZ, 00110$
	xor	a, a
00110$:
	ldhl	sp,	#0
	ld	(hl), a
;src/ui.c:26: while (*s && n < SCREEN_W) {
	ldhl	sp,	#4
	ld	(hl), #0x00
	ldhl	sp,	#7
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
00102$:
	ld	a, (bc)
	ldhl	sp,	#1
	ld	(hl), a
	or	a, a
	jr	Z, 00104$
	ldhl	sp,	#4
	ld	a, (hl)
	sub	a, #0x14
	jr	NC, 00104$
;src/ui.c:27: tilebuf[n++] = CHAR_TILE(*s) + off;
	ld	de, #_tilebuf
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#4
	inc	(hl)
	ldhl	sp,	#1
	ld	a, (hl)
	res	7, a
	add	a, #<(_font_map)
	ld	l, a
	ld	a, #0x00
	adc	a, #>(_font_map)
	ld	h, a
	ld	a, (hl)
	ldhl	sp,	#0
	add	a, (hl)
	ld	(de), a
;src/ui.c:28: s++;
	inc	bc
	jr	00102$
00104$:
;src/ui.c:30: if (n) set_bkg_tiles(x, y, n, 1, tilebuf);
	ldhl	sp,	#4
	ld	a, (hl)
	or	a, a
	jr	Z, 00107$
	ld	bc, #_tilebuf
	push	bc
	ld	a, #0x01
	push	af
	inc	sp
	ld	a, (hl-)
	dec	hl
	push	af
	inc	sp
	ld	a, (hl+)
	ld	d, a
	ld	e, (hl)
	push	de
	call	_set_bkg_tiles
	add	sp, #6
00107$:
;src/ui.c:31: }
	add	sp, #5
	pop	hl
	add	sp, #3
	jp	(hl)
_kbd_row0:
	.ascii "abcdefghij"
	.db 0x00
_kbd_row1:
	.ascii "klmnopqrst"
	.db 0x00
_kbd_row2:
	.ascii "uvwxyz'-,."
	.db 0x00
_kbd_row3:
	.ascii "0123456789"
	.db 0x00
_kbd_rows:
	.dw _kbd_row0
	.dw _kbd_row1
	.dw _kbd_row2
	.dw _kbd_row3
_kbd_last_labels:
	.dw __str_4
	.dw __str_5
	.dw __str_6
	.dw __str_7
	.dw __str_8
_kbd_last_cols:
	.db #0x00	; 0
	.db #0x02	; 2
	.db #0x04	; 4
	.db #0x09	; 9
	.db #0x0e	; 14
_kbd_last_keys:
	.db #0x3f	; 63
	.db #0x21	; 33
	.db #0x01	; 1
	.db #0x02	; 2
	.db #0x03	; 3
__str_4:
	.ascii "?"
	.db 0x00
__str_5:
	.ascii "!"
	.db 0x00
__str_6:
	.ascii "spc"
	.db 0x00
__str_7:
	.ascii "del"
	.db 0x00
__str_8:
	.ascii "send"
	.db 0x00
;src/ui.c:33: static void clear_row(uint8_t y)
;	---------------------------------
; Function clear_row
; ---------------------------------
_clear_row:
	ld	b, a
;src/ui.c:35: memset(tilebuf, 0, SCREEN_W);
	ld	de, #0x0014
	push	de
	ld	de, #0x0000
	push	de
	ld	de, #_tilebuf
	push	de
	call	_memset
	add	sp, #6
;src/ui.c:36: set_bkg_tiles(0, y, SCREEN_W, 1, tilebuf);
	ld	de, #_tilebuf
	push	de
	ld	hl, #0x114
	push	hl
	push	bc
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_set_bkg_tiles
	add	sp, #6
;src/ui.c:37: }
	ret
;src/ui.c:39: void ui_init(void)
;	---------------------------------
; Function ui_init
; ---------------------------------
_ui_init::
;src/ui.c:42: DISPLAY_OFF;                        /* VRAM and palettes are freely writable while the LCD is off */
	call	_display_off
;src/ui.c:43: set_bkg_data(0, FONT_NTILES, font_tiles);
	ld	de, #_font_tiles
	push	de
	ld	hl, #0x7200
	push	hl
	call	_set_bkg_data
	add	sp, #4
;src/ui.c:44: for (y = 0; y < 18; y++) clear_row(y);
	ld	c, #0x00
00104$:
	push	bc
	ld	a, c
	call	_clear_row
	pop	bc
	inc	c
	ld	a, c
	sub	a, #0x12
	jr	C, 00104$
;src/ui.c:50: if (_cpu == CGB_TYPE) set_default_palette();
	ld	a, (#__cpu)
	sub	a, #0x11
	jr	NZ, 00103$
	call	_set_default_palette
00103$:
;src/ui.c:51: memset(logbuf, ' ', sizeof(logbuf));
	ld	de, #0x00c8
	push	de
	ld	de, #0x0020
	push	de
	ld	de, #_logbuf
	push	de
	call	_memset
	add	sp, #6
;src/ui.c:52: log_line = 0;
;src/ui.c:53: log_col = 0;
	xor	a, a
	ld	(#_log_line), a
	ld	(#_log_col),a
;src/ui.c:54: SHOW_BKG;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x01
	ldh	(_LCDC_REG + 0), a
;src/ui.c:55: DISPLAY_ON;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x80
	ldh	(_LCDC_REG + 0), a
;src/ui.c:56: }
	ret
;src/ui.c:58: void ui_status(const char *s)
;	---------------------------------
; Function ui_status
; ---------------------------------
_ui_status::
;src/ui.c:60: clear_row(STATUS_ROW);
	push	de
	ld	a, #0x0a
	call	_clear_row
	pop	de
;src/ui.c:61: draw_text(0, STATUS_ROW, s, 0);
	xor	a, a
	push	af
	inc	sp
	push	de
	ld	e, #0x0a
	xor	a, a
	call	_draw_text
;src/ui.c:62: }
	ret
;src/ui.c:64: void ui_help(const char *s)
;	---------------------------------
; Function ui_help
; ---------------------------------
_ui_help::
;src/ui.c:66: clear_row(HELP_ROW);
	push	de
	ld	a, #0x11
	call	_clear_row
	pop	de
;src/ui.c:67: draw_text(0, HELP_ROW, s, 0);
	xor	a, a
	push	af
	inc	sp
	push	de
	ld	e, #0x11
	xor	a, a
	call	_draw_text
;src/ui.c:68: }
	ret
;src/ui.c:71: static void log_scroll(void)
;	---------------------------------
; Function log_scroll
; ---------------------------------
_log_scroll:
;src/ui.c:73: memmove(logbuf[0], logbuf[1], (LOG_LINES - 1) * SCREEN_W);
	ld	de, #0x00b4
	push	de
	ld	bc, #(_logbuf + 20)
	ld	de, #_logbuf
	call	_memmove
;src/ui.c:74: memset(logbuf[LOG_LINES - 1], ' ', SCREEN_W);
	ld	de, #0x0014
	push	de
	ld	de, #0x0020
	push	de
	ld	de, #(_logbuf + 180)
	push	de
	call	_memset
	add	sp, #6
;src/ui.c:75: }
	ret
;src/ui.c:77: void ui_log_newline(void)
;	---------------------------------
; Function ui_log_newline
; ---------------------------------
_ui_log_newline::
;src/ui.c:79: if (log_line == LOG_LINES - 1) log_scroll();
	ld	a, (#_log_line)
	sub	a, #0x09
	jr	NZ, 00102$
	call	_log_scroll
	jr	00103$
00102$:
;src/ui.c:80: else log_line++;
	ld	hl, #_log_line
	inc	(hl)
00103$:
;src/ui.c:81: log_col = 0;
	xor	a, a
	ld	(#_log_col),a
;src/ui.c:82: }
	ret
;src/ui.c:84: void ui_log_putc(char c)
;	---------------------------------
; Function ui_log_putc
; ---------------------------------
_ui_log_putc::
	add	sp, #-25
	ldhl	sp,	#24
;src/ui.c:86: if (c == '\n') { ui_log_newline(); return; }
	ld	(hl), a
	sub	a, #0x0a
	jr	NZ, 00102$
	call	_ui_log_newline
	jp	00117$
00102$:
;src/ui.c:87: if (log_col >= SCREEN_W) {
	ld	a, (#_log_col)
	sub	a, #0x14
	jp	C, 00116$
;src/ui.c:89: uint8_t s = SCREEN_W;
	ldhl	sp,	#20
	ld	(hl), #0x14
;src/ui.c:90: if (c != ' ') {
	ldhl	sp,	#24
	ld	a, (hl)
	sub	a, #0x20
	jr	Z, 00108$
;src/ui.c:91: while (s > 0 && logbuf[log_line][s - 1] != ' ') s--;
	ldhl	sp,	#23
	ld	(hl), #0x14
00104$:
	ldhl	sp,	#23
	ld	a, (hl)
	or	a, a
	jr	Z, 00126$
	ld	hl, #_log_line
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#23
	ld	l, (hl)
	dec	l
	ld	h, #0x00
	add	hl, bc
	ld	a, (hl)
	sub	a, #0x20
	jr	Z, 00126$
	ldhl	sp,	#23
	dec	(hl)
	jr	00104$
00126$:
	ldhl	sp,	#23
	ld	a, (hl)
	ldhl	sp,	#20
	ld	(hl), a
00108$:
;src/ui.c:93: if (c == ' ') {
	ldhl	sp,	#24
	ld	a, (hl)
	sub	a, #0x20
	jr	NZ, 00110$
;src/ui.c:94: ui_log_newline();
	call	_ui_log_newline
;src/ui.c:95: return;                          /* swallow the space at the wrap */
	jp	00117$
00110$:
;src/ui.c:97: if (s == 0 || s == SCREEN_W) {
	ldhl	sp,	#20
	ld	a, (hl)
	or	a, a
	jr	Z, 00111$
	ld	a, (hl)
	sub	a, #0x14
	jr	NZ, 00112$
00111$:
;src/ui.c:98: ui_log_newline();
	call	_ui_log_newline
	jp	00116$
00112$:
;src/ui.c:100: uint8_t n = SCREEN_W - s;
	ldhl	sp,	#20
	ld	a, (hl+)
	ld	c, a
	ld	a, #0x14
	sub	a, c
	ld	(hl), a
;src/ui.c:102: memcpy(tmp, &logbuf[log_line][s], n);
	ld	a, (hl+)
	ld	(hl+), a
	ld	(hl), #0x00
	ld	hl, #_log_line
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#20
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#22
	ld	e, (hl)
	ld	d, #0x00
	push	de
	ld	hl, #2
	add	hl, sp
	ld	e, l
	ld	d, h
	call	_memcpy
;src/ui.c:103: memset(&logbuf[log_line][s], ' ', n);
	ld	hl, #_log_line
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#20
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#22
	ld	e, (hl)
	ld	d, #0x00
	push	de
	ld	de, #0x0020
	push	de
	push	bc
	call	_memset
	add	sp, #6
;src/ui.c:104: ui_log_newline();
	call	_ui_log_newline
;src/ui.c:105: memcpy(logbuf[log_line], tmp, n);
	ld	hl, #_log_line
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	ld	e, l
	ld	d, h
	ldhl	sp,	#22
	ld	c, (hl)
	ld	b, #0x00
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	c, l
	ld	b, h
	call	_memcpy
;src/ui.c:106: log_col = n;
	ldhl	sp,	#21
	ld	a, (hl)
	ld	(#_log_col),a
00116$:
;src/ui.c:109: logbuf[log_line][log_col++] = c;
	ld	hl, #_log_line
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (_log_col)
	ld	e, a
	ld	hl, #_log_col
	inc	(hl)
	ld	a, e
	add	a, c
	ld	c, a
	ld	a, #0x00
	adc	a, b
	ld	b, a
	ldhl	sp,	#24
	ld	a, (hl)
	ld	(bc), a
00117$:
;src/ui.c:110: }
	add	sp, #25
	ret
;src/ui.c:112: void ui_log_puts(const char *s)
;	---------------------------------
; Function ui_log_puts
; ---------------------------------
_ui_log_puts::
;src/ui.c:114: while (*s) ui_log_putc(*s++);
00101$:
	ld	a, (de)
	or	a, a
	ret	Z
	inc	de
	push	de
	call	_ui_log_putc
	pop	de
;src/ui.c:115: }
	jr	00101$
;src/ui.c:117: void ui_log_flush(void)
;	---------------------------------
; Function ui_log_flush
; ---------------------------------
_ui_log_flush::
	add	sp, #-5
;src/ui.c:120: for (y = 0; y < LOG_LINES; y++) {
	ldhl	sp,	#3
	ld	(hl), #0x00
;src/ui.c:121: for (x = 0; x < SCREEN_W; x++) tilebuf[x] = CHAR_TILE(logbuf[y][x]);
00109$:
	ldhl	sp,	#3
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	add	hl, hl
	ld	bc, #_logbuf
	add	hl, bc
	inc	sp
	inc	sp
	push	hl
	ldhl	sp,	#4
	ld	(hl), #0x00
00103$:
	ld	de, #_tilebuf
	ldhl	sp,	#4
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	c, l
	ld	b, h
	pop	de
	push	de
	ldhl	sp,	#4
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ldhl	sp,	#2
	ld	(hl), a
	ld	l, (hl)
	res	7, l
	ld	h, #0x00
	ld	de, #_font_map
	add	hl, de
	ld	a, (hl)
	ld	(bc), a
	ldhl	sp,	#4
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x14
	jr	C, 00103$
;src/ui.c:122: set_bkg_tiles(0, y, SCREEN_W, 1, tilebuf);
	dec	hl
	ld	de, #_tilebuf
	push	de
	ld	de, #0x114
	push	de
	ld	h, (hl)
	ld	l, #0x00
	push	hl
	call	_set_bkg_tiles
	add	sp, #6
;src/ui.c:120: for (y = 0; y < LOG_LINES; y++) {
	ldhl	sp,	#3
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x0a
	jr	C, 00109$
;src/ui.c:124: }
	add	sp, #5
	ret
;src/ui.c:127: void ui_input_draw(const char *buf, uint8_t len)
;	---------------------------------
; Function ui_input_draw
; ---------------------------------
_ui_input_draw::
	add	sp, #-6
	ldhl	sp,	#4
	ld	(hl), e
	inc	hl
	ld	(hl), d
	ld	c, a
;src/ui.c:129: uint8_t x, start = 0, n = 0;
	ld	b, #0x00
;src/ui.c:130: tilebuf[n++] = CHAR_TILE('>');
	ld	a, (#(_font_map + 62) + 0)
	ld	(#_tilebuf),a
;src/ui.c:131: if (len > SCREEN_W - 2) start = len - (SCREEN_W - 2);
	ld	a, #0x12
	sub	a, c
	jr	NC, 00114$
	ld	a, c
	add	a, #0xee
	ld	b, a
;src/ui.c:132: for (x = start; x < len; x++) tilebuf[n++] = CHAR_TILE(buf[x]);
00114$:
	ldhl	sp,	#0
	ld	(hl), #0x01
00108$:
	ldhl	sp,	#0
	ld	a, (hl+)
	inc	a
	ld	(hl-), a
	ld	e, (hl)
	ld	d, #0x00
	ld	hl, #_tilebuf
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#4
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#3
	ld	(hl), a
	ld	a, b
	sub	a, c
	jr	NC, 00103$
	dec	hl
	dec	hl
	ld	a, (hl-)
	ld	(hl), a
	ldhl	sp,#4
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	l, b
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	res	7, a
	ld	l, a
	ld	h, #0x00
	ld	de, #_font_map
	add	hl, de
	ld	a, (hl)
	ldhl	sp,	#2
	ld	e, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, e
	ld	(hl), a
	inc	b
	jr	00108$
00103$:
;src/ui.c:133: tilebuf[n++] = CHAR_TILE('_');
	ldhl	sp,	#1
	ld	a, (hl+)
	ld	c, a
	ld	a, (#(_font_map + 95) + 0)
	ld	e, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, e
	ld	(hl), a
;src/ui.c:134: while (n < SCREEN_W) tilebuf[n++] = 0;
00104$:
	ld	a, c
	sub	a, #0x14
	jr	NC, 00106$
	ld	hl, #_tilebuf
	ld	b, #0x00
	add	hl, bc
	inc	c
	ld	(hl), #0x00
	jr	00104$
00106$:
;src/ui.c:135: set_bkg_tiles(0, INPUT_ROW, SCREEN_W, 1, tilebuf);
	ld	bc, #_tilebuf
	push	bc
	ld	hl, #0x114
	push	hl
	ld	hl, #0xb00
	push	hl
	call	_set_bkg_tiles
;src/ui.c:136: }
	add	sp, #12
	ret
;src/ui.c:139: uint8_t ui_kbd_cols(uint8_t row)
;	---------------------------------
; Function ui_kbd_cols
; ---------------------------------
_ui_kbd_cols::
;src/ui.c:141: return (row < 4) ? 10 : 5;
	sub	a, #0x04
	jr	NC, 00103$
	ld	a, #0x0a
	ret
00103$:
	ld	a, #0x05
;src/ui.c:142: }
	ret
;src/ui.c:144: uint8_t ui_kbd_key(uint8_t row, uint8_t col)
;	---------------------------------
; Function ui_kbd_key
; ---------------------------------
_ui_kbd_key::
	ld	b, a
	ld	c, e
;src/ui.c:146: if (row < 4) return kbd_rows[row][col];
	ld	a, b
	sub	a, #0x04
	jr	NC, 00102$
	ld	de, #_kbd_rows+0
	xor	a, a
	ld	l, b
	ld	h, a
	add	hl, hl
	add	hl, de
	ld	a, (hl+)
	ld	h, (hl)
	ld	l, a
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
	ret
00102$:
;src/ui.c:147: return kbd_last_keys[col];
	ld	hl, #_kbd_last_keys
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
;src/ui.c:148: }
	ret
;src/ui.c:150: void ui_kbd_draw(uint8_t cur_row, uint8_t cur_col)
;	---------------------------------
; Function ui_kbd_draw
; ---------------------------------
_ui_kbd_draw::
	add	sp, #-8
	ldhl	sp,	#5
	ld	(hl-), a
	ld	(hl), e
;src/ui.c:153: for (r = 0; r < 4; r++) {
	ldhl	sp,	#7
	ld	(hl), #0x00
00109$:
;src/ui.c:154: memset(tilebuf, 0, SCREEN_W);
	ld	bc, #_tilebuf
	ld	de, #0x0014
	push	de
	ld	de, #0x0000
	push	de
	push	bc
	call	_memset
	add	sp, #6
;src/ui.c:155: for (c = 0; c < 10; c++) {
	ldhl	sp,	#5
	ld	a, (hl+)
	inc	hl
	sub	a, (hl)
	ld	a, #0x01
	jr	Z, 00212$
	xor	a, a
00212$:
	ld	c, a
	ld	b, #0x00
00107$:
;src/ui.c:156: uint8_t inv = (r == cur_row && c == cur_col) ? FONT_INV_OFFSET : 0;
	bit	0, c
	jr	Z, 00115$
	ldhl	sp,	#4
	ld	a, (hl)
	sub	a, b
	jr	NZ, 00115$
	ldhl	sp,	#6
	ld	(hl), #0x39
	jr	00116$
00115$:
	ldhl	sp,	#6
	ld	(hl), #0x00
00116$:
;src/ui.c:157: tilebuf[c * 2] = CHAR_TILE(kbd_rows[r][c]) + inv;
	ld	e, b
	xor	a, a
	sla	e
	adc	a, a
	ldhl	sp,	#0
	ld	(hl), e
	inc	hl
	ld	(hl), a
	pop	de
	push	de
	ld	hl, #_tilebuf
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#4
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#3
	ld	(hl), a
	ldhl	sp,	#7
	ld	e, (hl)
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	ld	de, #_kbd_rows
	add	hl, de
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	ld	e, b
	ld	d, #0x00
	add	hl, de
	ld	l, (hl)
	res	7, l
	ld	h, #0x00
	ld	de, #_font_map
	add	hl, de
	ld	a, (hl)
	ldhl	sp,	#6
	add	a, (hl)
	ldhl	sp,	#2
	ld	e, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, e
	ld	(hl), a
;src/ui.c:155: for (c = 0; c < 10; c++) {
	inc	b
	ld	a, b
	sub	a, #0x0a
	jr	C, 00107$
;src/ui.c:159: set_bkg_tiles(0, KBD_ROW + r, SCREEN_W, 1, tilebuf);
	ld	bc, #_tilebuf
	ldhl	sp,	#7
	ld	a, (hl)
	add	a, #0x0c
	push	bc
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x14
	push	hl
	inc	sp
	ld	h, a
	ld	l, #0x00
	push	hl
	call	_set_bkg_tiles
	add	sp, #6
;src/ui.c:153: for (r = 0; r < 4; r++) {
	ldhl	sp,	#7
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x04
	jp	C, 00109$
;src/ui.c:161: memset(tilebuf, 0, SCREEN_W);
	ld	de, #0x0014
	push	de
	ld	de, #0x0000
	push	de
	ld	de, #_tilebuf
	push	de
	call	_memset
	add	sp, #6
;src/ui.c:162: for (c = 0; c < 5; c++) {
	ldhl	sp,	#5
	ld	a, (hl)
	sub	a, #0x04
	ld	a, #0x01
	jr	Z, 00217$
	xor	a, a
00217$:
	ldhl	sp,	#1
	ld	(hl), a
	ldhl	sp,	#6
	ld	(hl), #0x00
00111$:
;src/ui.c:163: const char *s = kbd_last_labels[c];
	ldhl	sp,	#6
	ld	c, (hl)
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	ld	de, #_kbd_last_labels
	add	hl, de
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
;src/ui.c:164: uint8_t x = kbd_last_cols[c];
	ld	de, #_kbd_last_cols
	ldhl	sp,	#6
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ld	e, a
;src/ui.c:165: uint8_t inv = (cur_row == 4 && c == cur_col) ? FONT_INV_OFFSET : 0;
	ldhl	sp,	#1
	bit	0, (hl)
	jr	Z, 00120$
	ldhl	sp,	#4
	ld	a, (hl+)
	inc	hl
	sub	a, (hl)
	ld	a, #0x39
	jr	Z, 00121$
00120$:
	xor	a, a
00121$:
	ldhl	sp,	#2
	ld	(hl), a
;src/ui.c:166: while (*s) tilebuf[x++] = CHAR_TILE(*s++) + inv;
	ldhl	sp,	#7
	ld	(hl), e
00103$:
	ld	a, (bc)
	ldhl	sp,	#3
	ld	(hl), a
	or	a, a
	jr	Z, 00112$
	ld	de, #_tilebuf
	ldhl	sp,	#7
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#7
	inc	(hl)
	ldhl	sp,	#3
	ld	a, (hl)
	inc	bc
	res	7, a
	add	a, #<(_font_map)
	ld	l, a
	ld	a, #0x00
	adc	a, #>(_font_map)
	ld	h, a
	ld	a, (hl)
	ldhl	sp,	#2
	add	a, (hl)
	ld	(de), a
	jr	00103$
00112$:
;src/ui.c:162: for (c = 0; c < 5; c++) {
	ldhl	sp,	#6
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x05
	jr	C, 00111$
;src/ui.c:168: set_bkg_tiles(0, KBD_ROW + 4, SCREEN_W, 1, tilebuf);
	ld	de, #_tilebuf
	push	de
	ld	hl, #0x114
	push	hl
	ld	hl, #0x1000
	push	hl
	call	_set_bkg_tiles
;src/ui.c:169: }
	add	sp, #14
	ret
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
