/// Exact rational numbers. Answers are never floating point (plan §6.7).
final class Rational implements Comparable<Rational> {
  /// Always reduced, with a positive denominator.
  final BigInt numerator;
  final BigInt denominator;

  const Rational._(this.numerator, this.denominator);

  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var n = numerator;
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) {
      throw ArgumentError('Denominator is zero');
    }
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  factory Rational.fromInt(int numerator, [int denominator = 1]) =>
      Rational(BigInt.from(numerator), BigInt.from(denominator));

  static final Rational zero = Rational.fromInt(0);
  static final Rational one = Rational.fromInt(1);

  /// Parses `7`, `-7`, `7/2`, `3 1/2`, `-3 1/2` and terminating decimals `3.25`.
  static Rational? tryParse(String input) {
    final s = input.trim();
    final mixed = RegExp(r'^([+-]?)(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(s);
    if (mixed != null) {
      final den = BigInt.parse(mixed[4]!);
      if (den == BigInt.zero) return null;
      final whole = BigInt.parse(mixed[2]!);
      final num = BigInt.parse(mixed[3]!);
      final r = Rational(whole * den + num, den);
      return mixed[1] == '-' ? -r : r;
    }
    final frac = RegExp(r'^([+-]?\d+)\s*/\s*([+-]?\d+)$').firstMatch(s);
    if (frac != null) {
      final den = BigInt.parse(frac[2]!);
      if (den == BigInt.zero) return null;
      return Rational(BigInt.parse(frac[1]!), den);
    }
    final dec = RegExp(r'^([+-]?)(\d*)\.(\d+)$').firstMatch(s);
    if (dec != null) {
      final digits = dec[3]!;
      final whole = dec[2]!.isEmpty ? BigInt.zero : BigInt.parse(dec[2]!);
      final scale = BigInt.from(10).pow(digits.length);
      final r = Rational(whole * scale + BigInt.parse(digits), scale);
      return dec[1] == '-' ? -r : r;
    }
    final integer = RegExp(r'^[+-]?\d+$').firstMatch(s);
    if (integer != null) return Rational(BigInt.parse(s));
    return null;
  }

  static Rational parse(String input) => tryParse(input) ?? (throw FormatException('Not a number', input));

  bool get isInteger => denominator == BigInt.one;
  bool get isNegative => numerator.isNegative;
  bool get isZero => numerator == BigInt.zero;
  int get sign => numerator.sign;

  /// Only valid when [isInteger]; throws otherwise.
  int toInt() {
    if (!isInteger) throw StateError('$this is not an integer');
    return numerator.toInt();
  }

  double toDouble() => numerator / denominator;

  Rational operator +(Rational o) =>
      Rational(numerator * o.denominator + o.numerator * denominator, denominator * o.denominator);
  Rational operator -(Rational o) =>
      Rational(numerator * o.denominator - o.numerator * denominator, denominator * o.denominator);
  Rational operator *(Rational o) => Rational(numerator * o.numerator, denominator * o.denominator);
  Rational operator /(Rational o) {
    if (o.isZero) throw ArgumentError('Division by zero');
    return Rational(numerator * o.denominator, denominator * o.numerator);
  }

  Rational operator -() => Rational._(-numerator, denominator);
  Rational abs() => isNegative ? -this : this;
  Rational get reciprocal => Rational.one / this;

  bool operator <(Rational o) => compareTo(o) < 0;
  bool operator <=(Rational o) => compareTo(o) <= 0;
  bool operator >(Rational o) => compareTo(o) > 0;
  bool operator >=(Rational o) => compareTo(o) >= 0;

  /// The whole part, rounded towards negative infinity.
  BigInt floor() {
    final q = numerator ~/ denominator;
    return (numerator.isNegative && q * denominator != numerator) ? q - BigInt.one : q;
  }

  @override
  int compareTo(Rational o) => (numerator * o.denominator).compareTo(o.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational && other.numerator == numerator && other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  /// `7/2`, `-3`.
  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';

  /// `3 1/2`, `-3 1/2`, `1/2`, `4`.
  String toMixedString() {
    if (isInteger || numerator.abs() < denominator) return toString();
    final whole = numerator.abs() ~/ denominator;
    final rest = numerator.abs() % denominator;
    return '${isNegative ? '-' : ''}$whole $rest/$denominator';
  }

  /// Decimal approximation for display only, with [places] digits.
  String toDecimalString(int places) => toDouble().toStringAsFixed(places);

  /// True when the decimal expansion ends (denominator has only factors 2 and 5).
  bool get isTerminatingDecimal {
    var d = denominator;
    final two = BigInt.two, five = BigInt.from(5);
    while (d % two == BigInt.zero) {
      d ~/= two;
    }
    while (d % five == BigInt.zero) {
      d ~/= five;
    }
    return d == BigInt.one;
  }
}

/// Shorthand used throughout the generators: `r(7, 2)` is 7/2.
Rational r(int n, [int d = 1]) => Rational.fromInt(n, d);
