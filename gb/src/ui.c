#include <gb/gb.h>
#include <gb/cgb.h>
#include <string.h>
#include "ui.h"
#include "font.h"

static char logbuf[LOG_LINES][SCREEN_W];
static uint8_t log_line, log_col;
static uint8_t tilebuf[SCREEN_W];

/* keyboard layout: rows of keys, each key is a label drawn at a column */
static const char kbd_row0[] = "abcdefghij";
static const char kbd_row1[] = "klmnopqrst";
static const char kbd_row2[] = "uvwxyz'-,.";
static const char kbd_row3[] = "0123456789";
static const char *const kbd_rows[4] = { kbd_row0, kbd_row1, kbd_row2, kbd_row3 };
/* last row: "?", "!", "spc", "del", "send" */
static const char *const kbd_last_labels[5] = { "?", "!", "spc", "del", "send" };
static const uint8_t kbd_last_cols[5] = { 0, 2, 4, 9, 14 };
static const uint8_t kbd_last_keys[5] = { '?', '!', KEY_SPACE, KEY_DEL, KEY_SEND };

static void draw_text(uint8_t x, uint8_t y, const char *s, uint8_t inverted)
{
    uint8_t n = 0;
    uint8_t off = inverted ? FONT_INV_OFFSET : 0;
    while (*s && n < SCREEN_W) {
        tilebuf[n++] = CHAR_TILE(*s) + off;
        s++;
    }
    if (n) set_bkg_tiles(x, y, n, 1, tilebuf);
}

static void clear_row(uint8_t y)
{
    memset(tilebuf, 0, SCREEN_W);
    set_bkg_tiles(0, y, SCREEN_W, 1, tilebuf);
}

void ui_init(void)
{
    uint8_t y;
    DISPLAY_OFF;                        /* VRAM and palettes are freely writable while the LCD is off */
    set_bkg_data(0, FONT_NTILES, font_tiles);
    for (y = 0; y < 18; y++) clear_row(y);
    /* The cartridge header declares CGB support, so a Game Boy Color (and
     * every emulator running in GBC mode, e.g. OpenEmu, SameBoy, Gambatte)
     * starts the ROM in CGB mode. There BGP is ignored and the boot ROM leaves
     * all colour palettes white: without this the screen stays blank. Give
     * BG palette 0 the DMG greys (white, light grey, dark grey, black). */
    if (_cpu == CGB_TYPE) set_default_palette();
    memset(logbuf, ' ', sizeof(logbuf));
    log_line = 0;
    log_col = 0;
    SHOW_BKG;
    DISPLAY_ON;
}

void ui_status(const char *s)
{
    clear_row(STATUS_ROW);
    draw_text(0, STATUS_ROW, s, 0);
}

void ui_help(const char *s)
{
    clear_row(HELP_ROW);
    draw_text(0, HELP_ROW, s, 0);
}

/* ---- conversation log ------------------------------------------------------ */
static void log_scroll(void)
{
    memmove(logbuf[0], logbuf[1], (LOG_LINES - 1) * SCREEN_W);
    memset(logbuf[LOG_LINES - 1], ' ', SCREEN_W);
}

void ui_log_newline(void)
{
    if (log_line == LOG_LINES - 1) log_scroll();
    else log_line++;
    log_col = 0;
}

void ui_log_putc(char c)
{
    if (c == '\n') { ui_log_newline(); return; }
    if (log_col >= SCREEN_W) {
        /* wrap: move the current (partial) word to the next line */
        uint8_t s = SCREEN_W;
        if (c != ' ') {
            while (s > 0 && logbuf[log_line][s - 1] != ' ') s--;
        }
        if (c == ' ') {
            ui_log_newline();
            return;                          /* swallow the space at the wrap */
        }
        if (s == 0 || s == SCREEN_W) {
            ui_log_newline();
        } else {
            uint8_t n = SCREEN_W - s;
            char tmp[SCREEN_W];
            memcpy(tmp, &logbuf[log_line][s], n);
            memset(&logbuf[log_line][s], ' ', n);
            ui_log_newline();
            memcpy(logbuf[log_line], tmp, n);
            log_col = n;
        }
    }
    logbuf[log_line][log_col++] = c;
}

void ui_log_puts(const char *s)
{
    while (*s) ui_log_putc(*s++);
}

void ui_log_flush(void)
{
    uint8_t y, x;
    for (y = 0; y < LOG_LINES; y++) {
        for (x = 0; x < SCREEN_W; x++) tilebuf[x] = CHAR_TILE(logbuf[y][x]);
        set_bkg_tiles(0, y, SCREEN_W, 1, tilebuf);
    }
}

/* ---- input line ------------------------------------------------------------ */
void ui_input_draw(const char *buf, uint8_t len)
{
    uint8_t x, start = 0, n = 0;
    tilebuf[n++] = CHAR_TILE('>');
    if (len > SCREEN_W - 2) start = len - (SCREEN_W - 2);
    for (x = start; x < len; x++) tilebuf[n++] = CHAR_TILE(buf[x]);
    tilebuf[n++] = CHAR_TILE('_');
    while (n < SCREEN_W) tilebuf[n++] = 0;
    set_bkg_tiles(0, INPUT_ROW, SCREEN_W, 1, tilebuf);
}

/* ---- keyboard -------------------------------------------------------------- */
uint8_t ui_kbd_cols(uint8_t row)
{
    return (row < 4) ? 10 : 5;
}

uint8_t ui_kbd_key(uint8_t row, uint8_t col)
{
    if (row < 4) return kbd_rows[row][col];
    return kbd_last_keys[col];
}

void ui_kbd_draw(uint8_t cur_row, uint8_t cur_col)
{
    uint8_t r, c;
    for (r = 0; r < 4; r++) {
        memset(tilebuf, 0, SCREEN_W);
        for (c = 0; c < 10; c++) {
            uint8_t inv = (r == cur_row && c == cur_col) ? FONT_INV_OFFSET : 0;
            tilebuf[c * 2] = CHAR_TILE(kbd_rows[r][c]) + inv;
        }
        set_bkg_tiles(0, KBD_ROW + r, SCREEN_W, 1, tilebuf);
    }
    memset(tilebuf, 0, SCREEN_W);
    for (c = 0; c < 5; c++) {
        const char *s = kbd_last_labels[c];
        uint8_t x = kbd_last_cols[c];
        uint8_t inv = (cur_row == 4 && c == cur_col) ? FONT_INV_OFFSET : 0;
        while (*s) tilebuf[x++] = CHAR_TILE(*s++) + inv;
    }
    set_bkg_tiles(0, KBD_ROW + 4, SCREEN_W, 1, tilebuf);
}
