/* Integer transformer inference for the Game Boy. Mirrors llm/simulate.py exactly. */
#ifndef LLM_H
#define LLM_H
#include <stdint.h>
#include "../gen/model_config.h"

extern int32_t logits[M_V];

void llm_init(void);                 /* enable SRAM, clear caches */
void llm_reset(void);                /* forget the conversation (clear KV caches) */
uint8_t llm_pos(void);               /* tokens currently in the context */
void llm_feed(uint8_t token);        /* run one token through the model; updates logits[] */
uint8_t llm_pick(uint8_t sample);    /* choose the next token from logits[] (greedy or sampled) */
void llm_seed(uint16_t seed);        /* seed the sampling RNG */

#endif
