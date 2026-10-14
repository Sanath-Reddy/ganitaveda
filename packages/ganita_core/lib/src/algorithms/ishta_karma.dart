import '../problem.dart';
import '../rational.dart';
import '../text.dart';

String _f(Rational x) => x.toMixedString();

/// Iṣṭa-karma, the rule of supposition (Līlāvatī 51), for "parts of a whole
/// go away, plus [multiplier] times the difference of the two parts; [remainder]
/// is left". With [multiplier] 0 there is no difference term.
///
/// Classical: try [guess], see what is left, then answer = guess × remainder ÷ left.
Trace ishtaKarma({
  required Rational partA,
  required Rational partB,
  required int multiplier,
  required Rational remainder,
  required Rational guess,
}) {
  final a = guess * partA;
  final b = guess * partB;
  final diff = (b - a).abs();
  final third = diff * r(multiplier);
  final gone = a + b + third;
  final left = guess - gone;
  if (left <= Rational.zero) {
    throw ArgumentError('Nothing is left over with these parts');
  }
  final answer = guess * remainder / left;
  final ansA = answer * partA, ansB = answer * partB;
  final ansThird = (ansB - ansA).abs() * r(multiplier);
  final fractionLeft = Rational.one - partA - partB - (partB - partA).abs() * r(multiplier);

  final classical = <Step>[
    Step(
      const LText('Suppose the whole is {g}.', 'ಒಟ್ಟು {g} ಎಂದು ಊಹಿಸಿ.').fill({'g': _f(guess)}),
      values: {'guess': guess},
    ),
    Step(
      const LText(
        '{pa} of {g} is {a}; {pb} of {g} is {b}.',
        '{g} ರ {pa} = {a}; {g} ರ {pb} = {b}.',
      ).fill({'pa': _f(partA), 'pb': _f(partB), 'g': _f(guess), 'a': _f(a), 'b': _f(b)}),
      working: '${_f(guess)} × ${_f(partA)} = ${_f(a)},  ${_f(guess)} × ${_f(partB)} = ${_f(b)}',
      values: {'a': a, 'b': b},
    ),
    if (multiplier > 0)
      Step(
        const LText(
          'Their difference is {d}; {m} times that is {t}.',
          'ಅವುಗಳ ವ್ಯತ್ಯಾಸ {d}; ಅದರ {m} ಪಟ್ಟು {t}.',
        ).fill({'d': _f(diff), 'm': multiplier, 't': _f(third)}),
        working: '${_f(diff)} × $multiplier = ${_f(third)}',
        values: {'third': third},
      ),
    Step(
      const LText(
        'Altogether {gone} have gone, so {left} are left.',
        'ಒಟ್ಟು {gone} ಹೋದವು, ಆದ್ದರಿಂದ {left} ಉಳಿದವು.',
      ).fill({'gone': _f(gone), 'left': _f(left)}),
      working: '${_f(guess)} − ${_f(gone)} = ${_f(left)}',
      values: {'left': left},
    ),
    Step(
      const LText(
        'But {rem} should be left. So the whole is {g} × {rem} ÷ {left} = {ans}.',
        'ಆದರೆ {rem} ಉಳಿಯಬೇಕು. ಆದ್ದರಿಂದ ಒಟ್ಟು = {g} × {rem} ÷ {left} = {ans}.',
      ).fill({'rem': _f(remainder), 'g': _f(guess), 'left': _f(left), 'ans': _f(answer)}),
      working: '${_f(guess)} × ${_f(remainder)} ÷ ${_f(left)} = ${_f(answer)}',
      values: {'answer': answer},
    ),
    Step(
      const LText(
        'Check: {ans} gives {a}, {b}{t} and leaves {rem}.',
        'ಪರಿಶೀಲನೆ: {ans} ರಿಂದ {a}, {b}{t} ಸಿಗುತ್ತವೆ ಮತ್ತು {rem} ಉಳಿಯುತ್ತದೆ.',
      ).fill({
        'ans': _f(answer),
        'a': _f(ansA),
        'b': _f(ansB),
        't': multiplier > 0 ? ', ${_f(ansThird)}' : '',
        'rem': _f(remainder),
      }),
    ),
  ];
  final modern = <Step>[
    Step(const LText('Let the whole be x.', 'ಒಟ್ಟು x ಎನ್ನಿ.')),
    Step(
      const LText('The part left is {fl} of x.', 'ಉಳಿಯುವ ಭಾಗ x ನ {fl}.').fill({'fl': _f(fractionLeft)}),
      working: multiplier > 0
          ? 'x − ${_f(partA)}x − ${_f(partB)}x − $multiplier·|${_f(partB)}x − ${_f(partA)}x| = ${_f(fractionLeft)}x'
          : 'x − ${_f(partA)}x − ${_f(partB)}x = ${_f(fractionLeft)}x',
    ),
    Step(
      const LText(
        'So x = {rem} ÷ {fl} = {ans}.',
        'ಆದ್ದರಿಂದ x = {rem} ÷ {fl} = {ans}.',
      ).fill({'rem': _f(remainder), 'fl': _f(fractionLeft), 'ans': _f(answer)}),
    ),
  ];
  return Trace(classical: classical, modern: modern, result: {'answer': answer, 'left': left});
}
