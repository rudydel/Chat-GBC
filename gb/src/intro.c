/* Intro screen: the Chat-GBC logo, the title and a small menu.
 *
 *   rows 0..7   logo (14x8 tiles)
 *   rows 9..10  "Chat-GBC" (16x2 tiles)
 *   rows 12..16 menu frame: new chat / chat history / credits
 *
 * Code and graphics live together in a switched ROM bank (bankpack picks one
 * with room, see gb/Makefile): the tiles are a header included here only, so
 * they are always in the bank that is mapped while this code runs.
 * Everything drawn goes through the bank-0 UI code.
 */
#pragma bank 255
#include <gb/gb.h>
#include <string.h>
#include "intro.h"
#include "intro_gfx.h"
#include "ui.h"
#include "font.h"
#include "../gen/model_config.h"

#define INTRO_BASE FONT_NTILES        /* first VRAM tile of the intro graphics, after the font */
#define LOGO_X   3
#define LOGO_Y   0
#define TITLE_X  2
#define TITLE_Y  9
#define FRAME_X  1
#define FRAME_Y  12
#define FRAME_W  18                   /* tiles, borders included */
#define FRAME_H  5
#define MENU_Y   (FRAME_Y + 1)
#define CUR_X    3
#define MENU_X   5
#define N_ITEMS  3
#define HIST_VIEW 17                  /* history lines on screen (row 17 is the help line) */

enum { MENU_NEW_CHAT, MENU_HISTORY, MENU_CREDITS };
static const char *const items[N_ITEMS] = { "new chat", "chat history", "credits" };
static uint8_t rowbuf[SCREEN_W];

static void release(void)
{
    while (joypad()) wait_vbl_done();
}

static void frames_wait(uint8_t frames)
{
    while (frames--) wait_vbl_done();
}

/* draw a w x h block of a tile map (INTRO_EMPTY -> font tile 0, blank) */
static void put_map(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t *map)
{
    uint8_t i;
    while (h--) {
        for (i = 0; i < w; i++) {
            uint8_t t = *map++;
            rowbuf[i] = (t == INTRO_EMPTY) ? 0 : INTRO_BASE + t;
        }
        set_bkg_tiles(x, y++, w, 1, rowbuf);
    }
}

/* one row of the frame: left tile, middle tile (or blank), right tile */
static void frame_row(uint8_t y, uint8_t left, uint8_t mid, uint8_t right)
{
    memset(rowbuf, mid == INTRO_EMPTY ? 0 : INTRO_BASE + mid, FRAME_W);
    rowbuf[0] = INTRO_BASE + left;
    rowbuf[FRAME_W - 1] = INTRO_BASE + right;
    set_bkg_tiles(FRAME_X, y, FRAME_W, 1, rowbuf);
}

static void draw_frame(void)
{
    uint8_t y;
    frame_row(FRAME_Y, FRAME_TL, FRAME_T, FRAME_TR);
    for (y = 1; y < FRAME_H - 1; y++) frame_row(FRAME_Y + y, FRAME_L, INTRO_EMPTY, FRAME_R);
    frame_row(FRAME_Y + FRAME_H - 1, FRAME_BL, FRAME_B, FRAME_BR);
}

static void draw_cursor(uint8_t sel)
{
    uint8_t i;
    for (i = 0; i < N_ITEMS; i++) {
        rowbuf[0] = (i == sel) ? INTRO_BASE + FRAME_CUR : 0;
        set_bkg_tiles(CUR_X, MENU_Y + i, 1, 1, rowbuf);
    }
}

/* the three lines inside the frame */
static void draw_menu(uint8_t sel)
{
    uint8_t i;
    for (i = 0; i < N_ITEMS; i++) {
        ui_blank(FRAME_X + 1, MENU_Y + i, FRAME_W - 2);
        ui_text(MENU_X, MENU_Y + i, items[i]);
    }
    draw_cursor(sel);
    ui_blank(0, HELP_ROW, SCREEN_W);
}

static void draw_screen(void)
{
    DISPLAY_OFF;
    set_bkg_data(INTRO_BASE, INTRO_NTILES, intro_tiles);
    ui_clear();
    put_map(LOGO_X, LOGO_Y, LOGO_TW, LOGO_TH, logo_map);
    put_map(TITLE_X, TITLE_Y, TITLE_TW, TITLE_TH, title_map);
    draw_frame();
    DISPLAY_ON;
}

/* credits, shown inside the frame until B */
static void credits(void)
{
    uint8_t i;
    for (i = 0; i < N_ITEMS; i++) ui_blank(FRAME_X + 1, MENU_Y + i, FRAME_W - 2);
    ui_text(CUR_X, MENU_Y, "made by");
    ui_text(CUR_X, MENU_Y + 1, "rudy delouya");
    ui_text(CUR_X, MENU_Y + 2, "model: " M_NAME);
    ui_text(0, HELP_ROW, "b: back");
    while (!(joypad() & J_B)) wait_vbl_done();
    release();
}

/* the chat history (every line of every reply so far), scrolling, until B */
static void history_draw(uint8_t top, uint8_t n)
{
    uint8_t i;
    for (i = 0; i < HIST_VIEW; i++) {
        ui_blank(0, i, SCREEN_W);
        if (top + i < n) ui_text_n(0, i, ui_hist_line(top + i), SCREEN_W);
    }
}

static void history(void)
{
    uint8_t n = ui_hist_count(), top, j;
    top = (n > HIST_VIEW) ? n - HIST_VIEW : 0;         /* start at the newest lines */
    DISPLAY_OFF;
    ui_clear();
    if (n == 0) ui_text(0, 0, "(no chats yet)");
    else history_draw(top, n);
    ui_text(0, HELP_ROW, "^/v: scroll  b: back");
    DISPLAY_ON;
    while (1) {
        wait_vbl_done();
        j = joypad();
        if (!j) continue;
        if (j & J_B) break;
        if (j & J_UP) { if (top) top--; }
        else if (j & J_DOWN) { if (top + HIST_VIEW < n) top++; }
        else if (j & J_LEFT) { top = (top > HIST_VIEW) ? top - HIST_VIEW : 0; }
        else if (j & J_RIGHT) { top = (top + 2 * HIST_VIEW < n) ? top + HIST_VIEW : (n > HIST_VIEW ? n - HIST_VIEW : 0); }
        else continue;
        if (n) history_draw(top, n);
        frames_wait(6);                                     /* auto-repeat while held */
    }
    release();
}

void intro_run(void) BANKED
{
    uint8_t sel = MENU_NEW_CHAT, j;
    draw_screen();
    draw_menu(sel);
    while (1) {
        wait_vbl_done();
        j = joypad();
        if (!j) continue;
        if (j & J_UP) sel = sel ? sel - 1 : N_ITEMS - 1;
        else if (j & J_DOWN) sel = (sel + 1 < N_ITEMS) ? sel + 1 : 0;
        else if (j & (J_A | J_START)) {
            release();
            if (sel == MENU_NEW_CHAT) return;
            if (sel == MENU_HISTORY) { history(); draw_screen(); }
            else credits();
            draw_menu(sel);
            continue;
        } else continue;
        draw_cursor(sel);
        release();
    }
}
