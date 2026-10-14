import csv
import shutil

import pytest

from tools import review
from tools.pack.load import CONTENT, load
from tools.pack.validate import validate


@pytest.fixture
def scratch(tmp_path):
    """A throw-away copy of content/, so imports never touch the real files."""
    dest = tmp_path / "content"
    shutil.copytree(CONTENT, dest)
    return dest


def decide(rows, value="approve", only=None):
    for r in rows:
        if only is None or only(r):
            r["decision"] = value
    return rows


def test_sanskrit_export_has_every_lesson_verse_and_a_sample(scratch):
    c, _ = load(scratch)
    rows = review.export_sanskrit(c)
    ids = {r["id"] for r in rows}
    assert set(review.lesson_verse_ids(c)) <= ids
    assert len(rows) > len(set(review.lesson_verse_ids(c)))
    assert sum("Kannada script check" in r["why"] for r in rows) >= 15
    assert all(r["kannada_script"] and r["iast"] and r["devanagari"] for r in rows)
    # deterministic: the same export twice
    assert [r["id"] for r in review.export_sanskrit(c)] == [r["id"] for r in rows]


def test_sanskrit_import_approves_verses_and_lessons_with_a_record(scratch):
    c, _ = load(scratch)
    rows = decide(review.export_sanskrit(c))
    rep = review.import_decisions(c, "sanskrit", rows, "A. Reviewer", "2026-12-01", scratch)
    assert rep["approved"] == len(rows)
    c2, dupes = load(scratch)
    for vid in review.lesson_verse_ids(c2):
        v = c2.verses[vid]
        assert v["review"] == "approved" and v["reviewed_by"] == "A. Reviewer" and v["reviewed_on"] == "2026-12-01"
    assert all(l["review"]["sanskrit"] == "approved" for l in c2.lessons.values())
    assert validate(c2, dupes).errors == []


def test_change_requests_are_reported_not_applied(scratch):
    c, _ = load(scratch)
    rows = review.export_sanskrit(c)
    rows[0]["decision"], rows[0]["comment"] = "change", "anusvāra"
    rep = review.import_decisions(c, "sanskrit", rows, "A. Reviewer", "2026-12-01", scratch)
    assert rep["changes"] == [f"{rows[0]['id']}: anusvāra"] and rep["approved"] == 0
    c2, _ = load(scratch)
    assert c2.verses[rows[0]["id"]]["review"] == "unreviewed"


def test_kannada_review_needs_every_string_of_a_lesson(scratch):
    c, _ = load(scratch)
    rows = review.export_kannada(c)
    lesson = "lesson.bee-swarm"
    decide(rows, only=lambda r: r["lesson"] == lesson)
    last = max(i for i, r in enumerate(rows) if r["lesson"] == lesson)
    rows[last]["decision"] = ""  # one string of the lesson left unreviewed
    partial = rows
    review.import_decisions(c, "kannada", partial, "K. Reviewer", "2026-12-02", scratch)
    c2, _ = load(scratch)
    assert c2.lessons[lesson]["review"]["kannada"] == "draft"
    full = decide(review.export_kannada(c2), only=lambda r: r["lesson"] == lesson)
    review.import_decisions(c2, "kannada", full, "K. Reviewer", "2026-12-02", scratch)
    c3, dupes = load(scratch)
    assert c3.lessons[lesson]["review"]["kannada"] == "approved"
    assert c3.lessons["lesson.jya"]["review"]["kannada"] == "draft"
    assert validate(c3, dupes).errors == []
    text = (scratch / "lessons" / "bee-swarm" / "lesson.yaml").read_text(encoding="utf-8")
    assert 'kannada: {by: "K. Reviewer", date: "2026-12-02"}' in text and "# " not in text.split("cards:")[0].replace("# No verse card", "")


def test_all_three_roles_open_the_release_gate(scratch):
    c, _ = load(scratch)
    for role, rows in (("sanskrit", review.export_sanskrit(c)), ("kannada", review.export_kannada(c)), ("maths", review.export_maths(c))):
        c, _ = load(scratch)
        review.import_decisions(c, role, decide(rows), f"{role} reviewer", "2026-12-05", scratch)
    c, dupes = load(scratch)
    report = validate(c, dupes, release=True)
    assert [e for e in report.errors if "not approved" in e or "lesson verse" in e] == []
    assert "OPEN" in review.status(c)


def test_roundtrip_through_csv_file(scratch, tmp_path):
    c, _ = load(scratch)
    path = tmp_path / "k.csv"
    review.write_csv(path, review.export_kannada(c))
    with open(path, encoding="utf-8-sig", newline="") as f:
        assert len(list(csv.DictReader(f))) == len(review.export_kannada(c))


def test_kannada_other_packet_covers_interface_and_content_pages(scratch):
    c, _ = load(scratch)
    rows = review.export_kannada_other(c)
    assert sum(r["lesson"] == "app" for r in rows) >= 150
    assert any(r["lesson"].startswith("concepts") for r in rows)
    assert all(r["kannada"] for r in rows)
    rep = review.import_decisions(c, "kannada-other", decide(rows[:3]), "K", "2026-12-01", scratch)
    assert rep["approved"] == 3


def test_release_build_is_blocked_until_reviews_are_in():
    c, dupes = load()
    errors = validate(c, dupes, release=True).errors
    assert any("not approved by every reviewer" in e for e in errors)
    assert any("not approved by the Sanskrit reviewer" in e for e in errors)
