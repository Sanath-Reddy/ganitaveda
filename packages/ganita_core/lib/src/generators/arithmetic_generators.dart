import '../algorithms/ishta_karma.dart';
import '../algorithms/proportion_series.dart';
import '../algorithms/roots.dart';
import '../algorithms/sign_rules.dart';
import '../problem.dart';
import '../random.dart';
import '../rational.dart';
import '../text.dart';
import 'common.dart';

/// Lesson 1: a whole loses fractions of itself (and a multiple of their
/// difference); a given number is left. Solved by iṣṭa-karma.
class FractionsRemainderGenerator implements Generator {
  @override
  final String id = 'fractions.remainder.v1';

  static const _stories = [
    (
      LText(
        'Out of a swarm of bees, {pa} settle on a kadamba flower and {pb} on a jasmine.{diff} {rem} bees are left. How many bees were in the swarm?',
        'ದುಂಬಿಗಳ ಹಿಂಡಿನಲ್ಲಿ {pa} ಕದಂಬದ ಹೂವಿನ ಮೇಲೂ {pb} ಮಲ್ಲಿಗೆಯ ಮೇಲೂ ಕೂರುತ್ತವೆ.{diff} {rem} ದುಂಬಿಗಳು ಉಳಿಯುತ್ತವೆ. ಹಿಂಡಿನಲ್ಲಿ ಎಷ್ಟು ದುಂಬಿಗಳಿದ್ದವು?',
      ),
      LText(
        ' {m} times the difference of these two groups flies to a kuṭaja bush.',
        ' ಈ ಎರಡು ಗುಂಪುಗಳ ವ್ಯತ್ಯಾಸದ {m} ಪಟ್ಟು ಕುಟಜದ ಪೊದೆಗೆ ಹಾರುತ್ತವೆ.',
      ),
      ['bees', 'bee', 'ದುಂಬಿಗಳು', 'ದುಂಬಿ'],
    ),
    (
      LText(
        'From a heap of lotuses, {pa} are offered at one shrine and {pb} at another.{diff} {rem} lotuses are left for the teacher. How many lotuses were there?',
        'ಕಮಲಗಳ ರಾಶಿಯಿಂದ {pa} ಒಂದು ಗುಡಿಗೂ {pb} ಇನ್ನೊಂದು ಗುಡಿಗೂ ಅರ್ಪಿಸಲಾಗುತ್ತದೆ.{diff} ಗುರುವಿಗೆ {rem} ಕಮಲಗಳು ಉಳಿಯುತ್ತವೆ. ಒಟ್ಟು ಎಷ್ಟು ಕಮಲಗಳಿದ್ದವು?',
      ),
      LText(
        ' {m} times the difference of these two offerings goes to a third shrine.',
        ' ಈ ಎರಡು ಅರ್ಪಣೆಗಳ ವ್ಯತ್ಯಾಸದ {m} ಪಟ್ಟು ಮೂರನೇ ಗುಡಿಗೆ ಹೋಗುತ್ತವೆ.',
      ),
      ['lotuses', 'lotus', 'ಕಮಲಗಳು', 'ಕಮಲ'],
    ),
    (
      LText(
        'A traveller spends {pa} of his coins on food and {pb} on lodging.{diff} He has {rem} coins left. How many coins did he start with?',
        'ಒಬ್ಬ ಪ್ರಯಾಣಿಕ ತನ್ನ ನಾಣ್ಯಗಳಲ್ಲಿ {pa} ಊಟಕ್ಕೂ {pb} ವಸತಿಗೂ ಖರ್ಚು ಮಾಡುತ್ತಾನೆ.{diff} ಅವನ ಬಳಿ {rem} ನಾಣ್ಯಗಳು ಉಳಿಯುತ್ತವೆ. ಅವನು ಎಷ್ಟು ನಾಣ್ಯಗಳೊಂದಿಗೆ ಹೊರಟಿದ್ದ?',
      ),
      LText(
        ' He pays a toll of {m} times the difference between those two amounts.',
        ' ಆ ಎರಡು ಮೊತ್ತಗಳ ವ್ಯತ್ಯಾಸದ {m} ಪಟ್ಟು ಸುಂಕ ಕೊಡುತ್ತಾನೆ.',
      ),
      ['coins', 'coin', 'ನಾಣ್ಯಗಳು', 'ನಾಣ್ಯ'],
    ),
  ];

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    while (true) {
      final unitDens = [2, 3, 4, 5, 6, 7, 8];
      final da = rng.pick(unitDens);
      final db = rng.pick(unitDens.where((d) => d != da).toList());
      var pa = r(1, da), pb = r(1, db);
      if (difficulty == 3 && rng.chance(50)) {
        // One part with a numerator above 1, e.g. 2/7.
        final num = rng.range(2, 3);
        if (num < db) pb = r(num, db);
      }
      final m = switch (difficulty) {
        1 => 0,
        2 => rng.range(1, 2),
        _ => rng.range(1, 3),
      };
      final left = Rational.one - pa - pb - (pb - pa).abs() * r(m);
      if (left <= Rational.zero || left >= r(1, 1)) continue;
      final base = lcm(pa.denominator.toInt(), lcm(pb.denominator.toInt(), left.denominator.toInt()));
      final k = rng.range(1, difficulty == 1 ? 3 : 5);
      final whole = r(base * k);
      final rem = whole * left;
      if (whole.toInt() > 240 || rem < Rational.one) continue;

      final story = rng.pick(_stories);
      final prompt = story.$1.fill({
        'pa': pa.toString(),
        'pb': pb.toString(),
        'rem': rem.toString(),
        'diff': m == 0 ? '' : '\u0000',
      });
      final diffText = m == 0 ? const LText('', '') : story.$2.fill({'m': m});
      final full = LText(prompt.en.replaceFirst('\u0000', diffText.en), prompt.kn.replaceFirst('\u0000', diffText.kn));
      final guess = r(base);
      final trace = ishtaKarma(partA: pa, partB: pb, multiplier: m, remainder: rem, guess: guess);
      final answer = Answer(whole, units: story.$3);
      return Problem(
        generatorId: id,
        seed: seed,
        difficulty: difficulty,
        prompt: full,
        answer: answer,
        hints: hintLadder(
          nudge: LText(
            'Try a guess that splits evenly, like $base, and see how many are left.',
            '$base ರಂತೆ ಸರಿಯಾಗಿ ಭಾಗವಾಗುವ ಒಂದು ಊಹೆ ಮಾಡಿ, ಎಷ್ಟು ಉಳಿಯುತ್ತವೆ ನೋಡಿ.',
          ),
          trace: trace,
          answer: answer,
        ),
        solution: trace,
        data: {'pa': '$pa', 'pb': '$pb', 'm': m, 'whole': whole.toInt()},
      );
    }
  }
}

/// Lesson 2: Brahmagupta's sign rules on integers.
class IntegerSignsGenerator implements Generator {
  @override
  final String id = 'integers.signs.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    int nz(int lo, int hi) {
      while (true) {
        final v = rng.range(lo, hi);
        if (v != 0) return v;
      }
    }

    late Rational a, b;
    late String op;
    String? op2;
    Rational? c;
    switch (difficulty) {
      case 1:
        op = rng.pick(['+', '−']);
        a = r(nz(-9, 9));
        b = r(nz(-9, 9));
      case 2:
        op = rng.pick(['×', '÷']);
        if (op == '×') {
          a = r(nz(-12, 12));
          b = r(nz(-12, 12));
        } else {
          b = r(nz(-9, 9));
          a = b * r(nz(-9, 9));
        }
      default:
        op = rng.pick(['+', '−', '×']);
        op2 = rng.pick(['+', '−', '×']);
        a = r(nz(-9, 9));
        b = r(nz(-9, 9));
        c = r(nz(-9, 9));
    }
    String show(Rational x) => x.isNegative ? '($x)' : '$x';
    final first = apply(op, a, b);
    final value = op2 == null ? first : apply(op2, first, c!);
    final expr = op2 == null ? '${show(a)} $op ${show(b)}' : '(${show(a)} $op ${show(b)}) $op2 ${show(c!)}';

    final useStory = difficulty == 1 && op == '+' && a.sign != b.sign && rng.chance(40);
    final LText prompt;
    if (useStory) {
      final fortune = a.isNegative ? b : a, debt = a.isNegative ? a : b;
      prompt = LText(
        'A trader has a fortune of $fortune and a debt of ${debt.abs()}. What is she worth? (A debt is negative.)',
        'ಒಬ್ಬ ವ್ಯಾಪಾರಿಯ ಬಳಿ $fortune ಧನ ಮತ್ತು ${debt.abs()} ಋಣ ಇದೆ. ಅವಳ ಬೆಲೆ ಎಷ್ಟು? (ಋಣ ಋಣಾತ್ಮಕ.)',
      );
    } else {
      prompt = LText('Work out $expr.', '$expr ಲೆಕ್ಕ ಮಾಡಿ.');
    }
    final steps = <Step>[
      Step(ruleFor(op, a, b), working: '${show(a)} $op ${show(b)} = $first'),
      if (op2 != null) Step(ruleFor(op2, first, c!), working: '${show(first)} $op2 ${show(c)} = $value'),
    ];
    final trace = Trace(classical: steps, result: {'answer': value});
    final answer = Answer(value);
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: prompt,
      answer: answer,
      hints: hintLadder(
        nudge: const LText(
          'Decide first whether the answer is a fortune (positive) or a debt (negative).',
          'ಉತ್ತರ ಧನವೋ (ಧನಾತ್ಮಕ) ಋಣವೋ (ಋಣಾತ್ಮಕ) ಎಂದು ಮೊದಲು ತೀರ್ಮಾನಿಸಿ.',
        ),
        trace: trace,
        answer: answer,
      ),
      solution: trace,
      data: {'expr': expr},
    );
  }
}

/// Lesson 4: the rule of three, direct and (at difficulty 3) inverse.
class RuleOfThreeGenerator implements Generator {
  @override
  final String id = 'ratio.rule_of_three.v1';

  static const _goods = [
    ('palas of rice', 'ಪಲ ಅಕ್ಕಿ', ['palas', 'pala', 'ಪಲ']),
    ('palas of camphor', 'ಪಲ ಕರ್ಪೂರ', ['palas', 'pala', 'ಪಲ']),
    ('measures of ghee', 'ಅಳತೆ ತುಪ್ಪ', ['measures', 'measure', 'ಅಳತೆ']),
    ('bundles of cloth', 'ಕಟ್ಟು ಬಟ್ಟೆ', ['bundles', 'bundle', 'ಕಟ್ಟು']),
  ];

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    if (difficulty == 3) {
      // Inverse: workers and days.
      late int days, workers, total;
      late List<int> divisors;
      do {
        days = rng.range(4, 24);
        workers = rng.range(2, 12);
        total = days * workers;
        divisors = [
          for (var w = 2; w <= 30; w++)
            if (total % w == 0 && w != workers) w,
        ];
      } while (divisors.isEmpty);
      final newWorkers = rng.pick(divisors);
      final answer = Answer(r(total ~/ newWorkers), units: const ['days', 'day', 'ದಿನಗಳು', 'ದಿನ']);
      final trace = trairashika(pramana: r(workers), phala: r(days), iccha: r(newWorkers), inverse: true);
      return Problem(
        generatorId: id,
        seed: seed,
        difficulty: difficulty,
        prompt: LText(
          '$workers builders finish a wall in $days days. How many days would $newWorkers builders take?',
          '$workers ಮೇಸ್ತ್ರಿಗಳು ಒಂದು ಗೋಡೆಯನ್ನು $days ದಿನಗಳಲ್ಲಿ ಮುಗಿಸುತ್ತಾರೆ. $newWorkers ಮೇಸ್ತ್ರಿಗಳಿಗೆ ಎಷ್ಟು ದಿನ ಬೇಕು?',
        ),
        answer: answer,
        hints: hintLadder(
          nudge: const LText(
            'More builders means fewer days. Is this the direct or the inverse rule?',
            'ಹೆಚ್ಚು ಮೇಸ್ತ್ರಿಗಳು ಎಂದರೆ ಕಡಿಮೆ ದಿನಗಳು. ಇದು ನೇರ ನಿಯಮವೋ ವ್ಯಸ್ತ ನಿಯಮವೋ?',
          ),
          trace: trace,
          answer: answer,
        ),
        solution: trace,
        data: {'w': workers, 'd': days, 'n': newWorkers},
      );
    }
    final good = rng.pick(_goods);
    late Rational pramana, phala, iccha;
    if (difficulty == 1) {
      pramana = r(rng.range(2, 9));
      final perUnit = rng.range(2, 12);
      phala = pramana * r(perUnit);
      iccha = r(rng.range(2, 15));
    } else {
      // A fraction in the measure or the fruit, as in Bhāskara's saffron.
      final halves = rng.pick([2, 3, 4]);
      phala = r(rng.range(halves + 1, 4 * halves), halves);
      pramana = r(rng.range(1, 6), rng.pick([1, 2, 7]));
      iccha = r(rng.range(2, 12));
    }
    final value = phala * iccha / pramana;
    final answer = Answer(value, form: value.isInteger ? AnswerForm.integer : AnswerForm.fraction, units: good.$3);
    final trace = trairashika(pramana: pramana, phala: phala, iccha: iccha);
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: LText(
        'If ${pramana.toMixedString()} niṣkas buy ${phala.toMixedString()} ${good.$1}, how many ${good.$1.split(' ').first} do ${iccha.toMixedString()} niṣkas buy?',
        '${pramana.toMixedString()} ನಿಷ್ಕಗಳಿಗೆ ${phala.toMixedString()} ${good.$2} ಸಿಕ್ಕರೆ, ${iccha.toMixedString()} ನಿಷ್ಕಗಳಿಗೆ ಎಷ್ಟು ${good.$2.split(' ').first} ಸಿಗುತ್ತದೆ?',
      ),
      answer: answer,
      hints: hintLadder(
        nudge: const LText(
          'Which number is the measure, which the fruit, which the desire?',
          'ಯಾವುದು ಪ್ರಮಾಣ, ಯಾವುದು ಫಲ, ಯಾವುದು ಇಚ್ಛಾ?',
        ),
        trace: trace,
        answer: answer,
      ),
      solution: trace,
      data: {'p': '$pramana', 'f': '$phala', 'i': '$iccha', 'g': good.$1},
    );
  }
}

/// Lesson 5: arithmetic progressions — sum, last term, or number of terms.
class ArithmeticSequenceGenerator implements Generator {
  @override
  final String id = 'sequences.arithmetic.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    final a = rng.range(1, 12), d = rng.range(1, 9), n = rng.range(5, difficulty == 1 ? 12 : 20);
    final trace = sredhi(adi: r(a), caya: r(d), gaccha: n);
    final last = trace.result['last']!, sum = trace.result['sum']!;
    final story = rng.chance(50);
    late LText prompt;
    late Answer answer;
    late LText nudge;
    switch (difficulty) {
      case 1:
        prompt = story
            ? LText(
                'Someone gives $a drammas on the first day and $d more each day after. How much in $n days altogether?',
                'ಒಬ್ಬರು ಮೊದಲ ದಿನ $a ದ್ರಮ್ಮ ಕೊಟ್ಟು ನಂತರ ಪ್ರತಿದಿನ $d ಹೆಚ್ಚು ಕೊಡುತ್ತಾರೆ. $n ದಿನಗಳಲ್ಲಿ ಒಟ್ಟು ಎಷ್ಟು?',
              )
            : LText(
                'First term $a, common difference $d, $n terms. Find the sum.',
                'ಮೊದಲ ಪದ $a, ಸಾಮಾನ್ಯ ವ್ಯತ್ಯಾಸ $d, $n ಪದಗಳು. ಮೊತ್ತ ಕಂಡುಹಿಡಿಯಿರಿ.',
              );
        answer = Answer(sum, units: const ['drammas', 'dramma', 'ದ್ರಮ್ಮ']);
        nudge = const LText(
          'Find the last term first, then the middle term.',
          'ಮೊದಲು ಕೊನೆಯ ಪದ, ನಂತರ ಮಧ್ಯ ಪದ ಕಂಡುಹಿಡಿಯಿರಿ.',
        );
      case 2:
        prompt = LText(
          'First term $a, common difference $d. What is term number $n?',
          'ಮೊದಲ ಪದ $a, ಸಾಮಾನ್ಯ ವ್ಯತ್ಯಾಸ $d. $n ನೇ ಪದ ಯಾವುದು?',
        );
        answer = Answer(last);
        nudge = const LText(
          'How many steps of the difference are there from the first term to this one?',
          'ಮೊದಲ ಪದದಿಂದ ಈ ಪದಕ್ಕೆ ವ್ಯತ್ಯಾಸದ ಎಷ್ಟು ಹೆಜ್ಜೆಗಳು?',
        );
      default:
        prompt = LText(
          'A progression starts at $a and grows by $d. How many terms add up to $sum?',
          'ಒಂದು ಶ್ರೇಢಿ $a ರಿಂದ ಆರಂಭವಾಗಿ $d ರಷ್ಟು ಬೆಳೆಯುತ್ತದೆ. ಎಷ್ಟು ಪದಗಳು ಕೂಡಿ $sum ಆಗುತ್ತವೆ?',
        );
        answer = Answer(r(n), units: const ['terms', 'ಪದಗಳು']);
        nudge = const LText(
          'Try a number of terms, find its sum, and adjust. Āryabhaṭa also gives a direct rule (Gaṇitapāda 20).',
          'ಕೆಲವು ಪದಗಳ ಸಂಖ್ಯೆ ಊಹಿಸಿ, ಮೊತ್ತ ಕಂಡು, ಸರಿಪಡಿಸಿ. ಆರ್ಯಭಟ ನೇರ ನಿಯಮವನ್ನೂ ಕೊಡುತ್ತಾನೆ (ಗಣಿತಪಾದ 20).',
        );
    }
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: prompt,
      answer: answer,
      hints: hintLadder(nudge: nudge, trace: trace, answer: answer),
      solution: trace,
      data: {'a': a, 'd': d, 'n': n, 'k': difficulty},
    );
  }
}

/// Lesson 7: partial sums of Mādhava's series, as exact fractions.
class MadhavaSeriesGenerator implements Generator {
  @override
  final String id = 'series.madhava.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    final n = switch (difficulty) {
      1 => rng.range(2, 3),
      2 => rng.range(3, 4),
      _ => rng.range(1, 3),
    };
    final m = madhavaSum(n);
    final terms = [for (var k = 0; k < n; k++) k == 0 ? '1' : '${k.isOdd ? ' − ' : ' + '}1/${2 * k + 1}'].join();
    late LText prompt;
    late Rational value;
    switch (difficulty) {
      case 1:
        prompt = LText('Add exactly: $terms. Give a fraction.', 'ನಿಖರವಾಗಿ ಕೂಡಿಸಿ: $terms. ಭಿನ್ನರಾಶಿಯಾಗಿ ಕೊಡಿ.');
        value = m.quarterSum;
      case 2:
        prompt = LText(
          'Mādhava\'s series with $n terms: 4 × ($terms). Give the exact fraction.',
          '$n ಪದಗಳ ಮಾಧವ ಶ್ರೇಢಿ: 4 × ($terms). ನಿಖರ ಭಿನ್ನರಾಶಿ ಕೊಡಿ.',
        );
        value = m.pi;
      default:
        prompt = LText(
          'Take $terms and add the end correction ${m.correction}. Multiply by 4. Give the exact fraction.',
          '$terms ತೆಗೆದುಕೊಂಡು ಕೊನೆಯ ತಿದ್ದುಪಡಿ ${m.correction} ಸೇರಿಸಿ. 4 ರಿಂದ ಗುಣಿಸಿ. ನಿಖರ ಭಿನ್ನರಾಶಿ ಕೊಡಿ.',
        );
        value = m.corrected;
    }
    final trace = madhavaTrace(n);
    final answer = Answer(value, form: AnswerForm.fraction);
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: prompt,
      answer: answer,
      hints: hintLadder(
        nudge: LText(
          'Bring every fraction to the denominator ${_lcmOdd(n)}.',
          'ಎಲ್ಲಾ ಭಿನ್ನರಾಶಿಗಳನ್ನು ${_lcmOdd(n)} ಛೇದಕ್ಕೆ ತನ್ನಿ.',
        ),
        trace: trace,
        answer: answer,
      ),
      solution: trace,
      data: {'n': n, 'k': difficulty},
    );
  }

  static int _lcmOdd(int n) {
    var l = 1;
    for (var k = 0; k < n; k++) {
      l = lcm(l, 2 * k + 1);
    }
    return l;
  }
}
