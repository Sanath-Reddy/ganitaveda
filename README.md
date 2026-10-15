# GanitaVeda

A free Android app that teaches classical Indian mathematics from the original texts, in English and Kannada.

Lessons are short card-based walkthroughs built around verses from the *Līlāvatī*, the *Brāhmasphuṭasiddhānta* and the *Āryabhaṭīya*. Verses can be read in Devanagari, Kannada script or IAST. Each lesson ends with practice problems, and lessons are mapped to the NCERT school syllabus (Classes 6–12).

## Features

- Lessons with interactive cards, verse view in three scripts, and generated practice problems with hints
- Spaced review ("Revise today") and a kolam that grows as you finish lessons
- Explore: search in any script, concepts, people, texts, a reading room and a timeline
- Works fully offline. No sign-up, no ads, no tracking; nothing leaves the phone
- English and Kannada interface, light and dark themes

## Status

Early and in testing. Translations are OCR drafts awaiting proofreading, the Kannada text is a first draft, and the Sanskrit texts are awaiting scholarly review. See [docs/status.md](docs/status.md) for what is built, what is verified and what still needs people.

## Repository layout

| Path | Contents |
|---|---|
| `apps/mobile/` | Flutter app (Android) |
| `packages/` | Shared Dart packages: core maths, content model, design system |
| `content/` | Texts, translations, concepts, people, curriculum and lessons (YAML) |
| `tools/` | Content ingestion, pack building and signing, review-site generator |
| `docs/` | Decisions, guides and checklists |

## Getting started

Requires Flutter 3.47.7 (pinned in `.fvmrc`) and Python 3.12+. See the [developer guide](docs/developer-guide.md) for setup and [docs/building.md](docs/building.md) for building and release.

```bash
python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/requirements.txt
tools/.venv/bin/python -m tools.pack validate
tools/.venv/bin/python -m tools.pack build
tools/.venv/bin/python -m tools.pack bundle
cd apps/mobile && flutter gen-l10n && flutter test && flutter run
```

## Documentation

- [Developer guide](docs/developer-guide.md)
- [Building and releasing](docs/building.md)
- [Review hand-off for Sanskrit, Kannada and maths reviewers](docs/reviewing.md)
- [Trying the app on a phone](docs/phone-test.md)
- [Architecture decisions](docs/adr/)

## Sources

Texts and translations come from public sources, each cited in the app under Sources and licences. Some source texts carry their own licences (for example GRETIL's CC BY-NC-SA 4.0), which are recorded in `content/sources/sources.yaml`.
