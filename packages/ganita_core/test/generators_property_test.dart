/// Generator property tests (plan §6.7): every generator, 1,000 seeds, every
/// difficulty. Answers are valid and checkable, numbers stay in range, text
/// is complete in both languages, and a session never repeats a problem.
import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

const seeds = 1000;
final _placeholder = RegExp(r'\{\w+\}');

void main() {
  const checker = AnswerChecker();

  for (final g in generators.values) {
    group(g.id, () {
      for (final difficulty in [1, 2, 3]) {
        test('difficulty $difficulty: $seeds seeds', () {
          for (var seed = 0; seed < seeds; seed++) {
            final p = g.generate(seed, difficulty);
            final where = '${g.id} seed $seed d$difficulty: ${p.prompt.en}';

            // Deterministic.
            expect(g.generate(seed, difficulty).key, p.key, reason: where);

            // Both languages, no unfilled placeholders, no stray markers.
            for (final text in [p.prompt, ...p.hints]) {
              expect(text.en.trim(), isNotEmpty, reason: where);
              expect(text.kn.trim(), isNotEmpty, reason: where);
              expect(_placeholder.hasMatch(text.en) || _placeholder.hasMatch(text.kn), isFalse, reason: where);
              expect(text.en.contains('\u0000') || text.kn.contains('\u0000'), isFalse, reason: where);
            }
            expect(RegExp('[ಀ-೿]').hasMatch(p.prompt.kn), isTrue, reason: 'Kannada prompt: $where');
            expect(p.hints, hasLength(3), reason: where);

            // The answer is a sensible size and the checker accepts its own canonical form.
            final v = p.answer.value;
            expect(v.abs() <= r(10000000000000), isTrue, reason: where);
            if (p.answer.form == AnswerForm.integer) {
              expect(v.isInteger, isTrue, reason: where);
            }
            expect(checker.check(p.answer.canonical, p.answer).verdict, Verdict.correct, reason: where);
            expect(checker.check(v.toString(), p.answer).verdict, Verdict.correct, reason: where);
            expect(checker.check('${(v + Rational.one)}', p.answer).isCorrect, isFalse, reason: where);

            // The full-solution hint ends with the answer.
            expect(p.hints.last.en, endsWith('Answer: ${p.answer.canonical}'), reason: where);
            expect(p.solution.classical, isNotEmpty, reason: where);
          }
        });
      }

      test('sessions never repeat a problem', () {
        for (var session = 0; session < 200; session++) {
          final set = generateSession(g.id, session, 5, difficulties: [1, 2, 2, 3, 3]);
          expect(set.map((p) => p.key).toSet(), hasLength(5), reason: '${g.id} session $session');
        }
      });
    });
  }

  test('specific answers are right, not just consistent', () {
    // Recompute each generator's answer independently from its data.
    for (var seed = 0; seed < seeds; seed++) {
      final bees = generators['fractions.remainder.v1']!.generate(seed, 2);
      final pa = Rational.parse(bees.data['pa'] as String), pb = Rational.parse(bees.data['pb'] as String);
      final m = bees.data['m'] as int, whole = r(bees.data['whole'] as int);
      final left = whole - whole * pa - whole * pb - (whole * pb - whole * pa).abs() * r(m);
      expect(left > Rational.zero && left.isInteger, isTrue);
      expect((whole * pa).isInteger && (whole * pb).isInteger, isTrue, reason: 'groups are whole');

      final tri = generators['geometry.right_triangle.v1']!.generate(seed, 1);
      final a = tri.data['a'] as int, b = tri.data['b'] as int, c = tri.data['c'] as int;
      expect(a * a + b * b, c * c);
      expect(tri.answer.value, r(c));

      final kt = generators['number_theory.kuttaka.v1']!.generate(seed, 2);
      final x = kt.answer.value.toInt();
      expect(((kt.data['a'] as int) * x + (kt.data['c'] as int)) % (kt.data['b'] as int), 0);

      final crt = generators['number_theory.kuttaka.v1']!.generate(seed, 3);
      final n = crt.answer.value.toInt();
      expect(n % (crt.data['d1'] as int), crt.data['r1']);
      expect(n % (crt.data['d2'] as int), crt.data['r2']);
      for (var smaller = 0; smaller < n; smaller++) {
        expect(
          smaller % (crt.data['d1'] as int) == crt.data['r1'] && smaller % (crt.data['d2'] as int) == crt.data['r2'],
          isFalse,
        );
      }

      final quad = generators['geometry.cyclic_quad.v1']!.generate(seed, 2);
      final sides = (quad.data['sides'] as String).split(', ').map(int.parse).toList();
      final s = r(sides.reduce((x, y) => x + y), 2);
      final product = sides.map((x) => s - r(x)).reduce((x, y) => x * y);
      expect(quad.answer.value * quad.answer.value, product);
    }
  });
}
