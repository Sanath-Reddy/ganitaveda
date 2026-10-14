# Review guide

The app cannot be released until a Sanskrit reviewer, a Kannada reviewer and a maths teacher have each
approved every lesson (plan §5.8). Nothing here edits the text for you: you mark rows in a spreadsheet,
and someone from the team applies the corrections and records your approval.

## For the team

```bash
python -m tools.review export sanskrit        # build/review/review-sanskrit.csv
python -m tools.review export kannada         # lesson strings
python -m tools.review export kannada-other   # interface, concept pages, people, timeline
python -m tools.review export maths
python -m tools.review import FILE.csv --role sanskrit --reviewer "Name"     # after the reviewer returns it
python -m tools.review status                 # who has approved what; is the release gate open?
python -m tools.preview                       # build/preview: read lessons as they look in the app
```

Import records `approved`, the reviewer's name and the date. Rows marked `change` are listed, not applied:
edit the content, rebuild, export again. A lesson is approved for a role only when every exported row for
that lesson is approved. `python -m tools.pack build --release` refuses to build until the gate is open.

## For the Sanskrit reviewer

Open `review-sanskrit.csv` in a spreadsheet (UTF-8). Each row is one verse with its text in Devanagari, Kannada
script and IAST, plus the source line. You check every verse that appears in a lesson and a 10% sample of the
others, and 20 verses in Kannada script. Look for: the verse matches the edition; sandhi and compounds
(the text is the e-text's word-by-word form, not continuous sandhi, ADR 3); anusvāra, visarga, avagraha and
conjuncts in Kannada script. Fill `decision` with `approve` or `change` and say what in `comment`.

## For the Kannada reviewer

`review-kannada.csv` holds every Kannada string of every lesson beside its English. `review-kannada-other.csv`
holds the interface and the concept, people and timeline pages. Check terminology against
`content/l10n/kn/terms.yaml` (Kannada school-textbook terms; Sanskrit technical terms stay in Sanskrit with an
explanation). All Kannada so far is a first draft by the assistant and has not been read by a native speaker.
Also look at the screens on a phone for line breaks and truncation.

## For the maths teacher

`review-maths.csv` lists each lesson card: the story, the numbers, the method and the practice settings, with the
NCERT chapter each lesson is mapped to. Please confirm the explanation and numbers, that problems are right for
the class, and the chapter numbers marked TO CONFIRM (they are placeholders until checked against the current books).
