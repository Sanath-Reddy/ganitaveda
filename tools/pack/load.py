"""Load the content/ tree into one in-memory model, keeping file paths for errors."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "content"
SCHEMAS = ROOT / "tools" / "schemas"


def read_yaml(path: Path) -> Any:
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


@dataclass
class Doc:
    path: Path
    schema: str
    data: Any


@dataclass
class Content:
    docs: list[Doc] = field(default_factory=list)
    licences: dict[str, dict] = field(default_factory=dict)
    sources: dict[str, dict] = field(default_factory=dict)
    works: dict[str, dict] = field(default_factory=dict)
    sections: dict[str, dict] = field(default_factory=dict)
    verses: dict[str, dict] = field(default_factory=dict)
    translations: dict[str, dict] = field(default_factory=dict)
    segments: dict[str, dict] = field(default_factory=dict)
    terms: dict[str, dict] = field(default_factory=dict)
    glossary: dict[str, dict] = field(default_factory=dict)
    areas: dict[str, dict] = field(default_factory=dict)
    concepts: dict[str, dict] = field(default_factory=dict)
    places: dict[str, dict] = field(default_factory=dict)
    people: dict[str, dict] = field(default_factory=dict)
    events: dict[str, dict] = field(default_factory=dict)
    curricula: list[dict] = field(default_factory=list)
    nodes: dict[str, dict] = field(default_factory=dict)
    media: dict[str, dict] = field(default_factory=dict)
    media_segments: dict[str, dict] = field(default_factory=dict)
    lessons: dict[str, dict] = field(default_factory=dict)
    redirects: dict[str, str] = field(default_factory=dict)
    registry: dict = field(default_factory=dict)
    origin: dict[str, Path] = field(default_factory=dict)

    def all_ids(self) -> set[str]:
        return set(self.origin)


def _add(c: Content, table: dict, item: dict, path: Path, dupes: list[str]) -> None:
    i = item["id"]
    if i in c.origin:
        dupes.append(f"{path}: duplicate id {i} (first in {c.origin[i]})")
    c.origin[i] = path
    table[i] = item


def load(content_dir: Path = CONTENT) -> tuple[Content, list[str]]:
    """Returns the model and any duplicate-id errors. Schema checks happen in validate."""
    c = Content()
    dupes: list[str] = []
    c.registry = read_yaml(SCHEMAS / "registry.yaml")

    def doc(path: Path, schema: str) -> Any:
        data = read_yaml(path)
        c.docs.append(Doc(path, schema, data))
        return data

    src = doc(content_dir / "sources" / "sources.yaml", "sources")
    for x in src.get("licences", []):
        _add(c, c.licences, x, content_dir / "sources" / "sources.yaml", dupes)
    for x in src.get("sources", []):
        _add(c, c.sources, x, content_dir / "sources" / "sources.yaml", dupes)

    for wdir in sorted((content_dir / "works").iterdir()):
        if not wdir.is_dir():
            continue
        w = doc(wdir / "work.yaml", "work")
        _add(c, c.works, w, wdir / "work.yaml", dupes)
        for s in w.get("sections", []):
            s = dict(s, work=w["id"])
            _add(c, c.sections, s, wdir / "work.yaml", dupes)
        for vf in sorted((wdir / "verses").glob("*.yaml")):
            for v in doc(vf, "verse") or []:
                v = dict(v, work=w["id"])
                _add(c, c.verses, v, vf, dupes)

    for tdir in sorted((content_dir / "translations").iterdir()):
        if not tdir.is_dir():
            continue
        t = doc(tdir / "translation.yaml", "translation")
        _add(c, c.translations, t, tdir / "translation.yaml", dupes)
        for sf in sorted(tdir.glob("*.yaml")):
            if sf.name == "translation.yaml":
                continue
            sd = doc(sf, "segments")
            for i, s in enumerate(sd.get("segments", []), 1):
                s = dict(s, translation=sd["translation"], work=sd["work"], ordinal=i)
                _add(c, c.segments, s, sf, dupes)

    g = doc(content_dir / "glossary" / "terms.yaml", "terms")
    for x in g.get("terms", []):
        _add(c, c.terms, x, content_dir / "glossary" / "terms.yaml", dupes)
    for x in g.get("glossary", []):
        _add(c, c.glossary, x, content_dir / "glossary" / "terms.yaml", dupes)

    for cf in sorted((content_dir / "concepts").glob("*.yaml")):
        cd = doc(cf, "concept")
        for x in cd.get("areas", []):
            _add(c, c.areas, x, cf, dupes)
        for x in cd.get("concepts", []):
            _add(c, c.concepts, x, cf, dupes)

    p = doc(content_dir / "mathematicians" / "people.yaml", "people")
    for x in p.get("places", []):
        _add(c, c.places, x, content_dir / "mathematicians" / "people.yaml", dupes)
    for x in p.get("mathematicians", []):
        _add(c, c.people, x, content_dir / "mathematicians" / "people.yaml", dupes)

    t = doc(content_dir / "timeline" / "timeline.yaml", "timeline")
    for x in t.get("events", []):
        _add(c, c.events, x, content_dir / "timeline" / "timeline.yaml", dupes)

    for cf in sorted((content_dir / "curriculum").glob("*.yaml")):
        cur = doc(cf, "curriculum")
        c.curricula.append(cur)
        for cl in cur.get("classes", []):
            for book in cl.get("books", []):
                for ch in book.get("chapters", []):
                    node = dict(ch, board=cur["board"], cls=cl["class"], book=book["id"])
                    _add(c, c.nodes, node, cf, dupes)

    m = doc(content_dir / "media" / "media.yaml", "media")
    for x in m.get("media", []):
        _add(c, c.media, x, content_dir / "media" / "media.yaml", dupes)
        for s in x.get("segments", []):
            _add(c, c.media_segments, dict(s, media=x["id"]), content_dir / "media" / "media.yaml", dupes)

    for lf in sorted((content_dir / "lessons").glob("*/lesson.yaml")):
        lesson = doc(lf, "lesson")
        _add(c, c.lessons, lesson, lf, dupes)

    rf = content_dir / "redirects.yaml"
    if rf.exists():
        c.redirects = read_yaml(rf) or {}

    return c, dupes


def schema_store() -> dict[str, dict]:
    return {p.name: json.loads(p.read_text(encoding="utf-8")) for p in SCHEMAS.glob("*.schema.json")}
