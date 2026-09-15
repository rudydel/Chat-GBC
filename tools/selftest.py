#!/usr/bin/env python3
"""Stage-by-stage comparison of the ROM engine against llm/simulate.py.

Builds nothing: expects gb/build/selftest.gb (make -C gb selftest) and the
matching models/<name>/model_int.json. Feeds the same tokens to both and
compares every intermediate buffer after each token.

    python3 tools/selftest.py gb/build/selftest.gb models/tiny/model_int.json [--tokens "hi there"]
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from llm.simulate import IntModel
from llm.intmodel import load_json
from llm import tokenizer as tok


def symbols(noi_path):
    """Parse the NoICE symbol file written by the linker (-Wl-j)."""
    syms = {}
    for line in open(noi_path):
        m = re.match(r"DEF\s+(_[A-Za-z0-9_]+)\s+0x([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rom")
    ap.add_argument("model_json")
    ap.add_argument("--tokens", default="when was the game boy released", help="prompt text to feed")
    ap.add_argument("--max-tokens", type=int, default=24)
    ap.add_argument("--profile", action="store_true", help="print frames spent between checkpoints")
    args = ap.parse_args()
    from pyboy import PyBoy
    syms = symbols(os.path.splitext(args.rom)[0] + ".noi")
    m = load_json(args.model_json)
    sim = IntModel(m)
    D, F, V = sim.D, sim.F, sim.V
    ids = tok.format_turn(args.tokens)[:args.max_tokens]

    pb = PyBoy(args.rom, window="null", sound_emulated=False, log_level="ERROR")
    pb.set_emulation_speed(0)
    for _ in range(120):
        pb.tick()
    mem = pb.memory
    for i, t in enumerate(ids):
        mem[syms["_selftest_tokens"] + i] = t
    mem[syms["_selftest_ntok"]] = len(ids)
    mem[syms["_selftest_go"]] = 1

    def rd8(name, n, signed=True):
        base = syms[name]
        out = []
        for i in range(n):
            b = mem[base + i]
            out.append(b - 256 if signed and b >= 128 else b)
        return out

    def rd16(name, n):
        base = syms[name]
        out = []
        for i in range(n):
            v = mem[base + 2 * i] | (mem[base + 2 * i + 1] << 8)
            out.append(v - 65536 if v >= 32768 else v)
        return out

    def rd32(name, n):
        base = syms[name]
        out = []
        for i in range(n):
            v = sum(mem[base + 4 * i + j] << (8 * j) for j in range(4))
            out.append(v - (1 << 32) if v >= (1 << 31) else v)
        return out

    readers = dict(h=lambda: rd16("_h", D), nbuf=lambda: rd8("_nbuf", D), q=lambda: rd8("_q", D),
                   k=lambda: rd8("_k", D), v=lambda: rd8("_v", D), o=lambda: rd8("_o", D),
                   a=lambda: rd8("_a", D), f=lambda: rd8("_f", F), logits=lambda: rd32("_logits", V))

    def wait_checkpoint():
        frames = 0
        while True:
            cur = mem[syms["_selftest_step"]]
            if cur != mem[syms["_selftest_ack"]]:
                return cur, frames
            pb.tick()
            frames += 1
            if frames > 60 * 600:
                print("timeout waiting for the ROM")
                sys.exit(2)

    all_ok = True
    for step, t in enumerate(ids):
        sim.forward(t)
        total_frames = 0
        ok = True
        for cid, bufs in sim.trace:
            got_id, frames = wait_checkpoint()
            total_frames += frames
            if args.profile:
                print(f"    checkpoint {cid:3d}: {frames:4d} frames ({frames * 17556 / 1000:.0f}k cycles)")
            if got_id != cid:
                print(f"checkpoint order mismatch: ROM {got_id}, simulator {cid}")
                sys.exit(2)
            if cid == 11 and step == 0 and "_dbg_ss" in syms:
                ss, r, inv = rd32("_dbg_ss", 1)[0], rd16("_dbg_r", 1)[0], rd32("_dbg_inv", 1)[0]
                print(f"  ROM norm internals: ss={ss} r={r} inv={inv} shift={rd32('_dbg_prod', 1)[0]}")
            for name, exp in bufs.items():
                got = readers[name]()
                exp = [int(x) for x in exp]
                if exp != got:
                    ok = False
                    diffs = [(i, e, g) for i, (e, g) in enumerate(zip(exp, got)) if e != g]
                    print(f"  step {step} checkpoint {cid} {name}: {len(diffs)} diffs, first (idx, sim, rom): {diffs[:5]}")
            mem[syms["_selftest_ack"]] = cid
        got_id, frames = wait_checkpoint()
        total_frames += frames
        assert got_id == 200, got_id
        mem[syms["_selftest_ack"]] = 200
        print(f"step {step} token {t:2d}: {'OK' if ok else 'MISMATCH'}  {total_frames} frames ({total_frames / 59.73:.2f} s)")
        all_ok &= ok
        if not ok:
            break
    print("ALL OK" if all_ok else "FAILED")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
