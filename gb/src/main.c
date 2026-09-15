/* Chat-GBC: talk to a nano language model on a Game Boy.
 *
 * Controls
 *   D-pad  move the keyboard cursor
 *   A      press the highlighted key
 *   B      backspace (or stop a reply while the model is talking)
 *   START  send the prompt
 *   SELECT toggle greedy / sampled decoding
 */
#include <gb/gb.h>
#include <string.h>
#include <stdint.h>
#include "ui.h"
#include "llm.h"

#define MIN_REPLY 24            /* start a fresh context if fewer tokens than this would remain */
#define MAX_REPLY 96

static const char vocab_chars[] = M_VOCAB_CHARS;
static char input[INPUT_MAX + 1];
static uint8_t input_len;
static uint8_t cur_row, cur_col;
static uint8_t sampling;
static uint16_t frame_count;

static uint8_t char_to_token(char c)
{
    uint8_t i;
    for (i = 4; i < M_V; i++)
        if (vocab_chars[i] == c) return i;
    return 0;
}

static void show_mode(void)
{
    ui_help(sampling ? "a:key b:del st:send *" : "a:key b:del st:send");
}

static uint8_t wait_key_release(void)
{
    uint8_t j;
    do { wait_vbl_done(); frame_count++; j = joypad(); } while (j);
    return j;
}

static void redraw_input(void)
{
    ui_input_draw(input, input_len);
}

/* feed the prompt, then generate a reply, printing it as it is produced */
static void chat(void)
{
    uint8_t i, n = 0, t;
    uint8_t stop = 0;

    if (input_len == 0) return;
    ui_log_puts("> ");
    ui_log_puts(input);
    ui_log_newline();
    ui_log_flush();

#ifdef KEEP_CONTEXT
    /* multi-turn: keep the conversation in the KV cache while it fits */
    if ((uint16_t)llm_pos() + input_len + 2 + MIN_REPLY > M_T) {
        llm_reset();
        ui_status("(new context)");
    } else {
        ui_status("reading...");
    }
#else
    /* every question starts a fresh context: the tiny model answers much more
     * reliably without earlier turns in its attention window (see docs) */
    llm_reset();
    ui_status("reading...");
#endif
    llm_seed(frame_count ^ (uint16_t)DIV_REG);

    llm_feed(TOK_USR);
    for (i = 0; i < input_len; i++) {
        llm_feed(char_to_token(input[i]));
        if (joypad() & J_B) { stop = 1; break; }
    }
    if (!stop) {
        llm_feed(TOK_BOT);
        ui_status("thinking...");
        ui_log_puts("< ");
        while (n < MAX_REPLY && llm_pos() < M_T) {
            t = llm_pick(sampling);
            if (t == TOK_EOS) break;
            if (t >= 4) {
                ui_log_putc(vocab_chars[t]);
                ui_log_flush();
            }
            n++;
            if (joypad() & J_B) break;
            llm_feed(t);
        }
    }
    ui_log_newline();
    ui_log_flush();
    ui_status("ready");
    input_len = 0;
    input[0] = 0;
    redraw_input();
    wait_key_release();
}

static void press_key(void)
{
    uint8_t key = ui_kbd_key(cur_row, cur_col);
    if (key == KEY_SEND) { chat(); return; }
    if (key == KEY_DEL) {
        if (input_len) input[--input_len] = 0;
    } else {
        char c = (key == KEY_SPACE) ? ' ' : (char)key;
        if (input_len < INPUT_MAX) { input[input_len++] = c; input[input_len] = 0; }
    }
    redraw_input();
}

#ifdef SELFTEST
/* Self-test build: feed a fixed token sequence and hand the intermediate
 * buffers to the host after every step (tools/selftest.py polls WRAM). */
volatile uint8_t selftest_step;
volatile uint8_t selftest_ack;
uint8_t selftest_tokens[64];
volatile uint8_t selftest_ntok;
volatile uint8_t selftest_go;

void dbg_sync(uint8_t id)
{
    selftest_step = id;
    while (selftest_ack != id) wait_vbl_done();
}

void main(void)
{
    uint8_t i;
    ui_init();
    ui_status("selftest");
    llm_init();
    while (!selftest_go) wait_vbl_done();
    ui_status("running");
    for (i = 0; i < selftest_ntok; i++) {
        llm_feed(selftest_tokens[i]);
        dbg_sync(200);
    }
    ui_status("done");
    while (1) wait_vbl_done();
}
#else
void main(void)
{
    uint8_t j;
    ui_init();
    ui_log_puts("chat-gbc: a nano llm");
    ui_log_newline();
    ui_log_puts("model " M_NAME);
    ui_log_newline();
    ui_log_puts("ask me about the game boy!");
    ui_log_newline();
    ui_log_flush();
    ui_status("loading...");
    llm_init();
    ui_status("ready");
    show_mode();
    redraw_input();
    ui_kbd_draw(cur_row, cur_col);

    while (1) {
        wait_vbl_done();
        frame_count++;
        j = joypad();
        if (!j) continue;
        if (j & J_UP) { if (cur_row) cur_row--; }
        else if (j & J_DOWN) { if (cur_row < KBD_ROWS - 1) cur_row++; }
        else if (j & J_LEFT) { cur_col = cur_col ? cur_col - 1 : ui_kbd_cols(cur_row) - 1; }
        else if (j & J_RIGHT) { cur_col = (cur_col + 1 < ui_kbd_cols(cur_row)) ? cur_col + 1 : 0; }
        else if (j & J_A) { press_key(); }
        else if (j & J_B) { if (input_len) input[--input_len] = 0; redraw_input(); }
        else if (j & J_START) { chat(); }
        else if (j & J_SELECT) { sampling = !sampling; show_mode(); }
        if (cur_col >= ui_kbd_cols(cur_row)) cur_col = ui_kbd_cols(cur_row) - 1;
        ui_kbd_draw(cur_row, cur_col);
        wait_key_release();
    }
}
#endif
