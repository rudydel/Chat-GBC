/* Intro screen: logo, title and the main menu (new chat / chat history / credits). */
#ifndef INTRO_H
#define INTRO_H
#include <gb/gb.h>

/* Draws the title screen and runs the menu. "chat history" and "credits" are
 * handled inside; returns when the player picks "new chat". Lives in a
 * switched ROM bank together with its tiles (bank 0 is nearly full). */
void intro_run(void) BANKED;

#endif
