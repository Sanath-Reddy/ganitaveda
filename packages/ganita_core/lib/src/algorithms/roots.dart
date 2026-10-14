import '../rational.dart';

/// Floor of the square root of a non-negative integer.
BigInt isqrt(BigInt n) {
  if (n.isNegative) throw ArgumentError.value(n, 'n');
  if (n < BigInt.two) return n;
  var x = BigInt.one << ((n.bitLength + 1) >> 1);
  while (true) {
    final y = (x + n ~/ x) >> 1;
    if (y >= x) return x;
    x = y;
  }
}

/// The exact square root when [x] is the square of a rational, else null.
Rational? exactSqrt(Rational x) {
  if (x.isNegative) return null;
  final n = isqrt(x.numerator), d = isqrt(x.denominator);
  return (n * n == x.numerator && d * d == x.denominator) ? Rational(n, d) : null;
}

BigInt factorial(int n) {
  var out = BigInt.one;
  for (var i = 2; i <= n; i++) {
    out *= BigInt.from(i);
  }
  return out;
}

int gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final t = a % b;
    a = b;
    b = t;
  }
  return a;
}

int lcm(int a, int b) => a ~/ gcd(a, b) * b;
