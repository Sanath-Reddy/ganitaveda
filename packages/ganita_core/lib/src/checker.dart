import 'problem.dart';
import 'rational.dart';

enum Verdict {
  correct,

  /// A decimal close enough to a non-terminating exact answer.
  correctApprox,
  wrong,
  unreadable,
}

class CheckResult {
  final Verdict verdict;
  final Rational? parsed;

  const CheckResult(this.verdict, [this.parsed]);

  bool get isCorrect => verdict == Verdict.correct || verdict == Verdict.correctApprox;
}

/// Reads what a student typed and compares it with the exact answer
/// (plan §6.7): integers, fractions `7/2`, mixed numbers `3 1/2`, decimals,
/// Kannada and Devanagari digits, and unit words after the number.
class AnswerChecker {
  const AnswerChecker();

  static const _digitBlocks = [0x0CE6, 0x0966]; // Kannada ೦, Devanagari ०

  static String normaliseDigits(String s) {
    final out = StringBuffer();
    for (final rune in s.runes) {
      var mapped = rune;
      for (final zero in _digitBlocks) {
        if (rune >= zero && rune <= zero + 9) mapped = 0x30 + (rune - zero);
      }
      out.writeCharCode(mapped);
    }
    return out.toString();
  }

  /// Strips unit words and spacing noise; returns null if nothing numeric is left.
  static String clean(String input, List<String> units) {
    var s = normaliseDigits(input).trim().toLowerCase();
    s = s.replaceAll('−', '-').replaceAll('⁄', '/').replaceAll(',', '');
    final sortedUnits = [...units]..sort((a, b) => b.length.compareTo(a.length));
    for (final u in sortedUnits) {
      final unit = u.toLowerCase();
      if (s.endsWith(unit)) {
        s = s.substring(0, s.length - unit.length).trim();
        break;
      }
    }
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  CheckResult check(String input, Answer answer) {
    final s = clean(input, answer.units);
    final value = Rational.tryParse(s);
    if (value == null) return const CheckResult(Verdict.unreadable);
    if (value == answer.value) return CheckResult(Verdict.correct, value);

    // A decimal for an answer whose decimal never ends: accept it if it is the
    // answer rounded to the places typed, and at least two places were typed.
    final dot = s.indexOf('.');
    if (dot >= 0 && !answer.value.isTerminatingDecimal) {
      final places = s.length - dot - 1;
      if (places >= 2) {
        final half = Rational(BigInt.one, BigInt.from(10).pow(places) * BigInt.two);
        if ((value - answer.value).abs() <= half) {
          return CheckResult(Verdict.correctApprox, value);
        }
      }
    }
    return CheckResult(Verdict.wrong, value);
  }
}
