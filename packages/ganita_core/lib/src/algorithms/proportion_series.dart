import 'dart:math' as math;

import '../problem.dart';
import '../rational.dart';
import '../text.dart';

String _f(Rational x) => x.toMixedString();

/// Trairāśika (Āryabhaṭīya 2.26, Līlāvatī 73): fruit of the desire = fruit × desire ÷ measure.
/// With [inverse], the vyasta form: measure × fruit ÷ desire.
Trace trairashika({required Rational pramana, required Rational phala, required Rational iccha, bool inverse = false}) {
  final result = inverse ? pramana * phala / iccha : phala * iccha / pramana;
  final classical = [
    Step(
      const LText(
        'Measure {p}, fruit {f}, desire {i}. Measure and desire are the same kind of thing.',
        'ಪ್ರಮಾಣ {p}, ಫಲ {f}, ಇಚ್ಛಾ {i}. ಪ್ರಮಾಣ ಮತ್ತು ಇಚ್ಛಾ ಒಂದೇ ಜಾತಿಯವು.',
      ).fill({'p': _f(pramana), 'f': _f(phala), 'i': _f(iccha)}),
    ),
    if (!inverse) ...[
      Step(
        const LText(
          'Multiply the fruit by the desire: {x}.',
          'ಫಲವನ್ನು ಇಚ್ಛೆಯಿಂದ ಗುಣಿಸಿ: {x}.',
        ).fill({'x': _f(phala * iccha)}),
        working: '${_f(phala)} × ${_f(iccha)} = ${_f(phala * iccha)}',
      ),
      Step(
        const LText(
          'Divide by the measure: {x}. That is the fruit of the desire.',
          'ಪ್ರಮಾಣದಿಂದ ಭಾಗಿಸಿ: {x}. ಅದೇ ಇಚ್ಛಾಫಲ.',
        ).fill({'x': _f(result)}),
        working: '${_f(phala * iccha)} ÷ ${_f(pramana)} = ${_f(result)}',
      ),
    ] else ...[
      Step(
        const LText(
          'More of the desire gives less fruit, so the rule is reversed: multiply measure by fruit: {x}.',
          'ಇಚ್ಛೆ ಹೆಚ್ಚಾದಂತೆ ಫಲ ಕಡಿಮೆ, ಆದ್ದರಿಂದ ನಿಯಮ ತಿರುಗುತ್ತದೆ: ಪ್ರಮಾಣವನ್ನು ಫಲದಿಂದ ಗುಣಿಸಿ: {x}.',
        ).fill({'x': _f(pramana * phala)}),
        working: '${_f(pramana)} × ${_f(phala)} = ${_f(pramana * phala)}',
      ),
      Step(
        const LText('Divide by the desire: {x}.', 'ಇಚ್ಛೆಯಿಂದ ಭಾಗಿಸಿ: {x}.').fill({'x': _f(result)}),
        working: '${_f(pramana * phala)} ÷ ${_f(iccha)} = ${_f(result)}',
      ),
    ],
  ];
  final modern = [
    Step(
      const LText('', ''),
      working: inverse
          ? '${_f(pramana)} × ${_f(phala)} = ${_f(iccha)} × x,  x = ${_f(result)}'
          : '${_f(pramana)} : ${_f(phala)} = ${_f(iccha)} : x,  x = ${_f(result)}',
    ),
  ];
  return Trace(classical: classical, modern: modern, result: {'answer': result});
}

/// Śreḍhī (Āryabhaṭīya 2.19, Līlāvatī 121): last, middle and sum of an arithmetic progression.
Trace sredhi({required Rational adi, required Rational caya, required int gaccha}) {
  if (gaccha < 1) throw ArgumentError.value(gaccha, 'gaccha');
  final n = r(gaccha);
  final last = adi + caya * (n - Rational.one);
  final middle = (adi + last) / r(2);
  final sum = middle * n;
  return Trace(
    classical: [
      Step(
        const LText(
          'Increase × (terms − 1), plus the first term, is the last term: {l}.',
          'ಹೆಚ್ಚಳ × (ಪದಗಳು − 1), ಮೊದಲ ಪದ ಸೇರಿಸಿದರೆ ಕೊನೆಯ ಪದ: {l}.',
        ).fill({'l': _f(last)}),
        working: '${_f(caya)} × ${gaccha - 1} + ${_f(adi)} = ${_f(last)}',
        values: {'last': last},
      ),
      Step(
        const LText(
          'First plus last, halved, is the middle term: {m}.',
          'ಮೊದಲ ಮತ್ತು ಕೊನೆಯ ಪದಗಳ ಮೊತ್ತದ ಅರ್ಧ ಮಧ್ಯ ಪದ: {m}.',
        ).fill({'m': _f(middle)}),
        working: '(${_f(adi)} + ${_f(last)}) ÷ 2 = ${_f(middle)}',
        values: {'middle': middle},
      ),
      Step(
        const LText(
          'The middle term times the number of terms is the sum: {s}.',
          'ಮಧ್ಯ ಪದ × ಪದಗಳ ಸಂಖ್ಯೆ = ಮೊತ್ತ: {s}.',
        ).fill({'s': _f(sum)}),
        working: '${_f(middle)} × $gaccha = ${_f(sum)}',
        values: {'sum': sum},
      ),
    ],
    modern: [
      Step(const LText('', ''), working: 'aₙ = a + (n − 1)d = ${_f(last)}'),
      Step(const LText('', ''), working: 'Sₙ = n(a + aₙ)/2 = ${_f(sum)}'),
    ],
    result: {'last': last, 'middle': middle, 'sum': sum},
  );
}

/// Āryabhaṭa's table of half-chords by differences (Āryabhaṭīya 2.12), beside
/// the modern values R·sin θ. Values are rounded to whole units as in the
/// tradition; display only, never used as an answer.
class JyaRow {
  final int index;
  final double arcMinutes;
  final int difference;
  final int halfChord;
  final double modern;

  const JyaRow(this.index, this.arcMinutes, this.difference, this.halfChord, this.modern);
}

List<JyaRow> jyaTable({int radius = 3438, int steps = 24}) {
  final arc = 5400.0 / steps; // a quarter circle is 5400 minutes
  final first = (radius * math.sin(arc / 60 * math.pi / 180)).round();
  final rows = <JyaRow>[];
  var sum = 0;
  var current = 0;
  for (var k = 1; k <= steps; k++) {
    final diff = k == 1 ? first : (first - sum / first).round();
    current += diff;
    sum += current;
    rows.add(JyaRow(k, arc * k, diff, current, radius * math.sin(arc * k / 60 * math.pi / 180)));
  }
  return rows;
}

Trace jyaTrace({int radius = 3438, int steps = 24}) {
  final rows = jyaTable(radius: radius, steps: steps);
  final first = rows.first.difference;
  return Trace(
    classical: [
      Step(
        const LText(
          'Divide the quarter circle into {n} arcs. The first half-chord is about the arc itself: {d}.',
          'ಕಾಲು ವೃತ್ತವನ್ನು {n} ಚಾಪಗಳಾಗಿ ವಿಭಾಗಿಸಿ. ಮೊದಲ ಅರ್ಧಜ್ಯಾ ಸುಮಾರು ಆ ಚಾಪದಷ್ಟೇ: {d}.',
        ).fill({'n': steps, 'd': first}),
      ),
      for (final row in rows.skip(1).take(3))
        Step(
          const LText(
            'Next difference: {d0} − (sum so far ÷ {d0}) = {d}; half-chord {h}.',
            'ಮುಂದಿನ ವ್ಯತ್ಯಾಸ: {d0} − (ಇಲ್ಲಿಯವರೆಗಿನ ಮೊತ್ತ ÷ {d0}) = {d}; ಅರ್ಧಜ್ಯಾ {h}.',
          ).fill({'d0': first, 'd': row.difference, 'h': row.halfChord}),
        ),
      Step(
        const LText(
          'Carried to the end of the quadrant, the rule as read here reaches {h}, a little short of the radius {R}. '
              "Āryabhaṭa's own table ends at the radius; as Clark notes, exactly how he worked it out is not known.",
          'ಇಲ್ಲಿ ಓದಿದಂತೆ ನಿಯಮವನ್ನು ಕಾಲು ವೃತ್ತದ ಕೊನೆಯವರೆಗೆ ಮುಂದುವರಿಸಿದರೆ {h} ಸಿಗುತ್ತದೆ, ತ್ರಿಜ್ಯ {R} ಗಿಂತ ಸ್ವಲ್ಪ ಕಡಿಮೆ. '
              'ಆರ್ಯಭಟನ ಕೋಷ್ಟಕ ತ್ರಿಜ್ಯದಲ್ಲೇ ಕೊನೆಗೊಳ್ಳುತ್ತದೆ; ಅವನು ಅದನ್ನು ನಿಖರವಾಗಿ ಹೇಗೆ ಲೆಕ್ಕ ಮಾಡಿದ ಎಂಬುದು ತಿಳಿದಿಲ್ಲ ಎಂದು ಕ್ಲಾರ್ಕ್ ಹೇಳುತ್ತಾರೆ.',
        ).fill({'h': rows.last.halfChord, 'R': radius}),
      ),
    ],
    modern: [
      for (final row in [rows[0], rows[steps ~/ 3 - 1], rows.last])
        Step(
          const LText('', ''),
          working:
              '${radius} · sin ${(row.arcMinutes / 60).toStringAsFixed(2)}° ≈ ${row.modern.toStringAsFixed(1)}  (rule: ${row.halfChord})',
        ),
    ],
  );
}

/// Mādhava's series π = 4(1 − 1/3 + 1/5 − …) with the end correction n/(4n² + 1),
/// in exact fractions (attributed to Mādhava; plan lesson 7).
class MadhavaSum {
  final int terms;
  final Rational quarterSum;
  final Rational correction;

  const MadhavaSum(this.terms, this.quarterSum, this.correction);

  Rational get pi => quarterSum * r(4);
  Rational get corrected => (quarterSum + correction) * r(4);
}

MadhavaSum madhavaSum(int n) {
  if (n < 1) throw ArgumentError.value(n, 'n');
  var s = Rational.zero;
  for (var k = 0; k < n; k++) {
    final term = r(1, 2 * k + 1);
    s = k.isEven ? s + term : s - term;
  }
  final mag = r(n, 4 * n * n + 1);
  final correction = n.isEven ? mag : -mag; // the sign of the next term
  return MadhavaSum(n, s, correction);
}

Trace madhavaTrace(int n) {
  final steps = <Step>[];
  for (var k = 1; k <= n; k++) {
    final m = madhavaSum(k);
    steps.add(
      Step(
        LText(
          'After $k term${k == 1 ? '' : 's'}: π ≈ ${_f(m.pi)} ≈ ${m.pi.toDecimalString(5)}',
          '$k ಪದ${k == 1 ? '' : 'ಗಳ'} ನಂತರ: π ≈ ${_f(m.pi)} ≈ ${m.pi.toDecimalString(5)}',
        ),
        values: {'pi': m.pi},
      ),
    );
  }
  final last = madhavaSum(n);
  steps.add(
    Step(
      LText(
        'Add the correction ${_f(last.correction)} before multiplying by 4: π ≈ ${last.corrected.toDecimalString(5)}',
        'ತಿದ್ದುಪಡಿ ${_f(last.correction)} ಸೇರಿಸಿ ನಂತರ 4 ರಿಂದ ಗುಣಿಸಿ: π ≈ ${last.corrected.toDecimalString(5)}',
      ),
      values: {'corrected': last.corrected},
    ),
  );
  return Trace(
    classical: steps,
    modern: [
      Step(const LText('', ''), working: 'π/4 = 1 − 1/3 + 1/5 − 1/7 + …  ≈ ${math.pi.toStringAsFixed(5)} × 1/4'),
    ],
    result: {'pi': last.pi, 'corrected': last.corrected},
  );
}
