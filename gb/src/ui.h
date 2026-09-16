/* Text user interface: chat log, input line, on-screen keyboard. */
#ifndef UI_H
#define UI_H
#include <stdint.h>

#define SCREEN_W 20
#define LOG_LINES 10          /* rows 0..9   : conversation */
#define STATUS_ROW 10         /* row 10      : status line */
#define INPUT_ROW 11          /* row 11      : "> prompt" */
#define KBD_ROW 12            /* rows 12..16 : keyboard */
#define HELP_ROW 17           /* row 17      : button help */
#define INPUT_MAX 40

#define KBD_ROWS 5
#define HIST_LINES 96         /* lines of conversation kept for the history screen */

void ui_init(void);
void ui_clear(void);                /* blank the whole screen */
void ui_blank(uint8_t x, uint8_t y, uint8_t w);
void ui_text(uint8_t x, uint8_t y, const char *s);
void ui_text_n(uint8_t x, uint8_t y, const char *s, uint8_t n);
void ui_status(const char *s);
void ui_help(const char *s);

/* conversation log */
void ui_log_putc(char c);           /* append with word wrap */
void ui_log_puts(const char *s);
void ui_log_newline(void);
void ui_log_flush(void);            /* copy the log to the screen */
void ui_log_clear(void);            /* forget the log (new chat) */

/* chat history: every finished log line is kept (ring of HIST_LINES) while recording is on */
void ui_log_record(uint8_t on);
uint8_t ui_hist_count(void);
const char *ui_hist_line(uint8_t i);   /* i = 0 oldest; SCREEN_W chars, not NUL terminated */

/* input line */
void ui_input_draw(const char *buf, uint8_t len);

/* keyboard: returns the key label under the cursor via ui_kbd_key() */
#define KEY_SPACE 1
#define KEY_DEL   2
#define KEY_SEND  3
void ui_kbd_draw(uint8_t cur_row, uint8_t cur_col);
uint8_t ui_kbd_cols(uint8_t row);
uint8_t ui_kbd_key(uint8_t row, uint8_t col);   /* character, or KEY_* */

#endif
