# Chat-GBC top-level Makefile
#
#   make setup        install the Python requirements and download GBDK-2020
#   make train        train the default model (configs/tiny.json) on data/gameboy
#   make finetune     continue training models/$(MODEL)/ckpt.pt on $(CHAT)
#   make rom          export models/$(MODEL)/ckpt.pt and build gb/build/chatgbc.gb
#   make test         run the ROM in an emulator and check it against the simulator
#   make selftest     stage-by-stage bit-exactness check (slower, more precise)
#   make chat         chat with the model on the host (integer simulation)
#
# Variables: MODEL=tiny (models/<MODEL>), CONFIG=configs/$(MODEL).json,
#            TEXT=data/gameboy/corpus, CHAT=data/gameboy/facts.jsonl

MODEL   ?= tiny
CONFIG  ?= configs/$(MODEL).json
TEXT    ?= data/gameboy/corpus
CHAT    ?= data/gameboy/facts.jsonl
PRETRAIN_STEPS ?= 8000
SFT_STEPS      ?= 6000
PYTHON  ?= python3
PROMPT  ?= when was the game boy released

.PHONY: all setup train finetune export rom test selftest chat clean

all: rom

setup:
	$(PYTHON) -m pip install -r requirements.txt
	tools/gbdk_setup.sh

train:
	$(PYTHON) -m llm.train --config $(CONFIG) --out models/$(MODEL) --text $(TEXT) --chat $(CHAT) \
		--pretrain-steps $(PRETRAIN_STEPS) --sft-steps $(SFT_STEPS)

finetune:
	$(PYTHON) -m llm.train --init models/$(MODEL)/ckpt.pt --out models/$(MODEL) --text $(TEXT) --chat $(CHAT) \
		--pretrain-steps 0 --sft-steps $(SFT_STEPS)

export: gb/gen/model_config.h

gb/gen/model_config.h: models/$(MODEL)/ckpt.pt llm/export.py llm/intmodel.py llm/quant.py
	$(PYTHON) -m llm.export models/$(MODEL)/ckpt.pt --out gb/gen

rom: export
	$(MAKE) -C gb

test: rom
	$(PYTHON) tools/emu_test.py gb/build/chatgbc.gb "$(PROMPT)" --model models/$(MODEL)/model_int.json

selftest: export
	$(MAKE) -C gb selftest
	$(PYTHON) tools/selftest.py gb/build/selftest.gb models/$(MODEL)/model_int.json

chat:
	$(PYTHON) -m llm.chat models/$(MODEL)/ckpt.pt --int

clean:
	$(MAKE) -C gb clean
