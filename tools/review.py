"""Reviewer hand-off (plan §5.8): export what each reviewer must check, import their decisions.

  python -m tools.review export sanskrit|kannada|maths [--out build/review]
  python -m tools.review import FILE.csv --role sanskrit|kannada|maths --reviewer "Name" [--date 2026-12-01]
  python -m tools.review status

Exports are plain CSV so reviewers can use any spreadsheet. A reviewer fills the `decision`
column with `approve`, `change` or leave it empty, and writes comments. Import never edits
the text: it only records who approved what and when (so a changed text needs a person to
edit the content and export again). `build --release` requires every lesson to be approved
by all three roles.

Rules (plan §5.8): the Sanskrit reviewer checks every lesson verse and a 10% sample of the
rest, plus 20 verses in Kannada script; the Kannada reviewer checks every Kannada string
of a lesson; the maths teacher checks explanations, numbers and class mapping.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from datetime import date
from pathlib import Path

import yaml

from tools.pack.load import CONTENT, ROOT, Content, load
from tools.pack.text import deva_to
from tools.pack.validate import iter_ltexts

ROLES = ("sanskrit", "kannada", "maths", "kannada-other")
OUT = ROOT / "build" / "review"
SAMPLE_PERCENT = 10
KANNADA_SCRIPT_CHECKS = 20


def _stable_sample(ids: list[str], percent: int) -> list[str]:
    """Deterministic: the same verses every export, spread across the text."""
    if not ids:
        return []
    step = max(1, round(100 / percent))
    return ids[::step]


def lesson_verse_ids(c: Content) -> list[str]:
    seen: dict[str, None] = {}
    for lesson in c.lessons.values():
        for card in lesson["cards"]:
            if card["type"] == "verse":
                seen[card["verse"]] = None
    return list(seen)


def export_sanskrit(c: Content) -> list[dict]:
    lesson_ids = lesson_verse_ids(c)
    lesson_set = set(lesson_ids)
    rest = [v for v in sorted(c.verses) if v not in lesson_set]
    sample = _stable_sample(rest, SAMPLE_PERCENT)
    kannada_checks = _stable_sample(lesson_ids + rest, max(1, round(100 * KANNADA_SCRIPT_CHECKS / len(c.verses))))[:KANNADA_SCRIPT_CHECKS]
    rows = []
    for why, ids in (("lesson verse", lesson_ids), ("10% sample", sample)):
        for vid in ids:
            v = c.verses[vid]
            rows.append({
                "id": vid, "why": why + (" + Kannada script check" if vid in kannada_checks else ""),
                "reference": f"{c.works[v['work']]['title_iast']} {v['ref_label']}",
                "devanagari": v["devanagari"], "iast": deva_to("iast", v["devanagari"]),
                "kannada_script": deva_to("kannada", v["devanagari"]), "source_text": v.get("source_text", ""),
                "notes": "; ".join(v.get("notes", [])), "current_status": v["review"],
                "decision": "", "comment": "",
            })
    # Kannada-script checks outside the two groups above still need to be listed.
    listed = {r["id"] for r in rows}
    for vid in kannada_checks:
        if vid not in listed:
            v = c.verses[vid]
            rows.append({
                "id": vid, "why": "Kannada script check",
                "reference": f"{c.works[v['work']]['title_iast']} {v['ref_label']}",
                "devanagari": v["devanagari"], "iast": deva_to("iast", v["devanagari"]),
                "kannada_script": deva_to("kannada", v["devanagari"]), "source_text": v.get("source_text", ""),
                "notes": "; ".join(v.get("notes", [])), "current_status": v["review"], "decision": "", "comment": "",
            })
    return rows


def export_kannada(c: Content) -> list[dict]:
    rows = []
    for lid, lesson in sorted(c.lessons.items()):
        doc = next(d for d in c.docs if d.schema == "lesson" and d.data["id"] == lid)
        for path, lt in iter_ltexts(doc.data):
            rows.append({"lesson": lid, "field": path, "english": lt["en"], "kannada": lt.get("kn", ""),
                         "current_status": lesson["review"]["kannada"], "decision": "", "comment": ""})
    return rows


def export_kannada_other(c: Content) -> list[dict]:
    """Kannada outside the lessons: interface strings and the concept, people, timeline and glossary text.
    Changes are reported by `import`; these items have no per-item status in the content files."""
    import json

    rows = []
    en = json.loads((ROOT / "apps/mobile/lib/l10n/app_en.arb").read_text(encoding="utf-8"))
    kn = json.loads((ROOT / "apps/mobile/lib/l10n/app_kn.arb").read_text(encoding="utf-8"))
    for key, text in en.items():
        if not key.startswith("@"):
            rows.append({"lesson": "app", "field": key, "english": text, "kannada": kn.get(key, ""),
                         "current_status": "draft", "decision": "", "comment": ""})
    for d in c.docs:
        if d.schema in {"concept", "people", "timeline", "terms", "work"}:
            for path, lt in iter_ltexts(d.data):
                rows.append({"lesson": d.path.name, "field": path, "english": lt["en"], "kannada": lt.get("kn", ""),
                             "current_status": "draft", "decision": "", "comment": ""})
    return rows


def export_maths(c: Content) -> list[dict]:
    rows = []
    for lid, lesson in sorted(c.lessons.items()):
        chapters = "; ".join(f"Class {c.nodes[n]['cls']} {c.nodes[n]['title']['en']} (chapter number {c.nodes[n]['number'] or 'TO CONFIRM'})"
                             for n in lesson.get("curriculum", []))
        for card in lesson["cards"]:
            if card["type"] in {"scene", "explore", "method", "practice", "quiz", "summary"}:
                text = ""
                for key in ("text", "prompt", "intro", "modern", "key_idea"):
                    if key in card:
                        text += f"{key}: {card[key]['en']}\n"
                detail = {k: card[k] for k in ("widget", "params", "algorithm", "inputs", "generator", "count", "difficulty") if k in card}
                rows.append({"lesson": lid, "card": f"{card['id']} ({card['type']})", "content": text.strip(),
                             "numbers_and_parameters": str(detail) if detail else "", "class_mapping": chapters,
                             "current_status": lesson["review"]["maths"], "decision": "", "comment": ""})
    return rows


EXPORTS = {"sanskrit": export_sanskrit, "kannada": export_kannada, "maths": export_maths,
           "kannada-other": export_kannada_other}


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as f:  # BOM so Excel reads Devanagari/Kannada
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def _set_line(text: str, pattern: str, replacement: str) -> str:
    new, n = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if n != 1:
        raise SystemExit(f"could not find {pattern!r} to update")
    return new


def _set_signoff(text: str, role: str, reviewer: str, on: str) -> str:
    """Records `signoff.<role>: {by, date}` after (not `on`: YAML 1.1 reads that key as true) the lesson's `review:` line, keeping the file's comments."""
    entry = f'  {role}: {{by: "{reviewer}", date: "{on}"}}'
    if re.search(r"^signoff:", text, re.M):
        if re.search(rf"^  {role}:", text, re.M):
            return re.sub(rf"^  {role}:.*$", entry, text, count=1, flags=re.M)
        return re.sub(r"^signoff:\n", f"signoff:\n{entry}\n", text, count=1, flags=re.M)
    return _set_line(text, r"^(review:.*)$", rf"\1\nsignoff:\n{entry}")


def _set_review(text: str, role: str, status: str) -> str:
    return _set_line(text, rf"({role}: )(?:unreviewed|draft|approved)", rf"\g<1>{status}")


def import_decisions(c: Content, role: str, rows: list[dict], reviewer: str, on: str, content_dir: Path = CONTENT) -> dict:
    report = {"approved": 0, "changes": [], "ignored": 0}
    approved_by_lesson: dict[str, list[bool]] = {}
    if role == "sanskrit":
        by_file: dict[Path, dict[str, str]] = {}
        for row in rows:
            decision = row.get("decision", "").strip().lower()
            vid = row["id"]
            if vid not in c.verses or decision not in {"approve", "change"}:
                report["ignored"] += 1
                continue
            if decision == "change":
                report["changes"].append(f"{vid}: {row.get('comment', '')}")
                continue
            by_file.setdefault(c.origin[vid], {})[vid] = decision
            report["approved"] += 1
        for path, ids in by_file.items():
            data = yaml.safe_load(path.read_text(encoding="utf-8"))
            for v in data:
                if v["id"] in ids:
                    v["review"] = "approved"
                    v["reviewed_by"], v["reviewed_on"] = reviewer, on
            path.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False, width=1000), encoding="utf-8")
        # A lesson is Sanskrit-approved when every verse on its verse cards is approved.
        c2, _ = load(content_dir)
        for lid, lesson in c2.lessons.items():
            verses = [card["verse"] for card in lesson["cards"] if card["type"] == "verse"]
            if not verses:
                # No verse card (the Mādhava lesson): nothing for the Sanskrit reviewer to approve.
                _update_lesson(c2, lid, "sanskrit", "n/a (no verse card)", on)
            elif all(c2.verses[v]["review"] == "approved" for v in verses):
                _update_lesson(c2, lid, "sanskrit", reviewer, on)
        return report

    if role == "kannada-other":
        for row in rows:
            decision = row.get("decision", "").strip().lower()
            if decision == "approve":
                report["approved"] += 1
            elif decision == "change":
                report["changes"].append(f"{row.get('lesson')} {row.get('field')}: {row.get('comment', '')}")
            else:
                report["ignored"] += 1
        return report

    key = "lesson"
    for row in rows:
        decision = row.get("decision", "").strip().lower()
        lid = row.get(key, "")
        if lid not in c.lessons or decision not in {"approve", "change"}:
            report["ignored"] += 1
            continue
        approved_by_lesson.setdefault(lid, []).append(decision == "approve")
        if decision == "change":
            report["changes"].append(f"{lid} {row.get('field') or row.get('card')}: {row.get('comment', '')}")
        else:
            report["approved"] += 1
    expected = {r[key]: 0 for r in EXPORTS[role](c)}
    for r in EXPORTS[role](c):
        expected[r[key]] += 1
    for lid, flags in approved_by_lesson.items():
        # Approved only if every exported row of the lesson was reviewed and approved.
        if all(flags) and len(flags) == expected[lid]:
            _update_lesson(c, lid, role, reviewer, on)
    return report


def _update_lesson(c: Content, lid: str, role: str, reviewer: str, on: str) -> None:
    path = c.origin[lid]
    text = path.read_text(encoding="utf-8")
    text = _set_review(text, role, "approved")
    text = _set_signoff(text, role, reviewer, on)
    path.write_text(text, encoding="utf-8")


def status(c: Content) -> str:
    lines = [f"{'lesson':34} {'maths':11} {'sanskrit':11} {'kannada':11}"]
    for lid, lesson in sorted(c.lessons.items()):
        r = lesson["review"]
        lines.append(f"{lid:34} {r['maths']:11} {r['sanskrit']:11} {r['kannada']:11}")
    unreviewed = sum(1 for v in c.verses.values() if v["review"] != "approved")
    lines.append(f"\nverses approved: {len(c.verses) - unreviewed}/{len(c.verses)}")
    ready = all(all(v == "approved" for v in l["review"].values()) for l in c.lessons.values())
    lines.append("release gate: " + ("OPEN, every lesson fully approved" if ready else "CLOSED, reviews outstanding"))
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="python -m tools.review", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    ex = sub.add_parser("export")
    ex.add_argument("role", choices=ROLES)
    ex.add_argument("--out", default=str(OUT))
    im = sub.add_parser("import")
    im.add_argument("file")
    im.add_argument("--role", choices=ROLES, required=True)
    im.add_argument("--reviewer", required=True)
    im.add_argument("--date", default=date.today().isoformat())
    sub.add_parser("status")
    args = ap.parse_args(argv)
    c, _ = load()
    if args.cmd == "export":
        rows = EXPORTS[args.role](c)
        path = Path(args.out) / f"review-{args.role}.csv"
        write_csv(path, rows)
        print(f"{len(rows)} rows written to {path}")
    elif args.cmd == "import":
        with open(args.file, encoding="utf-8-sig", newline="") as f:
            rows = list(csv.DictReader(f))
        rep = import_decisions(c, args.role, rows, args.reviewer, args.date)
        print(f"approved {rep['approved']}, changes requested {len(rep['changes'])}, ignored {rep['ignored']}")
        for ch in rep["changes"]:
            print("  change:", ch)
    else:
        print(status(c))
    return 0


if __name__ == "__main__":
    sys.exit(main())
