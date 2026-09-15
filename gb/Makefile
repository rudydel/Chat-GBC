# Build the Chat-GBC ROM with GBDK-2020.
#
#   make            -> build/chatgbc.gb (needs gb/gen/* from `python -m llm.export`)
#   make clean
#
# GBDK_HOME defaults to ../tools/gbdk (see tools/gbdk_setup.sh).
GBDK_HOME ?= ../tools/gbdk
LCC = $(GBDK_HOME)/bin/lcc

include gen/model.mk

PROJECT   ?= chatgbc
BUILD     = build
OBJ       ?= $(BUILD)/obj
EXTRA_CFLAGS ?=

# MBC5 + RAM + battery, ROM size auto, RAM size from the model, DMG + GBC compatible
LCCFLAGS  = -Wl-yt0x1B -Wm-yoA -Wm-ya$(RAM_BANKS) -Wm-yc -Wm-yn"CHATGBC" -Wl-j -Wl-m
CFLAGS    = -Wf-MMD -Wf--opt-code-speed -Wf--max-allocs-per-node50000 $(EXTRA_CFLAGS)

SRC_C     = $(wildcard src/*.c) $(wildcard gen/*.c)
SRC_S     = $(wildcard src/*.s) $(wildcard gen/*.s)
OBJS      = $(patsubst %.c,$(OBJ)/%.o,$(SRC_C)) $(patsubst %.s,$(OBJ)/%.o,$(SRC_S))

all: $(BUILD)/$(PROJECT).gb

# self-test ROM: same engine compiled with -DSELFTEST, main() replaced by a
# host-driven harness (see tools/selftest.py)
selftest:
	$(MAKE) PROJECT=selftest OBJ=$(BUILD)/obj_selftest EXTRA_CFLAGS=-Wf-DSELFTEST $(BUILD)/selftest.gb

$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(LCC) $(CFLAGS) -c -o $@ $<

$(OBJ)/%.o: %.s
	@mkdir -p $(dir $@)
	$(LCC) -c -o $@ $<

# header dependencies written by sdcc (-Wf-MMD): a new gen/model_config.h rebuilds llm.o etc.
-include $(OBJS:.o=.d)

$(BUILD)/$(PROJECT).gb: $(OBJS)
	$(LCC) $(LCCFLAGS) -o $@ $(OBJS)
	python3 ../tools/check_map.py $(BUILD)/$(PROJECT).map
	@echo "ROM: $@ (model $(MODEL_NAME), $(ROM_BANKS) ROM banks, $(RAM_BANKS) SRAM banks)"

clean:
	rm -rf $(BUILD)

.PHONY: all clean selftest
