import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// Golden screenshots of key screens in English and Kannada, light and dark
/// (plan §5.8 definition of done). Regenerate with `flutter test --update-goldens`
/// after an intended visual change, and review the PNGs in the PR.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);

  final screens = {
    'school': '/school',
    'verse': '/verse/verse.lilavati.55',
    'concept': '/concept/concept.kuttaka',
    'explore': '/explore',
  };

  for (final locale in ['en', 'kn']) {
    for (final theme in ['light', 'dark']) {
      for (final e in screens.entries) {
        testWidgets('${e.key} $locale $theme', (t) async {
          phone(t);
          final store = onboardedStore(locale: locale, script: locale == 'kn' ? 'kannada' : 'devanagari')
            ..writeSetting('theme', theme);
          await t.pumpWidget(testApp(store));
          await settle(t);
          if (e.value != '/school') {
            final router = GoRouter.of(t.element(find.byType(Scaffold).first));
            if (e.value == '/explore') {
              router.go(e.value);
            } else {
              unawaited(router.push(e.value));
            }
            await settle(t);
          }
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${e.key}_${locale}_$theme.png'));
        });
      }
    }
  }

  for (final card in [1, 3, 4]) {
    testWidgets('bee-swarm card $card en light', (t) async {
      phone(t);
      final store = onboardedStore()
        ..saveProgress('lesson.bee-swarm', 1, card, {
          'practice': {'seed': 1, 'current': 0, 'right': 0},
        });
      await t.pumpWidget(testApp(store));
      await settle(t);
      unawaited(GoRouter.of(t.element(find.byType(Scaffold).first)).push('/lesson/lesson.bee-swarm'));
      await settle(t);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/lesson_bee_card${card}_en_light.png'));
    });
  }
}
