/// On-device integration test (plan §8.5): first launch through a whole lesson,
/// kill-and-resume, offline operation, and frame timings while swiping cards.
///
///   flutter test integration_test/app_test.dart -d EMULATOR_OR_PHONE_ID
///
/// It uses the real bootstrap (files in the app's own storage, the bundled pack),
/// so it exercises the same code path as a real launch. Run on a fresh install.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/app/app.dart';
import 'package:ganitaveda/app/bootstrap.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

Future<void> settle(WidgetTester t, [int ms = 2000]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until [f] appears (real time passes on a device; fixed waits are flaky on slow emulators).
Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 15}) async {
  for (var i = 0; i < seconds * 10 && f.evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Types on the app's own number pad, as a student does (also covers the pad on a device).
Future<void> typeOnPad(WidgetTester t, String text) async {
  for (final ch in text.split('')) {
    final label = switch (ch) {
      ' ' => 'a b/c',
      '-' => '−',
      _ => ch,
    };
    await t.tap(find.widgetWithText(OutlinedButton, label));
    await t.pump(const Duration(milliseconds: 150));
  }
  await settle(t, 300);
}

Future<void> tapOn(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await settle(t, 300);
  await t.tap(f);
  await settle(t, 600);
}

Future<ProviderContainer> launch(WidgetTester t) async {
  final overrides = await bootstrap();
  await t.pumpWidget(ProviderScope(overrides: overrides, child: const GanitaVedaApp()));
  await settle(t);
  return ProviderScope.containerOf(t.element(find.byType(GanitaVedaApp)));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch, a full lesson, kill and resume, review queue', (t) async {
    final launchWatch = Stopwatch()..start();
    var c = await launch(t);
    launchWatch.stop();
    // Test output is the report here, so print is intended.
    // ignore: avoid_print
    print('PERF bootstrap+first frames: ${launchWatch.elapsedMilliseconds} ms');

    // Onboarding (fresh install).
    expect(find.text('Choose your language'), findsOneWidget);
    await tapOn(t, find.text('Next'));
    await tapOn(t, find.text('Class 6'));
    await tapOn(t, find.text('Next'));
    await tapOn(t, find.text('Start'));
    expect(find.text('Fractions'), findsOneWidget);

    // Open the bee-swarm lesson and walk its cards.
    await tapOn(t, find.text('Fractions'));
    await tapOn(t, find.text('The swarm of bees'));
    await waitFor(t, find.textContaining('A swarm of bees flies over a garden'));
    expect(find.textContaining('A swarm of bees flies over a garden'), findsOneWidget);
    await tapOn(t, find.text('Next').last);

    // Step the swarm to 15 with the buttons.
    for (var i = 0; i < 3; i++) {
      await tapOn(t, find.byTooltip('Increase').first);
    }

    // Kill the app mid-lesson and relaunch: same card, same state.
    await t.pumpWidget(const SizedBox());
    c = await launch(t);
    expect(find.text('Choose your language'), findsNothing, reason: 'settings survived the restart');
    await tapOn(t, find.text('Fractions'));
    await tapOn(t, find.text('The swarm of bees').first);
    await waitFor(t, find.textContaining('Exactly 1 left'));
    expect(find.textContaining('Exactly 1 left'), findsOneWidget);

    // Verse, method, practice.
    await tapOn(t, find.text('Next').last);
    await waitFor(t, find.text('H. T. Colebrooke (1817)'));
    expect(find.text('H. T. Colebrooke (1817)'), findsOneWidget);
    await tapOn(t, find.text('Next').last);
    await tapOn(t, find.text('Show all steps'));
    expect(find.textContaining('30 × 1 ÷ 2 = 15'), findsWidgets);
    await tapOn(t, find.text('Next').last);

    final store = c.read(userStoreProvider);
    final seed = ((store.progress('lesson.bee-swarm')!.state['practice']! as Map)['seed']) as int;
    final problems = generateSession('fractions.remainder.v1', seed, 4, difficulties: [1, 2, 2, 3]);
    for (final (index, p) in problems.indexed) {
      // Each problem's header proves the previous "Next problem" tap has been processed.
      await waitFor(t, find.text('Problem ${index + 1} of 4'));
      await typeOnPad(t, p.answer.canonical);
      // By icon: on a real Android runtime the semantics-label finder resolves to a
      // different render object and the tap misses the button.
      await tapOn(t, find.widgetWithIcon(FilledButton, Icons.check));
      await waitFor(t, find.text('Correct!'));
      expect(find.text('Correct!'), findsOneWidget);
      await tapOn(t, find.text('Next problem'));
    }
    await waitFor(t, find.textContaining('4 of 4 right first time'));
    expect(find.textContaining('4 of 4 right first time'), findsOneWidget);
    await tapOn(t, find.text('Next').last);
    await tapOn(t, find.text('Finish lesson'));
    expect(store.completedLessons(), ['lesson.bee-swarm']);
    expect(store.reviewItems(), hasLength(1));
  });

  testWidgets('every lesson opens and swipes through all its cards; frame timings', (t) async {
    final c = await launch(t);
    final lessons = c.read(contentProvider).lessons();
    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);

    final router = GoRouter.of(t.element(find.byType(Scaffold).first));
    for (final l in lessons) {
      final doc = c.read(contentProvider).lesson(l.id)!;
      unawaited(router.push('/lesson/${l.id}'));
      await settle(t, 800);
      for (var i = 1; i < doc.cards.length; i++) {
        await t.tap(
          find.byTooltip('Next').hitTestable().evaluate().isNotEmpty
              ? find.byTooltip('Next').hitTestable()
              : find.text('Next').last,
        );
        await settle(t, 400);
      }
      expect(t.takeException(), isNull, reason: l.id);
      router.pop();
      await settle(t, 400);
    }
    SchedulerBinding.instance.removeTimingsCallback(collect);

    final build = frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()..sort();
    final raster = frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()..sort();
    double pct(List<double> v, double p) => v.isEmpty ? 0 : v[((v.length - 1) * p).round()];
    final slow = frames.where((f) => f.totalSpan.inMicroseconds > 16667).length;
    // Test output is the report here, so print is intended.
    // ignore: avoid_print
    print(
      'PERF frames=${frames.length} build p50=${pct(build, .5).toStringAsFixed(1)}ms p95=${pct(build, .95).toStringAsFixed(1)}ms '
      'raster p50=${pct(raster, .5).toStringAsFixed(1)}ms p95=${pct(raster, .95).toStringAsFixed(1)}ms '
      'over16.7ms=${(100 * slow / (frames.isEmpty ? 1 : frames.length)).toStringAsFixed(1)}%',
    );
    binding.reportData = {
      'frames': frames.length,
      'slowFramePercent': 100 * slow / (frames.isEmpty ? 1 : frames.length),
    };
    expect(frames, isNotEmpty);
  });
}
