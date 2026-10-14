"""Review preview site (plan §5.8): static, phone-friendly HTML built from content/.

  python -m tools.preview [--out build/preview]

Reviewers read lessons with every card, each verse in three scripts beside its
translations, English and Kannada side by side, and the review status of each
item. CI publishes the output to GitHub Pages on every content PR.
"""

from __future__ import annotations

import argparse
import html
import sys
from pathlib import Path

from tools.pack.build import coverage_report
from tools.pack.load import ROOT, Content, load
from tools.pack.text import deva_to
from tools.pack.validate import validate

CSS = """
:root{--paper:#F5EEDF;--surface:#FBF7EE;--leaf:#E8D6A8;--ink:#1F1A14;--muted:#5C5346;--indigo:#2C3E73;
--kumkum:#A8322A;--neem:#2C6449;--line:#D9CDB6}
@media (prefers-color-scheme:dark){:root{--paper:#14110D;--surface:#1E1A14;--leaf:#3A3122;--ink:#EFE6D3;
--muted:#B7AC98;--indigo:#9DB0E8;--kumkum:#E5837A;--neem:#7CC4A0;--line:#3A3328}}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);
font:16px/1.55 "Anek Latin","Anek Kannada",system-ui,sans-serif}
main{max-width:760px;margin:0 auto;padding:16px}a{color:var(--indigo)}
h1{font-size:26px;line-height:1.25}h2{font-size:20px;margin-top:28px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:12px 0}
.leaf{background:var(--leaf)}.type{font-size:12px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
.kn{font-family:"Anek Kannada",sans-serif;line-height:1.7}.deva{font-family:"Tiro Devanagari Sanskrit",serif;font-size:19px}
.knscript{font-family:"Tiro Kannada",serif;font-size:19px}.iast{font-style:italic}
.pair{display:grid;grid-template-columns:1fr;gap:6px}@media (min-width:640px){.pair{grid-template-columns:1fr 1fr}}
.badge{display:inline-block;font-size:12px;padding:1px 8px;border-radius:99px;border:1px solid var(--line);margin-right:4px}
.approved{color:var(--neem)}.draft,.unreviewed,.ocr-draft{color:var(--kumkum)}
table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid var(--line);padding:6px;text-align:left;vertical-align:top}
pre{white-space:pre-wrap;margin:0}
"""


def esc(s: object) -> str:
    return html.escape(str(s))


def page(title: str, body: str, depth: int = 0) -> str:
    up = "../" * depth
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{esc(title)} · GanitaVeda review</title><style>{CSS}</style></head>'
            f'<body><main><p><a href="{up}index.html">GanitaVeda review</a></p>{body}</main></body></html>')


def lt(x: dict | None) -> str:
    if not x:
        return ""
    kn = x.get("kn")
    kn_html = f'<div class="kn">{esc(kn)}</div>' if kn else '<div class="kn draft">Kannada missing</div>'
    return f'<div class="pair"><div>{esc(x["en"])}</div>{kn_html}</div>'


def badge(label: str, status: str) -> str:
    return f'<span class="badge {esc(status)}">{esc(label)}: {esc(status)}</span>'


def verse_block(c: Content, vid: str) -> str:
    v = c.verses[vid]
    work = c.works[v["work"]]
    segs = [s for s in c.segments.values() if vid in s["verses"]]
    trs = "".join(
        f'<div class="card"><div class="type">{esc(c.translations[s["translation"]]["translator"])} '
        f'({c.translations[s["translation"]]["year"]}) · {esc(s.get("label", ""))} · p. {esc(s["page"])} '
        f'{badge("text", s["status"])}</div><p>{esc(s["text"])}</p></div>' for s in segs) \
        or '<p class="draft">No translation segment yet.</p>'
    notes = "".join(f"<li>{esc(n)}</li>" for n in v.get("notes", []))
    return (f'<div class="card leaf"><div class="type">{esc(work["title_iast"])} {esc(v["ref_label"])} '
            f'{badge("Sanskrit", v["review"])}</div>'
            f'<pre class="deva">{esc(v["devanagari"])}</pre><pre class="knscript">{esc(deva_to("kannada", v["devanagari"]))}</pre>'
            f'<pre class="iast">{esc(deva_to("iast", v["devanagari"]))}</pre>'
            f'<details><summary>Source line (GRETIL)</summary><pre>{esc(v.get("source_text", ""))}</pre>'
            f'{f"<ul>{notes}</ul>" if notes else ""}</details></div>{trs}')


def lesson_page(c: Content, lesson: dict) -> str:
    rv = lesson["review"]
    out = [f'<h1>{esc(lesson["title"]["en"])}</h1>{lt(lesson["title"])}',
           f'<p>{badge("maths", rv["maths"])}{badge("Sanskrit", rv["sanskrit"])}{badge("Kannada", rv["kannada"])}</p>',
           f'<p>{lesson["minutes"]} min · author {lesson["author"]} · '
           + ", ".join(esc(c.nodes[n]["title"]["en"]) + f' (Class {c.nodes[n]["cls"]})' for n in lesson.get("curriculum", []))
           + "</p>"]
    for card in lesson["cards"]:
        t = card["type"]
        body = ""
        if t == "scene":
            body = lt(card["text"]) + f'<p class="type">art: {esc(card["art"])}</p>'
        elif t == "explore":
            body = lt(card["prompt"]) + lt(card.get("goal")) + f'<p class="type">widget {esc(card["widget"])} {esc(card["params"])}</p>'
        elif t == "verse":
            body = lt(card.get("intro")) + verse_block(c, card["verse"])
        elif t == "method":
            body = lt(card["intro"]) + lt(card.get("modern")) + f'<p class="type">algorithm {esc(card["algorithm"])} {esc(card["inputs"])}</p>'
        elif t == "practice":
            body = f'<p>{card["count"]} problems from <code>{esc(card["generator"])}</code>, difficulty {esc(card.get("difficulty"))}. '\
                   f'Try them in the app\'s generator playground (debug builds).</p>'
        elif t == "quiz":
            for q in card["questions"]:
                body += lt(q["prompt"]) + "<ol>" + "".join(
                    f'<li{" class=approved" if i == q["answer"] else ""}>{lt(ch)}</li>' for i, ch in enumerate(q["choices"])) + "</ol>" + lt(q.get("why"))
        elif t == "watch":
            body = f'<p>segment {esc(card["segment"])}</p>'
        elif t == "summary":
            body = lt(card["key_idea"]) + lt(card.get("textbook"))
        out.append(f'<div class="card"><div class="type">{esc(card["id"])} · {esc(t)}</div>{body}</div>')
    return page(lesson["title"]["en"], "".join(out), 1)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "build" / "preview"))
    args = ap.parse_args(argv)
    out = Path(args.out)
    (out / "lessons").mkdir(parents=True, exist_ok=True)
    (out / "works").mkdir(parents=True, exist_ok=True)
    c, dupes = load()
    report = validate(c, dupes)

    for lesson in c.lessons.values():
        slug = lesson["id"].split(".", 1)[1]
        (out / "lessons" / f"{slug}.html").write_text(lesson_page(c, lesson), encoding="utf-8")

    for w in c.works.values():
        slug = w["id"].split(".", 1)[1]
        verses = sorted((v for v in c.verses.values() if v["work"] == w["id"]), key=lambda v: (v["section"], v["ordinal"]))
        body = f'<h1>{esc(w["title_iast"])}</h1>{lt(w["about"])}' + "".join(verse_block(c, v["id"]) for v in verses)
        (out / "works" / f"{slug}.html").write_text(page(w["title_iast"], body, 1), encoding="utf-8")

    concepts = "".join(f'<div class="card"><div class="type">{esc(k["area"])} · {esc(k["classical_iast"])}</div>'
                       f'<h2>{esc(k["name"]["en"])}</h2>{lt(k["summary"])}{lt(k["body"])}</div>' for k in c.concepts.values())
    (out / "concepts.html").write_text(page("Concepts", "<h1>Concepts</h1>" + concepts), encoding="utf-8")
    people = "".join(f'<div class="card"><h2>{esc(p["name"]["en"])}</h2>{lt(p["dates_label"])}{lt(p["summary"])}</div>'
                     for p in c.people.values())
    (out / "people.html").write_text(page("Mathematicians", "<h1>Mathematicians</h1>" + people), encoding="utf-8")

    cov = "".join(f'<tr><td>{esc(r["translation"])}</td><td>{esc(r["work"])}</td><td>{r["covered"]}/{r["total"]}</td>'
                  f'<td>{r["lesson_verses_covered"]}/{r["lesson_verses"]}</td></tr>' for r in coverage_report(c))
    issues = "".join(f"<li class=draft>{esc(e)}</li>" for e in report.errors) + \
        "".join(f"<li>{esc(w)}</li>" for w in report.warnings)
    lessons = "".join(f'<li><a href="lessons/{l["id"].split(".", 1)[1]}.html">{esc(l["title"]["en"])}</a> '
                      f'{badge("maths", l["review"]["maths"])}{badge("Sanskrit", l["review"]["sanskrit"])}'
                      f'{badge("Kannada", l["review"]["kannada"])}</li>' for l in c.lessons.values())
    works = "".join(f'<li><a href="works/{w["id"].split(".", 1)[1]}.html">{esc(w["title_iast"])}</a></li>' for w in c.works.values())
    index = (f'<h1>GanitaVeda content review</h1><p>Kannada coverage {report.stats["kannada_coverage"]}% · '
             f'{report.stats["verses"]} verses, {report.stats["verses_unreviewed"]} not yet approved.</p>'
             f'<h2>Lessons</h2><ul>{lessons}</ul><h2>Texts</h2><ul>{works}</ul>'
             f'<p><a href="concepts.html">Concepts</a> · <a href="people.html">Mathematicians</a></p>'
             f'<h2>Translation coverage</h2><table><tr><th>Translation</th><th>Work</th><th>Verses</th><th>Lesson verses</th></tr>{cov}</table>'
             f'<h2>Checks</h2><ul>{issues or "<li class=approved>No issues</li>"}</ul>')
    (out / "index.html").write_text(page("Overview", index), encoding="utf-8")
    print(f"preview written to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
