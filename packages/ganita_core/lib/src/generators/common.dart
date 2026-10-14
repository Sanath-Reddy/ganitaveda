import '../problem.dart';
import '../text.dart';

/// Builds the three-step hint ladder (plan §4.6): a nudge, the classical
/// step, and the full solution ending in the answer.
List<LText> hintLadder({required LText nudge, required Trace trace, required Answer answer}) {
  final steps = trace.classical;
  final key = steps.length > 1 ? steps[steps.length ~/ 2] : steps.first;
  final keyText = key.working == null
      ? key.text
      : LText('${key.text.en}\n${key.working}', '${key.text.kn}\n${key.working}');
  final full = LText(
    '${steps.map((s) => s.text.en).where((t) => t.isNotEmpty).join(' ')}\nAnswer: ${answer.canonical}',
    '${steps.map((s) => s.text.kn).where((t) => t.isNotEmpty).join(' ')}\nಉತ್ತರ: ${answer.canonical}',
  );
  return [nudge, keyText, full];
}

/// Mixes a session seed with a problem index into a well-spread seed.
int mixSeed(int session, int index) {
  var x = (session * 0x9E3779B1 + index * 0x85EBCA77) & 0xFFFFFFFF;
  x ^= x >>> 16;
  x = (x * 0x7FEB352D) & 0xFFFFFFFF;
  x ^= x >>> 15;
  return x;
}
