# Status against the plan

Updated 14 October 2026. "Verified" means covered by an automated test that passes.
Mobile/device testing has not been done yet (the reference phone, TalkBack, 16 KB
emulator, real CDN).

## Built and verified

| Plan | What exists | Verified by |
|---|---|---|
| §5.1 sources | GRETIL Līlāvatī (251 verse units), Brāhmasphuṭasiddhānta ch. 12 and 18 (168), Āryabhaṭīya Gaṇitapāda (31 of 33 root verses); Colebrooke 1817 and Clark 1930 OCR | `tools/ingest/fetch_sources.sh` (SHA-256 pinned) |
| §5.3 scripts | Devanagari generated from source IAST; Kannada and IAST at build time | round-trip check on all 450 verses |
| §5.2 translations | Colebrooke: 13 Līlāvatī + 6 BSS segments; Clark: 6 Āryabhaṭīya segments; Taylor: listed, 0 segments | coverage report; every lesson verse with a translation has one |
| §5.4 Kannada | All interface strings (185) and all content strings in English and Kannada (draft) | validator: 100% coverage; gen-l10n: no untranslated |
| §5.5 curriculum | NCERT Classes 6–12 mapping (draft; chapter numbers 0 = to confirm) | repository tests |
| §5.7 citations | Every work, person, concept and event cites sources | validator fails on a missing citation |
| §6.5 packs | validate → build `content.db` (1.4 MB, FTS5) → Ed25519-signed manifest → CDN layout → bundle | Python and Dart tests, cross-language signature check |
| §6.5 updates | Daily, Wi-Fi-only check; signature, schema, min app version, size, SHA-256, integrity; staging; activation; rollback | `pack_update_test.dart` (8 cases) |
| §6.6 engine | 8 card types, registry, skip unknown/newer cards, state saved on every card change, resume | widget flow test incl. "kill and resume" |
| §6.7 problems | 10 generators × 3 difficulties, exact answers, hint ladders, EN/KN text, no repeats per session | 1,000-seed property tests (30,000 problems) |
| §6.8 review | Leitner 1/3/7/16/35 behind an interface; attempts log; "Revise today" | unit tests |
| §6.9 search | One box, any script, aliases (Pythagoras, rule of three, Pell's equation) | Python + Dart tests on the real pack |
| §6.11 l10n | ARB + `localized_text`; Kannada fonts and line heights | goldens EN/KN light/dark |
| §6.12 Android | targetSdk 36, minSdk 24, predictive back, edge-to-edge, no AD_ID, 16 KB check script | build config; device check pending |
| §7 design | Tokens, fonts, theme, components, kolam (single-curve mirror kolam per lesson) | contrast test, kolam tests, 19 goldens |
| §4 screens | Onboarding, School, chapter, lesson player, verse view, Explore (areas, concepts, texts, reading room, people, lineage, timeline, search), Progress (kolam, review, bookmarks), Settings (all §4.8 items), sources and licences, privacy, debug tools | widget tests open every screen |
| §8.4 CI | content-check, app-check, content-release, app-release, link-check | workflows run the same commands verified locally |

## Android build (verified on this machine, not on a device)

- Debug APK and release AAB build with Flutter 3.47.7 and JDK 21. `targetSdk` 36, `minSdk` 24,
  permissions limited to INTERNET and ACCESS_NETWORK_STATE, no AD_ID.
- Every native library in the APK and AAB is 16 KB aligned (`tools/check_16kb.sh`).
- Size: the AAB is 66.7 MB because it holds three ABIs. One arm64 install is about 28 MB
  (native 21 MB, assets 5.7 MB incl. a 1.4 MB pack, code 1.6 MB), just inside the 30 MB budget;
  `libapp.so` (8 MB) and the six font files (4.2 MB) are the places to trim if needed.
- Release builds are signed with the debug key until `android/key.properties` exists.

## Not done, and why

| Item | Needs |
|---|---|
| Sanskrit review of every lesson verse and the analytic-text decision (ADR 3) | Sanskrit reviewer |
| Āryabhaṭīya 2.16, 2.21 and the first halves of 2.6, 2.7, 2.9, 2.17, 2.27 | Locating in the commentary e-text |
| Proofreading the OCR segments (all `ocr-draft`; some pages "to confirm") | Page images, a person |
| Taylor 1816 translation | OCR of the Google Books scan |
| Kannada review of all Kannada text (my drafts) | Kannada reviewer |
| Maths teacher review of lessons and NCERT chapter numbers | Maths teacher |
| Videos: 6 sources listed as `pending`; none ship until someone pins IDs and minutes | Watching the lectures |
| Verse recitation audio | Reciter (the app shows a play button once files are bundled) |
| Final illustrations (code-drawn placeholders now, ADR 4) | Designer |
| Release signing key, CDN host, application ID, Play account | Team decisions (plan §14) |
| Performance on the reference phone, TalkBack walkthrough, usability rounds | Devices and students |
| ~40 concept pages (18 now) | Writing and sources |

## Deviations from the plan

- `sqlite3` directly instead of `drift` (ADR 2).
- `flutter_math_fork`, `vector_graphics` and `alchemist` are not used yet: working lines are
  plain text, art is code-drawn (ADR 4), and goldens use `matchesGoldenFile`.
- Two colour tokens tuned for AA (ADR 5).
