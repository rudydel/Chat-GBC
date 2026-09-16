# Chat-GBC top-level Makefile
#
#   make setup        install the Python requirements and download GBDK-2020
#   make train        train the default model (configs/tiny.json) on data/gameboy
#   make finetune     continue training models/$(MODEL)/ckpt.pt on $(CHAT)
#   make rom          export models/$(MODEL)/ckpt.pt and build gb/build/chatgbc.gb
#   make test         run the ROM in an emulator and check it against the simulator
#   make selftest     stage-by-stage bit-exactness check (slower, more precise)
#   make chat         chat with the model on the host (integer simulation)
#   make eval         exact match / char error rate on training and held-out questions (integer model)
#
# Variables: MODEL=tiny (models/<MODEL>), CONFIG=configs/$(MODEL).json,
#            TEXT=data/gameboy/corpus (+ data/gameboy/wiki when fetched), CHAT=data/gameboy (every *.jsonl),
#            AUGMENT=0.5 (question augmentation probability), HELDOUT=0.2 (held-out share per fact)

MODEL   ?= tiny
CONFIG  ?= configs/$(MODEL).json
TEXT    ?= data/gameboy/corpus $(wildcard data/gameboy/wiki)
CHAT    ?= data/gameboy
PRETRAIN_STEPS ?= 12000
SFT_STEPS      ?= 8000
AUGMENT ?= 0.5
HELDOUT ?= 0.2
PYTHON  ?= python3
PROMPT  ?= when was the game boy released

.PHONY: all setup train finetune export rom test selftest chat eval clean

all: rom

setup:
	$(PYTHON) -m pip install -r requirements.txt
	tools/gbdk_setup.sh

train:
	$(PYTHON) -m llm.train --config $(CONFIG) --out models/$(MODEL) --text $(TEXT) --chat $(CHAT) \
		--pretrain-steps $(PRETRAIN_STEPS) --sft-steps $(SFT_STEPS) --augment $(AUGMENT) --heldout $(HELDOUT) --eval-int

finetune:
	$(PYTHON) -m llm.train --init models/$(MODEL)/ckpt.pt --out models/$(MODEL) --text $(TEXT) --chat $(CHAT) \
		--pretrain-steps 0 --sft-steps $(SFT_STEPS) --augment $(AUGMENT) --heldout $(HELDOUT) --eval-int

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

eval:
	$(PYTHON) -m llm.evaluate models/$(MODEL)/ckpt.pt --chat $(CHAT) --heldout $(HELDOUT) --int --bad

clean:
	$(MAKE) -C gb clean
