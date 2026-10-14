/// Spaced review (plan §6.8). Screens depend on [ReviewScheduler] only, so a
/// better algorithm (FSRS) can replace Leitner boxes later.
class ReviewState {
  /// 1-based box number; 0 means "not yet in review".
  final int box;
  final DateTime due;

  const ReviewState(this.box, this.due);
}

abstract class ReviewScheduler {
  ReviewState next(ReviewState? current, {required bool correct, required DateTime now});
}

class LeitnerScheduler implements ReviewScheduler {
  /// Days until the next review for boxes 1..5.
  static const intervals = [1, 3, 7, 16, 35];

  const LeitnerScheduler();

  @override
  ReviewState next(ReviewState? current, {required bool correct, required DateTime now}) {
    final box = correct ? ((current?.box ?? 0) + 1).clamp(1, intervals.length) : 1;
    final day = DateTime(now.year, now.month, now.day);
    return ReviewState(box, day.add(Duration(days: intervals[box - 1])));
  }
}
