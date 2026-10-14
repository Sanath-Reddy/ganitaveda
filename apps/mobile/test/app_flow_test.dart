import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/features/lesson/lesson_player.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// Scrolls to a widget, then taps it, as a user would.
Future<void> tapOn(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await settle(t);
  await t.tap(f);
  await settle(t);
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late SqliteContentRepository content;
  setUpAll(() async {
    await loadAppFonts();
  });
  setUp(() => content = openPack());

  testWidgets('first launch: language, class, script, then School', (t) async {
    phone(t);
    final store = UserStore.inMemory();
    await t.pumpWidget(testApp(store, content: content));
    await settle(t);
    expect(find.text('Choose your language'), findsOneWidget);
    await t.tap(find.text('ಕನ್ನಡ'));
    await settle(t);
    expect(find.text('ನಿಮ್ಮ ಭಾಷೆ ಆರಿಸಿ'), findsOneWidget, reason: 'switches language at once');
    await tapOn(t, find.text('ಮುಂದೆ'));
    await tapOn(t, find.text('6ನೇ ತರಗತಿ'));
    await tapOn(t, find.text('ಮುಂದೆ'));
    await tapOn(t, find.text('ಆರಂಭಿಸಿ'));
    await settle(t);
    expect(find.text('ಶಾಲೆ'), findsWidgets);
    expect(find.text('ಭಿನ್ನರಾಶಿಗಳು'), findsOneWidget, reason: 'Class 6 Fractions chapter in Kannada');
    final settings = store.readSettings();
    expect(settings['script'], 'kannada', reason: 'Kannada readers default to Kannada script');
    expect(settings['onboarded'], isTrue);
  });

  testWidgets('School hides empty chapters and lists lessons', (t) async {
    phone(t);
    await t.pumpWidget(testApp(onboardedStore(), content: content));
    await settle(t);
    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('The Other Side of Zero'), findsOneWidget);
    expect(find.text('Patterns in Mathematics'), findsNothing, reason: 'no lessons or checked videos yet');
    await t.tap(find.text('Fractions'));
    await settle(t);
    expect(find.text('The swarm of bees'), findsOneWidget);
  });

  testWidgets('a whole lesson: play, verse, method, practice, finish, review queued; resumes after a restart', (
    t,
  ) async {
    phone(t);
    final store = onboardedStore();
    await t.pumpWidget(testApp(store, content: content));
    await settle(t);
    await t.tap(find.text('Fractions'));
    await settle(t);
    await t.tap(find.text('The swarm of bees'));
    await settle(t);

    // 1. Scene
    expect(find.textContaining('A swarm of bees flies over a garden'), findsOneWidget);
    await t.tap(find.text('Next').last);
    await settle(t);
    // 2. Play: step the swarm to 15 with the buttons (no dragging needed).
    var n = 12;
    while (n < 15) {
      await tapOn(t, find.byTooltip('Increase').first);
      await settle(t);
      n++;
    }
    expect(find.textContaining('Exactly 1 left'), findsOneWidget);

    // "Kill" the app mid-lesson and reopen: it resumes on the same card with the same state.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(testApp(store, content: content));
    await settle(t);
    await t.tap(find.text('Fractions'));
    await settle(t);
    await t.tap(find.text('The swarm of bees').first);
    await settle(t);
    expect(find.textContaining('Exactly 1 left'), findsOneWidget, reason: 'resumed exactly');

    // 3. Verse: Devanagari, Colebrooke beside it, script switch.
    await t.tap(find.text('Next').last);
    await settle(t);
    expect(find.textContaining('पञ्च-अंशस्'), findsOneWidget);
    expect(find.text('H. T. Colebrooke (1817)'), findsOneWidget);
    await t.tap(find.text('IAST'));
    await settle(t);
    expect(find.textContaining('pañca-aṃśas'), findsOneWidget);

    // 4. Method: step through.
    await t.tap(find.text('Next').last);
    await settle(t);
    expect(find.textContaining('Suppose the whole is 30'), findsOneWidget);
    await tapOn(t, find.text('Show all steps'));
    await settle(t);
    expect(find.textContaining('30 × 1 ÷ 2 = 15'), findsWidgets);

    // 5. Practice: answer every problem with the generator's own answer, typing on the number pad.
    await t.tap(find.text('Next').last);
    await settle(t);
    final saved = store.progress('lesson.bee-swarm')!;
    final practice = (saved.state['practice']! as Map)['seed'] as int;
    final problems = generateSession('fractions.remainder.v1', practice, 4, difficulties: [1, 2, 2, 3]);
    for (final p in problems) {
      await t.enterText(find.byType(TextField), p.answer.canonical);
      await tapOn(t, find.bySemanticsLabel('Check').last);
      await settle(t);
      expect(find.text('Correct!'), findsOneWidget, reason: p.prompt.en);
      await tapOn(t, find.text('Next problem'));
      await settle(t);
    }
    expect(find.textContaining('4 of 4 right first time'), findsOneWidget);
    expect(store.attemptCount(), 4);

    // 6. Summary: finish; the kolam gains a loop and review is scheduled.
    await t.tap(find.text('Next').last);
    await settle(t);
    await tapOn(t, find.text('Finish lesson'));
    await settle(t);
    expect(find.textContaining('1 lesson finished'), findsOneWidget);
    expect(store.completedLessons(), ['lesson.bee-swarm']);
    expect(store.reviewItems().single.templateId, 'lesson.bee-swarm.practice');
  });

  testWidgets('a wrong answer gets feedback and the hint ladder ends in the answer', (t) async {
    phone(t);
    final store = onboardedStore()
      ..saveProgress('lesson.trairashika', 1, 4, {
        'practice': {'seed': 7, 'current': 0, 'right': 0},
      });
    await t.pumpWidget(testApp(store, content: content));
    await settle(t);
    await t.tap(find.text('Explore'));
    await settle(t);
    // open via router directly
    final element = t.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(element).push('/lesson/lesson.trairashika'));
    await settle(t);
    final p = generateSession('ratio.rule_of_three.v1', 7, 4, difficulties: [1, 2, 2, 3]).first;
    await t.enterText(find.byType(TextField), '${p.answer.value + Rational.one}');
    await tapOn(t, find.bySemanticsLabel('Check').last);
    await settle(t);
    expect(find.text('Not quite. Try again, or take a hint.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tapOn(t, find.textContaining(RegExp('hint', caseSensitive: false)).last);
      await settle(t);
    }
    expect(find.textContaining('Answer: ${p.answer.canonical}'), findsOneWidget);
    expect(store.attemptCount(), 1);
  });

  for (final (locale, label) in [('en', 'English'), ('kn', 'Kannada')]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('$label at ${(scale * 100).round()}% text: every lesson card lays out without overflow', (t) async {
        phone(t, textScale: scale);
        final store = onboardedStore(locale: locale, script: locale == 'kn' ? 'kannada' : 'devanagari');
        for (final lesson in content.lessons()) {
          final doc = content.lesson(lesson.id)!;
          for (var i = 0; i < doc.cards.length; i++) {
            store.saveProgress(lesson.id, doc.version, i, {});
            await t.pumpWidget(testApp(store, content: content));
            await settle(t);
            unawaited(GoRouter.of(t.element(find.byType(Scaffold).first)).push('/lesson/${lesson.id}'));
            await settle(t);
            expect(find.byType(LessonPlayer), findsOneWidget);
            expect(t.takeException(), isNull, reason: '${lesson.id} card $i');
            await t.pumpWidget(const SizedBox());
          }
        }
      });
    }
  }

  testWidgets('Explore: search in Kannada script finds the pulveriser; concept, person, lineage, timeline open', (
    t,
  ) async {
    phone(t);
    await t.pumpWidget(testApp(onboardedStore(), content: content));
    await settle(t);
    await t.tap(find.text('Explore'));
    await settle(t);
    await t.tap(find.byType(TextField));
    await settle(t);
    await t.enterText(find.byType(TextField), 'ಕುಟ್ಟಕ');
    await settle(t);
    expect(find.text('Kuṭṭaka'), findsWidgets);
    final router = GoRouter.of(t.element(find.byType(Scaffold).first));
    for (final path in [
      '/explore/lineage',
      '/explore/timeline',
      '/concept/concept.trairashika',
      '/person/person.damodara',
      '/text/work.lilavati',
      '/section/section.bss.18',
      '/verse/verse.bss.18.30',
    ]) {
      unawaited(router.push(path));
      await settle(t);
      expect(t.takeException(), isNull, reason: path);
    }
    // Other tabs are reached with go(), as the tab bar does; then deeper pages are pushed.
    for (final path in [
      '/progress',
      '/progress/settings',
      '/progress/settings/translations',
      '/progress/settings/sources',
    ]) {
      router.go(path);
      await settle(t);
      expect(t.takeException(), isNull, reason: path);
    }
    router.go('/progress');
    await settle(t);
    expect(find.text('Your kolam'), findsOneWidget);
    // A bookmark opened from Progress pushes a page from another tab: must not crash.
    unawaited(router.push('/concept/concept.kuttaka'));
    await settle(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('dark theme and Kannada render the verse view', (t) async {
    phone(t);
    final store = onboardedStore(locale: 'kn', script: 'kannada')..writeSetting('theme', 'dark');
    await t.pumpWidget(testApp(store, content: content));
    await settle(t);
    unawaited(GoRouter.of(t.element(find.byType(Scaffold).first)).push('/verse/verse.lilavati.55'));
    await settle(t);
    expect(find.textContaining('ಪಞ್ಚ-ಅಂಶಸ್'), findsOneWidget);
    expect(find.text('ಇಂಗ್ಲಿಷ್'), findsOneWidget, reason: 'English translation is labelled in Kannada mode');
  });
}
