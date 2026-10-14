import '../problem.dart';
import 'arithmetic_generators.dart';
import 'common.dart';
import 'geometry_generators.dart';

/// Every generator the app knows, by id. Must match `generators` in
/// tools/schemas/registry.yaml (checked by test/registry_test.dart).
final Map<String, Generator> generators = {
  for (final g in <Generator>[
    FractionsRemainderGenerator(),
    IntegerSignsGenerator(),
    RightTriangleGenerator(),
    RuleOfThreeGenerator(),
    ArithmeticSequenceGenerator(),
    HalfChordGenerator(),
    MadhavaSeriesGenerator(),
    KuttakaGenerator(),
    CyclicQuadGenerator(),
    AnkapashaGenerator(),
  ])
    g.id: g,
};

/// A practice set: [count] problems with no repeats (plan §6.7).
/// [difficulties] gives one difficulty per problem; missing entries use 2.
List<Problem> generateSession(String generatorId, int sessionSeed, int count, {List<int>? difficulties}) {
  final g = generators[generatorId];
  if (g == null) throw ArgumentError('Unknown generator $generatorId');
  final seen = <String>{};
  final out = <Problem>[];
  for (var i = 0; i < count; i++) {
    final difficulty = (difficulties != null && i < difficulties.length) ? difficulties[i] : 2;
    for (var attempt = 0; ; attempt++) {
      final p = g.generate(mixSeed(sessionSeed, i * 1000 + attempt), difficulty);
      if (seen.add(p.key) || attempt >= 50) {
        out.add(p);
        break;
      }
    }
  }
  return out;
}
