#!/usr/bin/env python3
"""Sanity-check the linker map of the ROM: bank-0 code must not overlap the
SQ lookup table (fixed at 0x3E00) and WRAM usage must leave room for the stack."""
import re
import sys

SQ_ADDR = 0x3E00
WRAM_LIMIT = 0xDF00


def main(path):
    txt = open(path).read()
    areas = {}
    for m in re.finditer(r"^(_[A-Z0-9_]+)\s+([0-9A-F]{8})\s+([0-9A-F]{8})\s+=", txt, re.M):
        name, base, size = m.group(1), int(m.group(2), 16), int(m.group(3), 16)
        areas.setdefault(name, []).append((base, size))
    ok = True
    for name in ("_CODE", "_HOME", "_BASE", "_CODE_0", "_LIT", "_GSINIT", "_GSFINAL", "_INITIALIZER", "_INITIALIZED_dummy"):
        for base, size in areas.get(name, []):
            end = base + size
            if base < 0x4000 and end > SQ_ADDR:
                print(f"ERROR: area {name} [{base:04X}..{end:04X}) overlaps the SQ table at {SQ_ADDR:04X}")
                ok = False
    for name in ("_DATA", "_BSS", "_INITIALIZED"):
        for base, size in areas.get(name, []):
            end = base + size
            if 0xC000 <= base < 0xE000 and end > WRAM_LIMIT:
                print(f"ERROR: WRAM area {name} ends at {end:04X} (> {WRAM_LIMIT:04X}, stack space)")
                ok = False
    code = [(b, s) for n in ("_CODE",) for b, s in areas.get(n, [])]
    if code:
        b, s = code[0]
        print(f"bank0 _CODE: {b:04X}..{b + s:04X} ({s} bytes), SQ table at {SQ_ADDR:04X}")
    data_end = max([b + s for n in ("_DATA", "_BSS") for b, s in areas.get(n, [])] or [0])
    print(f"WRAM used up to {data_end:04X}")
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1])
