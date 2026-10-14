import 'package:flutter_test/flutter_test.dart';
import 'package:ganitaveda/shared/data/settings.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates a fresh database to the latest version', () {
    final s = UserStore.inMemory();
    expect(s.version, UserStore.latestVersion);
  });

  test('refuses a database from a newer app', () {
    final db = sqlite3.openInMemory()..execute('PRAGMA user_version = 99');
    expect(() => UserStore.wrap(db), throwsStateError);
  });

  test('settings round-trip', () {
    final s = UserStore.inMemory();
    const settings = AppSettings(
      locale: 'kn',
      classNo: 8,
      script: 'kannada',
      textScale: 1.5,
      onboarded: true,
      translationOrder: {
        'kn': ['a', 'b'],
      },
    );
    for (final e in settings.toMap().entries) {
      s.writeSetting(e.key, e.value);
    }
    final back = AppSettings.fromMap(s.readSettings());
    expect(back.locale, 'kn');
    expect(back.classNo, 8);
    expect(back.textScale, 1.5);
    expect(back.translationOrder['kn'], ['a', 'b']);
  });

  test('progress resumes exactly and survives completion', () {
    final s = UserStore.inMemory();
    s.saveProgress('lesson.bee-swarm', 1, 3, {
      'play': {'n': 15},
    });
    final p = s.progress('lesson.bee-swarm')!;
    expect(p.cardIndex, 3);
    expect((p.state['play']! as Map)['n'], 15);
    expect(s.lastInProgress()!.lessonId, 'lesson.bee-swarm');
    s.completeLesson('lesson.bee-swarm', 1);
    s.saveProgress('lesson.bee-swarm', 1, 0, {}); // reopening a finished lesson keeps it done
    expect(s.progress('lesson.bee-swarm')!.done, isTrue);
    expect(s.completedLessons(), ['lesson.bee-swarm']);
  });

  test('attempts are logged and reviews follow Leitner boxes', () {
    final s = UserStore.inMemory();
    final day = DateTime(2026, 11, 1, 9);
    s.logAttempt(
      templateId: 't',
      seed: 1,
      answer: '15',
      correct: true,
      hintsUsed: 0,
      ms: 900,
      firstTry: true,
      now: day,
    );
    expect(s.attemptCount(), 1);
    final first = s.scheduleReview(templateId: 't', generatorId: 'g', correct: true, now: day);
    expect(first.box, 1);
    expect(s.dueReviews(day), isEmpty);
    expect(s.dueReviews(day.add(const Duration(days: 1))).single.templateId, 't');
    final second = s.scheduleReview(
      templateId: 't',
      generatorId: 'g',
      correct: true,
      now: day.add(const Duration(days: 1)),
    );
    expect(second.box, 2);
    final back = s.scheduleReview(
      templateId: 't',
      generatorId: 'g',
      correct: false,
      now: day.add(const Duration(days: 4)),
    );
    expect(back.box, 1);
  });

  test('bookmarks and id redirects', () {
    final s = UserStore.inMemory();
    s.setBookmark('concept.old', on: true);
    s.saveProgress('lesson.old', 1, 2, {});
    s.applyRedirects({'concept.old': 'concept.new', 'lesson.old': 'lesson.new'});
    expect(s.bookmarks(), ['concept.new']);
    expect(s.progress('lesson.new')!.cardIndex, 2);
  });
}
