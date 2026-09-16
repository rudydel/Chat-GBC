# Building the ROM

## Requirements

* Python 3.9+ with `torch`, `numpy` (training / export) and `pyboy` (tests):
  `pip install -r requirements.txt`
* [GBDK-2020](https://github.com/gbdk-2020/gbdk-2020) 4.4 (C compiler and
  linker for the Game Boy): `tools/gbdk_setup.sh` downloads the Linux build
  to `tools/gbdk`. On macOS / Windows pass the platform:
  `tools/gbdk_setup.sh 4.4.0 macos` / `win64`, or set `GBDK_HOME` when
  calling `make -C gb GBDK_HOME=/path/to/gbdk`.
* `make`.

## Steps

```bash
python3 -m llm.export models/tiny/ckpt.pt --out gb/gen   # 1. checkpoint -> C/asm sources
make -C gb                                               # 2. sources -> gb/build/chatgbc.gb
python3 tools/emu_test.py gb/build/chatgbc.gb "hello" --model models/tiny/model_int.json   # 3. verify
```

`make rom` at the repository root does steps 1 and 2, `make test` does 3.

### What the export generates (`gb/gen/`)

| File | Content |
|------|---------|
| `model_config.h` | dimensions, fixed-point constants, vocabulary string |
| `model_weights.h`, `model_desc.c` | descriptor tables: pointer + ROM bank of every matrix, per-layer shifts |
| `model_bank_N.c` | the weight matrices, one file per 16 KiB ROM bank (`#pragma bank N`) |
| `dot_gen.s` | the unrolled SM83 dot-product routine with an entry point every 16 elements, and the square table at 0x3E00 |
| `model.mk` | Makefile fragment: number of ROM/SRAM banks for the cartridge header |

The generated files for the shipped model are committed so that the ROM can
be built (and CI can build it) without PyTorch.

### Cartridge header

`gb/Makefile` sets MBC5 + RAM + battery (`-Wl-yt0x1B`), automatic ROM size
and the SRAM size from `model.mk` (2 banks of 8 KiB per layer: one for the
K cache, one for the V cache). The `tiny` model needs 32 KiB SRAM and a
128 KiB ROM; `micro` needs 6 SRAM banks and is declared as 128 KiB SRAM
(makebin only accepts 1, 4 or 16 banks) with a 256 KiB ROM. Flash
cartridges (EverDrive, EZ-Flash Jr, etc.) and all emulators support this.

`tools/check_map.py` runs after linking and fails the build if bank-0 code
grows into the square table at 0x3E00 or WRAM runs into the stack.

## Test builds

* `make -C gb selftest` builds `gb/build/selftest.gb`, the same engine with
  `main()` replaced by a host-driven harness. `python3 tools/selftest.py
  gb/build/selftest.gb models/tiny/model_int.json --profile` feeds tokens,
  compares every intermediate buffer (residual, norm output, q/k/v,
  attention output, FFN, logits) with the Python simulator after every
  stage, and prints the cycle cost of each stage.
* `tools/emu_test.py` uses the normal ROM: it navigates the on-screen
  keyboard, types the prompt, presses START, reads the reply back from the
  tile map and compares it with the simulator.

## Emulator notes

* PyBoy is used headless (`window="null"`). Any accurate emulator works for
  playing: SameBoy, BGB, mGBA, Gambatte (OpenEmu uses the last two).
* The header flags the ROM as CGB compatible (`-Wm-yc`), so a Game Boy Color
  and every emulator running in GBC mode start it in CGB mode. In CGB mode
  the DMG palette register `BGP` is ignored and the boot ROM leaves the colour
  palettes white, so `ui_init()` loads BG palette 0 with the DMG greys
  (`set_default_palette()`) when `_cpu == CGB_TYPE`. Without that the ROM
  ran but showed a blank white screen on OpenEmu / SameBoy / real hardware.
  PyBoy does not reproduce this: its built-in boot ROM initialises the CGB
  palettes to visible colours and the emulator test reads the tile map, not
  the pixels, so check anything palette related in SameBoy or on hardware.
* On a Game Boy Color `main()` switches to double speed (`cpu_fast()`),
  which halves the time per character; an original Game Boy runs at normal
  speed. The self-test ROM stays at normal speed so profiles are comparable.
