import 'package:ganita_core/ganita_core.dart';

/// The lesson engine version this app implements (plan §6.6). Cards whose
/// `min_engine` is newer, or whose type is unknown, are skipped with a note.
const int kEngineVersion = 1;

LText ltextFrom(Object? json, {LText fallback = const LText('', '')}) {
  if (json is Map) {
    final en = (json['en'] as String?) ?? '';
    return LText(en, (json['kn'] as String?) ?? en);
  }
  return fallback;
}

LText? ltextOrNull(Object? json) => json is Map ? ltextFrom(json) : null;

sealed class LessonCard {
  final String id;
  final String type;
  final int minEngine;

  const LessonCard(this.id, this.type, this.minEngine);

  static LessonCard fromJson(Map<String, Object?> j) {
    final id = j['id'] as String;
    final type = j['type'] as String;
    final minEngine = (j['min_engine'] as int?) ?? 1;
    if (minEngine > kEngineVersion) return UnsupportedCard(id, type, minEngine);
    return switch (type) {
      'scene' => SceneCard(id, minEngine, art: j['art'] as String, text: ltextFrom(j['text'])),
      'explore' => ExploreCard(
        id,
        minEngine,
        widget: j['widget'] as String,
        params: Map<String, Object?>.from(j['params'] as Map),
        prompt: ltextFrom(j['prompt']),
        goal: ltextOrNull(j['goal']),
      ),
      'verse' => VerseCard(
        id,
        minEngine,
        verseId: j['verse'] as String,
        highlight: [...?(j['highlight'] as List?)?.cast<String>()],
        showCompare: (j['show_compare'] as bool?) ?? false,
        intro: ltextOrNull(j['intro']),
      ),
      'method' => MethodCard(
        id,
        minEngine,
        algorithm: j['algorithm'] as String,
        inputs: Map<String, Object?>.from(j['inputs'] as Map),
        intro: ltextFrom(j['intro']),
        modern: ltextOrNull(j['modern']),
      ),
      'watch' => WatchCard(
        id,
        minEngine,
        segmentId: j['segment'] as String,
        optional: (j['optional'] as bool?) ?? false,
      ),
      'practice' => PracticeCard(
        id,
        minEngine,
        generatorId: j['generator'] as String,
        count: j['count'] as int,
        difficulty: [...?(j['difficulty'] as List?)?.cast<int>()],
        templateId: (j['template'] as String?) ?? id,
      ),
      'quiz' => QuizCard(
        id,
        minEngine,
        questions: [
          for (final q in (j['questions'] as List).cast<Map>())
            QuizQuestion(
              prompt: ltextFrom(q['prompt']),
              choices: [for (final c in q['choices'] as List) ltextFrom(c)],
              answer: q['answer'] as int,
              why: ltextOrNull(q['why']),
            ),
        ],
      ),
      'summary' => SummaryCard(
        id,
        minEngine,
        keyIdea: ltextFrom(j['key_idea']),
        textbook: ltextOrNull(j['textbook']),
        next: j['next'] as String?,
      ),
      _ => UnsupportedCard(id, type, minEngine),
    };
  }
}

class SceneCard extends LessonCard {
  final String art;
  final LText text;
  const SceneCard(String id, int minEngine, {required this.art, required this.text}) : super(id, 'scene', minEngine);
}

class ExploreCard extends LessonCard {
  final String widget;
  final Map<String, Object?> params;
  final LText prompt;
  final LText? goal;
  const ExploreCard(
    String id,
    int minEngine, {
    required this.widget,
    required this.params,
    required this.prompt,
    this.goal,
  }) : super(id, 'explore', minEngine);
}

class VerseCard extends LessonCard {
  final String verseId;
  final List<String> highlight;
  final bool showCompare;
  final LText? intro;
  const VerseCard(
    String id,
    int minEngine, {
    required this.verseId,
    this.highlight = const [],
    this.showCompare = false,
    this.intro,
  }) : super(id, 'verse', minEngine);
}

class MethodCard extends LessonCard {
  final String algorithm;
  final Map<String, Object?> inputs;
  final LText intro;
  final LText? modern;
  const MethodCard(
    String id,
    int minEngine, {
    required this.algorithm,
    required this.inputs,
    required this.intro,
    this.modern,
  }) : super(id, 'method', minEngine);
}

class WatchCard extends LessonCard {
  final String segmentId;
  final bool optional;
  const WatchCard(String id, int minEngine, {required this.segmentId, this.optional = false})
    : super(id, 'watch', minEngine);
}

class PracticeCard extends LessonCard {
  final String generatorId;
  final int count;
  final List<int> difficulty;
  final String templateId;
  const PracticeCard(
    String id,
    int minEngine, {
    required this.generatorId,
    required this.count,
    this.difficulty = const [],
    required this.templateId,
  }) : super(id, 'practice', minEngine);
}

class QuizQuestion {
  final LText prompt;
  final List<LText> choices;
  final int answer;
  final LText? why;
  const QuizQuestion({required this.prompt, required this.choices, required this.answer, this.why});
}

class QuizCard extends LessonCard {
  final List<QuizQuestion> questions;
  const QuizCard(String id, int minEngine, {required this.questions}) : super(id, 'quiz', minEngine);
}

class SummaryCard extends LessonCard {
  final LText keyIdea;
  final LText? textbook;
  final String? next;
  const SummaryCard(String id, int minEngine, {required this.keyIdea, this.textbook, this.next})
    : super(id, 'summary', minEngine);
}

/// A card this app cannot draw: newer engine or unknown type. Shown as a short
/// "Update the app to see this part" note, never a crash.
class UnsupportedCard extends LessonCard {
  const UnsupportedCard(String id, String type, int minEngine) : super(id, type, minEngine);
}

class LessonDoc {
  final String id;
  final int version;
  final LText title;
  final LText? subtitle;
  final int minutes;
  final String area;
  final List<String> concepts;
  final List<String> curriculum;
  final List<LessonCard> cards;

  const LessonDoc({
    required this.id,
    required this.version,
    required this.title,
    this.subtitle,
    required this.minutes,
    required this.area,
    required this.concepts,
    required this.curriculum,
    required this.cards,
  });

  factory LessonDoc.fromJson(Map<String, Object?> j) => LessonDoc(
    id: j['id'] as String,
    version: j['version'] as int,
    title: ltextFrom(j['title']),
    subtitle: ltextOrNull(j['subtitle']),
    minutes: j['minutes'] as int,
    area: j['area'] as String,
    concepts: [...(j['concepts'] as List).cast<String>()],
    curriculum: [...?(j['curriculum'] as List?)?.cast<String>()],
    cards: [for (final c in (j['cards'] as List).cast<Map>()) LessonCard.fromJson(Map<String, Object?>.from(c))],
  );

  bool get hasUnsupportedCards => cards.any((c) => c is UnsupportedCard);
}
