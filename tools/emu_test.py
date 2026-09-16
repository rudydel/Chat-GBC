#!/usr/bin/env python3
"""Run the ROM headlessly in PyBoy, type a prompt on the on-screen keyboard,
read the reply back from the tile map and (optionally) check it against the
bit-exact Python simulator.

    python3 tools/emu_test.py gb/build/chatgbc.gb "when was the game boy released" \
        --model models/tiny/model_int.json

Exit code 0 when the ROM and the simulator agree.
"""
import argparse
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# keyboard layout - must match gb/src/ui.c
KBD_ROWS = ["abcdefghij", "klmnopqrst", "uvwxyz'-,.", "0123456789"]
LAST_ROW = {"?": 0, "!": 1, " ": 2}
STATUS_ROW, LOG_LINES = 10, 10


def key_pos(ch):
    for r, row in enumerate(KBD_ROWS):
        if ch in row:
            return r, row.index(ch)
    if ch in LAST_ROW:
        return 4, LAST_ROW[ch]
    raise ValueError(f"cannot type {ch!r}")


class Console:
    def __init__(self, rom, font_map, quiet=True):
        from pyboy import PyBoy
        self.pb = PyBoy(rom, window="null", sound_emulated=False, log_level="ERROR" if quiet else "INFO")
        self.pb.set_emulation_speed(0)
        self.frames = 0
        self.tiles = font_map["tile_to_char"]
        self.inv = font_map["inv_offset"]
        self.row, self.col = 0, 0

    def tick(self, n=1):
        for _ in range(n):
            self.pb.tick()
        self.frames += n

    def screen(self):
        mem = self.pb.memory
        lines = []
        for y in range(18):
            chars = []
            for x in range(20):
                t = mem[0x9800 + 32 * y + x]      # raw BG tile map (LCDC uses 0x9800 / 0x8000 addressing)
                if t >= self.inv:
                    t -= self.inv
                chars.append(self.tiles[t] if t < len(self.tiles) else "?")
            lines.append("".join(chars))
        return lines

    def press(self, btn, hold=3, gap=3):
        self.pb.button_press(btn)
        self.tick(hold)
        self.pb.button_release(btn)
        self.tick(gap)

    def wait_text(self, text, max_frames=600):
        """wait until some row of the screen contains text"""
        start = self.frames
        while self.frames - start < max_frames:
            self.tick(10)
            if any(text in row for row in self.screen()):
                return self.frames - start
        raise TimeoutError(f"text {text!r} not on screen:\n" + "\n".join(self.screen()))

    def wait_status(self, text, max_frames=20 * 60 * 60):
        start = self.frames
        while self.frames - start < max_frames:
            self.tick(10)
            if self.screen()[STATUS_ROW].startswith(text):
                return self.frames - start
        raise TimeoutError(f"status {text!r} not reached; screen:\n" + "\n".join(self.screen()))

    def type_text(self, text):
        for ch in text:
            r, c = key_pos(ch)
            while self.row < r:
                self.press("down"); self.row += 1
            while self.row > r:
                self.press("up"); self.row -= 1
            ncols = 10 if self.row < 4 else 5
            self.col = min(self.col, ncols - 1)
            while self.col != c:
                if (c - self.col) % ncols <= ncols // 2:
                    self.press("right"); self.col = (self.col + 1) % ncols
                else:
                    self.press("left"); self.col = (self.col - 1) % ncols
            self.press("a")

    def send(self):
        self.press("start")


def last_reply(lines):
    """Text of the last '<' paragraph of the conversation log (whitespace removed:
    the ROM's word wrap drops spaces at line breaks)."""
    rows = [l.rstrip() for l in lines[:LOG_LINES]]
    start = None
    for i, r in enumerate(rows):
        if r.startswith("<"):
            start = i
    if start is None:
        return ""
    text = rows[start][1:] + "".join(rows[start + 1:])
    return "".join(text.split())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rom")
    ap.add_argument("prompts", nargs="+")
    ap.add_argument("--model", help="model_int.json to compare against")
    ap.add_argument("--font-map", default=os.path.join(os.path.dirname(__file__), "font_map.json"))
    ap.add_argument("--timeout-min", type=float, default=30, help="emulated minutes to wait per reply")
    ap.add_argument("--dump", action="store_true", help="print the whole screen after each reply")
    args = ap.parse_args()

    font_map = json.load(open(args.font_map))
    con = Console(args.rom, font_map)
    con.tick(120)
    con.wait_text("new chat")          # intro menu, cursor on "new chat"
    con.press("a")
    con.wait_status("ready", 600)

    sim = None
    if args.model:
        from llm.simulate import IntModel
        from llm.intmodel import load_json
        from llm import tokenizer as tok
        sim = IntModel(load_json(args.model))

    ok = True
    for prompt in args.prompts:
        con.type_text(prompt)
        con.send()
        t0 = time.time()
        frames = con.wait_status("ready", int(args.timeout_min * 60 * 60))
        scr = con.screen()
        if args.dump:
            print("\n".join("|" + l + "|" for l in scr))
        reply = last_reply(scr)
        secs = frames / 59.73
        print(f"> {prompt}")
        print(f"< {reply}")
        print(f"  ({secs:.1f} s of Game Boy time for prompt + reply, {secs / max(1, len(prompt) + len(reply) + 3):.2f} s/char; "
              f"{time.time() - t0:.1f} s wall)")
        if sim is not None:
            expect_ids = sim.chat_reply(prompt, max_new=96)
            expect = "".join(tok.text_of(expect_ids).split())
            # the screen only shows the last 10 lines: compare the visible tail
            if expect.endswith(reply) and (len(reply) > 0 or len(expect) == 0):
                print(f"  simulator: MATCH ({len(expect_ids)} tokens)")
            else:
                print(f"  simulator: MISMATCH, expected: {expect!r}")
                ok = False
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
