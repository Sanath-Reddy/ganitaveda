# content_model

- `LessonDoc` and typed cards; unknown types and newer `min_engine` become
  `UnsupportedCard` ("Update the app to see this part"), never a crash.
- `Manifest`: canonical JSON + Ed25519 verification, SHA-256, version comparison.
- `ContentRepository` / `SqliteContentRepository`: every query screens need from `content.db`.

Tests run against `build/pack` (build it first with `python -m tools.pack build`).
