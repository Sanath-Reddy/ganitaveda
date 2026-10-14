/// Pure Dart maths shared by the app and CI (plan §6.7).
library;

export 'src/algorithms/geometry.dart' show bhujaKotiKarna, cyclicQuad;
export 'src/algorithms/ishta_karma.dart' show ishtaKarma;
export 'src/algorithms/number_theory.dart'
    show AnkapashaResult, KuttakaResult, ankapasha, ankapashaTrace, kuttaka, kuttakaTrace;
export 'src/algorithms/proportion_series.dart'
    show JyaRow, MadhavaSum, jyaTable, jyaTrace, madhavaSum, madhavaTrace, sredhi, trairashika;
export 'src/algorithms/roots.dart' show exactSqrt, factorial, gcd, isqrt, lcm;
export 'src/algorithms/sign_rules.dart' show apply, kind, ruleFor, signRules;
export 'src/checker.dart';
export 'src/generators/common.dart' show mixSeed;
export 'src/generators/geometry_generators.dart' show primitiveTriples;
export 'src/generators/registry.dart';
export 'src/problem.dart';
export 'src/random.dart';
export 'src/rational.dart';
export 'src/scheduler.dart';
export 'src/search/normalise.dart';
export 'src/text.dart';
