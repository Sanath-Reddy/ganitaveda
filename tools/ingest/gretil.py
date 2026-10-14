"""Ingest GRETIL e-texts into content/works/*/verses/*.yaml.

The GRETIL files are IAST. We keep the source line verbatim (`source_text`),
derive a cleaned IAST reading text, and generate the canonical Devanagari from
it. Every verse lands with `review: unreviewed`; the Sanskrit reviewer flips it.

Run from the repo root:  python -m tools.ingest.gretil
"""

from __future__ import annotations

import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

import yaml
from indic_transliteration import sanscript

ROOT = Path(__file__).resolve().parents[2]
RAW = Path(__file__).resolve().parent / "raw"
WORKS = ROOT / "content" / "works"


@dataclass
class Verse:
    id: str
    section: str
    ordinal: int
    ref_label: str
    source_text: str
    iast: str = ""
    devanagari: str = ""
    notes: list[str] = field(default_factory=list)


def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


# ---------------------------------------------------------------- cleaning

_BRACKET = re.compile(r"\[([^\]]*)\]")


def clean_iast(raw: str) -> tuple[str, list[str]]:
    """Strip Hayashi's editorial markup; return (reading text, notes)."""
    notes: list[str] = []
    text = raw

    def keep_note(m: re.Match) -> str:
        inner = m.group(1).strip()
        # Metre labels and editorial notes become notes, not text.
        if inner:
            notes.append(inner)
        return ""

    text = re.sub(r"\(?(Lil|BSS)_[0-9.]+p?\)?", "", text)
    # A whole verse in square brackets is one the edition marks as doubtful;
    # keep the text and record the bracket (and any Colebrooke number) as a note.
    whole = re.fullmatch(r"\s*\[(.*?)(?:\s*cb\.(\d+))?\]\s*", text, re.S)
    if whole and "//" in whole.group(1):
        notes.append("bracketed in the edition")
        if whole.group(2):
            notes.append(f"Colebrooke numbers this {whole.group(2)}")
        text = whole.group(1)
    text = _BRACKET.sub(keep_note, text)
    text = re.sub(r"\{btabular\}.*?\{etabular\}", "", text)
    text = text.replace("%", "").replace("@", "").replace("#", "")
    # Editor's numeric glosses: "-14-" inside compounds, bare numbers, "5dvi".
    text = re.sub(r"-\d+(_\d+)*-", "-", text)
    text = re.sub(r"(?<![\w])\d+(_\d+)*(?![\w])", "", text)
    text = re.sub(r"(?<![\w])\d+(?=[a-zāīūṛṝḷēōṃḥñṅṇṭḍśṣ])", "", text)
    text = text.replace("--", "-")
    # Danda: GRETIL uses / and //.
    text = text.replace("//", " ||").replace("/", " |")
    text = re.sub(r"[ \t]+", " ", text)
    lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
    return nfc("\n".join(lines)), notes


def to_devanagari(iast: str) -> str:
    return nfc(sanscript.transliterate(iast, sanscript.IAST, sanscript.DEVANAGARI))


def from_devanagari(deva: str, scheme: str) -> str:
    return nfc(sanscript.transliterate(deva, sanscript.DEVANAGARI, scheme))


# ---------------------------------------------------------------- parsers

def _text_body(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").split("\n")
    start = next(i for i, ln in enumerate(lines) if ln.strip() == "# Text")
    return lines[start + 1:]


def parse_numbered(path: Path, marker: str, work: str, id_for, section_for) -> list[Verse]:
    """Lines ending in ` <marker>_N` close verse N; the block runs back to a blank
    line, a heading, or a prose line ending in `(<marker>_Np)`."""
    body = _text_body(path)
    end_re = re.compile(rf"\s{marker}_([0-9.]+)\s*$")
    verses: list[Verse] = []
    heading = ""
    block: list[str] = []
    for ln in body:
        s = ln.rstrip()
        if not s.strip():
            block = []
            continue
        if re.fullmatch(r"\s*\[[^\]]+\]\s*", s):
            heading = s.strip()[1:-1]
            block = []
            continue
        if re.search(rf"\({marker}_[0-9.]+p\)\s*$", s):
            block = []
            continue
        block.append(s)
        m = end_re.search(s)
        if m:
            ref = m.group(1)
            # Drop leading prose: keep from the first line that carries a half-verse mark.
            lines = list(block)
            while len(lines) > 1 and (
                    not re.search(r"/\s*(\[[^\]]*\])?\s*$", lines[0])
                    or re.match(r"(atha|iti|atra|udāharaṇam)\b", lines[0])
                    or "karaṇa-sūtram" in lines[0]):
                lines.pop(0)
            src = "\n".join(lines)
            iast, notes = clean_iast(src)
            v = Verse(id=id_for(ref), section=section_for(ref, heading), ordinal=0,
                      ref_label=ref, source_text=nfc(src), iast=iast, notes=notes)
            verses.append(v)
            block = []
    for i, v in enumerate(verses, 1):
        v.ordinal = i
    return verses


def ascii_key(s: str) -> str:
    """'aṅka-pāśa' -> 'anka-pasa'. Shared with the search index (tools/pack/text.py)."""
    return "".join(c for c in unicodedata.normalize("NFD", s) if not unicodedata.combining(c))


def slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", ascii_key(s).lower()).strip("-") or "front"


def parse_lilavati() -> list[Verse]:
    return parse_numbered(
        RAW / "sa_bhAskara-lIlAvatI.txt", "Lil", "lilavati",
        id_for=lambda r: f"verse.lilavati.{r}",
        section_for=lambda r, h: f"section.lilavati.{slug(h)}",
    )


def parse_bss() -> list[Verse]:
    vs = parse_numbered(
        RAW / "sa_brahmagupta-brAhmasphuTasiddhAnta.txt", "BSS", "brahmasphutasiddhanta",
        id_for=lambda r: f"verse.bss.{r}",
        section_for=lambda r, h: f"section.bss.{r.split('.')[0]}",
    )
    # Version 1 ships chapters 12 and 18 only (plan §5.1).
    return [v for v in vs if v.ref_label.split(".")[0] in {"12", "18"}]


# Āryabhaṭīya root verses are interleaved with Bhāskara I's commentary and his
# own example verses, which reuse the same numbering. A person picks each root
# verse by the exact text of its closing line; the ingester only copies text.
ARYA_ANCHORS = RAW.parent / "aryabhatiya_ganitapada_anchors.yaml"


def parse_aryabhatiya() -> list[Verse]:
    xml = (RAW / "arya.xml").read_text(encoding="utf-8")
    elements = [re.sub(r"<[^>]+>", "", e).strip()
                for e in re.findall(r"<(?:l|p)>(.*?)</(?:l|p)>", xml, re.S)]
    anchors = yaml.safe_load(ARYA_ANCHORS.read_text(encoding="utf-8"))
    out: list[Verse] = []
    for n, a in sorted(anchors["ganitapada"].items()):
        for line in a["lines"]:
            count = elements.count(line)
            if count != 1:
                raise SystemExit(f"Āryabhaṭīya 2.{n}: line found {count} times: {line!r}")
        src = "\n".join(a["lines"])
        iast = re.sub(r"\s*\|\|\s*\d+\s*\|\|\s*$", " ||", src)
        v = Verse(id=f"verse.aryabhatiya.2.{n}", section="section.aryabhatiya.ganitapada",
                  ordinal=int(n), ref_label=f"2.{n}", source_text=nfc(src), iast=nfc(iast))
        if a.get("incomplete"):
            v.notes.append(a["incomplete"])
        out.append(v)
    return out


# ---------------------------------------------------------------- output

def finish(verses: list[Verse]) -> list[str]:
    """Generate Devanagari and run the round-trip check. Returns failures."""
    bad = []
    for v in verses:
        v.devanagari = to_devanagari(v.iast)
        back = to_devanagari(from_devanagari(v.devanagari, sanscript.IAST))
        if back != v.devanagari:
            bad.append(v.id)
    return bad


def write(work: str, source: str, verses: list[Verse]) -> None:
    by_section: dict[str, list[Verse]] = {}
    for v in verses:
        by_section.setdefault(v.section, []).append(v)
    d = WORKS / work / "verses"
    d.mkdir(parents=True, exist_ok=True)
    # Keep reviewers' work: review status, notes and term links survive a
    # re-run as long as the source text of the verse is unchanged.
    kept: dict[str, dict] = {}
    for old in d.glob("*.yaml"):
        for row in yaml.safe_load(old.read_text(encoding="utf-8")) or []:
            kept[row["id"]] = row
        old.unlink()
    for sec, vs in by_section.items():
        rows = []
        for v in vs:
            row = {
                "id": v.id, "section": v.section, "ordinal": v.ordinal, "ref_label": v.ref_label,
                "devanagari": v.devanagari, "source_text": v.source_text, "source": source,
                "review": "unreviewed",
            }
            if v.notes:
                row["notes"] = v.notes
            prev = kept.get(v.id)
            if prev and prev.get("source_text") == v.source_text:
                row["review"] = prev.get("review", "unreviewed")
                if prev.get("terms"):
                    row["terms"] = prev["terms"]
            rows.append(row)
        name = sec.split(".", 2)[-1]
        (d / f"{name}.yaml").write_text(
            yaml.safe_dump(rows, allow_unicode=True, sort_keys=False, width=1000), encoding="utf-8")


def main() -> int:
    jobs = [
        ("lilavati", "source.gretil-lilavati", parse_lilavati()),
        ("brahmasphutasiddhanta", "source.gretil-bss", parse_bss()),
        ("aryabhatiya", "source.gretil-aryabhatiya", parse_aryabhatiya()),
    ]
    failed = False
    for work, source, verses in jobs:
        bad = finish(verses)
        write(work, source, verses)
        print(f"{work}: {len(verses)} verses, {len(bad)} round-trip failures")
        if bad:
            failed = True
            print("  ", bad[:10])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
