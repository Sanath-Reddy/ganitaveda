"""Content checks run by CI (plan §5, §8.4): schemas, references, citations,
licences, transliteration round-trip, lesson structure and Kannada coverage."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterator

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

from .load import Content, schema_store
from .text import round_trips

NC_LICENCE_NOTE = "non-commercial licence: the app must stay free, with no ads or payments"


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    stats: dict[str, Any] = field(default_factory=dict)

    def err(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    @property
    def ok(self) -> bool:
        return not self.errors


def _validators() -> dict[str, Draft202012Validator]:
    store = schema_store()
    registry = Registry().with_resources(
        (name, Resource.from_contents(s)) for name, s in store.items())
    return {name.removesuffix(".schema.json"): Draft202012Validator(s, registry=registry)
            for name, s in store.items() if name != "common.schema.json"}


def iter_ltexts(node: Any, path: str = "") -> Iterator[tuple[str, dict]]:
    """Yield every localised-text object ({en, kn?}) anywhere in a document."""
    if isinstance(node, dict):
        if "en" in node and set(node) <= {"en", "kn"} and isinstance(node["en"], str):
            yield path, node
            return
        for k, v in node.items():
            yield from iter_ltexts(v, f"{path}.{k}" if path else str(k))
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from iter_ltexts(v, f"{path}[{i}]")


def validate(c: Content, dupes: list[str], release: bool = False) -> Report:
    r = Report()
    for d in dupes:
        r.err(d)

    # 1. Schemas
    vals = _validators()
    for d in c.docs:
        for e in sorted(vals[d.schema].iter_errors(d.data), key=lambda e: list(e.path)):
            loc = "/".join(str(p) for p in e.absolute_path)
            r.err(f"{d.path.relative_to(d.path.parents[2])}: {loc}: {e.message[:300]}")
    if r.errors:
        return r  # reference checks assume schema-valid data

    ids = c.all_ids()

    def ref(where: str, target: str | None, table: dict | None = None, what: str = "") -> None:
        if target is None:
            return
        pool = table if table is not None else ids
        if target not in pool:
            r.err(f"{where}: unknown {what or 'reference'} {target}")

    def claims(where: str, cl: dict | None) -> None:
        for fieldname, cites in (cl or {}).items():
            for cite in cites:
                ref(f"{where} claims.{fieldname}", cite["source"], c.sources, "source")

    # 2. Licences and sources
    for s in c.sources.values():
        ref(s["id"], s["licence"], c.licences, "licence")
    # Only material the app redistributes (texts, translations, fonts) binds the app's terms.
    nc = sorted({s["id"] for s in c.sources.values() if s["kind"] in ("text", "translation", "font")
                 and s["licence"] in c.licences and not c.licences[s["licence"]]["commercial_use"]})
    if nc:
        r.stats["non_commercial_sources"] = nc
        r.stats["licence_note"] = NC_LICENCE_NOTE

    # 3. Works, sections, verses
    for w in c.works.values():
        ref(w["id"], w["author"], c.people, "author")
        ref(w["id"], w["source"], c.sources, "source")
        ref(w["id"], w["licence"], c.licences, "licence")
        if w["source"] in c.sources and c.sources[w["source"]]["licence"] != w["licence"]:
            r.err(f"{w['id']}: licence {w['licence']} differs from its source's licence")
        if "dates" not in w["claims"]:
            r.err(f"{w['id']}: dates need a source (claims.dates)")
        claims(w["id"], w["claims"])
    bad_rt = []
    for v in c.verses.values():
        ref(v["id"], v["section"], c.sections, "section")
        if v["section"] in c.sections and c.sections[v["section"]]["work"] != v["work"]:
            r.err(f"{v['id']}: section belongs to another work")
        ref(v["id"], v["source"], c.sources, "source")
        for t in v.get("terms", []):
            ref(v["id"], t, c.terms, "term")
        if not round_trips(v["devanagari"]):
            bad_rt.append(v["id"])
    for b in bad_rt:
        r.err(f"{b}: Devanagari -> IAST -> Devanagari does not round-trip")

    # 4. Translations
    for t in c.translations.values():
        ref(t["id"], t["licence"], c.licences, "licence")
        ref(t["id"], t["source"], c.sources, "source")
        for w in t["works"]:
            ref(t["id"], w, c.works, "work")
    for s in c.segments.values():
        ref(s["id"], s["translation"], c.translations, "translation")
        ref(s["id"], s["work"], c.works, "work")
        for v in s["verses"]:
            ref(s["id"], v, c.verses, "verse")
            if v in c.verses and c.verses[v]["work"] != s["work"]:
                r.err(f"{s['id']}: verse {v} is not in {s['work']}")
        for gl in s.get("glossary", []):
            ref(s["id"], gl, c.glossary, "glossary entry")
        if s["status"] == "ocr-draft":
            r.warn(f"{s['id']}: OCR draft, not yet proofread against the page images")

    # 5. Terms, concepts, areas
    for t in c.terms.values():
        ref(t["id"], t.get("concept"), c.concepts, "concept")
    for k in c.concepts.values():
        ref(k["id"], k["area"], c.areas, "area")
        for v in k["verses"]:
            ref(k["id"], v["verse"], c.verses, "verse")
        for rel in k.get("related", []):
            ref(k["id"], rel["to"], c.concepts, "concept")
        for p in k.get("people", []):
            ref(k["id"], p, c.people, "mathematician")
        if (k.get("people") or k["verses"]) and not k["claims"]:
            r.err(f"{k['id']}: links people or verses but cites no source (claims)")
        claims(k["id"], k["claims"])

    # 6. People, places, timeline
    for p in c.people.values():
        ref(p["id"], p.get("place"), c.places, "place")
        for w in p.get("works", []):
            ref(p["id"], w, c.works, "work")
        for t in p.get("teachers", []):
            ref(p["id"], t["id"], c.people, "teacher")
            ref(p["id"], t["source"], c.sources, "source")
        if "dates" not in p["claims"]:
            r.err(f"{p['id']}: dates need a source (claims.dates)")
        claims(p["id"], p["claims"])
    for e in c.events.values():
        ref(e["id"], e["source"], c.sources, "source")
        for l in e.get("links", []):
            ref(e["id"], l)
        if e["year_to"] < e["year_from"]:
            r.err(f"{e['id']}: year_to is before year_from")

    # 7. Media
    for m in c.media.values():
        ref(m["id"], m["licence"], c.licences, "licence")
        if m["status"] == "checked" and not (m.get("external_id") and m.get("duration_s")):
            r.err(f"{m['id']}: checked media needs an external_id and duration_s")
        for s in m["segments"]:
            if s["end_s"] <= s["start_s"] or s["end_s"] > m.get("duration_s", 0):
                r.err(f"{s['id']}: segment times out of range")
            if m["status"] == "checked" and not (s.get("checked_by") and s.get("checked_on")):
                r.err(f"{s['id']}: a checked segment records who checked it and when")
        if m["status"] == "pending":
            r.warn(f"{m['id']}: pending, left out of packs until its minutes are pinned")

    # 8. Curriculum
    for n in c.nodes.values():
        for l in n.get("links", []):
            ref(n["id"], l["to"])

    # 9. Lessons
    reg = c.registry
    for lesson in c.lessons.values():
        lid = lesson["id"]
        ref(lid, lesson["area"], c.areas, "area")
        for k in lesson["concepts"]:
            ref(lid, k, c.concepts, "concept")
        for n in lesson.get("curriculum", []):
            ref(lid, n, c.nodes, "curriculum node")
        claims(lid, lesson.get("claims"))
        seen = set()
        for card in lesson["cards"]:
            where = f"{lid}#{card['id']}"
            if card["id"] in seen:
                r.err(f"{where}: duplicate card id")
            seen.add(card["id"])
            ctype = card["type"]
            if ctype not in reg["card_types"]:
                r.err(f"{where}: unknown card type {ctype}")
                continue
            if card.get("min_engine", 1) > reg["engine_version"]:
                r.warn(f"{where}: needs engine {card['min_engine']}; current apps will skip it")
            if ctype == "explore":
                w = card["widget"]
                if w not in reg["widgets"]:
                    r.err(f"{where}: unknown widget {w}")
                else:
                    extra = set(card["params"]) - set(reg["widgets"][w])
                    if extra:
                        r.err(f"{where}: widget {w} does not take {sorted(extra)}")
            elif ctype == "verse":
                ref(where, card["verse"], c.verses, "verse")
                for t in card.get("highlight", []):
                    ref(where, t, c.terms, "term")
            elif ctype == "method":
                if card["algorithm"] not in reg["algorithms"]:
                    r.err(f"{where}: unknown algorithm {card['algorithm']}")
            elif ctype == "watch":
                ref(where, card["segment"], c.media_segments, "media segment")
                seg = c.media_segments.get(card["segment"])
                if seg and c.media[seg["media"]]["status"] == "pending" and not card.get("optional"):
                    r.err(f"{where}: a required watch card points at pending media")
            elif ctype == "practice":
                if card["generator"] not in reg["generators"]:
                    r.err(f"{where}: unknown generator {card['generator']}")
                d = card.get("difficulty")
                if d and len(d) != card["count"]:
                    r.err(f"{where}: difficulty list must have one entry per problem")
            elif ctype == "quiz":
                for q in card["questions"]:
                    if q["answer"] >= len(q["choices"]):
                        r.err(f"{where}: quiz answer index out of range")
            elif ctype == "summary" and card.get("next"):
                ref(where, card["next"], c.lessons, "lesson")
        if lesson["cards"][-1]["type"] != "summary":
            r.err(f"{lid}: the last card must be a summary (it schedules review)")
        if release and any(v != "approved" for v in lesson["review"].values()):
            r.err(f"{lid}: not approved by every reviewer {lesson['review']}")

    # 10. Kannada coverage
    total = with_kn = 0
    missing: list[str] = []
    for d in c.docs:
        for path, lt in iter_ltexts(d.data):
            total += 1
            if lt.get("kn"):
                with_kn += 1
            else:
                missing.append(f"{d.path.name}:{path}")
    r.stats["kannada_coverage"] = round(100.0 * with_kn / total, 1) if total else 100.0
    r.stats["kannada_missing"] = len(missing)
    if missing:
        msg = f"{len(missing)} strings have no Kannada, e.g. {missing[:3]}"
        (r.err if release else r.warn)(msg)

    # 11. Review status of verse text
    unreviewed = sum(1 for v in c.verses.values() if v["review"] != "approved")
    r.stats["verses"] = len(c.verses)
    r.stats["verses_unreviewed"] = unreviewed
    if release:
        for lesson in c.lessons.values():
            for card in lesson["cards"]:
                v = c.verses.get(card.get("verse", ""))
                if v and v["review"] != "approved":
                    r.err(f"{lesson['id']}: lesson verse {v['id']} is not approved by the Sanskrit reviewer")

    return r
