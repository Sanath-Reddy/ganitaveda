import '../problem.dart';
import '../rational.dart';
import '../text.dart';
import 'roots.dart';

/// Result of the pulveriser: the smallest whole x ≥ 0 with a·x + c divisible
/// by b, and the quotient y = (a·x + c) / b.
class KuttakaResult {
  final int a, b, c;
  final int common;
  final List<int> quotients;

  /// The vallī column as it shrinks: each entry is the column after one step.
  final List<List<int>> valli;
  final int multiplier;
  final int quotient;

  const KuttakaResult(this.a, this.b, this.c, this.common, this.quotients, this.valli, this.multiplier, this.quotient);
}

/// Bhāskara's kuṭṭaka (Līlāvatī 242–247, after Āryabhaṭīya 2.32–33):
/// reduce by the common divisor, divide mutually until the remainder is 1,
/// set the quotients in a column with the additive and zero below, fold the
/// column upwards, and reduce. If the number of quotients is odd, the results
/// are taken from the reduced divisor and dividend.
///
/// Returns null when a and b share a factor that does not divide c
/// (an "ill-put" question).
KuttakaResult? kuttaka(int a, int b, int c) {
  if (a <= 0 || b <= 0) throw ArgumentError('Dividend and divisor must be positive');
  final g = gcd(a, b);
  if (c % g != 0) return null;
  final a1 = a ~/ g, b1 = b ~/ g, c1 = c ~/ g;
  if (b1 == 1) {
    // Every x works; the smallest is 0.
    return KuttakaResult(a, b, c, g, const [], const [], 0, c ~/ b);
  }

  // Mutual division of the reduced dividend and divisor until the remainder is 1.
  final quotients = <int>[];
  var x = a1, y = b1;
  while (true) {
    quotients.add(x ~/ y);
    final rem = x % y;
    if (rem == 1 || rem == 0) break;
    x = y;
    y = rem;
  }

  var column = [...quotients, c1, 0];
  final valli = <List<int>>[List.of(column)];
  while (column.length > 2) {
    final n = column.length;
    final upper = column[n - 3] * column[n - 2] + column[n - 1];
    column = [...column.sublist(0, n - 3), upper, column[n - 2]];
    valli.add(List.of(column));
  }
  final top = column[0], bottom = column[1];

  int mod(int v, int m) => ((v % m) + m) % m;
  int xs, ys;
  if (quotients.length.isEven) {
    ys = mod(top, a1);
    xs = mod(bottom, b1);
  } else {
    ys = mod(a1 - mod(top, a1), a1);
    xs = mod(b1 - mod(bottom, b1), b1);
  }
  // The rule fixes x modulo b1; take the smallest and recompute the quotient
  // exactly from the original numbers, then check it.
  if ((a1 * xs + c1) % b1 != 0) {
    throw StateError('kuṭṭaka rule failed for $a, $b, $c');
  }
  final quotient = (a * xs + c) ~/ b;
  if (mod(quotient, a1) != ys) {
    throw StateError('kuṭṭaka quotient disagrees for $a, $b, $c');
  }
  return KuttakaResult(a, b, c, g, quotients, valli, xs, quotient);
}

Trace kuttakaTrace(int a, int b, int c) {
  final k = kuttaka(a, b, c);
  if (k == null) {
    return Trace(
      classical: [
        Step(
          LText(
            '$a and $b share the factor ${gcd(a, b)}, which does not divide $c. Bhāskara calls this an ill-put question: there is no answer.',
            '$a ಮತ್ತು $b ಗೆ ಸಾಮಾನ್ಯ ಅಪವರ್ತನ ${gcd(a, b)} ಇದೆ, ಅದು $c ಅನ್ನು ಭಾಗಿಸುವುದಿಲ್ಲ. ಭಾಸ್ಕರ ಇದನ್ನು ತಪ್ಪಾಗಿ ಕೇಳಿದ ಪ್ರಶ್ನೆ ಎನ್ನುತ್ತಾನೆ: ಉತ್ತರವಿಲ್ಲ.',
          ),
        ),
      ],
    );
  }
  final a1 = a ~/ k.common, b1 = b ~/ k.common, c1 = c ~/ k.common;
  return Trace(
    classical: [
      if (k.common > 1)
        Step(
          LText(
            'Divide dividend, divisor and additive by their common factor ${k.common}: $a1, $b1, $c1.',
            'ಭಾಜ್ಯ, ಭಾಜಕ ಮತ್ತು ಕ್ಷೇಪವನ್ನು ಸಾಮಾನ್ಯ ಅಪವರ್ತನ ${k.common} ರಿಂದ ಭಾಗಿಸಿ: $a1, $b1, $c1.',
          ),
        ),
      if (k.quotients.isNotEmpty)
        Step(
          LText(
            'Divide $a1 and $b1 into each other until the remainder is 1. The quotients are ${k.quotients.join(', ')}.',
            '$a1 ಮತ್ತು $b1 ಅನ್ನು ಶೇಷ 1 ಆಗುವವರೆಗೆ ಪರಸ್ಪರ ಭಾಗಿಸಿ. ಭಾಗಲಬ್ಧಗಳು ${k.quotients.join(', ')}.',
          ),
        ),
      if (k.valli.isNotEmpty)
        Step(
          LText(
            'Write them in a column with the additive $c1 and 0 below: ${k.valli.first.join(' / ')}.',
            'ಅವನ್ನು ಕಂಬಸಾಲಿನಲ್ಲಿ ಬರೆದು ಕೆಳಗೆ ಕ್ಷೇಪ $c1 ಮತ್ತು 0 ಬರೆಯಿರಿ: ${k.valli.first.join(' / ')}.',
          ),
        ),
      for (final col in k.valli.skip(1))
        Step(
          LText(
            'Multiply the number above the last-but-one by it and add the last: ${col.join(' / ')}.',
            'ಕೊನೆಯ ಹಿಂದಿನದರ ಮೇಲಿರುವ ಸಂಖ್ಯೆಯನ್ನು ಅದರಿಂದ ಗುಣಿಸಿ ಕೊನೆಯದನ್ನು ಕೂಡಿಸಿ: ${col.join(' / ')}.',
          ),
        ),
      if (k.quotients.length.isOdd)
        Step(
          const LText(
            'There is an odd number of quotients, so take the results away from the reduced divisor and dividend.',
            'ಭಾಗಲಬ್ಧಗಳ ಸಂಖ್ಯೆ ಬೆಸ, ಆದ್ದರಿಂದ ಫಲಗಳನ್ನು ಕಡಿಮೆಗೊಳಿಸಿದ ಭಾಜಕ ಮತ್ತು ಭಾಜ್ಯದಿಂದ ಕಳೆಯಿರಿ.',
          ),
        ),
      Step(
        LText(
          'Reduce by $b1: the multiplier is ${k.multiplier}, and the quotient is ${k.quotient}.',
          '$b1 ರಿಂದ ಶೇಷ ತೆಗೆಯಿರಿ: ಗುಣಕ ${k.multiplier}, ಲಬ್ಧಿ ${k.quotient}.',
        ),
        values: {'multiplier': r(k.multiplier), 'quotient': r(k.quotient)},
      ),
      Step(
        LText(
          'Check: $a × ${k.multiplier} + $c = ${a * k.multiplier + c} = $b × ${k.quotient}.',
          'ಪರಿಶೀಲನೆ: $a × ${k.multiplier} + $c = ${a * k.multiplier + c} = $b × ${k.quotient}.',
        ),
      ),
    ],
    modern: [
      Step(
        const LText('', ''),
        working: '${a}x + $c = ${b}y  →  x = ${k.multiplier} + ${b1}t,  y = ${k.quotient} + ${a1}t',
      ),
    ],
    result: {'multiplier': r(k.multiplier), 'quotient': r(k.quotient)},
  );
}

/// Aṅkapāśa (Līlāvatī 261–264): how many numbers the digits make, and their sum.
/// Repeated digits divide the count by the arrangements of the repeats.
class AnkapashaResult {
  final BigInt count;
  final BigInt sum;

  const AnkapashaResult(this.count, this.sum);
}

AnkapashaResult ankapasha(List<int> digits) {
  final n = digits.length;
  if (n == 0) throw ArgumentError('No digits');
  var count = factorial(n);
  final reps = <int, int>{};
  for (final d in digits) {
    reps[d] = (reps[d] ?? 0) + 1;
  }
  for (final k in reps.values) {
    count ~/= factorial(k);
  }
  final digitSum = BigInt.from(digits.fold<int>(0, (s, d) => s + d));
  final repunit = BigInt.parse('1' * n);
  final sum = count * digitSum * repunit ~/ BigInt.from(n);
  return AnkapashaResult(count, sum);
}

Trace ankapashaTrace(List<int> digits) {
  final n = digits.length;
  final res = ankapasha(digits);
  final hasRepeats = digits.toSet().length != n;
  final chain = List.generate(n, (i) => '${i + 1}').join(' × ');
  final digitSum = digits.fold<int>(0, (s, d) => s + d);
  return Trace(
    classical: [
      Step(
        LText(
          'There are $n places. Multiply 1, 2, … up to $n: $chain = ${factorial(n)}.',
          '$n ಸ್ಥಾನಗಳಿವೆ. 1, 2, … $n ವರೆಗೆ ಗುಣಿಸಿ: $chain = ${factorial(n)}.',
        ),
      ),
      if (hasRepeats)
        Step(
          LText(
            'Some digits repeat; divide by the arrangements of the repeated ones: ${res.count} numbers.',
            'ಕೆಲವು ಅಂಕಿಗಳು ಪುನರಾವರ್ತಿಸುತ್ತವೆ; ಪುನರಾವರ್ತಿತವುಗಳ ಜೋಡಣೆಗಳಿಂದ ಭಾಗಿಸಿ: ${res.count} ಸಂಖ್ಯೆಗಳು.',
          ),
        ),
      Step(
        LText(
          'Divide the count by the number of digits and multiply by their sum $digitSum: ${res.count * BigInt.from(digitSum) ~/ BigInt.from(n)}. That is what each place adds up to.',
          'ಎಣಿಕೆಯನ್ನು ಅಂಕಿಗಳ ಸಂಖ್ಯೆಯಿಂದ ಭಾಗಿಸಿ, ಅವುಗಳ ಮೊತ್ತ $digitSum ರಿಂದ ಗುಣಿಸಿ: ${res.count * BigInt.from(digitSum) ~/ BigInt.from(n)}. ಪ್ರತಿ ಸ್ಥಾನದ ಮೊತ್ತ ಇದು.',
        ),
      ),
      Step(
        LText(
          'Set that down in each of the $n places and add: ${res.sum}.',
          'ಅದನ್ನು $n ಸ್ಥಾನಗಳಲ್ಲೂ ಬರೆದು ಕೂಡಿಸಿ: ${res.sum}.',
        ),
        values: {'count': Rational(res.count), 'sum': Rational(res.sum)},
      ),
    ],
    modern: [
      Step(
        const LText('', ''),
        working:
            '${hasRepeats ? 'n!/(k₁!k₂!…)' : '$n!'} = ${res.count},  sum = ${res.count}/$n × $digitSum × ${'1' * n} = ${res.sum}',
      ),
    ],
    result: {'count': Rational(res.count), 'sum': Rational(res.sum)},
  );
}
