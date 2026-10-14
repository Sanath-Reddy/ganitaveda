import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every lesson id gives a single closed curve, the same one each time', () {
    for (var i = 0; i < 300; i++) {
      final id = 'lesson.test-$i';
      final a = KolamMotif.generate(seedFromId(id));
      final b = KolamMotif.generate(seedFromId(id));
      expect(a.path, b.path);
      // A single curve passes every inner midpoint twice and every boundary one once.
      final counts = <Offset, int>{};
      for (final p in a.path) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
      for (final e in counts.entries) {
        final boundary = e.key.dx == 0 || e.key.dy == 0 || e.key.dx == 2 * a.width || e.key.dy == 2 * a.height;
        expect(e.value, boundary ? 1 : 2, reason: '$id ${e.key}');
      }
      expect(a.mirrors, isNotEmpty, reason: 'generated motifs use inner mirrors: $id');
    }
  });

  test('layouts that split into several curves are rejected', () {
    // A 2×2 grid with no inner mirrors makes more than one loop.
    expect(KolamMotif.traceSingle(2, 2, const {}), isNull);
    // A 1×n strip with no mirrors is one loop.
    expect(KolamMotif.traceSingle(1, 3, const {}), isNotNull);
  });
}
