import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

void main() {
  const s = LeitnerScheduler();
  final now = DateTime(2026, 11, 1, 18, 30);

  test('correct answers climb the boxes 1, 3, 7, 16, 35 days', () {
    var state = s.next(null, correct: true, now: now);
    final days = <int>[];
    for (var i = 0; i < 6; i++) {
      days.add(state.due.difference(DateTime(2026, 11, 1)).inDays);
      state = s.next(state, correct: true, now: now);
    }
    expect(days, [1, 3, 7, 16, 35, 35]);
  });

  test('a wrong answer goes back to box 1', () {
    final high = ReviewState(4, DateTime(2026));
    final back = s.next(high, correct: false, now: now);
    expect(back.box, 1);
    expect(back.due, DateTime(2026, 11, 2));
  });
}
