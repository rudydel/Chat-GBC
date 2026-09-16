"""Tokenizer shared by the trainer, the simulator and the ROM.

The vocabulary has a fixed *base* of 54 tokens (4 specials, space, a-z, 0-9,
13 punctuation marks) so that the on-screen keyboard can type every
character, plus up to 201 learned *subword* tokens (frequent words, word
pieces and short phrases such as "game boy", "nintendo", "the ", "ed "). Text
is encoded by **greedy longest match**: at every position the longest token
that matches the upcoming characters is taken. The ROM runs the same
algorithm in C on the typed question (gb/src/main.c), so the two sides agree
by construction. A subword token costs one model step but prints several
characters, which makes replies two to three times faster on the console.

The learned tokens belong to a checkpoint: they are stored in ckpt.pt and in
model_int.json and installed with set_vocab() when the model is loaded.
Token ids stay one byte (at most 255 tokens).

Token ids:
    0  <pad>   padding (never predicted)
    1  <eos>   end of an assistant turn
    2  <usr>   start of a user turn
    3  <bot>   start of an assistant turn
    4  ' '     space
    5..30      a-z
    31..40     0-9
    41..53     punctuation (see PUNCT)
    54..       learned subword tokens (see learn_vocab / set_vocab)
"""
import unicodedata
from collections import Counter

PAD, EOS, USR, BOT = 0, 1, 2, 3
SPECIALS = ["<pad>", "<eos>", "<usr>", "<bot>"]
LETTERS = "abcdefghijklmnopqrstuvwxyz"
DIGITS = "0123456789"
PUNCT = ".,?!'-:()/&\";"

BASE_VOCAB = SPECIALS + [" "] + list(LETTERS) + list(DIGITS) + list(PUNCT)
BASE_SIZE = len(BASE_VOCAB)          # 54
MAX_VOCAB = 255                      # token ids are uint8_t in the ROM (and loop counters must not wrap)
MAX_TOKEN_LEN = 12                   # characters per learned token

CHAR_TO_ID = {c: i for i, c in enumerate(BASE_VOCAB) if len(c) == 1}

# --- the active vocabulary (base + learned tokens); replaced by set_vocab() ---
VOCAB = list(BASE_VOCAB)
VOCAB_SIZE = len(VOCAB)
EXTRA = []                           # learned tokens, in id order (54..)
_TOKEN_TO_ID = {c: i for c, i in CHAR_TO_ID.items()}
_MAX_LEN = 1


def set_vocab(extra):
    """Install the learned tokens `extra` (list of strings, ids 54..) as the active vocabulary."""
    global VOCAB, VOCAB_SIZE, EXTRA, _TOKEN_TO_ID, _MAX_LEN
    extra = list(extra)
    assert BASE_SIZE + len(extra) <= MAX_VOCAB, f"at most {MAX_VOCAB - BASE_SIZE} learned tokens"
    seen = set()
    for t in extra:
        assert 2 <= len(t) <= MAX_TOKEN_LEN, f"bad token length: {t!r}"
        assert all(c in CHAR_TO_ID for c in t), f"token with characters outside the base vocabulary: {t!r}"
        assert t not in seen, f"duplicate token {t!r}"
        seen.add(t)
    VOCAB = list(BASE_VOCAB) + extra
    VOCAB_SIZE = len(VOCAB)
    EXTRA = extra
    _TOKEN_TO_ID = dict(CHAR_TO_ID)
    _TOKEN_TO_ID.update({t: BASE_SIZE + i for i, t in enumerate(extra)})
    _MAX_LEN = max([1] + [len(t) for t in extra])


def extra_vocab():
    return list(EXTRA)


# Characters that are silently normalised to something in the vocabulary.
_REPLACE = {
    "’": "'", "‘": "'", "“": '"', "”": '"',
    "–": "-", "—": "-", "…": "...", " ": " ",
    "\t": " ", "\r": " ", "\n": " ",
    "[": "(", "]": ")", "{": "(", "}": ")", "*": "", "_": " ",
    "+": " plus ", "%": " percent", "$": "", "#": "", "@": " at ",
    "=": "-", "<": "(", ">": ")", "|": " ", "\\": "/", "~": "-", "`": "'",
    "^": "", "×": "x",
}


def normalize(text: str) -> str:
    """Lower-case, strip accents, map unsupported characters, squeeze spaces."""
    text = unicodedata.normalize("NFKD", text)
    out = []
    for ch in text:
        if unicodedata.combining(ch):
            continue
        ch = ch.lower()
        ch = _REPLACE.get(ch, ch)
        out.append(ch)
    text = "".join(out)
    text = "".join(ch for ch in text if ch in CHAR_TO_ID)
    while "  " in text:
        text = text.replace("  ", " ")
    return text.strip()


def encode(text: str, normalize_text: bool = True) -> list:
    """Greedy longest-match encoding with the active vocabulary (mirrors tokenize() in gb/src/main.c)."""
    if normalize_text:
        text = normalize(text)
    out = []
    i, n = 0, len(text)
    while i < n:
        L = min(_MAX_LEN, n - i)
        while L > 1:
            tid = _TOKEN_TO_ID.get(text[i:i + L])
            if tid is not None:
                out.append(tid)
                i += L
                break
            L -= 1
        else:
            tid = CHAR_TO_ID.get(text[i])
            if tid is not None:
                out.append(tid)
            i += 1
    return out


def decode(ids) -> str:
    out = []
    for i in ids:
        i = int(i)
        if i < len(SPECIALS):
            out.append({PAD: "", EOS: "", USR: "\n> ", BOT: "\n< "}[i])
        else:
            out.append(VOCAB[i])
    return "".join(out)


def text_of(ids) -> str:
    """Characters of the non-special tokens only (what the console prints)."""
    return "".join(VOCAB[int(i)] for i in ids if int(i) >= len(SPECIALS))


def format_turn(question: str, answer: str = None) -> list:
    """<usr> question <bot> [answer <eos>] as token ids."""
    ids = [USR] + encode(question) + [BOT]
    if answer is not None:
        ids += encode(answer) + [EOS]
    return ids


def _words(text):
    """Whole words with their leading space (" game", " boy", "when" at the start of a text)."""
    out, cur = [], ""
    for ch in text:
        if ch == " ":
            if cur:
                out.append(cur)
            cur = " "
        else:
            cur += ch
    if cur and cur != " ":
        out.append(cur)
    return out


def learn_vocab(texts, n_extra, max_len=MAX_TOKEN_LEN, per_round=8):
    """Learn `n_extra` subword tokens from normalised strings.

    Byte-pair style: repeatedly encode the texts with the *greedy* encoder,
    count adjacent token pairs and add the most frequent pairs (concatenated,
    at most `max_len` characters) as new tokens. Because the counts come from
    the same greedy encoder that is used afterwards, the vocabulary is tuned
    for it. Tokens respect word boundaries: a token is a piece of one word
    (" gam", "ed", "boy"), a whole word with its leading space (" nintendo"),
    or a phrase of whole words (" game boy"); no token ends with a space or
    starts in the middle of one word and continues into the next.
    Deterministic (ties broken by the token string). Leaves the learned
    vocabulary installed and returns it."""
    assert 0 <= n_extra <= MAX_VOCAB - BASE_SIZE
    set_vocab([])
    words = set()
    for t in texts:
        words.update(_words(t))
    words.discard(" ")

    def allowed(a, b):
        s = a + b
        if len(s) > max_len or s.endswith(" ") or " " in b[1:] and not b.startswith(" "):
            return False
        if b.startswith(" "):
            # phrase: a must be a whole word or phrase (starts with a space, and the space in
            # front of b proves a ended at a word boundary), b a whole word
            return a.startswith(" ") and b in words
        return " " not in b and " " not in a[1:]      # extend one word (a may carry the leading space)

    extra = []
    while len(extra) < n_extra:
        pairs = Counter()
        for t in texts:
            ids = encode(t, normalize_text=False)
            for a, b in zip(ids, ids[1:]):
                pairs[(a, b)] += 1
        cands = []
        for (a, b), c in pairs.items():
            sa, sb = VOCAB[a], VOCAB[b]
            if allowed(sa, sb) and (sa + sb) not in _TOKEN_TO_ID:
                cands.append((-c, sa + sb))
        if not cands:
            break
        cands.sort()
        take = min(per_round, n_extra - len(extra))
        new = []
        for _, s in cands:
            if s not in new:
                new.append(s)
            if len(new) == take:
                break
        extra += new
        set_vocab(extra)
    return extra


if __name__ == "__main__":
    print("base vocab size", BASE_SIZE)
    for i, t in enumerate(BASE_VOCAB):
        print(i, repr(t))
    print(decode(format_turn("When was the Game Boy released?", "In 1989.")))
