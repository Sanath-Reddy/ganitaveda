"""Script handling shared by the pack builder, the ingester and the preview site."""

from __future__ import annotations

import re
import unicodedata

from indic_transliteration import sanscript

SCRIPTS = {"devanagari": sanscript.DEVANAGARI, "kannada": sanscript.KANNADA, "iast": sanscript.IAST}


def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


def deva_to(script: str, deva: str) -> str:
    if script == "devanagari":
        return nfc(deva)
    return nfc(sanscript.transliterate(deva, sanscript.DEVANAGARI, SCRIPTS[script]))


def iast_to_deva(iast: str) -> str:
    return nfc(sanscript.transliterate(iast, sanscript.IAST, sanscript.DEVANAGARI))


def round_trips(deva: str) -> bool:
    """Devanagari -> IAST -> Devanagari must be exact (plan §5.3)."""
    return iast_to_deva(deva_to("iast", deva)) == nfc(deva)


# Anusvāra before a stop is read as the nasal of that stop's class, so
# "aṃka" (as Kannada and Devanagari usually write it) and "aṅka" share a key.
_ANUSVARA = [(r"ṃ(?=[kg])", "ṅ"), (r"ṃ(?=[cj])", "ñ"), (r"ṃ(?=[ṭḍ])", "ṇ"),
             (r"ṃ(?=[td])", "n"), (r"ṃ(?=[pb])", "m")]


def ascii_key(s: str) -> str:
    """Plain-ASCII search key: 'kuṭṭaka' -> 'kuttaka'. Works on IAST or English.

    The app implements the same folding in ganita_core (search/normalise.dart);
    tools/tests/test_text.py and the Dart tests share fixtures in
    tools/tests/fixtures/ascii_keys.json so the two cannot drift."""
    s = nfc(s).lower()
    for pat, rep in _ANUSVARA:
        s = re.sub(pat, rep, s)
    s = "".join(c for c in unicodedata.normalize("NFD", s) if not unicodedata.combining(c))
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return " ".join(s.split())


def any_script_key(s: str) -> str:
    """Fold Devanagari or Kannada (or IAST) text to its ASCII key."""
    if re.search(r"[ऀ-ॿ]", s):
        s = deva_to("iast", s)
    elif re.search(r"[ಀ-೿]", s):
        s = nfc(sanscript.transliterate(s, sanscript.KANNADA, sanscript.IAST))
    return ascii_key(s)
