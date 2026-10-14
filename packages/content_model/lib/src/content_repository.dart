import 'dart:convert';

import 'package:ganita_core/ganita_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'lesson.dart';

/// Scripts a verse can be shown in. Rows in `verse_text`, so more scripts are
/// a build-config change (plan §5.3).
enum VerseScript { devanagari, kannada, iast }

class Area {
  final String id;
  final LText name;
  final String sanskritIast;
  final LText blurb;
  const Area(this.id, this.name, this.sanskritIast, this.blurb);
}

class LessonSummary {
  final String id;
  final LText title;
  final LText? subtitle;
  final int minutes;
  final String areaId;
  const LessonSummary(this.id, this.title, this.subtitle, this.minutes, this.areaId);
}

class Verse {
  final String id;
  final String workId;
  final LText workTitle;
  final String workIast;
  final String refLabel;
  final String review;
  final Map<VerseScript, String> texts;
  final String sourceCitation;
  final String licenceName;
  const Verse(
    this.id,
    this.workId,
    this.workTitle,
    this.workIast,
    this.refLabel,
    this.review,
    this.texts,
    this.sourceCitation,
    this.licenceName,
  );

  String text(VerseScript s) => texts[s] ?? texts[VerseScript.devanagari]!;
}

class TranslationInfo {
  final String id;
  final String translator;
  final int year;
  final String language;
  final String kind;
  final LText about;
  final LText? styleNote;
  final String licenceName;
  final Map<String, (int covered, int total)> coverage;
  const TranslationInfo(
    this.id,
    this.translator,
    this.year,
    this.language,
    this.kind,
    this.about,
    this.styleNote,
    this.licenceName,
    this.coverage,
  );

  int get covered => coverage.values.fold(0, (s, c) => s + c.$1);
  int get total => coverage.values.fold(0, (s, c) => s + c.$2);
}

class GlossaryEntry {
  final String id;
  final String headword;
  final LText note;
  const GlossaryEntry(this.id, this.headword, this.note);
}

class Segment {
  final String id;
  final String translationId;
  final String translator;
  final int year;
  final String? label;
  final String text;
  final String page;
  final String status;
  final List<GlossaryEntry> glossary;
  const Segment(
    this.id,
    this.translationId,
    this.translator,
    this.year,
    this.label,
    this.text,
    this.page,
    this.status,
    this.glossary,
  );
}

class Term {
  final String id;
  final String devanagari, kannada, iast;
  final LText gloss;
  final String? conceptId;
  const Term(this.id, this.devanagari, this.kannada, this.iast, this.gloss, this.conceptId);

  String inScript(VerseScript s) => switch (s) {
    VerseScript.devanagari => devanagari,
    VerseScript.kannada => kannada,
    VerseScript.iast => iast,
  };
}

class SourceRef {
  final String id;
  final String citation;
  final String? url;
  final String? note;
  final String licenceName;
  final String? attribution;
  final String kind;
  const SourceRef(this.id, this.citation, this.url, this.note, this.licenceName, this.attribution, this.kind);
}

class ConceptSummary {
  final String id;
  final LText name;
  final String classicalIast;
  final LText summary;
  final String areaId;
  const ConceptSummary(this.id, this.name, this.classicalIast, this.summary, this.areaId);
}

class ConceptPage {
  final ConceptSummary concept;
  final LText modernName;
  final LText body;
  final List<(Verse, String)> verses;
  final List<LessonSummary> lessons;
  final List<(ConceptSummary, String)> related;
  final List<PersonSummary> people;
  final List<SourceRef> sources;
  const ConceptPage(
    this.concept,
    this.modernName,
    this.body,
    this.verses,
    this.lessons,
    this.related,
    this.people,
    this.sources,
  );
}

class PersonSummary {
  final String id;
  final LText name;
  final String nameIast;
  final LText datesLabel;
  final int sortYear;
  const PersonSummary(this.id, this.name, this.nameIast, this.datesLabel, this.sortYear);
}

class PersonPage {
  final PersonSummary person;
  final LText summary;
  final LText? place;
  final List<(String id, LText title)> works;
  final List<PersonSummary> teachers;
  final List<PersonSummary> students;
  final List<ConceptSummary> concepts;
  final List<SourceRef> sources;
  const PersonPage(
    this.person,
    this.summary,
    this.place,
    this.works,
    this.teachers,
    this.students,
    this.concepts,
    this.sources,
  );
}

class TimelineEvent {
  final String id;
  final int yearFrom, yearTo;
  final String region;
  final LText label;
  final LText? detail;
  final List<String> links;
  final SourceRef source;
  const TimelineEvent(
    this.id,
    this.yearFrom,
    this.yearTo,
    this.region,
    this.label,
    this.detail,
    this.links,
    this.source,
  );
}

class WorkInfo {
  final String id;
  final LText title;
  final String titleIast;
  final LText about;
  final String authorId;
  final int yearFrom, yearTo;
  final List<(String id, LText label, int verses)> sections;
  final SourceRef source;
  const WorkInfo(
    this.id,
    this.title,
    this.titleIast,
    this.about,
    this.authorId,
    this.yearFrom,
    this.yearTo,
    this.sections,
    this.source,
  );
}

class MediaSegment {
  final String id;
  final String provider;
  final String externalId;
  final LText title;
  final LText mediaTitle;
  final String speaker;
  final String organisation;
  final int startS, endS;
  const MediaSegment(
    this.id,
    this.provider,
    this.externalId,
    this.title,
    this.mediaTitle,
    this.speaker,
    this.organisation,
    this.startS,
    this.endS,
  );

  Duration get length => Duration(seconds: endS - startS);
  Uri get uri => Uri.parse('https://www.youtube.com/watch?v=$externalId&t=${startS}s');
}

class ChapterEntry {
  final String id;
  final int classNo;
  final int number;
  final LText title;
  final LText bookTitle;
  final List<LessonSummary> lessons;
  final List<MediaSegment> watch;
  final bool recommended;
  const ChapterEntry(
    this.id,
    this.classNo,
    this.number,
    this.title,
    this.bookTitle,
    this.lessons,
    this.watch,
    this.recommended,
  );

  bool get isEmpty => lessons.isEmpty && watch.isEmpty;
}

class SearchHit {
  final String type;
  final String id;
  final String title;
  final String snippet;
  const SearchHit(this.type, this.id, this.title, this.snippet);
}

class LicenceInfo {
  final String id, name, url;
  final bool commercialUse;
  const LicenceInfo(this.id, this.name, this.url, this.commercialUse);
}

/// Everything screens read from the content pack. Screens depend on this
/// interface only (plan §6.3), so storage can change without touching them.
abstract interface class ContentRepository {
  String get contentVersion;
  int get schemaVersion;

  List<Area> areas();
  List<LessonSummary> lessons();
  LessonDoc? lesson(String id);
  LessonSummary? lessonSummary(String id);
  Verse? verse(String id);
  List<Segment> segmentsFor(String verseId);
  List<TranslationInfo> translations();
  List<Term> termsFor(List<String> ids);
  List<ConceptSummary> concepts({String? areaId});
  ConceptPage? concept(String id);
  List<PersonSummary> people();
  PersonPage? person(String id);
  List<TimelineEvent> timeline();
  List<WorkInfo> works();
  List<Verse> versesOfSection(String sectionId);
  List<ChapterEntry> chapters(int classNo);
  MediaSegment? mediaSegment(String id);
  List<SearchHit> search(String query, String locale, {int limit});
  List<SourceRef> sources();
  List<LicenceInfo> licences();

  /// The first verse a translation segment translates (search results open it).
  String? verseOfSegment(String segmentId);

  /// Resolves renamed ids through the pack's redirect table.
  String resolve(String id);

  void close();
}

class SqliteContentRepository implements ContentRepository {
  final Database _db;
  final Map<String, LText> _ltCache = {};

  SqliteContentRepository(this._db) {
    _loadTexts();
  }

  factory SqliteContentRepository.open(String path) =>
      SqliteContentRepository(sqlite3.open(path, mode: OpenMode.readOnly));

  /// localized_text is small; read it once.
  void _loadTexts() {
    final en = <String, String>{}, kn = <String, String>{};
    for (final row in _db.select('SELECT entity_id, field, locale, text FROM localized_text')) {
      final key = '${row['entity_id']}#${row['field']}';
      (row['locale'] == 'kn' ? kn : en)[key] = row['text'] as String;
    }
    for (final e in en.entries) {
      _ltCache[e.key] = LText(e.value, kn[e.key] ?? e.value);
    }
  }

  LText _lt(String id, String field) => _ltCache['$id#$field'] ?? const LText('', '');
  LText? _ltn(String id, String field) => _ltCache['$id#$field'];

  late final Map<String, String> _meta = {
    for (final r in _db.select('SELECT key, value FROM meta')) r['key'] as String: r['value'] as String,
  };

  @override
  String get contentVersion => _meta['content_version'] ?? '0';

  @override
  int get schemaVersion => int.parse(_meta['schema_version'] ?? '0');

  @override
  String resolve(String id) {
    var current = id;
    for (var i = 0; i < 5; i++) {
      final rows = _db.select('SELECT new_id FROM redirect WHERE old_id = ?', [current]);
      if (rows.isEmpty) break;
      current = rows.first['new_id'] as String;
    }
    return current;
  }

  @override
  List<Area> areas() => [
    for (final r in _db.select('SELECT id, sanskrit_iast FROM area ORDER BY ordinal'))
      Area(
        r['id'] as String,
        _lt(r['id'] as String, 'name'),
        r['sanskrit_iast'] as String,
        _lt(r['id'] as String, 'blurb'),
      ),
  ];

  LessonSummary _lessonRow(Row r) => LessonSummary(
    r['id'] as String,
    _lt(r['id'] as String, 'title'),
    _ltn(r['id'] as String, 'subtitle'),
    r['minutes'] as int,
    r['area_id'] as String,
  );

  @override
  List<LessonSummary> lessons() => [
    for (final r in _db.select('SELECT id, minutes, area_id FROM lesson ORDER BY id')) _lessonRow(r),
  ];

  @override
  LessonSummary? lessonSummary(String id) {
    final rows = _db.select('SELECT id, minutes, area_id FROM lesson WHERE id = ?', [resolve(id)]);
    return rows.isEmpty ? null : _lessonRow(rows.first);
  }

  @override
  LessonDoc? lesson(String id) {
    final rows = _db.select('SELECT doc_json FROM lesson WHERE id = ?', [resolve(id)]);
    if (rows.isEmpty) return null;
    return LessonDoc.fromJson(jsonDecode(rows.first['doc_json'] as String) as Map<String, Object?>);
  }

  SourceRef _source(String id, {String? note}) {
    final r = _db.select(
      'SELECT s.id, s.citation, s.url, s.attribution, s.kind, l.name FROM source s JOIN licence l ON l.id = s.licence_id WHERE s.id = ?',
      [id],
    ).first;
    return SourceRef(
      r['id'] as String,
      r['citation'] as String,
      r['url'] as String?,
      note,
      r['name'] as String,
      r['attribution'] as String?,
      r['kind'] as String,
    );
  }

  List<SourceRef> _claims(String entityId) => [
    for (final r in _db.select('SELECT DISTINCT source_id, note FROM claim_source WHERE entity_id = ?', [entityId]))
      _source(r['source_id'] as String, note: r['note'] as String?),
  ];

  @override
  Verse? verse(String id) {
    final rows = _db.select(
      '''
      SELECT v.id, v.work_id, v.ref_label, v.review, w.title_iast, w.source_id, l.name AS licence
      FROM verse v JOIN work w ON w.id = v.work_id JOIN licence l ON l.id = w.licence_id WHERE v.id = ?''',
      [resolve(id)],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final texts = {
      for (final t in _db.select('SELECT script, text FROM verse_text WHERE verse_id = ?', [r['id']]))
        VerseScript.values.byName(t['script'] as String): t['text'] as String,
    };
    return Verse(
      r['id'] as String,
      r['work_id'] as String,
      _lt(r['work_id'] as String, 'title'),
      r['title_iast'] as String,
      r['ref_label'] as String,
      r['review'] as String,
      texts,
      _source(r['source_id'] as String).citation,
      r['licence'] as String,
    );
  }

  @override
  List<Segment> segmentsFor(String verseId) => [
    for (final r in _db.select(
      '''
          SELECT s.id, s.translation_id, t.translator, t.year, s.label, s.text, s.page, s.status
          FROM segment_verse sv JOIN translation_segment s ON s.id = sv.segment_id
          JOIN translation t ON t.id = s.translation_id WHERE sv.verse_id = ? ORDER BY t.year''',
      [resolve(verseId)],
    ))
      Segment(
        r['id'] as String,
        r['translation_id'] as String,
        r['translator'] as String,
        r['year'] as int,
        r['label'] as String?,
        r['text'] as String,
        r['page'] as String,
        r['status'] as String,
        [
          for (final g in _db.select(
            'SELECT g.id, g.headword FROM segment_glossary sg JOIN glossary g ON g.id = sg.glossary_id WHERE sg.segment_id = ?',
            [r['id']],
          ))
            GlossaryEntry(g['id'] as String, g['headword'] as String, _lt(g['id'] as String, 'note')),
        ],
      ),
  ];

  @override
  List<TranslationInfo> translations() => [
    for (final r in _db.select(
      'SELECT t.id, t.translator, t.year, t.language, t.kind, l.name FROM translation t JOIN licence l ON l.id = t.licence_id ORDER BY t.year',
    ))
      TranslationInfo(
        r['id'] as String,
        r['translator'] as String,
        r['year'] as int,
        r['language'] as String,
        r['kind'] as String,
        _lt(r['id'] as String, 'about'),
        _ltn(r['id'] as String, 'style_note'),
        r['name'] as String,
        {
          for (final c in _db.select(
            'SELECT work_id, verses_covered, verses_total FROM translation_work WHERE translation_id = ?',
            [r['id']],
          ))
            c['work_id'] as String: (c['verses_covered'] as int, c['verses_total'] as int),
        },
      ),
  ];

  @override
  List<Term> termsFor(List<String> ids) => [
    for (final id in ids)
      for (final r in _db.select('SELECT * FROM term WHERE id = ?', [id]))
        Term(
          r['id'] as String,
          r['devanagari'] as String,
          r['kannada'] as String,
          r['iast'] as String,
          _lt(r['id'] as String, 'gloss'),
          r['concept_id'] as String?,
        ),
  ];

  ConceptSummary _conceptRow(Row r) => ConceptSummary(
    r['id'] as String,
    _lt(r['id'] as String, 'name'),
    r['classical_iast'] as String,
    _lt(r['id'] as String, 'summary'),
    r['area_id'] as String,
  );

  @override
  List<ConceptSummary> concepts({String? areaId}) => [
    for (final r
        in areaId == null
            ? _db.select('SELECT * FROM concept ORDER BY id')
            : _db.select('SELECT * FROM concept WHERE area_id = ? ORDER BY id', [areaId]))
      _conceptRow(r),
  ];

  PersonSummary _personRow(Row r) => PersonSummary(
    r['id'] as String,
    _lt(r['id'] as String, 'name'),
    r['name_iast'] as String,
    _lt(r['id'] as String, 'dates_label'),
    r['sort_year'] as int,
  );

  @override
  ConceptPage? concept(String id) {
    final rows = _db.select('SELECT * FROM concept WHERE id = ?', [resolve(id)]);
    if (rows.isEmpty) return null;
    final c = _conceptRow(rows.first);
    final verses = <(Verse, String)>[];
    for (final r in _db.select(
      '''
        SELECT cv.verse_id, cv.role FROM concept_verse cv JOIN verse v ON v.id = cv.verse_id
        JOIN work w ON w.id = v.work_id WHERE cv.concept_id = ? ORDER BY w.year_from, v.ordinal''',
      [c.id],
    )) {
      final v = verse(r['verse_id'] as String);
      if (v != null) verses.add((v, r['role'] as String));
    }
    return ConceptPage(
      c,
      _lt(c.id, 'modern_name'),
      _lt(c.id, 'body'),
      verses,
      [
        for (final r in _db.select(
          'SELECT l.id, l.minutes, l.area_id FROM lesson_concept lc JOIN lesson l ON l.id = lc.lesson_id WHERE lc.concept_id = ?',
          [c.id],
        ))
          _lessonRow(r),
      ],
      [
        for (final r in _db.select(
          'SELECT c.*, cr.type FROM concept_relation cr JOIN concept c ON c.id = cr.to_id WHERE cr.from_id = ?',
          [c.id],
        ))
          (_conceptRow(r), r['type'] as String),
      ],
      [
        for (final r in _db.select(
          'SELECT m.* FROM concept_person cp JOIN mathematician m ON m.id = cp.mathematician_id WHERE cp.concept_id = ? ORDER BY m.sort_year',
          [c.id],
        ))
          _personRow(r),
      ],
      _claims(c.id),
    );
  }

  @override
  List<PersonSummary> people() => [
    for (final r in _db.select('SELECT * FROM mathematician ORDER BY sort_year')) _personRow(r),
  ];

  @override
  PersonPage? person(String id) {
    final rows = _db.select('SELECT * FROM mathematician WHERE id = ?', [resolve(id)]);
    if (rows.isEmpty) return null;
    final p = _personRow(rows.first);
    final place = rows.first['place_id'] as String?;
    return PersonPage(
      p,
      _lt(p.id, 'summary'),
      place == null ? null : _lt(place, 'name'),
      [
        for (final r in _db.select('SELECT work_id FROM authored WHERE mathematician_id = ?', [p.id]))
          (r['work_id'] as String, _lt(r['work_id'] as String, 'title')),
      ],
      [
        for (final r in _db.select(
          'SELECT m.* FROM teacher_of t JOIN mathematician m ON m.id = t.teacher_id WHERE t.student_id = ?',
          [p.id],
        ))
          _personRow(r),
      ],
      [
        for (final r in _db.select(
          'SELECT m.* FROM teacher_of t JOIN mathematician m ON m.id = t.student_id WHERE t.teacher_id = ?',
          [p.id],
        ))
          _personRow(r),
      ],
      [
        for (final r in _db.select(
          'SELECT c.* FROM concept_person cp JOIN concept c ON c.id = cp.concept_id WHERE cp.mathematician_id = ?',
          [p.id],
        ))
          _conceptRow(r),
      ],
      _claims(p.id),
    );
  }

  @override
  List<TimelineEvent> timeline() => [
    for (final r in _db.select('SELECT * FROM timeline_event ORDER BY year_from, year_to'))
      TimelineEvent(
        r['id'] as String,
        r['year_from'] as int,
        r['year_to'] as int,
        r['region'] as String,
        _lt(r['id'] as String, 'label'),
        _ltn(r['id'] as String, 'detail'),
        [
          for (final l in _db.select('SELECT entity_id FROM timeline_link WHERE event_id = ?', [r['id']]))
            l['entity_id'] as String,
        ],
        _source(r['source_id'] as String, note: r['source_note'] as String?),
      ),
  ];

  @override
  List<WorkInfo> works() => [
    for (final r in _db.select('SELECT * FROM work ORDER BY year_from'))
      WorkInfo(
        r['id'] as String,
        _lt(r['id'] as String, 'title'),
        r['title_iast'] as String,
        _lt(r['id'] as String, 'about'),
        r['author_id'] as String,
        r['year_from'] as int,
        r['year_to'] as int,
        [
          for (final s in _db.select(
            'SELECT s.id, count(v.id) AS n FROM section s LEFT JOIN verse v ON v.section_id = s.id WHERE s.work_id = ? GROUP BY s.id ORDER BY s.ordinal',
            [r['id']],
          ))
            (s['id'] as String, _lt(s['id'] as String, 'label'), s['n'] as int),
        ],
        _source(r['source_id'] as String),
      ),
  ];

  @override
  List<Verse> versesOfSection(String sectionId) => [
    for (final r in _db.select('SELECT id FROM verse WHERE section_id = ? ORDER BY ordinal', [sectionId]))
      verse(r['id'] as String)!,
  ];

  @override
  MediaSegment? mediaSegment(String id) {
    final rows = _db.select(
      '''
      SELECT s.id, s.start_s, s.end_s, m.id AS media_id, m.provider, m.external_id, m.speaker, m.organisation
      FROM media_segment s JOIN media m ON m.id = s.media_id WHERE s.id = ?''',
      [resolve(id)],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return MediaSegment(
      r['id'] as String,
      r['provider'] as String,
      r['external_id'] as String,
      _lt(r['id'] as String, 'title'),
      _lt(r['media_id'] as String, 'title'),
      r['speaker'] as String,
      r['organisation'] as String,
      r['start_s'] as int,
      r['end_s'] as int,
    );
  }

  @override
  List<ChapterEntry> chapters(int classNo) {
    final out = <ChapterEntry>[];
    for (final n in _db.select(
      "SELECT * FROM curriculum_node WHERE board = 'board.ncert' AND class = ? ORDER BY chapter_no = 0, chapter_no, id",
      [classNo],
    )) {
      final lessons = <LessonSummary>[];
      final watch = <MediaSegment>[];
      var recommended = false;
      for (final l in _db.select(
        'SELECT entity_id, relevance FROM curriculum_link WHERE node_id = ? ORDER BY ordinal',
        [n['id']],
      )) {
        final id = l['entity_id'] as String;
        if (l['relevance'] == 'recommended') recommended = true;
        final lesson = lessonSummary(id);
        if (lesson != null) lessons.add(lesson);
        final seg = mediaSegment(id);
        if (seg != null) watch.add(seg);
      }
      out.add(
        ChapterEntry(
          n['id'] as String,
          classNo,
          n['chapter_no'] as int,
          _lt(n['id'] as String, 'title'),
          _lt(n['book'] as String, 'title'),
          lessons,
          watch,
          recommended,
        ),
      );
    }
    return out;
  }

  @override
  List<SearchHit> search(String query, String locale, {int limit = 40}) {
    final fts = ftsQuery(query);
    if (fts.isEmpty) return const [];
    final rows = _db.select(
      '''
      SELECT entity_type, entity_id, title, snippet(search_index, 4, '[', ']', '…', 12) AS snip
      FROM search_index WHERE search_index MATCH ? AND locale = ? ORDER BY rank LIMIT ?''',
      [fts, locale, limit],
    );
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add('${r['entity_type']}:${r['entity_id']}'))
          SearchHit(r['entity_type'] as String, r['entity_id'] as String, r['title'] as String, r['snip'] as String),
    ];
  }

  @override
  List<SourceRef> sources() => [
    for (final r in _db.select('SELECT id FROM source ORDER BY kind, id')) _source(r['id'] as String),
  ];

  @override
  List<LicenceInfo> licences() => [
    for (final r in _db.select('SELECT * FROM licence ORDER BY id'))
      LicenceInfo(r['id'] as String, r['name'] as String, r['url'] as String, (r['commercial_use'] as int) == 1),
  ];

  @override
  String? verseOfSegment(String segmentId) {
    final rows = _db.select('SELECT verse_id FROM segment_verse WHERE segment_id = ? ORDER BY verse_id LIMIT 1', [
      segmentId,
    ]);
    return rows.isEmpty ? null : rows.first['verse_id'] as String;
  }

  @override
  void close() => _db.close();
}
