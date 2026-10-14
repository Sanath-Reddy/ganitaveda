import 'rational.dart';
import 'text.dart';

/// One line of worked solution: the words, and optionally the arithmetic.
class Step {
  final LText text;

  /// Plain arithmetic shown under the words, e.g. `30 × 1 ÷ 2 = 15`.
  final String? working;

  /// Named values at this step, for widgets that draw the trace.
  final Map<String, Rational> values;

  const Step(this.text, {this.working, this.values = const {}});
}

/// The output of an algorithm: classical steps and the modern working beside them.
class Trace {
  final List<Step> classical;
  final List<Step> modern;
  final Map<String, Rational> result;

  const Trace({required this.classical, this.modern = const [], this.result = const {}});
}

enum AnswerForm { integer, fraction }

class Answer {
  final Rational value;
  final AnswerForm form;

  /// Unit words accepted (and ignored) after the number, in either language.
  final List<String> units;

  const Answer(this.value, {this.form = AnswerForm.integer, this.units = const []});

  /// The canonical way to write the answer (what the full-solution hint shows).
  String get canonical => form == AnswerForm.fraction ? value.toMixedString() : value.toString();
}

class Problem {
  final String generatorId;
  final int seed;
  final int difficulty;
  final LText prompt;
  final Answer answer;

  /// Nudge, classical step, full solution (plan §4.6).
  final List<LText> hints;
  final Trace solution;

  /// The numbers that define this problem; two problems with equal [key] are repeats.
  final Map<String, Object> data;

  const Problem({
    required this.generatorId,
    required this.seed,
    required this.difficulty,
    required this.prompt,
    required this.answer,
    required this.hints,
    required this.solution,
    required this.data,
  });

  String get key => '$generatorId|${(data.keys.toList()..sort()).map((k) => '$k=${data[k]}').join(',')}';
}

abstract class Generator {
  String get id;

  /// Difficulty 1–3. Must be deterministic in [seed].
  Problem generate(int seed, int difficulty);
}
