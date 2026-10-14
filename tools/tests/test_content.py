"""Build the real content into a pack and check what the app relies on."""

import json
import sqlite3

import pytest

from tools.pack.build import build, coverage_report
from tools.pack.load import load
from tools.pack.text import any_script_key
from tools.pack.validate import validate


@pytest.fixture(scope="module")
def content():
    c, dupes = load()
    return c, dupes


@pytest.fixture(scope="module")
def db(content, tmp_path_factory):
    c, _ = content
    out = tmp_path_factory.mktemp("pack") / "content.db"
    build(c, out, "2026.10.14")
    conn = sqlite3.connect(out)
    yield conn
    conn.close()


def test_content_validates(content):
    c, dupes = content
    report = validate(c, dupes)
    assert report.errors == []
    assert report.stats["kannada_coverage"] == 100.0


def test_every_lesson_ends_with_summary_and_compiles(db):
    for (doc,) in db.execute("SELECT doc_json FROM lesson"):
        lesson = json.loads(doc)
        assert lesson["cards"][-1]["type"] == "summary"
        assert all("min_engine" in card for card in lesson["cards"])


def test_ten_launch_lessons(db):
    assert db.execute("SELECT count(*) FROM lesson").fetchone()[0] == 10


def test_every_verse_has_three_scripts(db):
    n = db.execute("SELECT count(*) FROM verse").fetchone()[0]
    per_script = dict(db.execute("SELECT script, count(*) FROM verse_text GROUP BY script"))
    assert per_script == {"devanagari": n, "kannada": n, "iast": n}


@pytest.mark.parametrize("query,expected", [
    ("kuttaka", "lesson.kuttaka"), ("कुट्टक", "lesson.kuttaka"), ("ಕುಟ್ಟಕ", "lesson.kuttaka"),
    ("Pythagoras", "concept.bhuja-koti-karna"), ("rule of three", "lesson.trairashika"),
    ("pell's equation", "concept.varga-prakriti"),
])
def test_search_across_scripts(db, query, expected):
    fts = " ".join(f'"{t}"*' for t in any_script_key(query).split())
    ids = [r[0] for r in db.execute(
        "SELECT entity_id FROM search_index WHERE locale='en' AND search_index MATCH ? ORDER BY rank LIMIT 5",
        (f"{{text keys}}: {fts}",))]
    assert expected in ids


def test_pending_media_never_ships(db):
    assert db.execute("SELECT count(*) FROM media WHERE external_id IS NULL OR external_id = ''").fetchone()[0] == 0


def test_lesson_verses_have_a_translation(content):
    c, _ = content
    rows = coverage_report(c)
    for row in rows:
        if row["translation"] == "translation.taylor-1816":
            continue  # OCR not done yet (plan §5.2)
        assert row["lesson_verses_covered"] == row["lesson_verses"], row


def test_all_33_ganitapada_root_verses_and_clark_covers_them(content):
    c, _ = content
    verses = {v["ref_label"] for v in c.verses.values() if v["work"] == "work.aryabhatiya"}
    assert verses == {f"2.{n}" for n in range(1, 34)}
    covered = {v for s in c.segments.values() if s["translation"] == "translation.clark-1930" for v in s["verses"]}
    assert {f"verse.aryabhatiya.2.{n}" for n in range(1, 34)} <= covered


def test_two_line_verses_have_both_halves(content):
    """Verses the e-text splits across commentary must carry both halves (2 lines)."""
    c, _ = content
    for n in (6, 7, 9, 16, 17, 21, 27):
        v = c.verses[f"verse.aryabhatiya.2.{n}"]
        assert v["devanagari"].count("\n") >= 1, v["id"]
        assert "J" not in v["source_text"].replace("sāJchāyābhaktā", ""), v["id"]


def test_concept_pages_have_sources_and_both_languages(content):
    c, _ = content
    assert len(c.concepts) >= 40
    for k in c.concepts.values():
        assert k["claims"], k["id"]
        assert k["name"]["kn"] and k["body"]["kn"], k["id"]
