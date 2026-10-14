import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

void main() {
  const checker = AnswerChecker();

  test('accepts integers, fractions, mixed numbers and units', () {
    final a = Answer(r(105, 2), form: AnswerForm.fraction, units: const ['palas', 'ಪಲ']);
    for (final input in ['105/2', '52 1/2', '52.5', '52 1/2 palas', ' 52.50 ', '೫೨.೫ ಪಲ']) {
      expect(checker.check(input, a).verdict, Verdict.correct, reason: input);
    }
    expect(checker.check('52', a).verdict, Verdict.wrong);
    expect(checker.check('fifty', a).verdict, Verdict.unreadable);
  });

  test('decimals for non-terminating answers need two places and the right rounding', () {
    final a = Answer(r(1, 3), form: AnswerForm.fraction);
    expect(checker.check('0.33', a).verdict, Verdict.correctApprox);
    expect(checker.check('0.333', a).verdict, Verdict.correctApprox);
    expect(checker.check('0.3', a).verdict, Verdict.wrong);
    expect(checker.check('0.34', a).verdict, Verdict.wrong);
  });

  test('negative answers and the true minus sign', () {
    final a = Answer(r(-15));
    expect(checker.check('-15', a).isCorrect, isTrue);
    expect(checker.check('−15', a).isCorrect, isTrue);
    expect(checker.check('15', a).isCorrect, isFalse);
  });
}
