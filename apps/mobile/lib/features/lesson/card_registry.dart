import 'package:content_model/content_model.dart';
import 'package:flutter/material.dart';
import 'package:ganita_core/ganita_core.dart';

import 'package:ganitaveda/features/lesson/cards/basic_cards.dart';
import 'package:ganitaveda/features/lesson/cards/method_card.dart';
import 'package:ganitaveda/features/lesson/cards/practice_card.dart';
import 'package:ganitaveda/features/lesson/widgets/explore_widgets.dart';

/// What a card renderer gets: its card, saved state, and navigation.
class CardContext {
  const new({
    required this.lesson,
    required this.card,
    required this.state,
    required this.setState,
    required this.next,
    required this.close,
  });
  final LessonDoc lesson;
  final LessonCard card;
  final Map<String, Object?> state;
  final void Function(Map<String, Object?> state) setState;
  final VoidCallback? next;
  final VoidCallback close;
}

typedef CardRenderer = Widget Function(CardContext c);

/// type → renderer (plan §6.6). Must match `card_types` in
/// tools/schemas/registry.yaml (test/registry_parity_test.dart).
final Map<String, CardRenderer> cardRenderers = {
  'scene': SceneCardView.new,
  'explore': ExploreCardView.new,
  'verse': VerseCardView.new,
  'method': MethodCardView.new,
  'watch': WatchCardView.new,
  'practice': (c) => PracticeCardView(key: ValueKey('${c.lesson.id}#${c.card.id}'), c),
  'quiz': QuizCardView.new,
  'summary': SummaryCardView.new,
};

Widget buildCard(BuildContext context, CardContext c) {
  final card = c.card;
  if (card is UnsupportedCard) return UnsupportedCardView(c);
  final r = cardRenderers[card.type];
  return r == null ? UnsupportedCardView(c) : r(c);
}

Rational _rat(Object? v) => switch (v) {
  final int i => r(i),
  final String s => Rational.parse(s),
  final num n => Rational.parse(n.toString()),
  _ => throw ArgumentError('Not a number: $v'),
};

List<Rational> _rats(Object? v) => [for (final x in v! as List) _rat(x)];

typedef AlgorithmRunner = Trace Function(Map<String, Object?> inputs);

/// algorithm id → trace (plan §6.7). Must match `algorithms` in registry.yaml.
final Map<String, AlgorithmRunner> algorithms = {
  'ishta_karma': (i) {
    final parts = _rats(i['parts']);
    return ishtaKarma(
      partA: parts[0],
      partB: parts[1],
      multiplier: (i['difference_multiplier'] as int?) ?? 0,
      remainder: _rat(i['remainder']),
      guess: _rat(i['guess']),
    );
  },
  'sign_rules': (i) => signRules(a: _rat(i['a']), b: _rat(i['b'])),
  'bhuja_koti_karna': (i) => bhujaKotiKarna(
    bhuja: i['bhuja'] == null ? null : _rat(i['bhuja']),
    koti: i['koti'] == null ? null : _rat(i['koti']),
    karna: i['karna'] == null ? null : _rat(i['karna']),
  ),
  'trairashika': (i) => trairashika(
    pramana: _rat(i['pramana']),
    phala: _rat(i['phala']),
    iccha: _rat(i['iccha']),
    inverse: (i['inverse'] as bool?) ?? false,
  ),
  'sredhi': (i) => sredhi(adi: _rat(i['adi']), caya: _rat(i['caya']), gaccha: i['gaccha']! as int),
  'jya_table': (i) => jyaTrace(radius: (i['radius'] as int?) ?? 3438, steps: (i['steps'] as int?) ?? 24),
  'madhava_series': (i) => madhavaTrace((i['terms'] as int?) ?? 5),
  'kuttaka': (i) => kuttakaTrace(i['a']! as int, i['b']! as int, i['c']! as int),
  'cyclic_quad': (i) => cyclicQuad(_rats(i['sides'])),
  'ankapasha': (i) => ankapashaTrace([...(i['digits']! as List).cast<int>()]),
};

/// widget id → builder. Must match `widgets` in registry.yaml.
final Map<String, ExploreWidgetBuilder> exploreWidgets = {
  'swarm': (p, s, set) => SwarmExplorer(params: p, state: s, onState: set),
  'number_line': (p, s, set) => NumberLineExplorer(params: p, state: s, onState: set),
  'triangle': (p, s, set) => TriangleExplorer(params: p, state: s, onState: set),
  'ratio_balance': (p, s, set) => RatioBalanceExplorer(params: p, state: s, onState: set),
  'sequence_builder': (p, s, set) => SequenceExplorer(params: p, state: s, onState: set),
  'chord': (p, s, set) => ChordExplorer(params: p, state: s, onState: set),
  'series_plot': (p, s, set) => SeriesExplorer(params: p, state: s, onState: set),
  'division_table': (p, s, set) => DivisionTableExplorer(params: p, state: s, onState: set),
  'cyclic_quad': (p, s, set) => CyclicQuadExplorer(params: p, state: s, onState: set),
  'digit_arrange': (p, s, set) => DigitArrangeExplorer(params: p, state: s, onState: set),
};
