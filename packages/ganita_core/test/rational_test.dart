import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

void main() {
  test('normalises sign and lowest terms', () {
    expect(r(6, -8), r(-3, 4));
    expect(r(6, -8).toString(), '-3/4');
    expect(r(0, 5), Rational.zero);
  });

  test('arithmetic is exact', () {
    expect(r(1, 3) + r(1, 6), r(1, 2));
    expect(r(5, 2) * r(9) / r(3, 7), r(105, 2));
    expect((r(1, 5) - r(1, 3)).abs(), r(2, 15));
  });

  test('parses the forms students type', () {
    expect(Rational.parse('7/2'), r(7, 2));
    expect(Rational.parse('3 1/2'), r(7, 2));
    expect(Rational.parse('-3 1/2'), r(-7, 2));
    expect(Rational.parse('3.5'), r(7, 2));
    expect(Rational.parse(' -12 '), r(-12));
    expect(Rational.parse('.25'), r(1, 4));
    expect(Rational.tryParse('1/0'), isNull);
    expect(Rational.tryParse('abc'), isNull);
  });

  test('mixed form and decimals', () {
    expect(r(105, 2).toMixedString(), '52 1/2');
    expect(r(-7, 2).toMixedString(), '-3 1/2');
    expect(r(1, 3).isTerminatingDecimal, isFalse);
    expect(r(3, 8).isTerminatingDecimal, isTrue);
    expect(r(-7, 2).floor(), BigInt.from(-4));
  });

  test('exact square roots', () {
    expect(exactSqrt(r(25, 4)), r(5, 2));
    expect(exactSqrt(r(2)), isNull);
    expect(isqrt(BigInt.parse('100100025')), BigInt.from(10005)); // Līlāvatī 21's example
  });
}
