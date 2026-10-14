import 'dart:io';

import 'package:content_model/content_model.dart';
import 'package:test/test.dart';

/// Runs against the pack built by `python -m tools.pack build`
/// (CI builds it before the Dart tests).
void main() {
  final path = '../../build/pack/content.db';
  late SqliteContentRepository repo;

  setUpAll(() {
    if (!File(path).existsSync()) {
      fail('Build the pack first: python -m tools.pack build');
    }
    repo = SqliteContentRepository.open(path);
  });
  tearDownAll(() => repo.close());

  test('meta', () {
    expect(repo.schemaVersion, 1);
    expect(repo.contentVersion, matches(RegExp(r'^\d{4}\.\d{2}\.\d{2}')));
  });

  test('ten lessons, each with a summary card and no unsupported cards', () {
    final lessons = repo.lessons();
    expect(lessons, hasLength(10));
    for (final s in lessons) {
      final doc = repo.lesson(s.id)!;
      expect(doc.cards.last, isA<SummaryCard>());
      expect(doc.hasUnsupportedCards, isFalse, reason: s.id);
      expect(s.title.kn, isNot(s.title.en), reason: 'Kannada title for ${s.id}');
    }
  });

  test('the bee verse in three scripts with Colebrooke beside it', () {
    final v = repo.verse('verse.lilavati.55')!;
    expect(v.text(VerseScript.devanagari), startsWith('पञ्च'));
    expect(v.text(VerseScript.kannada), startsWith('ಪಞ್ಚ'));
    expect(v.text(VerseScript.iast), startsWith('pañca'));
    final segs = repo.segmentsFor(v.id);
    expect(segs.single.translator, 'H. T. Colebrooke');
    expect(segs.single.glossary.map((g) => g.headword), contains('Cadamba'));
  });

  test('translation coverage is reported honestly', () {
    final t = {for (final x in repo.translations()) x.id: x};
    expect(t['translation.taylor-1816']!.covered, 0);
    expect(t['translation.colebrooke-1817']!.covered, greaterThan(0));
  });

  test('concept page gathers verses in date order, lessons, people and sources', () {
    final c = repo.concept('concept.trairashika')!;
    expect(c.verses.first.$1.workId, 'work.aryabhatiya'); // 499 before 628 before 1150
    expect(c.lessons.map((l) => l.id), contains('lesson.trairashika'));
    expect(c.people.map((p) => p.id), containsAll(['person.aryabhata', 'person.brahmagupta']));
    expect(c.sources, isNotEmpty);
  });

  test('lineage', () {
    final d = repo.person('person.damodara')!;
    expect(d.teachers.map((p) => p.id), ['person.paramesvara']);
    expect(d.students.map((p) => p.id), containsAll(['person.nilakantha', 'person.jyesthadeva']));
  });

  test('School: class 6 chapters with lessons; empty ones are marked empty', () {
    final chapters = repo.chapters(6);
    final fractions = chapters.firstWhere((c) => c.id == 'ncert.6.gp.fractions');
    expect(fractions.lessons.single.id, 'lesson.bee-swarm');
    expect(chapters.firstWhere((c) => c.id == 'ncert.6.gp.patterns').isEmpty, isTrue);
    expect(repo.chapters(12).single.recommended, isTrue);
  });

  test('search in any script', () {
    for (final q in ['kuttaka', 'कुट्टक', 'ಕುಟ್ಟಕ', 'kuṭṭaka']) {
      expect(repo.search(q, 'en').map((h) => h.id), contains('lesson.kuttaka'), reason: q);
    }
    expect(repo.search('Pythagoras', 'kn').map((h) => h.id), contains('concept.bhuja-koti-karna'));
    expect(repo.search('', 'en'), isEmpty);
  });

  test('works, sections and the reading room', () {
    final lil = repo.works().firstWhere((w) => w.id == 'work.lilavati');
    expect(lil.sections.length, greaterThan(10));
    final verses = repo.versesOfSection(lil.sections.first.$1);
    expect(verses, isNotEmpty);
    expect(repo.timeline().first.yearFrom, lessThan(0));
  });
}
