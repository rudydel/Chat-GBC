#!/usr/bin/env python3
"""Download Game Boy related articles from Wikipedia (plain-text extracts) to
augment the pre-training corpus.

    python3 data/gameboy/scripts/fetch_web.py [--out data/gameboy/wiki] [--lang en]

The text is licensed CC BY-SA 4.0 by the Wikipedia contributors. The script
only uses the public MediaWiki API (no scraping of HTML pages).
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

TITLES = [
    "Game Boy", "Game Boy family", "Game Boy Color", "Game Boy Pocket", "Game Boy Light",
    "Game Boy Advance", "Game Boy Advance SP", "Game Boy Micro", "Super Game Boy",
    "Game Boy Camera", "Game Boy Printer", "Game Link Cable", "Game Boy Player",
    "Gunpei Yokoi", "Satoru Okada", "Nintendo Research & Development 1",
    "Tetris (Game Boy video game)", "Tetris", "Alexey Pajitnov", "Henk Rogers",
    "Super Mario Land", "Super Mario Land 2: 6 Golden Coins", "Wario Land: Super Mario Land 3",
    "The Legend of Zelda: Link's Awakening", "Kirby's Dream Land", "Metroid II: Return of Samus",
    "Donkey Kong (1994 video game)", "Pokémon Red, Blue, and Yellow", "Pokémon Gold and Silver",
    "Kirby Tilt 'n' Tumble", "List of best-selling Game Boy video games",
    "Atari Lynx", "Game Gear", "TurboExpress", "Handheld game console",
    "Nintendo", "History of Nintendo", "Game & Watch", "Virtual Boy", "WonderSwan",
    "Sharp SM83", "Memory bank controller",
]

API = "https://{lang}.wikipedia.org/w/api.php"


def fetch(title, lang):
    params = {"action": "query", "prop": "extracts", "explaintext": 1, "redirects": 1,
              "format": "json", "titles": title}
    url = API.format(lang=lang) + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "Chat-GBC dataset builder (github.com/rudydel/Chat-GBC)"})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.load(r)
    pages = data["query"]["pages"]
    page = next(iter(pages.values()))
    return page.get("extract", "")


def clean(text):
    # drop section headers, reference sections and very short lines
    out = []
    skip = False
    for line in text.split("\n"):
        line = line.strip()
        m = re.match(r"^=+\s*(.*?)\s*=+$", line)
        if m:
            skip = m.group(1).lower() in ("references", "external links", "see also", "notes", "further reading", "bibliography")
            continue
        if skip or len(line) < 40:
            continue
        out.append(line)
    return "\n\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "wiki"))
    ap.add_argument("--lang", default="en")
    ap.add_argument("--titles", nargs="*", default=TITLES)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    total = 0
    for t in args.titles:
        try:
            text = clean(fetch(t, args.lang))
        except Exception as e:  # network errors, missing pages
            print(f"  skip {t!r}: {e}", file=sys.stderr)
            continue
        if not text:
            print(f"  empty {t!r}", file=sys.stderr)
            continue
        fn = re.sub(r"[^a-z0-9]+", "_", t.lower()).strip("_") + ".txt"
        with open(os.path.join(args.out, fn), "w", encoding="utf-8") as f:
            f.write(text + "\n")
        total += len(text)
        print(f"  {t}: {len(text)} chars")
        time.sleep(0.5)
    print(f"wrote {total} characters to {args.out}")


if __name__ == "__main__":
    main()
