# ganita_core

Pure Dart, shared by the app and CI (plan §6.7).

- `Rational`: exact arithmetic; answers are never floating point.
- Algorithms with step traces: iṣṭa-karma, sign rules, bhuja-koṭi-karṇa, trairāśika,
  śreḍhī, the jyā table, Mādhava's series, kuṭṭaka, Brahmagupta's quadrilateral, aṅkapāśa.
- Ten seeded generators (`generators`), `generateSession` (no repeats), `AnswerChecker`
  (integers, fractions, mixed numbers, decimals, units, Kannada/Devanagari digits).
- `LeitnerScheduler` behind `ReviewScheduler`; `asciiKey`/`ftsQuery` for search in any script.

`dart test` runs every generator for 1,000 seeds at every difficulty.
