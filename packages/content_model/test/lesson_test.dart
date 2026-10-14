import 'package:content_model/content_model.dart';
import 'package:test/test.dart';

void main() {
  test('unknown card types and newer engines are skipped, not crashes', () {
    final doc = LessonDoc.fromJson({
      'id': 'lesson.x',
      'version': 1,
      'title': {'en': 'X'},
      'minutes': 5,
      'area': 'area.arithmetic',
      'concepts': ['concept.x'],
      'cards': [
        {
          'id': 'a',
          'type': 'scene',
          'art': 'art.x',
          'text': {'en': 'hi', 'kn': 'ನಮಸ್ಕಾರ'},
        },
        {'id': 'b', 'type': 'hologram', 'min_engine': 1},
        {
          'id': 'c',
          'type': 'scene',
          'min_engine': kEngineVersion + 1,
          'art': 'x',
          'text': {'en': 'later'},
        },
        {
          'id': 'd',
          'type': 'summary',
          'key_idea': {'en': 'k'},
        },
      ],
    });
    expect(doc.cards.map((c) => c.runtimeType.toString()), [
      'SceneCard',
      'UnsupportedCard',
      'UnsupportedCard',
      'SummaryCard',
    ]);
    expect(doc.hasUnsupportedCards, isTrue);
    // A missing Kannada string falls back to English.
    expect((doc.cards.last as SummaryCard).keyIdea.kn, 'k');
  });
}
