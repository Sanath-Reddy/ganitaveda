import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

void main() {
  test('iṣṭa-karma solves the bee swarm (Līlāvatī 55) from a guess of 30', () {
    final t = ishtaKarma(partA: r(1, 5), partB: r(1, 3), multiplier: 3, remainder: r(1), guess: r(30));
    expect(t.result['left'], r(2));
    expect(t.result['answer'], r(15));
    // Any guess gives the same answer.
    final t2 = ishtaKarma(partA: r(1, 5), partB: r(1, 3), multiplier: 3, remainder: r(1), guess: r(1));
    expect(t2.result['answer'], r(15));
  });

  test("Brahmagupta's sign rules", () {
    final t = signRules(a: r(5), b: r(-3));
    expect(t.result['+'], r(2));
    expect(t.result['−'], r(8));
    expect(t.result['×'], r(-15));
    expect(t.result['÷'], r(-5, 3));
    expect(ruleFor('×', r(-2), r(-3)).en, contains('fortune'));
  });

  test('bhuja-koṭi-karṇa (Līlāvatī 137: 3, 4 → 5)', () {
    expect(bhujaKotiKarna(bhuja: r(3), koti: r(4)).result['karna'], r(5));
    expect(bhujaKotiKarna(bhuja: r(3), karna: r(5)).result['leg'], r(4));
    expect(() => bhujaKotiKarna(bhuja: r(3)), throwsArgumentError);
  });

  test('trairāśika: saffron (Līlāvatī 74) and the inverse rule', () {
    expect(trairashika(pramana: r(3, 7), phala: r(5, 2), iccha: r(9)).result['answer'], r(105, 2));
    expect(trairashika(pramana: r(4), phala: r(12), iccha: r(6), inverse: true).result['answer'], r(8));
  });

  test('śreḍhī: alms (Līlāvatī 122): first 4, increase 5, 15 days', () {
    final t = sredhi(adi: r(4), caya: r(5), gaccha: 15);
    expect(t.result['last'], r(74));
    expect(t.result['middle'], r(39));
    expect(t.result['sum'], r(585)); // as in Colebrooke §120
  });

  test("Āryabhaṭa's half-chord rule: differences start 225, 224, 222, 219", () {
    final rows = jyaTable();
    expect(rows.take(4).map((r) => r.difference), [225, 224, 222, 219]);
    expect(rows.length, 24);
    // Read with the divisor 225, the rule stays within 2% of the true values
    // and ends a little short of the radius (the trace says so).
    for (final row in rows) {
      expect((row.halfChord - row.modern).abs() / row.modern, lessThan(0.02));
    }
    expect(rows.last.halfChord, lessThan(3438));
    expect(jyaTrace().classical.last.text.en, contains('short of the radius'));
  });

  test("Mādhava's series with the end correction", () {
    expect(madhavaSum(1).pi, r(4));
    expect(madhavaSum(2).pi, r(8, 3));
    expect(madhavaSum(2).corrected, r(160, 51));
    // The correction makes a few terms very close to π.
    final m = madhavaSum(10);
    expect((m.corrected.toDouble() - 3.141592653589793).abs(), lessThan(1e-5));
    expect((m.pi.toDouble() - 3.141592653589793).abs(), greaterThan(0.09));
  });

  test("kuṭṭaka: Bhāskara's example 221x + 65 = 195y gives 5 and 6", () {
    final k = kuttaka(221, 195, 65)!;
    expect(k.common, 13);
    expect(k.quotients, [1, 7]);
    expect(k.valli.first, [1, 7, 5, 0]);
    expect(k.valli.last, [40, 35]);
    expect(k.multiplier, 5);
    expect(k.quotient, 6);
    expect(kuttaka(6, 4, 3), isNull, reason: 'ill-put: 2 does not divide 3');
  });

  test('kuṭṭaka rule always gives a true smallest answer', () {
    for (var a = 1; a <= 60; a++) {
      for (var b = 2; b <= 40; b++) {
        for (final c in [0, 1, 7, 23, 60]) {
          final k = kuttaka(a, b, c);
          final g = gcd(a, b);
          if (c % g != 0) {
            expect(k, isNull);
            continue;
          }
          expect((a * k!.multiplier + c) % b, 0, reason: '$a $b $c');
          final smallest = List.generate(b, (x) => x).firstWhere((x) => (a * x + c) % b == 0);
          expect(k.multiplier, smallest, reason: '$a $b $c');
        }
      }
    }
  });

  test("Brahmagupta's quadrilateral 25, 39, 52, 60", () {
    final t = cyclicQuad([r(25), r(39), r(52), r(60)]);
    expect(t.result['s'], r(88));
    expect(t.result['area'], r(1764));
    expect(t.result['diagonal'], r(56));
  });

  test('aṅkapāśa (Līlāvatī 262)', () {
    expect(ankapasha([2, 8]).count, BigInt.from(2));
    expect(ankapasha([2, 8]).sum, BigInt.from(110));
    expect(ankapasha([3, 9, 8]).count, BigInt.from(6));
    expect(ankapasha([3, 9, 8]).sum, BigInt.from(4440));
    expect(ankapasha([2, 3, 4, 5, 6, 7, 8, 9]).count, BigInt.from(40320));
    expect(ankapasha([2, 2, 1, 1]).count, BigInt.from(6));
    // Brute force agrees on repeated digits.
    final nums = <int>{};
    void perm(List<int> left, int acc) {
      if (left.isEmpty) {
        nums.add(acc);
        return;
      }
      for (var i = 0; i < left.length; i++) {
        perm([...left]..removeAt(i), acc * 10 + left[i]);
      }
    }

    perm([2, 2, 1, 1, 5], 0);
    expect(ankapasha([2, 2, 1, 1, 5]).count, BigInt.from(nums.length));
    expect(ankapasha([2, 2, 1, 1, 5]).sum, BigInt.from(nums.reduce((a, b) => a + b)));
  });
}
