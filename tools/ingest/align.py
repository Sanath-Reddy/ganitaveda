"""Suggest which Sanskrit verses a translation paragraph belongs to (plan §5.2 step 4).

A person confirms every suggestion; this only narrows the search. The signal is
numbers: Hayashi's e-text marks numerals with `%` (`%pañca-aṃśas`, `%tri-guṇas`),
and a translation paragraph for the same example repeats them in words or digits.

  python -m tools.ingest.align colebrooke > build/align-colebrooke.csv
  python -m tools.ingest.align evaluate colebrooke       # score against confirmed segments

Output columns: paragraph, page_hint, suggestion1, score1, suggestion2, score2, suggestion3, score3, text.
"""

from __future__ import annotations

import csv
import re
import sys
from collections import Counter
from pathlib import Path

import yaml

from tools.pack.text import ascii_key

ROOT = Path(__file__).resolve().parents[2]
RAW = Path(__file__).resolve().parent / "raw"

SANSKRIT_NUMBERS = {
    "eka": 1, "dvi": 2, "dvau": 2, "dve": 2, "tri": 3, "catur": 4, "catus": 4, "pañca": 5, "ṣaṭ": 6, "ṣaḍ": 6,
    "sapta": 7, "aṣṭa": 8, "nava": 9, "daśa": 10, "ekādaśa": 11, "dvādaśa": 12, "trayodaśa": 13, "caturdaśa": 14,
    "pañcadaśa": 15, "ṣoḍaśa": 16, "saptadaśa": 17, "aṣṭādaśa": 18, "viṃśati": 20, "triṃśat": 30, "catvāriṃśat": 40,
    "pañcāśat": 50, "ṣaṣṭi": 60, "saptati": 70, "aśīti": 80, "navati": 90, "śata": 100, "sahasra": 1000,
    "ayuta": 10000, "lakṣa": 100000, "koṭi": 10000000,
}
ENGLISH_NUMBERS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
    "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
    "seventy": 70, "eighty": 80, "ninety": 90, "hundred": 100, "thousand": 1000,
    "half": 2, "third": 3, "fourth": 4, "quarter": 4, "fifth": 5, "sixth": 6, "seventh": 7, "eighth": 8,
    "ninth": 9, "tenth": 10, "thirds": 3, "fifths": 5, "sixths": 6, "sevenths": 7, "ninths": 9, "tenths": 10,
}
ENGLISH_CONTENT = {"swarm": "ali", "bees": "ali", "lotus": "kamala", "coin": "niṣka", "camphor": "karpūra"}


def sanskrit_numbers(iast: str) -> Counter[int]:
    """Numbers from `%`-marked words in a verse's source_text, compounds split on hyphens."""
    out: Counter[int] = Counter()
    for word in re.findall(r"%([^\s/]+)", iast):
        for part in word.split("-"):
            part = part.strip("%@#")
            if part in SANSKRIT_NUMBERS:
                out[SANSKRIT_NUMBERS[part]] += 1
    return out


def english_numbers(text: str) -> Counter[int]:
    out: Counter[int] = Counter()
    low = text.lower()
    for m in re.finditer(r"\b\d+\b", low):
        out[int(m.group())] += 1
    for word in re.findall(r"[a-z]+", low):
        if word in ENGLISH_NUMBERS:
            out[ENGLISH_NUMBERS[word]] += 1
    return out


def score(verse_nums: Counter[int], para_nums: Counter[int]) -> float:
    if not verse_nums or not para_nums:
        return 0.0
    inter = sum((verse_nums & para_nums).values())
    union = sum((verse_nums | para_nums).values())
    return inter / union


def colebrooke_paragraphs() -> list[tuple[int, str]]:
    """Numbered paragraphs of the Līlāvatī part of the 1817 OCR (up to the Algebra)."""
    lines = (RAW / "colebrooke_djvu.txt").read_text(encoding="utf-8").split("\n")
    stop = next(i for i, ln in enumerate(lines) if "ELEMENTAL" in ln and "ALGEBRA" in ln)
    # Paragraph heads vary in the OCR ("Rule", "Example", "Reduction of…", "Statement"), so
    # accept any capitalised word and rely on the numbers rising in step.
    # Multi-stanza rules are headed with a range ("14 — 15.  Rule of multiplication").
    para_re = r"^\s*(\d{1,3})(?:\s*[—–-]+\s*\d{1,3})?\s*[.:]\s+[A-Z][a-z]"
    start = next(i for i, ln in enumerate(lines) if i > 4000 and (m := re.match(para_re, ln)) and int(m.group(1)) <= 14)
    paras: list[tuple[int, str]] = []
    cur: list[str] = []
    num = 0
    for ln in lines[start:stop]:
        m = re.match(para_re, ln)
        if m and num < int(m.group(1)) <= num + (14 if num == 0 else 8):
            if cur:
                paras.append((num, " ".join(cur)))
            num = int(m.group(1))
            cur = [re.sub(r"\s+", " ", ln).strip()]
        elif cur and ln.strip():
            cur.append(re.sub(r"\s+", " ", ln).strip())
    if cur:
        paras.append((num, " ".join(cur)))
    return paras


def verse_table() -> dict[str, Counter[int]]:
    table: dict[str, Counter[int]] = {}
    for f in sorted((ROOT / "content" / "works" / "lilavati" / "verses").glob("*.yaml")):
        for v in yaml.safe_load(f.read_text(encoding="utf-8")):
            table[v["id"]] = sanskrit_numbers(v["source_text"])
    return table


def verse_no(verse_id: str) -> int:
    return int(verse_id.rsplit(".", 1)[1])


def expected_verse(para: int, anchors: list[tuple[int, int]]) -> float:
    """Where paragraph `para` should fall in the verse numbering, interpolated between
    confirmed (paragraph, verse number) anchors; slope 1 beyond the ends."""
    pts = sorted(set(anchors))
    if not pts:
        return float(para)
    if para <= pts[0][0]:
        return pts[0][1] + (para - pts[0][0])
    if para >= pts[-1][0]:
        return pts[-1][1] + (para - pts[-1][0])
    for (p0, v0), (p1, v1) in zip(pts, pts[1:], strict=False):
        if p0 <= para <= p1:
            return v0 if p1 == p0 else v0 + (v1 - v0) * (para - p0) / (p1 - p0)
    return float(para)


def suggest(para_text: str, table: dict[str, Counter[int]], para_no: int, anchors: list[tuple[int, int]],
            window: int = 6, k: int = 3) -> list[tuple[str, float]]:
    """Verses near the interpolated position, ranked by number overlap, then nearness."""
    nums = english_numbers(para_text)
    centre = expected_verse(para_no, anchors)
    ranked = []
    for vid, vn in table.items():
        d = abs(verse_no(vid) - centre)
        if d <= window:
            ranked.append((vid, score(vn, nums) - d * 0.02))
    ranked.sort(key=lambda t: -t[1])
    return [(v, round(s, 3)) for v, s in ranked[:k]]


def known_pairs() -> list[tuple[str, int]]:
    """(verse id, Colebrooke paragraph number) for segments a person has already aligned."""
    pairs = []
    path = ROOT / "content" / "translations" / "colebrooke-1817" / "lilavati.yaml"
    for s in yaml.safe_load(path.read_text(encoding="utf-8"))["segments"]:
        m = re.search(r"\d+", s.get("label", ""))
        if m:
            pairs += [(v, int(m.group())) for v in s["verses"]]
    return pairs


def evaluate() -> None:
    """Leave-one-out: each confirmed pair is predicted from the other pairs."""
    paras = dict(colebrooke_paragraphs())
    table = verse_table()
    pairs = [(v, n) for v, n in known_pairs() if n in paras]
    hit1 = hit3 = within = 0
    for verse, n in pairs:
        anchors = [(m, verse_no(v)) for v, m in pairs if (v, m) != (verse, n)]
        sug = [v for v, _ in suggest(paras[n], table, n, anchors, k=5)]
        within += abs(expected_verse(n, anchors) - verse_no(verse)) <= 6
        hit1 += bool(sug) and sug[0] == verse
        hit3 += verse in sug[:3]
        print(f"para {n:>3} -> {verse:24} expected near {expected_verse(n, anchors):6.1f}, suggested {sug[:3]}")
    print(f"in window {within}/{len(pairs)}, top-1 {hit1}/{len(pairs)}, top-3 {hit3}/{len(pairs)}")


def main(argv: list[str]) -> int:
    if argv and argv[0] == "evaluate":
        evaluate()
        return 0
    paras = colebrooke_paragraphs()
    table = verse_table()
    present = {n for n, _ in paras}
    anchors = [(m, verse_no(v)) for v, m in known_pairs() if m in present]
    w = csv.writer(sys.stdout)
    w.writerow(["paragraph", "suggestion1", "score1", "suggestion2", "score2", "suggestion3", "score3", "text"])
    for n, text in paras:
        sug = suggest(text, table, n, anchors)
        row: list[object] = [n]
        for i in range(3):
            row += list(sug[i]) if i < len(sug) else ["", ""]
        w.writerow(row + [text[:200]])
    print(f"{len(paras)} paragraphs", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
