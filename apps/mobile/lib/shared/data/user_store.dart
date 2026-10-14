import 'dart:convert';

import 'package:ganita_core/ganita_core.dart';
import 'package:sqlite3/sqlite3.dart';

/// user.db (plan §6.4, Appendix B): settings, progress, the attempts log,
/// the review queue, bookmarks and pack history. It stores ids from
/// content.db, never copies of content, so content updates never touch it.
///
/// Migrations run in order inside a transaction; [migrations] only grows.
class UserStore {
  new _(this.db);

  factory open(String path) => UserStore.wrap(sqlite3.open(path));

  factory inMemory() => UserStore.wrap(sqlite3.openInMemory());

  factory wrap(Database db) {
    db.execute('PRAGMA journal_mode = WAL');
    final store = UserStore._(db);
    store._migrate();
    return store;
  }
  final Database db;

  static const migrations = <List<String>>[
    // 1: the Appendix B tables.
    [
      'CREATE TABLE setting (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      '''
CREATE TABLE lesson_progress (lesson_id TEXT PRIMARY KEY, lesson_version INTEGER NOT NULL,
           status TEXT NOT NULL, card_index INTEGER NOT NULL, state_json TEXT NOT NULL, updated_at INTEGER NOT NULL,
           completed_at INTEGER)''',
      '''
CREATE TABLE attempt (id INTEGER PRIMARY KEY AUTOINCREMENT, lesson_id TEXT, template_id TEXT NOT NULL,
           seed INTEGER NOT NULL, answer TEXT NOT NULL, correct INTEGER NOT NULL, hints_used INTEGER NOT NULL,
           ms INTEGER NOT NULL, at INTEGER NOT NULL, first_try INTEGER NOT NULL DEFAULT 1)''',
      'CREATE INDEX attempt_template ON attempt (template_id, at)',
      '''
CREATE TABLE review_item (template_id TEXT PRIMARY KEY, generator_id TEXT NOT NULL, lesson_id TEXT,
           box INTEGER NOT NULL, due_at INTEGER NOT NULL)''',
      'CREATE TABLE bookmark (entity_id TEXT PRIMARY KEY, at INTEGER NOT NULL)',
      'CREATE TABLE pack_history (content_version TEXT NOT NULL, installed_at INTEGER NOT NULL, status TEXT NOT NULL)',
    ],
  ];

  static int get latestVersion => migrations.length;

  int get version => db.select('PRAGMA user_version').first.values.first! as int;

  void _migrate() {
    final from = version;
    if (from > migrations.length) {
      throw StateError('user.db is newer ($from) than this app understands (${migrations.length})');
    }
    for (var v = from; v < migrations.length; v++) {
      db.execute('BEGIN');
      try {
        migrations[v].forEach(db.execute);
        db.execute('PRAGMA user_version = ${v + 1}');
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  // ---------------------------------------------------------------- settings

  Map<String, Object?> readSettings() => {
    for (final r in db.select('SELECT key, value FROM setting')) r['key'] as String: jsonDecode(r['value'] as String),
  };

  void writeSetting(String key, Object? value) => db.execute(
    'INSERT INTO setting (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, jsonEncode(value)],
  );

  // ---------------------------------------------------------------- progress

  LessonProgress? progress(String lessonId) {
    final rows = db.select('SELECT * FROM lesson_progress WHERE lesson_id = ?', [lessonId]);
    return rows.isEmpty ? null : LessonProgress._(rows.first);
  }

  List<LessonProgress> allProgress() => [
    for (final r in db.select('SELECT * FROM lesson_progress ORDER BY updated_at DESC')) LessonProgress._(r),
  ];

  /// Saved on every card change so the student resumes exactly where they left off (plan §6.6).
  void saveProgress(String lessonId, int version, int cardIndex, Map<String, Object?> state, {DateTime? now}) {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    db.execute(
      '''
      INSERT INTO lesson_progress (lesson_id, lesson_version, status, card_index, state_json, updated_at)
      VALUES (?, ?, 'in_progress', ?, ?, ?)
      ON CONFLICT(lesson_id) DO UPDATE SET lesson_version = excluded.lesson_version,
        card_index = excluded.card_index, state_json = excluded.state_json, updated_at = excluded.updated_at,
        status = CASE WHEN status = 'done' THEN 'done' ELSE 'in_progress' END''',
      [lessonId, version, cardIndex, jsonEncode(state), at],
    );
  }

  void completeLesson(String lessonId, int version, {DateTime? now}) {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    db.execute(
      '''
      INSERT INTO lesson_progress (lesson_id, lesson_version, status, card_index, state_json, updated_at, completed_at)
      VALUES (?, ?, 'done', 0, '{}', ?, ?)
      ON CONFLICT(lesson_id) DO UPDATE SET status = 'done', updated_at = excluded.updated_at,
        completed_at = COALESCE(completed_at, excluded.completed_at)''',
      [lessonId, version, at, at],
    );
  }

  /// Finished lessons in the order they were first finished (the kolam's order).
  List<String> completedLessons() => [
    for (final r in db.select(
      "SELECT lesson_id FROM lesson_progress WHERE status = 'done' ORDER BY completed_at, lesson_id",
    ))
      r['lesson_id'] as String,
  ];

  LessonProgress? lastInProgress() {
    final rows = db.select(
      "SELECT * FROM lesson_progress WHERE status = 'in_progress' ORDER BY updated_at DESC LIMIT 1",
    );
    return rows.isEmpty ? null : LessonProgress._(rows.first);
  }

  // ---------------------------------------------------------------- attempts and review

  /// Attempts are an append-only log (plan §6.4); review state is derived from it.
  void logAttempt({
    required String templateId,
    required int seed,
    required String answer,
    required bool correct,
    required int hintsUsed,
    required int ms,
    required bool firstTry,
    String? lessonId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    db.execute(
      '''
INSERT INTO attempt (lesson_id, template_id, seed, answer, correct, hints_used, ms, at, first_try)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        lessonId,
        templateId,
        seed,
        answer,
        if (correct) 1 else 0,
        hintsUsed,
        ms,
        at.millisecondsSinceEpoch,
        if (firstTry) 1 else 0,
      ],
    );
  }

  /// Puts a practice template into review, or moves it along after a review
  /// answer. A first-try correct answer without hints counts as correct.
  ReviewState scheduleReview({
    required String templateId,
    required String generatorId,
    required bool correct,
    String? lessonId,
    DateTime? now,
    ReviewScheduler scheduler = const LeitnerScheduler(),
  }) {
    final at = now ?? DateTime.now();
    final current = reviewState(templateId);
    final next = scheduler.next(current, correct: correct, now: at);
    db.execute(
      '''
      INSERT INTO review_item (template_id, generator_id, lesson_id, box, due_at) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(template_id) DO UPDATE SET box = excluded.box, due_at = excluded.due_at''',
      [templateId, generatorId, lessonId, next.box, next.due.millisecondsSinceEpoch],
    );
    return next;
  }

  ReviewState? reviewState(String templateId) {
    final rows = db.select('SELECT box, due_at FROM review_item WHERE template_id = ?', [templateId]);
    if (rows.isEmpty) return null;
    return ReviewState(rows.first['box'] as int, DateTime.fromMillisecondsSinceEpoch(rows.first['due_at'] as int));
  }

  List<ReviewItem> reviewItems() => [
    for (final r in db.select('SELECT * FROM review_item ORDER BY due_at'))
      ReviewItem(
        r['template_id'] as String,
        r['generator_id'] as String,
        r['lesson_id'] as String?,
        r['box'] as int,
        DateTime.fromMillisecondsSinceEpoch(r['due_at'] as int),
      ),
  ];

  List<ReviewItem> dueReviews(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return reviewItems().where((r) => r.due.isBefore(endOfDay)).toList();
  }

  int attemptCount() => db.select('SELECT count(*) AS n FROM attempt').first['n'] as int;

  // ---------------------------------------------------------------- bookmarks

  bool isBookmarked(String id) => db.select('SELECT 1 FROM bookmark WHERE entity_id = ?', [id]).isNotEmpty;

  void setBookmark(String id, {required bool on}) => on
      ? db.execute('INSERT OR IGNORE INTO bookmark VALUES (?, ?)', [id, DateTime.now().millisecondsSinceEpoch])
      : db.execute('DELETE FROM bookmark WHERE entity_id = ?', [id]);

  List<String> bookmarks() => [
    for (final r in db.select('SELECT entity_id FROM bookmark ORDER BY at DESC')) r['entity_id'] as String,
  ];

  // ---------------------------------------------------------------- pack history

  void logPack(String contentVersion, String status) => db.execute('INSERT INTO pack_history VALUES (?, ?, ?)', [
    contentVersion,
    DateTime.now().millisecondsSinceEpoch,
    status,
  ]);

  List<(String, String)> packHistory() => [
    for (final r in db.select('SELECT content_version, status FROM pack_history ORDER BY installed_at DESC'))
      (r['content_version'] as String, r['status'] as String),
  ];

  /// Renamed ids from a new pack's redirect table are applied to stored progress.
  void applyRedirects(Map<String, String> redirects) {
    if (redirects.isEmpty) return;
    db.execute('BEGIN');
    for (final e in redirects.entries) {
      db.execute('UPDATE OR IGNORE lesson_progress SET lesson_id = ? WHERE lesson_id = ?', [e.value, e.key]);
      db.execute('UPDATE OR IGNORE bookmark SET entity_id = ? WHERE entity_id = ?', [e.value, e.key]);
      db.execute('UPDATE attempt SET lesson_id = ? WHERE lesson_id = ?', [e.value, e.key]);
    }
    db.execute('COMMIT');
  }

  void close() => db.close();
}

class LessonProgress {
  new _(Row r)
    : lessonId = r['lesson_id'] as String,
      lessonVersion = r['lesson_version'] as int,
      status = r['status'] as String,
      cardIndex = r['card_index'] as int,
      state = Map<String, Object?>.from(jsonDecode(r['state_json'] as String) as Map),
      updatedAt = DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int);
  final String lessonId;
  final int lessonVersion;
  final String status;
  final int cardIndex;
  final Map<String, Object?> state;
  final DateTime updatedAt;

  bool get done => status == 'done';
}

class ReviewItem {
  const new(this.templateId, this.generatorId, this.lessonId, this.box, this.due);
  final String templateId;
  final String generatorId;
  final String? lessonId;
  final int box;
  final DateTime due;
}
