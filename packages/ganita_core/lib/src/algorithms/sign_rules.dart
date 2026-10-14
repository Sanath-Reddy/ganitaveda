import '../problem.dart';
import '../rational.dart';
import '../text.dart';

const _fortune = LText('fortune', 'ಧನ');
const _debt = LText('debt', 'ಋಣ');
const _zero = LText('zero', 'ಸೊನ್ನೆ');

LText kind(Rational x) => x.isZero ? _zero : (x.isNegative ? _debt : _fortune);

String _s(Rational x) => x.isNegative ? '(${x.toMixedString()})' : x.toMixedString();

/// Brahmagupta's rule (BSS 18.30–35) that decides the sign of a result.
LText ruleFor(String op, Rational a, Rational b) {
  final ka = kind(a);
  switch (op) {
    case '+':
      if (a.isZero || b.isZero) {
        return const LText(
          'Zero added to a quantity leaves it as it is.',
          'ಸೊನ್ನೆಯನ್ನು ಕೂಡಿಸಿದರೆ ಪ್ರಮಾಣ ಹಾಗೆಯೇ ಇರುತ್ತದೆ.',
        );
      }
      if (a.sign == b.sign) {
        return LText('Two ${ka.en}s together make a ${ka.en}.', 'ಎರಡು ${ka.kn} ಸೇರಿ ${ka.kn}.');
      }
      return const LText(
        'A fortune and a debt: take their difference; equal ones make zero.',
        'ಧನ ಮತ್ತು ಋಣ: ಅವುಗಳ ವ್ಯತ್ಯಾಸ ತೆಗೆದುಕೊಳ್ಳಿ; ಸಮವಾಗಿದ್ದರೆ ಸೊನ್ನೆ.',
      );
    case '−':
      if (a.isZero) {
        return const LText(
          'Taken from zero, a debt becomes a fortune and a fortune a debt.',
          'ಸೊನ್ನೆಯಿಂದ ಕಳೆದರೆ ಋಣ ಧನವಾಗುತ್ತದೆ, ಧನ ಋಣವಾಗುತ್ತದೆ.',
        );
      }
      if (b.isNegative && !a.isNegative || !b.isNegative && a.isNegative) {
        return const LText(
          'A debt taken from a fortune, or a fortune from a debt: add them together.',
          'ಧನದಿಂದ ಋಣ, ಅಥವಾ ಋಣದಿಂದ ಧನ ಕಳೆಯುವುದಾದರೆ: ಎರಡನ್ನೂ ಒಟ್ಟು ಸೇರಿಸಿ.',
        );
      }
      return const LText(
        'Like from like: take the smaller from the greater; if the greater is taken from the smaller, the result is reversed.',
        'ಒಂದೇ ಜಾತಿಯವು: ದೊಡ್ಡದರಿಂದ ಚಿಕ್ಕದನ್ನು ಕಳೆಯಿರಿ; ಚಿಕ್ಕದರಿಂದ ದೊಡ್ಡದನ್ನು ಕಳೆದರೆ ಫಲ ತಿರುಗುತ್ತದೆ.',
      );
    case '×':
      if (a.isZero || b.isZero) {
        return const LText('Anything times zero is zero.', 'ಯಾವುದನ್ನಾದರೂ ಸೊನ್ನೆಯಿಂದ ಗುಣಿಸಿದರೆ ಸೊನ್ನೆ.');
      }
      return a.sign == b.sign
          ? const LText(
              'The product of two debts, or of two fortunes, is a fortune.',
              'ಎರಡು ಋಣಗಳ, ಅಥವಾ ಎರಡು ಧನಗಳ ಗುಣಲಬ್ಧ ಧನ.',
            )
          : const LText('The product of a debt and a fortune is a debt.', 'ಋಣ ಮತ್ತು ಧನದ ಗುಣಲಬ್ಧ ಋಣ.');
    case '÷':
      return a.sign * b.sign >= 0
          ? const LText(
              'Fortune by fortune, or debt by debt, gives a fortune.',
              'ಧನವನ್ನು ಧನದಿಂದ, ಅಥವಾ ಋಣವನ್ನು ಋಣದಿಂದ ಭಾಗಿಸಿದರೆ ಧನ.',
            )
          : const LText(
              'A fortune divided by a debt, or a debt by a fortune, is a debt.',
              'ಧನವನ್ನು ಋಣದಿಂದ, ಅಥವಾ ಋಣವನ್ನು ಧನದಿಂದ ಭಾಗಿಸಿದರೆ ಋಣ.',
            );
  }
  throw ArgumentError.value(op, 'op');
}

Rational apply(String op, Rational a, Rational b) => switch (op) {
  '+' => a + b,
  '−' => a - b,
  '×' => a * b,
  '÷' => a / b,
  _ => throw ArgumentError.value(op, 'op'),
};

/// All four operations on one fortune or debt [a] and another [b] (plan lesson 2).
Trace signRules({required Rational a, required Rational b}) {
  final ops = ['+', '−', '×', if (!b.isZero) '÷'];
  final classical = <Step>[
    Step(
      LText(
        'Take ${_s(a)} (${kind(a).en}) and ${_s(b)} (${kind(b).en}).',
        '${_s(a)} (${kind(a).kn}) ಮತ್ತು ${_s(b)} (${kind(b).kn}) ತೆಗೆದುಕೊಳ್ಳಿ.',
      ),
    ),
    for (final op in ops)
      Step(
        ruleFor(op, a, b),
        working: '${_s(a)} $op ${_s(b)} = ${apply(op, a, b).toMixedString()}',
        values: {op: apply(op, a, b)},
      ),
    Step(ruleFor('×', b, b), working: '${_s(b)} × ${_s(b)} = ${(b * b).toMixedString()}'),
  ];
  final modern = [
    for (final op in ops)
      Step(const LText('', ''), working: '${_s(a)} $op ${_s(b)} = ${apply(op, a, b).toMixedString()}'),
  ];
  return Trace(classical: classical, modern: modern, result: {for (final op in ops) op: apply(op, a, b)});
}
