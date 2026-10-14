"""Compile validated content into content.db (plan §6.5 step 4)."""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from .load import Content
from .text import any_script_key, ascii_key, deva_to, iast_to_deva
from .validate import iter_ltexts

SCHEMA_VERSION = 1
DDL = Path(__file__).with_name("content_schema.sql")
LOCALES = ("en", "kn")


def _lt(db: sqlite3.Connection, entity: str, field: str, lt: dict | None) -> None:
    if not lt:
        return
    for loc in LOCALES:
        if lt.get(loc):
            db.execute("INSERT INTO localized_text VALUES (?,?,?,?)", (entity, field, loc, lt[loc]))


def _claims(db: sqlite3.Connection, entity: str, claims: dict | None) -> None:
    for field, cites in (claims or {}).items():
        for cite in cites:
            db.execute("INSERT OR IGNORE INTO claim_source VALUES (?,?,?,?)",
                       (entity, field, cite["source"], cite.get("note")))


def _search(db, etype: str, eid: str, title: dict, body: dict | None, keys: list[str]) -> None:
    key_text = " ".join(dict.fromkeys(k for k in (any_script_key(x) for x in keys) if k))
    for loc in LOCALES:
        t = title.get(loc) or title.get("en")
        b = (body or {}).get(loc) or (body or {}).get("en") or ""
        db.execute("INSERT INTO search_index (entity_type, entity_id, locale, title, text, keys) "
                   "VALUES (?,?,?,?,?,?)", (etype, eid, loc, t, f"{t} {b}".strip(), key_text))


def compile_lesson(lesson: dict, c: Content) -> dict:
    """The JSON document the app's lesson engine reads (plan §6.6)."""
    cards = []
    for card in lesson["cards"]:
        card = dict(card)
        card.setdefault("min_engine", c.registry["card_types"].get(card["type"], {}).get("min_engine", 1))
        if card["type"] == "practice":
            card["template"] = f"{lesson['id']}.{card['id']}"
        cards.append(card)
    return {
        "id": lesson["id"], "version": lesson["version"], "title": lesson["title"],
        "subtitle": lesson.get("subtitle"), "minutes": lesson["minutes"], "area": lesson["area"],
        "concepts": lesson["concepts"], "curriculum": lesson.get("curriculum", []), "cards": cards,
    }


def build(c: Content, out: Path, content_version: str) -> dict:
    if out.exists():
        out.unlink()
    db = sqlite3.connect(out)
    db.executescript(DDL.read_text(encoding="utf-8"))
    stats: dict[str, int] = {}

    meta = {"schema_version": str(SCHEMA_VERSION), "content_version": content_version,
            "engine_version": str(c.registry["engine_version"]),
            "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
    db.executemany("INSERT INTO meta VALUES (?,?)", meta.items())

    for l in c.licences.values():
        db.execute("INSERT INTO licence VALUES (?,?,?,?,?)",
                   (l["id"], l["name"], l["url"], int(l["commercial_use"]), int(l["share_alike"])))
    for s in c.sources.values():
        db.execute("INSERT INTO source VALUES (?,?,?,?,?,?)",
                   (s["id"], s["citation"], s.get("url"), s["licence"], s.get("attribution"), s["kind"]))

    # Texts and verses in every script
    for w in c.works.values():
        db.execute("INSERT INTO work VALUES (?,?,?,?,?,?,?,?)",
                   (w["id"], w["title_iast"], w["author"], w["year_from"], w["year_to"],
                    w["source"], w["licence"], w.get("text_form")))
        _lt(db, w["id"], "title", w["title"])
        _lt(db, w["id"], "about", w.get("about"))
        _claims(db, w["id"], w["claims"])
        _search(db, "work", w["id"], w["title"], w.get("about"), [w["title_iast"]])
    for s in c.sections.values():
        db.execute("INSERT INTO section VALUES (?,?,?,?)", (s["id"], s["work"], None, s["ordinal"]))
        _lt(db, s["id"], "label", s["label"])
    for v in c.verses.values():
        db.execute("INSERT INTO verse (id, work_id, section_id, ordinal, ref_label, review) VALUES (?,?,?,?,?,?)",
                   (v["id"], v["work"], v["section"], v["ordinal"], v["ref_label"], v["review"]))
        texts = {s: deva_to(s, v["devanagari"]) for s in ("devanagari", "kannada", "iast")}
        for script, text in texts.items():
            db.execute("INSERT INTO verse_text VALUES (?,?,?)", (v["id"], script, text))
        for t in v.get("terms", []):
            db.execute("INSERT INTO verse_term VALUES (?,?)", (v["id"], t))
        work_title = c.works[v["work"]]["title"]
        label = {loc: f"{work_title.get(loc) or work_title['en']} {v['ref_label']}" for loc in LOCALES}
        _search(db, "verse", v["id"], label, None, [texts["iast"]])
    stats["verses"] = len(c.verses)

    # Translations, with coverage per work (shown in the picker, plan §4.7)
    for t in c.translations.values():
        db.execute("INSERT INTO translation VALUES (?,?,?,?,?,?,?)",
                   (t["id"], t["translator"], t["year"], t["language"], t["kind"], t["licence"], t["source"]))
        _lt(db, t["id"], "about", t["about"])
        _lt(db, t["id"], "style_note", t.get("style_note"))
        for w in t["works"]:
            covered = {v for s in c.segments.values() if s["translation"] == t["id"] and s["work"] == w
                       for v in s["verses"]}
            total = sum(1 for v in c.verses.values() if v["work"] == w)
            db.execute("INSERT INTO translation_work VALUES (?,?,?,?)", (t["id"], w, len(covered), total))
    for s in c.segments.values():
        db.execute("INSERT INTO translation_segment VALUES (?,?,?,?,?,?,?)",
                   (s["id"], s["translation"], s["ordinal"], s.get("label"), s["text"], str(s["page"]), s["status"]))
        for v in s["verses"]:
            db.execute("INSERT INTO segment_verse VALUES (?,?)", (s["id"], v))
        for g in s.get("glossary", []):
            db.execute("INSERT INTO segment_glossary VALUES (?,?)", (s["id"], g))
        tr = c.translations[s["translation"]]
        title = {loc: f"{tr['translator']} ({tr['year']})" for loc in LOCALES}
        db.execute("INSERT INTO search_index (entity_type, entity_id, locale, title, text, keys) VALUES (?,?,?,?,?,?)",
                   ("segment", s["id"], "en", title["en"], s["text"], ""))

    # Terms and glossary
    for t in c.terms.values():
        deva = iast_to_deva(t["iast"])
        db.execute("INSERT INTO term VALUES (?,?,?,?,?,?)",
                   (t["id"], deva, deva_to("kannada", deva), t["iast"], ascii_key(t["iast"]), t.get("concept")))
        _lt(db, t["id"], "gloss", t["gloss"])
        _search(db, "term", t["id"], {"en": t["iast"], "kn": deva_to("kannada", deva)}, t["gloss"],
                [t["iast"], *t.get("aliases", [])])
    for g in c.glossary.values():
        db.execute("INSERT INTO glossary VALUES (?,?)", (g["id"], g["headword"]))
        _lt(db, g["id"], "note", g["note"])
        _search(db, "glossary", g["id"], {"en": g["headword"]}, g["note"], [g["headword"]])

    # Areas and concepts
    for a in c.areas.values():
        db.execute("INSERT INTO area VALUES (?,?,?)", (a["id"], a["ordinal"], a["sanskrit_iast"]))
        _lt(db, a["id"], "name", a["name"])
        _lt(db, a["id"], "blurb", a["blurb"])
    for k in c.concepts.values():
        db.execute("INSERT INTO concept VALUES (?,?,?)", (k["id"], k["area"], k["classical_iast"]))
        for f in ("name", "modern_name", "summary", "body"):
            _lt(db, k["id"], f, k.get(f))
        for v in k["verses"]:
            db.execute("INSERT INTO concept_verse VALUES (?,?,?)", (k["id"], v["verse"], v["role"]))
        for rel in k.get("related", []):
            db.execute("INSERT INTO concept_relation VALUES (?,?,?)", (k["id"], rel["to"], rel["type"]))
        for p in k.get("people", []):
            db.execute("INSERT INTO concept_person VALUES (?,?)", (k["id"], p))
        _claims(db, k["id"], k["claims"])
        _search(db, "concept", k["id"], k["name"], k["summary"],
                [k["classical_iast"], *k.get("aliases", []), k["modern_name"]["en"]])

    # People
    for p in c.places.values():
        db.execute("INSERT INTO place VALUES (?,?,?)", (p["id"], p["lat"], p["lon"]))
        _lt(db, p["id"], "name", p["name"])
    for p in c.people.values():
        sort_year = p.get("born_from") or p.get("died_from") or 0
        db.execute("INSERT INTO mathematician VALUES (?,?,?,?,?,?,?,?)",
                   (p["id"], p["name_iast"], p.get("born_from"), p.get("born_to"), p.get("died_from"),
                    p.get("died_to"), p.get("place"), sort_year))
        for f in ("name", "dates_label", "summary"):
            _lt(db, p["id"], f, p.get(f))
        for w in p.get("works", []):
            db.execute("INSERT INTO authored VALUES (?,?)", (p["id"], w))
        for t in p.get("teachers", []):
            db.execute("INSERT INTO teacher_of VALUES (?,?,?,?)", (t["id"], p["id"], t["source"], t.get("note")))
        _claims(db, p["id"], p["claims"])
        _search(db, "person", p["id"], p["name"], p["summary"], [p["name_iast"]])

    for e in c.events.values():
        db.execute("INSERT INTO timeline_event VALUES (?,?,?,?,?,?)",
                   (e["id"], e["year_from"], e["year_to"], e["region"], e["source"], e.get("source_note")))
        _lt(db, e["id"], "label", e["label"])
        _lt(db, e["id"], "detail", e.get("detail"))
        for l in e.get("links", []):
            db.execute("INSERT INTO timeline_link VALUES (?,?)", (e["id"], l))

    # Curriculum
    for cur in c.curricula:
        _lt(db, cur["board"], "name", cur["name"])
        for cl in cur["classes"]:
            for book in cl["books"]:
                _lt(db, book["id"], "title", book["title"])
    for n in c.nodes.values():
        db.execute("INSERT INTO curriculum_node VALUES (?,?,?,?,?,?)",
                   (n["id"], n["board"], n["cls"], n["book"], n["number"], None))
        _lt(db, n["id"], "title", n["title"])
        for i, l in enumerate(n.get("links", [])):
            if l["to"] in c.media_segments and c.media[c.media_segments[l["to"]]["media"]]["status"] != "checked":
                continue
            db.execute("INSERT INTO curriculum_link VALUES (?,?,?,?)", (n["id"], l["to"], l["relevance"], i))

    # Media: only checked uploads ship (plan §5.6)
    shipped_segments = set()
    for m in c.media.values():
        if m["status"] != "checked":
            continue
        db.execute("INSERT INTO media VALUES (?,?,?,?,?,?,?,?)",
                   (m["id"], m["provider"], m["external_id"], m["speaker"], m["organisation"],
                    m["licence"], m["duration_s"], m["level"]))
        _lt(db, m["id"], "title", m["title"])
        for s in m["segments"]:
            db.execute("INSERT INTO media_segment VALUES (?,?,?,?,?,?)",
                       (s["id"], m["id"], s["start_s"], s["end_s"], s.get("checked_by"), s.get("checked_on")))
            _lt(db, s["id"], "title", s["title"])
            shipped_segments.add(s["id"])
            _search(db, "media", s["id"], s["title"], None, [m["speaker"]])
    stats["media_segments"] = len(shipped_segments)

    # Lessons
    for lesson in c.lessons.values():
        doc = compile_lesson(lesson, c)
        doc["cards"] = [card for card in doc["cards"]
                        if card["type"] != "watch" or card["segment"] in shipped_segments]
        db.execute("INSERT INTO lesson VALUES (?,?,?,?,?)",
                   (lesson["id"], lesson["version"], lesson["minutes"], lesson["area"],
                    json.dumps(doc, ensure_ascii=False, sort_keys=True)))
        _lt(db, lesson["id"], "title", lesson["title"])
        _lt(db, lesson["id"], "subtitle", lesson.get("subtitle"))
        _claims(db, lesson["id"], lesson.get("claims"))
        for k in lesson["concepts"]:
            db.execute("INSERT INTO lesson_concept VALUES (?,?)", (lesson["id"], k))
        for card in doc["cards"]:
            if card["type"] == "practice":
                params = {"count": card["count"], "difficulty": card.get("difficulty")}
                db.execute("INSERT INTO problem_template VALUES (?,?,?,?)",
                           (card["template"], lesson["id"], card["generator"], json.dumps(params)))
        keys = [c.concepts[k]["classical_iast"] for k in lesson["concepts"]]
        keys += [a for k in lesson["concepts"] for a in c.concepts[k].get("aliases", [])]
        _search(db, "lesson", lesson["id"], lesson["title"], lesson.get("subtitle"), keys)
    stats["lessons"] = len(c.lessons)

    for old, new in c.redirects.items():
        db.execute("INSERT INTO redirect VALUES (?,?)", (old, new))

    db.execute("INSERT INTO search_index(search_index) VALUES ('optimize')")
    db.commit()
    db.execute("VACUUM")
    ok = db.execute("PRAGMA integrity_check").fetchone()[0]
    db.close()
    if ok != "ok":
        raise RuntimeError(f"integrity_check failed: {ok}")
    stats["bytes"] = out.stat().st_size
    return stats


def coverage_report(c: Content) -> list[dict]:
    """Share of each work's verses each translation covers (plan §5.2 step 6)."""
    rows = []
    for t in c.translations.values():
        for w in t["works"]:
            covered = {v for s in c.segments.values() if s["translation"] == t["id"] and s["work"] == w
                       for v in s["verses"]}
            total = sum(1 for v in c.verses.values() if v["work"] == w)
            lesson_verses = {card["verse"] for l in c.lessons.values() for card in l["cards"]
                             if card["type"] == "verse" and c.verses.get(card["verse"], {}).get("work") == w}
            rows.append({"translation": t["id"], "work": w, "covered": len(covered), "total": total,
                         "lesson_verses": len(lesson_verses),
                         "lesson_verses_covered": len(lesson_verses & covered)})
    return rows


def strings_for_kn_review(c: Content) -> list[tuple[str, str]]:
    return [(f"{d.path.name}:{p}", lt["en"]) for d in c.docs for p, lt in iter_ltexts(d.data) if not lt.get("kn")]
