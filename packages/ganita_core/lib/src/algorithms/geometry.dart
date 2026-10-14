import '../problem.dart';
import '../rational.dart';
import '../text.dart';
import 'roots.dart';

String _f(Rational x) => x.toMixedString();

String _root(Rational sq) {
  final e = exactSqrt(sq);
  return e != null ? _f(e) : '√${_f(sq)} ≈ ${(sq.toDouble()).toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '')}';
}

/// Bhuja-koṭi-karṇa (Līlāvatī 136): any two of side, upright and hypotenuse give the third.
/// Pass exactly two of the three.
Trace bhujaKotiKarna({Rational? bhuja, Rational? koti, Rational? karna}) {
  final given = [bhuja, koti, karna].where((x) => x != null).length;
  if (given != 2) throw ArgumentError('Give exactly two sides');
  if (karna == null) {
    final sq = bhuja! * bhuja + koti! * koti;
    return Trace(
      classical: [
        Step(
          const LText(
            'Square the side and the upright: {a} and {b}.',
            'ಭುಜ ಮತ್ತು ಕೋಟಿಯನ್ನು ವರ್ಗಿಸಿ: {a} ಮತ್ತು {b}.',
          ).fill({'a': _f(bhuja * bhuja), 'b': _f(koti * koti)}),
          working: '${_f(bhuja)}² = ${_f(bhuja * bhuja)},  ${_f(koti)}² = ${_f(koti * koti)}',
        ),
        Step(
          const LText('Add them: {s}.', 'ಕೂಡಿಸಿ: {s}.').fill({'s': _f(sq)}),
          working: '${_f(bhuja * bhuja)} + ${_f(koti * koti)} = ${_f(sq)}',
        ),
        Step(
          const LText('The square root is the hypotenuse: {c}.', 'ಅದರ ವರ್ಗಮೂಲವೇ ಕರ್ಣ: {c}.').fill({'c': _root(sq)}),
          values: {if (exactSqrt(sq) != null) 'karna': exactSqrt(sq)!},
        ),
      ],
      modern: [
        Step(
          const LText('', ''),
          working: 'c = √(a² + b²) = √(${_f(bhuja * bhuja)} + ${_f(koti * koti)}) = ${_root(sq)}',
        ),
      ],
      result: {if (exactSqrt(sq) != null) 'karna': exactSqrt(sq)!},
    );
  }
  final leg = bhuja ?? koti!;
  final legName = bhuja != null ? const LText('side', 'ಭುಜ') : const LText('upright', 'ಕೋಟಿ');
  final otherName = bhuja != null ? const LText('upright', 'ಕೋಟಿ') : const LText('side', 'ಭುಜ');
  final sq = karna * karna - leg * leg;
  if (sq.isNegative) throw ArgumentError('The hypotenuse must be the longest side');
  return Trace(
    classical: [
      Step(
        LText(
          'Square the hypotenuse and the ${legName.en}: ${_f(karna * karna)} and ${_f(leg * leg)}.',
          'ಕರ್ಣ ಮತ್ತು ${legName.kn} ವರ್ಗಿಸಿ: ${_f(karna * karna)} ಮತ್ತು ${_f(leg * leg)}.',
        ),
      ),
      Step(
        const LText('Take the difference: {d}.', 'ವ್ಯತ್ಯಾಸ ತೆಗೆದುಕೊಳ್ಳಿ: {d}.').fill({'d': _f(sq)}),
        working: '${_f(karna * karna)} − ${_f(leg * leg)} = ${_f(sq)}',
      ),
      Step(
        LText('Its square root is the ${otherName.en}: ${_root(sq)}.', 'ಅದರ ವರ್ಗಮೂಲವೇ ${otherName.kn}: ${_root(sq)}.'),
      ),
    ],
    modern: [Step(const LText('', ''), working: '√(${_f(karna)}² − ${_f(leg)}²) = ${_root(sq)}')],
    result: {if (exactSqrt(sq) != null) 'leg': exactSqrt(sq)!},
  );
}

/// Brahmagupta's exact area of a quadrilateral with its corners on a circle
/// (BSS 12.21), and the diagonal separating sides a, b from c, d (BSS 12.28).
Trace cyclicQuad(List<Rational> sides) {
  if (sides.length != 4) throw ArgumentError('Four sides');
  final [a, b, c, d] = sides;
  final s = (a + b + c + d) / r(2);
  final factors = [s - a, s - b, s - c, s - d];
  if (factors.any((x) => x <= Rational.zero)) {
    throw ArgumentError('Each side must be less than the sum of the others');
  }
  final product = factors.reduce((x, y) => x * y);
  final gross = (a + c) / r(2) * ((b + d) / r(2));
  final diagSq = (a * c + b * d) * (a * d + b * c) / (a * b + c * d);
  final area = exactSqrt(product);
  return Trace(
    classical: [
      Step(
        const LText(
          'Half the sum of the sides is {s}. Set it down four times.',
          'ಬಾಹುಗಳ ಮೊತ್ತದ ಅರ್ಧ {s}. ಅದನ್ನು ನಾಲ್ಕು ಕಡೆ ಬರೆಯಿರಿ.',
        ).fill({'s': _f(s)}),
        working: '(${sides.map(_f).join(' + ')}) ÷ 2 = ${_f(s)}',
        values: {'s': s},
      ),
      Step(
        const LText(
          'Take a side from each: {fs}.',
          'ಪ್ರತಿಯೊಂದರಿಂದ ಒಂದು ಬಾಹು ಕಳೆಯಿರಿ: {fs}.',
        ).fill({'fs': factors.map(_f).join(', ')}),
      ),
      Step(
        const LText('Multiply them: {p}.', 'ಅವನ್ನು ಗುಣಿಸಿ: {p}.').fill({'p': _f(product)}),
        working: '${factors.map(_f).join(' × ')} = ${_f(product)}',
      ),
      Step(
        const LText(
          'The square root is the exact area: {A}.',
          'ವರ್ಗಮೂಲವೇ ನಿಖರ ವಿಸ್ತೀರ್ಣ: {A}.',
        ).fill({'A': _root(product)}),
        values: {if (area != null) 'area': area},
      ),
      Step(
        const LText(
          'For comparison, the gross area (half sums of opposite sides multiplied) is {g}.',
          'ಹೋಲಿಕೆಗೆ, ಸ್ಥೂಲ ವಿಸ್ತೀರ್ಣ (ಎದುರು ಬಾಹುಗಳ ಮೊತ್ತದ ಅರ್ಧಗಳ ಗುಣಲಬ್ಧ) {g}.',
        ).fill({'g': _f(gross)}),
      ),
      Step(
        const LText(
          'The diagonal between the first two sides and the last two is {p}.',
          'ಮೊದಲ ಎರಡು ಮತ್ತು ಕೊನೆಯ ಎರಡು ಬಾಹುಗಳನ್ನು ಬೇರ್ಪಡಿಸುವ ಕರ್ಣ {p}.',
        ).fill({'p': _root(diagSq)}),
        working: '√((ac + bd)(ad + bc) ÷ (ab + cd)) = ${_root(diagSq)}',
      ),
    ],
    modern: [Step(const LText('', ''), working: 's = ${_f(s)},  A = √((s−a)(s−b)(s−c)(s−d)) = ${_root(product)}')],
    result: {'s': s, if (area != null) 'area': area, if (exactSqrt(diagSq) != null) 'diagonal': exactSqrt(diagSq)!},
  );
}
