"""Character-level tokenizer shared by the trainer, the simulator and the ROM.

The vocabulary is fixed (not learned) so that the on-screen keyboard of the
ROM can type every token and the C code can be generated from it.

Token ids:
    0  <pad>   padding (never predicted)
    1  <eos>   end of an assistant turn
    2  <usr>   start of a user turn
    3  <bot>   start of an assistant turn
    4  ' '     space
    5..30      a-z
    31..40     0-9
    41..       punctuation (see PUNCT)
"""
import unicodedata

PAD, EOS, USR, BOT = 0, 1, 2, 3
SPECIALS = ["<pad>", "<eos>", "<usr>", "<bot>"]
LETTERS = "abcdefghijklmnopqrstuvwxyz"
DIGITS = "0123456789"
PUNCT = ".,?!'-:()/&\";"

VOCAB = SPECIALS + [" "] + list(LETTERS) + list(DIGITS) + list(PUNCT)
VOCAB_SIZE = len(VOCAB)
CHAR_TO_ID = {c: i for i, c in enumerate(VOCAB) if len(c) == 1}

# Characters that are silently normalised to something in the vocabulary.
_REPLACE = {
    "’": "'", "‘": "'", "“": '"', "”": '"',
    "–": "-", "—": "-", "…": "...", " ": " ",
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
    if normalize_text:
        text = normalize(text)
    return [CHAR_TO_ID[c] for c in text if c in CHAR_TO_ID]


def decode(ids) -> str:
    out = []
    for i in ids:
        i = int(i)
        if i < len(SPECIALS):
            out.append({PAD: "", EOS: "", USR: "\n> ", BOT: "\n< "}[i])
        else:
            out.append(VOCAB[i])
    return "".join(out)


def format_turn(question: str, answer: str = None) -> list:
    """<usr> question <bot> [answer <eos>] as token ids."""
    ids = [USR] + encode(question) + [BOT]
    if answer is not None:
        ids += encode(answer) + [EOS]
    return ids


def c_vocab_table() -> str:
    """Return the vocabulary as a C string literal of display characters."""
    chars = []
    for i, tok in enumerate(VOCAB):
        chars.append("?" if len(tok) != 1 else tok)
    s = "".join(chars).replace("\\", "\\\\").replace('"', '\\"')
    return '"' + s + '"'


if __name__ == "__main__":
    print("vocab size", VOCAB_SIZE)
    for i, t in enumerate(VOCAB):
        print(i, repr(t))
    print(decode(format_turn("When was the Game Boy released?", "In 1989.")))
