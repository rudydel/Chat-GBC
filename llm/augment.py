"""Question augmentation for training.

The fact base has two to five hand written phrasings per fact. Users, on the
other hand, type on a D-pad keyboard: short, unpunctuated, sloppy questions
with typos and without the polite framing of the training data. These
augmentations turn every training question into a *distribution* of
questions so that the model learns the words that matter instead of
memorising exact strings.

All operations work on normalised text (see tokenizer.normalize) and return
normalised text, so nothing outside the vocabulary can be produced.

    >>> rng = random.Random(0)
    >>> augment_question("when was the game boy released", rng)
    'game boy released'
"""
import random

from . import tokenizer as tok

# Framing that users add or omit at will.
PREFIXES = ["hey", "hi", "please", "tell me", "quick question", "so", "um", "ok",
            "can you tell me", "i want to know", "do you know", "question",
            "i wonder", "hey there", "just curious"]
SUFFIXES = ["?", "?", "??", "please", "thanks", "pls", "!", "if you know", "in short", "quickly"]

# Leading question phrases, longest first (so "what is the" wins over "what").
QUESTION_PHRASES = sorted([
    "can you tell me about", "can you tell me", "tell me about", "tell me", "do you know",
    "what is the", "what was the", "what are the", "what were the",
    "what is", "what was", "what are", "what were", "what kind of", "what",
    "when was the", "when did the", "when was", "when did", "when",
    "who was the", "who is the", "who was", "who is", "who",
    "how many", "how much", "how did", "how does", "how",
    "which", "where", "why", "describe", "explain", "name", "list",
], key=len, reverse=True)

# Words that carry little meaning and are often dropped by users.
FILLERS = {"the", "a", "an", "of", "is", "was", "did", "does", "do", "are", "were",
           "please", "actually", "really", "exactly", "original"}

_LETTERS = tok.LETTERS
_NEIGHBOURS = {  # typical mis-hits on a qwerty keyboard (also plausible on the D-pad grid)
    "a": "qsz", "b": "vn", "c": "xv", "d": "sf", "e": "wr", "f": "dg", "g": "fh", "h": "gj",
    "i": "uo", "j": "hk", "k": "jl", "l": "k", "m": "n", "n": "bm", "o": "ip", "p": "o",
    "q": "wa", "r": "et", "s": "ad", "t": "ry", "u": "yi", "v": "cb", "w": "qe", "x": "zc",
    "y": "tu", "z": "xa",
}


def _words(q):
    return q.split()


def op_drop_word(q, rng):
    w = _words(q)
    if len(w) < 3:
        return q
    del w[rng.randrange(len(w))]
    return " ".join(w)


def op_drop_filler(q, rng):
    w = _words(q)
    idx = [i for i, x in enumerate(w) if x in FILLERS]
    if not idx or len(w) < 2:
        return q
    del w[rng.choice(idx)]
    return " ".join(w)


def op_swap_adjacent(q, rng):
    w = _words(q)
    if len(w) < 3:
        return q
    i = rng.randrange(len(w) - 1)
    w[i], w[i + 1] = w[i + 1], w[i]
    return " ".join(w)


def op_strip_punct(q, rng):
    return "".join(ch for ch in q if ch not in tok.PUNCT)


def op_prefix(q, rng):
    return rng.choice(PREFIXES) + " " + q


def op_suffix(q, rng):
    s = rng.choice(SUFFIXES)
    return q + ("" if s.startswith("?") or s == "!" else " ") + s


def op_keywords(q, rng):
    """Strip the question phrase and the fillers: 'when was the game boy released' -> 'game boy released'."""
    q = op_strip_punct(q, rng)
    for ph in QUESTION_PHRASES:
        if q.startswith(ph + " "):
            q = q[len(ph) + 1:]
            break
    w = [x for x in _words(q) if x not in FILLERS]
    return " ".join(w) if w else q


def op_typo(q, rng):
    """One keyboard slip in a word of at least four letters: drop, double, swap or mis-hit a letter."""
    w = _words(q)
    cand = [i for i, x in enumerate(w) if len(x) >= 4 and x.isalpha()]
    if not cand:
        return q
    i = rng.choice(cand)
    s = w[i]
    j = rng.randrange(len(s))
    kind = rng.randrange(4)
    if kind == 0:                                  # dropped letter
        s = s[:j] + s[j + 1:]
    elif kind == 1:                                # doubled letter
        s = s[:j] + s[j] + s[j:]
    elif kind == 2 and j + 1 < len(s):             # transposed letters
        s = s[:j] + s[j + 1] + s[j] + s[j + 2:]
    else:                                          # neighbouring key
        s = s[:j] + rng.choice(_NEIGHBOURS.get(s[j], _LETTERS)) + s[j + 1:]
    w[i] = s
    return " ".join(w)


def op_gameboy(q, rng):
    """Write 'game boy' as one word (or 'game boy color' as 'gbc'), as most people type it."""
    if "game boy color" in q and rng.random() < 0.3:
        return q.replace("game boy color", "gbc")
    if "game boy" in q:
        return q.replace("game boy", "gameboy")
    return q


def op_truncate(q, rng):
    """Cut the question after a random word (the user hit START early or typed only the key words)."""
    w = _words(q)
    if len(w) < 4:
        return q
    n = rng.randrange(2, len(w))
    return " ".join(w[:n])


# (operation, relative weight). Shape changes (keywords, framing, dropped words)
# dominate; typos are kept rarer so the model does not learn to expect them.
OPS = [
    (op_keywords, 3.0),
    (op_gameboy, 2.0),
    (op_drop_filler, 2.0),
    (op_prefix, 1.5),
    (op_suffix, 1.5),
    (op_strip_punct, 1.0),
    (op_drop_word, 0.7),
    (op_swap_adjacent, 0.5),
    (op_typo, 1.0),
    (op_truncate, 0.5),
]
_OP_FNS = [f for f, _ in OPS]
_OP_W = [w for _, w in OPS]


def augment_question(q, rng: random.Random, max_ops=2):
    """Apply one or two random operations to a normalised question.
    Returns the original question if the result would be empty."""
    n_ops = 1 if rng.random() < 0.7 else max_ops
    out = q
    for f in rng.choices(_OP_FNS, weights=_OP_W, k=n_ops):
        out = f(out, rng)
    out = tok.normalize(out)
    return out if out else q


if __name__ == "__main__":
    import sys
    rng = random.Random(0)
    qs = sys.argv[1:] or ["when was the game boy released", "who designed the game boy", "what cpu does the game boy use"]
    for q in qs:
        print(q)
        for _ in range(8):
            print("   ", augment_question(tok.normalize(q), rng))
