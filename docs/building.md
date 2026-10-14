# Building and releasing

## Toolchain

- Flutter **3.47.7** (Dart 3.13), pinned in `.fvmrc`. On the dev machine it lives in
  `~/fvm/versions/3.47.7`; `fvm use` picks it up.
- JDK 17+ for Gradle (CI uses Temurin 21).
- Android SDK with platform 36; Gradle downloads missing parts once the SDK licence is accepted.
- Python 3.12+ with `tools/requirements.txt` (exact pins in `tools/requirements.lock`).

## Content pack

```bash
python -m tools.pack validate            # add --release to require all reviews and 100% Kannada
python -m tools.pack build --version 2026.11.22 --base-url https://<cdn>
python -m tools.pack bundle              # baseline pack inside the app
python -m tools.pack publish --channel beta --cdn build/cdn
python -m tools.pack verify build/pack/manifest.json
python -m tools.pack coverage            # translation coverage report
```

Signing: CI sets `PACK_SIGNING_KEY` (base64 raw Ed25519) and `PACK_KEY_ID`.
Locally, a development key is generated in `build/dev-signing.key` (key id `dev`).
Generate the real key with `python -m tools.pack keygen <path outside the repo>`, keep an
offline copy with both team members, and put the public key (and the next one) into
`AppConfig._releaseKeys` in `apps/mobile/lib/app/config.dart`.

## Aligning a translation (plan §5.2)

```bash
python -m tools.ingest.align > build/align-colebrooke.csv   # candidate verses per Colebrooke paragraph
python -m tools.ingest.align evaluate                        # leave-one-out check on confirmed segments
```

The helper reads numbers (Hayashi marks numerals with `%`) and uses confirmed segments as anchors
to estimate where each paragraph falls. On the 7 evaluable confirmed pairs it puts the right verse
inside its window 7 times and in the top three 5 times. It parses about 150 of 247 paragraphs from
the rough OCR. A person confirms every suggestion.

## App build flags (`--dart-define`)

| Name | Meaning |
|---|---|
| `APP_VERSION` | Compared with a pack's `min_app_version`. CI passes the pubspec/tag version. |
| `CONTENT_BASE_URL` | CDN root with `/channels/*.json` and `/packs/...`. Empty: updates off. |
| `PACK_DEV_PUBLIC_KEY` | Debug builds only: trust a developer's own pack key. |
| `REPORT_EMAIL` | Recipient for "Report a problem". Empty: the user fills it in. |

```bash
cd apps/mobile
flutter build apk --debug
flutter build appbundle --release --dart-define=APP_VERSION=1.0.0 --dart-define=CONTENT_BASE_URL=https://<cdn>
../../tools/check_16kb.sh build/app/outputs/bundle/release/app-release.aab
```

Release signing reads `apps/mobile/android/key.properties` (never committed); without it
release builds fall back to the debug key so `flutter run --release` works locally.

## Tests

| Where | Command |
|---|---|
| Tools | `python -m pytest tools/tests` |
| ganita_core (incl. 1,000-seed generator properties) | `cd packages/ganita_core && dart test` |
| content_model (needs `build/pack`) | `cd packages/content_model && dart test` |
| design_system | `cd packages/design_system && flutter test` |
| App (unit, widget, flows, goldens) | `cd apps/mobile && flutter test` |
| Regenerate goldens after an intended visual change | `flutter test test/goldens_test.dart --update-goldens` |
