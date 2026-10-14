import '../algorithms/geometry.dart';
import '../algorithms/number_theory.dart';
import '../algorithms/roots.dart';
import '../problem.dart';
import '../random.dart';
import '../rational.dart';
import '../text.dart';
import 'common.dart';

/// Primitive Pythagorean triples (side, upright, hypotenuse) from Euclid's
/// formula with m > n, coprime, opposite parity.
List<(int, int, int)> primitiveTriples(int maxHyp) => [
  for (var m = 2; m * m < maxHyp; m++)
    for (var n = 1; n < m; n++)
      if ((m - n).isOdd && gcd(m, n) == 1 && m * m + n * n <= maxHyp) (m * m - n * n, 2 * m * n, m * m + n * n),
];

/// Lesson 3: right triangles with whole-number sides.
class RightTriangleGenerator implements Generator {
  @override
  final String id = 'geometry.right_triangle.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    final triples = primitiveTriples(difficulty == 1 ? 30 : 65);
    final (p, q, h) = rng.pick(triples);
    final k = rng.range(1, difficulty == 1 ? 3 : 4);
    var (a, b, c) = (p * k, q * k, h * k);
    if (rng.chance(50)) (a, b) = (b, a);
    late LText prompt;
    late Answer answer;
    late Trace trace;
    late LText nudge;
    const units = ['units', 'hastas', 'hasta', 'ಹಸ್ತ', 'ಏಕಮಾನ'];
    switch (difficulty) {
      case 1:
        prompt = LText(
          'The side (bhuja) is $a and the upright (koṭi) is $b. How long is the hypotenuse (karṇa)?',
          'ಭುಜ $a ಮತ್ತು ಕೋಟಿ $b. ಕರ್ಣ ಎಷ್ಟು ಉದ್ದ?',
        );
        answer = Answer(r(c), units: units);
        trace = bhujaKotiKarna(bhuja: r(a), koti: r(b));
        nudge = const LText('Square both sides and add.', 'ಎರಡೂ ಬಾಹುಗಳನ್ನು ವರ್ಗಿಸಿ ಕೂಡಿಸಿ.');
      case 2:
        prompt = rng.chance(50)
            ? LText(
                'A ladder $c hastas long leans against a wall with its foot $a hastas from the wall. How high up the wall does it reach?',
                '$c ಹಸ್ತ ಉದ್ದದ ಏಣಿ ಗೋಡೆಗೆ ಒರಗಿದೆ; ಅದರ ಬುಡ ಗೋಡೆಯಿಂದ $a ಹಸ್ತ ದೂರದಲ್ಲಿದೆ. ಅದು ಗೋಡೆಯಲ್ಲಿ ಎಷ್ಟು ಎತ್ತರ ತಲುಪುತ್ತದೆ?',
              )
            : LText(
                'The hypotenuse is $c and the side is $a. Find the upright.',
                'ಕರ್ಣ $c ಮತ್ತು ಭುಜ $a. ಕೋಟಿ ಕಂಡುಹಿಡಿಯಿರಿ.',
              );
        answer = Answer(r(b), units: units);
        trace = bhujaKotiKarna(bhuja: r(a), karna: r(c));
        nudge = const LText(
          'Take the difference of the squares, not the sum.',
          'ವರ್ಗಗಳ ಮೊತ್ತವಲ್ಲ, ವ್ಯತ್ಯಾಸ ತೆಗೆದುಕೊಳ್ಳಿ.',
        );
      default:
        final (lo, hi) = a < b ? (a, b) : (b, a);
        final d = hi - lo;
        prompt = LText(
          'In a right triangle the hypotenuse is $c and the two legs differ by $d. How long is the longer leg?',
          'ಲಂಬಕೋನ ತ್ರಿಭುಜದಲ್ಲಿ ಕರ್ಣ $c ಮತ್ತು ಎರಡು ಬಾಹುಗಳ ವ್ಯತ್ಯಾಸ $d. ಉದ್ದದ ಬಾಹು ಎಷ್ಟು?',
        );
        answer = Answer(r(hi), units: units);
        final twice = 2 * c * c - d * d;
        final sumLegs = exactSqrt(r(twice))!;
        trace = Trace(
          classical: [
            Step(
              LText(
                'Twice the square of the hypotenuse, less the square of the difference: ${2 * c * c} − ${d * d} = $twice.',
                'ಕರ್ಣದ ವರ್ಗದ ಎರಡರಷ್ಟರಿಂದ ವ್ಯತ್ಯಾಸದ ವರ್ಗ ಕಳೆಯಿರಿ: ${2 * c * c} − ${d * d} = $twice.',
              ),
            ),
            Step(LText('Its square root is the sum of the legs: $sumLegs.', 'ಅದರ ವರ್ಗಮೂಲ ಬಾಹುಗಳ ಮೊತ್ತ: $sumLegs.')),
            Step(
              LText(
                'Add the difference and halve: ($sumLegs + $d) ÷ 2 = $hi.',
                'ವ್ಯತ್ಯಾಸ ಕೂಡಿಸಿ ಅರ್ಧ ಮಾಡಿ: ($sumLegs + $d) ÷ 2 = $hi.',
              ),
            ),
          ],
          result: {'answer': r(hi)},
        );
        nudge = const LText(
          '(sum of legs)² + (difference)² = 2 × hypotenuse². Bhāskara uses this in Līlāvatī 158.',
          '(ಬಾಹುಗಳ ಮೊತ್ತ)² + (ವ್ಯತ್ಯಾಸ)² = 2 × ಕರ್ಣ². ಭಾಸ್ಕರ ಇದನ್ನು ಲೀಲಾವತೀ 158ರಲ್ಲಿ ಬಳಸುತ್ತಾನೆ.',
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
      data: {'a': a, 'b': b, 'c': c, 'k': difficulty},
    );
  }
}

/// Lesson 6: half-chords with whole-number answers — the chord of a sixth of
/// the circle equals the radius (Āryabhaṭīya 2.9), and Pythagorean half-chords.
class HalfChordGenerator implements Generator {
  @override
  final String id = 'trig.half_chord.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    late LText prompt, nudge;
    late Answer answer;
    late Trace trace;
    switch (difficulty) {
      case 1:
        final radius = 2 * rng.range(6, 120);
        prompt = LText(
          'In a circle of radius $radius, how long is the half-chord of an arc of 30°?',
          '$radius ತ್ರಿಜ್ಯದ ವೃತ್ತದಲ್ಲಿ 30° ಚಾಪದ ಅರ್ಧಜ್ಯಾ ಎಷ್ಟು?',
        );
        answer = Answer(r(radius ~/ 2));
        nudge = const LText(
          'The chord of a sixth of the circle (60°) equals the radius.',
          'ವೃತ್ತದ ಆರನೇ ಒಂದು ಭಾಗದ (60°) ಜ್ಯಾ ತ್ರಿಜ್ಯಕ್ಕೆ ಸಮ.',
        );
        trace = Trace(
          classical: [
            Step(
              LText(
                'The chord of 60° equals the radius, $radius (Āryabhaṭīya 2.9).',
                '60° ಜ್ಯಾ ತ್ರಿಜ್ಯಕ್ಕೆ ಸಮ, $radius (ಆರ್ಯಭಟೀಯ 2.9).',
              ),
            ),
            Step(
              LText('The half-chord of 30° is half of it: ${radius ~/ 2}.', '30° ಅರ್ಧಜ್ಯಾ ಅದರ ಅರ್ಧ: ${radius ~/ 2}.'),
            ),
          ],
          result: {'answer': r(radius ~/ 2)},
        );
      default:
        final (p, q, h) = rng.pick(primitiveTriples(30));
        final k = rng.range(1, 12);
        final radius = h * k, jya = p * k, kotijya = q * k;
        if (difficulty == 2) {
          prompt = LText(
            'In a circle of radius $radius, a half-chord (jyā) is $jya. How long is the koṭijyā, the distance from the centre to the chord?',
            '$radius ತ್ರಿಜ್ಯದ ವೃತ್ತದಲ್ಲಿ ಒಂದು ಅರ್ಧಜ್ಯಾ $jya. ಕೋಟಿಜ್ಯಾ, ಅಂದರೆ ಕೇಂದ್ರದಿಂದ ಜ್ಯಾಕ್ಕಿರುವ ದೂರ ಎಷ್ಟು?',
          );
          answer = Answer(r(kotijya));
          nudge = const LText(
            'Radius, half-chord and koṭijyā make a right triangle.',
            'ತ್ರಿಜ್ಯ, ಅರ್ಧಜ್ಯಾ ಮತ್ತು ಕೋಟಿಜ್ಯಾ ಲಂಬಕೋನ ತ್ರಿಭುಜ ರಚಿಸುತ್ತವೆ.',
          );
          trace = bhujaKotiKarna(bhuja: r(jya), karna: r(radius));
        } else {
          prompt = LText(
            'In a circle of radius $radius, a half-chord is $jya. How long is the arrow (śara), from the chord to the arc?',
            '$radius ತ್ರಿಜ್ಯದ ವೃತ್ತದಲ್ಲಿ ಒಂದು ಅರ್ಧಜ್ಯಾ $jya. ಜ್ಯಾದಿಂದ ಚಾಪದವರೆಗಿನ ಶರ (ಬಾಣ) ಎಷ್ಟು?',
          );
          answer = Answer(r(radius - kotijya));
          nudge = const LText(
            'Find the koṭijyā first; the arrow is what is left of the radius.',
            'ಮೊದಲು ಕೋಟಿಜ್ಯಾ ಕಂಡುಹಿಡಿಯಿರಿ; ತ್ರಿಜ್ಯದಲ್ಲಿ ಉಳಿದದ್ದೇ ಶರ.',
          );
          final t = bhujaKotiKarna(bhuja: r(jya), karna: r(radius));
          trace = Trace(
            classical: [
              ...t.classical,
              Step(
                LText(
                  'The arrow is the radius less the koṭijyā: $radius − $kotijya = ${radius - kotijya}.',
                  'ಶರ = ತ್ರಿಜ್ಯ − ಕೋಟಿಜ್ಯಾ: $radius − $kotijya = ${radius - kotijya}.',
                ),
              ),
            ],
            modern: t.modern,
            result: {'answer': r(radius - kotijya)},
          );
        }
    }
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: prompt,
      answer: answer,
      hints: hintLadder(nudge: nudge, trace: trace, answer: answer),
      solution: trace,
      data: {'prompt': prompt.en},
    );
  }
}

/// Lesson 9: cyclic quadrilaterals built from two right triangles on a common
/// hypotenuse (the construction in BSS 12.38), so every answer is whole.
class CyclicQuadGenerator implements Generator {
  @override
  final String id = 'geometry.cyclic_quad.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    final triples = primitiveTriples(difficulty == 3 ? 30 : 17);
    final t1 = rng.pick(triples);
    final t2 = rng.pick(triples.where((t) => t != t1).toList());
    final (a, b, c) = t1;
    final (p, q, h) = t2;
    // Scale each triangle so both hypotenuses are c·h, then divide by any common factor.
    var sides = [a * h, b * h, q * c, p * c];
    final g = sides.reduce(gcd);
    sides = sides.map((s) => s ~/ g).toList();
    final diagonal = c * h ~/ g;
    final rs = sides.map(r).toList();
    final trace = cyclicQuad(rs);
    final s = trace.result['s']!;
    late LText prompt, nudge;
    late Answer answer;
    final list = sides.join(', ');
    switch (difficulty) {
      case 1:
        prompt = LText(
          'A quadrilateral with its corners on a circle has sides $list. What is half its perimeter, s?',
          'ಮೂಲೆಗಳು ವೃತ್ತದ ಮೇಲಿರುವ ಚತುರ್ಭುಜದ ಬಾಹುಗಳು $list. ಅದರ ಪರಿಧಿಯ ಅರ್ಧ s ಎಷ್ಟು?',
        );
        answer = Answer(s, form: s.isInteger ? AnswerForm.integer : AnswerForm.fraction);
        nudge = const LText('Add the four sides and halve.', 'ನಾಲ್ಕು ಬಾಹುಗಳನ್ನು ಕೂಡಿಸಿ ಅರ್ಧ ಮಾಡಿ.');
      case 2:
        prompt = LText(
          'A quadrilateral with its corners on a circle has sides $list. Find its area.',
          'ಮೂಲೆಗಳು ವೃತ್ತದ ಮೇಲಿರುವ ಚತುರ್ಭುಜದ ಬಾಹುಗಳು $list. ಅದರ ವಿಸ್ತೀರ್ಣ ಕಂಡುಹಿಡಿಯಿರಿ.',
        );
        answer = Answer(trace.result['area']!);
        nudge = const LText(
          'Find s, take each side from it, multiply the four results, then take the square root.',
          's ಕಂಡು, ಪ್ರತಿ ಬಾಹುವನ್ನು ಅದರಿಂದ ಕಳೆದು, ನಾಲ್ಕು ಫಲಗಳನ್ನು ಗುಣಿಸಿ, ವರ್ಗಮೂಲ ತೆಗೆಯಿರಿ.',
        );
      default:
        prompt = LText(
          'A quadrilateral with its corners on a circle has sides $list, in that order. How long is the diagonal that separates the first two sides from the last two?',
          'ಮೂಲೆಗಳು ವೃತ್ತದ ಮೇಲಿರುವ ಚತುರ್ಭುಜದ ಬಾಹುಗಳು ಈ ಕ್ರಮದಲ್ಲಿ $list. ಮೊದಲ ಎರಡು ಬಾಹುಗಳನ್ನು ಕೊನೆಯ ಎರಡರಿಂದ ಬೇರ್ಪಡಿಸುವ ಕರ್ಣ ಎಷ್ಟು ಉದ್ದ?',
        );
        answer = Answer(r(diagonal));
        nudge = const LText(
          'Brahmagupta: √((ac + bd)(ad + bc) ÷ (ab + cd)).',
          'ಬ್ರಹ್ಮಗುಪ್ತ: √((ac + bd)(ad + bc) ÷ (ab + cd)).',
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
      data: {'sides': list, 'k': difficulty},
    );
  }
}

/// Lesson 8: the pulveriser, and (difficulty 3) remainder problems solved with it.
class KuttakaGenerator implements Generator {
  @override
  final String id = 'number_theory.kuttaka.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    while (true) {
      if (difficulty == 3) {
        final d1 = rng.range(3, 13), d2 = rng.range(3, 13);
        if (d1 == d2 || gcd(d1, d2) != 1) continue;
        final r1 = rng.range(1, d1 - 1), r2 = rng.range(1, d2 - 1);
        // N = d1·x + r1 with d1·x + (r1 − r2) divisible by d2.
        final c = ((r1 - r2) % d2 + d2) % d2;
        final k = kuttaka(d1, d2, c)!;
        final n = d1 * k.multiplier + r1;
        final trace = kuttakaTrace(d1, d2, c);
        final answer = Answer(r(n));
        return Problem(
          generatorId: id,
          seed: seed,
          difficulty: difficulty,
          prompt: LText(
            'A number leaves remainder $r1 when divided by $d1, and remainder $r2 when divided by $d2. What is the smallest such number?',
            'ಒಂದು ಸಂಖ್ಯೆಯನ್ನು $d1 ರಿಂದ ಭಾಗಿಸಿದರೆ ಶೇಷ $r1, $d2 ರಿಂದ ಭಾಗಿಸಿದರೆ ಶೇಷ $r2. ಅಂತಹ ಅತಿ ಚಿಕ್ಕ ಸಂಖ್ಯೆ ಯಾವುದು?',
          ),
          answer: answer,
          hints: hintLadder(
            nudge: LText(
              'Write the number as $d1·x + $r1. Then $d1·x + ${r1 - r2} must be divisible by $d2.',
              'ಸಂಖ್ಯೆಯನ್ನು $d1·x + $r1 ಎಂದು ಬರೆಯಿರಿ. ಆಗ $d1·x + ${r1 - r2} ಯು $d2 ರಿಂದ ಭಾಗವಾಗಬೇಕು.',
            ),
            trace: trace,
            answer: answer,
          ),
          solution: trace,
          data: {'d1': d1, 'r1': r1, 'd2': d2, 'r2': r2},
        );
      }
      final g = difficulty == 1 ? 1 : rng.range(2, 5);
      final a = rng.range(3, 25), b = rng.range(5, 17), c = rng.range(1, 30);
      if (gcd(a, b) != 1 || a == b) continue;
      final k = kuttaka(a * g, b * g, c * g)!;
      if (k.multiplier == 0) continue;
      final trace = kuttakaTrace(a * g, b * g, c * g);
      final answer = Answer(r(k.multiplier));
      return Problem(
        generatorId: id,
        seed: seed,
        difficulty: difficulty,
        prompt: LText(
          'Find the smallest whole number x so that ${a * g}·x + ${c * g} is exactly divisible by ${b * g}.',
          '${a * g}·x + ${c * g} ಯು ${b * g} ರಿಂದ ಶೇಷವಿಲ್ಲದೆ ಭಾಗವಾಗುವಂತಹ ಅತಿ ಚಿಕ್ಕ ಪೂರ್ಣ ಸಂಖ್ಯೆ x ಕಂಡುಹಿಡಿಯಿರಿ.',
        ),
        answer: answer,
        hints: hintLadder(
          nudge: g > 1
              ? LText(
                  'First divide all three numbers by their common factor $g.',
                  'ಮೊದಲು ಮೂರೂ ಸಂಖ್ಯೆಗಳನ್ನು ಸಾಮಾನ್ಯ ಅಪವರ್ತನ $g ರಿಂದ ಭಾಗಿಸಿ.',
                )
              : const LText(
                  'Divide the two numbers into each other and write down the quotients.',
                  'ಎರಡು ಸಂಖ್ಯೆಗಳನ್ನು ಪರಸ್ಪರ ಭಾಗಿಸಿ ಭಾಗಲಬ್ಧಗಳನ್ನು ಬರೆಯಿರಿ.',
                ),
          trace: trace,
          answer: answer,
        ),
        solution: trace,
        data: {'a': a * g, 'b': b * g, 'c': c * g},
      );
    }
  }
}

/// Lesson 10: counting arrangements of digits and their sum (Līlāvatī 261–264).
class AnkapashaGenerator implements Generator {
  @override
  final String id = 'combinatorics.ankapasha.v1';

  @override
  Problem generate(int seed, int difficulty) {
    final rng = SeededRandom(seed);
    late List<int> digits;
    late LText prompt, nudge;
    late Answer answer;
    switch (difficulty) {
      case 1:
        digits = rng.shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9]).take(rng.range(3, 5)).toList();
        prompt = LText(
          'How many different numbers can be written with the digits ${digits.join(', ')}, using each once?',
          '${digits.join(', ')} ಅಂಕಿಗಳನ್ನು ಒಮ್ಮೆ ಮಾತ್ರ ಬಳಸಿ ಎಷ್ಟು ಬೇರೆಬೇರೆ ಸಂಖ್ಯೆಗಳನ್ನು ಬರೆಯಬಹುದು?',
        );
        answer = Answer(Rational(ankapasha(digits).count), units: const ['numbers', 'ಸಂಖ್ಯೆಗಳು']);
        nudge = const LText(
          'How many choices for the first place? Then for the next?',
          'ಮೊದಲ ಸ್ಥಾನಕ್ಕೆ ಎಷ್ಟು ಆಯ್ಕೆಗಳು? ನಂತರದದಕ್ಕೆ?',
        );
      case 2:
        digits = rng.shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9]).take(3).toList();
        prompt = LText(
          'Write every number made from the digits ${digits.join(', ')}, each used once. What do they add up to?',
          '${digits.join(', ')} ಅಂಕಿಗಳನ್ನು ಒಮ್ಮೆ ಮಾತ್ರ ಬಳಸಿ ಮಾಡುವ ಎಲ್ಲ ಸಂಖ್ಯೆಗಳ ಮೊತ್ತ ಎಷ್ಟು?',
        );
        answer = Answer(Rational(ankapasha(digits).sum));
        nudge = const LText(
          'Each digit sits in each place equally often.',
          'ಪ್ರತಿ ಅಂಕಿಯೂ ಪ್ರತಿ ಸ್ಥಾನದಲ್ಲಿ ಸಮನಾಗಿ ಬರುತ್ತದೆ.',
        );
      default:
        final pick = rng.shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9]);
        final shape = rng.pick([
          [2, 1, 1],
          [2, 2],
          [3, 1],
          [2, 2, 1],
          [3, 2],
        ]);
        digits = [for (var i = 0; i < shape.length; i++) ...List.filled(shape[i], pick[i])];
        digits = rng.shuffled(digits);
        prompt = LText(
          'How many different numbers can be written with the digits ${digits.join(', ')}, using all of them?',
          '${digits.join(', ')} ಅಂಕಿಗಳನ್ನೆಲ್ಲ ಬಳಸಿ ಎಷ್ಟು ಬೇರೆಬೇರೆ ಸಂಖ್ಯೆಗಳನ್ನು ಬರೆಯಬಹುದು?',
        );
        answer = Answer(Rational(ankapasha(digits).count), units: const ['numbers', 'ಸಂಖ್ಯೆಗಳು']);
        nudge = const LText(
          'Swapping two equal digits gives the same number. Divide out those swaps.',
          'ಎರಡು ಸಮಾನ ಅಂಕಿಗಳನ್ನು ಅದಲುಬದಲು ಮಾಡಿದರೆ ಅದೇ ಸಂಖ್ಯೆ. ಆ ಅದಲುಬದಲುಗಳಿಂದ ಭಾಗಿಸಿ.',
        );
    }
    final trace = ankapashaTrace(digits);
    return Problem(
      generatorId: id,
      seed: seed,
      difficulty: difficulty,
      prompt: prompt,
      answer: answer,
      hints: hintLadder(nudge: nudge, trace: trace, answer: answer),
      solution: trace,
      data: {'digits': (List.of(digits)..sort()).join(), 'k': difficulty},
    );
  }
}
