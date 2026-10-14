# Status against the plan

Updated 14 October 2026. "Verified" means covered by an automated test that passes.
Mobile/device testing has not been done yet (the reference phone, TalkBack, 16 KB
emulator, real CDN).

## Built and verified

| Plan | What exists | Verified by |
|---|---|---|
| §5.1 sources | GRETIL Līlāvatī (251 verse units), Brāhmasphuṭasiddhānta ch. 12 and 18 (168), Āryabhaṭīya Gaṇitapāda (all 33 root verses); Colebrooke 1817 and Clark 1930 OCR | `tools/ingest/fetch_sources.sh` (SHA-256 pinned) |
| §5.3 scripts | Devanagari generated from source IAST; Kannada and IAST at build time | round-trip check on all 450 verses |
| §5.2 translations | Colebrooke: 13 Līlāvatī + 6 BSS segments; Clark: all 33 Gaṇitapāda verses (OCR drafts); Taylor: 7 segments covering 4 of the 5 Līlāvatī lesson verses (OCR drafts) | coverage report; every lesson verse with a translation has one |
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
- Size: the three-ABI AAB is 66.7 MB, but a phone downloads one ABI. Per-ABI release APKs
  (`--split-per-abi --split-debug-info`) are 21.3 MB (armv7), 23.9 MB (arm64), 25.4 MB (x86_64),
  inside the 30 MB budget.
- Release builds are signed with the debug key until `android/key.properties` exists.

## Accessibility and layout checks (automated, `accessibility_layout_test.dart`)

- Android tap-target size (48 dp) and labelled-tap-target guidelines on 8 screens in English and Kannada,
  and on every card of every lesson.
- No overflow or exception on 800×1280, 1280×800, 915×412 (phone landscape) and 320×568 (small phone) in both
  languages, on all main screens and on cards of three lessons; navigation rail at 600 dp and wider.
- Every text colour is an AA-checked design token, in light and dark.
- Bugs these found and fixed: a provider written during a rebuild when leaving a lesson with `go()`;
  Explore area cards overflowing on small screens and large text; `turmeric` (about 2.7:1) used for text.
- Not covered: TalkBack reading order and announcements, which need a person with a screen reader.

## Emulator run (this machine, KVM, headless)

Android 15 (API 35) x86_64 **16 KB page size** image, software GPU. Not a phone, but a real Android runtime:

| Check | Result |
|---|---|
| Release APK installs and runs on a 16 KB-page system | yes, no crash, edge-to-edge layout correct |
| Cold start (`am start -W`, 5 runs) | 1.17, 0.96, 0.98, 0.96, 1.01 s; budget 2.0 s |
| Integration test: first launch, full lesson, kill-and-resume, review queue | passes |
| Integration test: every lesson's cards, no exceptions | passes |
| Frame timings | **not meaningful**: measured in a debug build on a software-rendered emulator (p95 build 43 ms, 65% of frames over 16.7 ms). The 60 fps budget needs a profile build on the reference phone |

The Android 16.1 (API 36.1) 16 KB image crash-loops surfaceflinger in headless mode here
(`mapper.ranchu: Assertion failed: !hasReadColorBufferDma`), an emulator/image bug unrelated to the app,
so the API 35 image was used. Run the same test with `flutter test integration_test -d <device>`.

## Not done, and why

| Item | Needs |
|---|---|
| Sanskrit review of every lesson verse and the analytic-text decision (ADR 3) | Sanskrit reviewer |
| Proofreading the OCR segments (all `ocr-draft`; some pages "to confirm") | Page images, a person |
| Taylor 1816: 12 of 251 Līlāvatī verses (lesson verses 4 of 5, plus the opening operations). The 5th lesson verse (digit arrangements) is not in Taylor's OCR. The rest needs OCR clean-up | A person with the page images |
| Kannada review of all Kannada text (my drafts) | Kannada reviewer |
| Maths teacher review of lessons and NCERT chapter numbers | Maths teacher |
| Videos: 6 sources listed as `pending`; none ship until someone pins IDs and minutes | Watching the lectures |
| Verse recitation audio | Reciter (the app shows a play button once files are bundled) |
| Final illustrations (code-drawn placeholders now, ADR 4) | Designer |
| Release signing key, CDN host, application ID, Play account | Team decisions (plan §14) |
| Frame timings in a profile build, memory and battery on the reference phone, TalkBack walkthrough, usability rounds | Real device and students |
| Review of the 40 concept pages (all have sources; Kannada is draft) | Maths teacher, Kannada reviewer |

## Tools added after the first pass

- `tools/ingest/align.py`: suggests verse alignments for translation paragraphs (see docs/building.md).

## Content notes

- Āryabhaṭa 2.6 (pyramid volume) and 2.7 (sphere volume) are wrong by modern standards; their concept pages say so.
- Verse 16 and 21 carry the e-text's own local numbers (13, 20) in the source line; notes record why they are Shukla's 16 and 21.
- Verse 16 has an e-text typo ("sāJchāyā"); the reading text is corrected and the verse note says so.

## Deviations from the plan

- `sqlite3` directly instead of `drift` (ADR 2).
- `flutter_math_fork`, `vector_graphics` and `alchemist` are not used yet: working lines are
  plain text, art is code-drawn (ADR 4), and goldens use `matchesGoldenFile`.
- Two colour tokens tuned for AA (ADR 5).
