# GanitaVeda: developer guide

A free Android app that teaches classical Indian mathematics from the original
texts, in English and Kannada. See [status.md](status.md) for what is built, what is verified and what
still needs people.

## Layout (plan §8.1)

```text
apps/mobile/            Flutter app (Android)
packages/ganita_core/   pure Dart: Rational, algorithms, generators, checker, scheduler, search keys
packages/content_model/ lesson documents, manifest signing check, content.db repository
packages/design_system/ tokens, fonts, theme, components, kolam
content/                texts, translations, concepts, people, curriculum, lessons (YAML)
tools/ingest/           GRETIL and OCR ingestion
tools/pack/             validate → build content.db → sign → publish
tools/preview/          review site for reviewers
tools/schemas/          JSON Schemas and the card/widget/generator registry
docs/                   decisions, guides, checklists
```

## Quick start

```bash
# Tools (Python 3.12+)
python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/requirements.txt
tools/.venv/bin/python -m tools.pack validate        # content checks
tools/.venv/bin/python -m tools.pack build           # build/pack/content.db + signed manifest
tools/.venv/bin/python -m tools.pack bundle          # copy it into the app as the offline baseline
tools/.venv/bin/python -m tools.preview              # build/preview/index.html for reviewers

# App (Flutter 3.47.7, pinned in .fvmrc)
fvm flutter pub get            # or put ~/fvm/versions/3.47.7/bin first on PATH
cd apps/mobile && flutter gen-l10n && flutter test && flutter run
```

Full build, signing and release steps: [building.md](building.md). Review hand-off for the Sanskrit, Kannada and maths reviewers: [reviewing.md](reviewing.md).
