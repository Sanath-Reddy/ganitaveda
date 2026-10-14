import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 15; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Opens a route as the app would (tabs with go, detail pages with push).
Future<void> open(WidgetTester t, String path) async {
  final router = GoRouter.of(t.element(find.byType(Scaffold).first));
  if (path.startsWith('/school') || path.startsWith('/progress') || path == '/explore') {
    router.go(path);
  } else {
    // Reset to a tab first so pages never stack with the same key.
    router.go('/school');
    await settle(t);
    unawaited(router.push(path));
  }
  await settle(t);
}

const screens = [
  '/school',
  '/explore',
  '/progress',
  '/progress/settings',
  '/verse/verse.lilavati.55',
  '/concept/concept.kuttaka',
  '/person/person.madhava',
  '/explore/timeline',
];

void main() {
  setUpAll(loadAppFonts);

  group('accessibility guidelines (plan §7.7)', () {
    for (final locale in ['en', 'kn']) {
      for (final path in screens) {
        testWidgets('$path in $locale: tap targets, labels', (t) async {
          final handle = t.ensureSemantics();
          phone(t);
          await t.pumpWidget(
            testApp(onboardedStore(locale: locale, script: locale == 'kn' ? 'kannada' : 'devanagari')),
          );
          await settle(t);
          await open(t, path);
          await expectLater(t, meetsGuideline(androidTapTargetGuideline));
          await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });
      }
    }

    // Every lesson card of every lesson.
    testWidgets('lesson cards: tap targets and labels (English)', (t) async {
      final handle = t.ensureSemantics();
      phone(t);
      final content = openPack();
      final store = onboardedStore();
      for (final l in content.lessons()) {
        final doc = content.lesson(l.id)!;
        for (var i = 0; i < doc.cards.length; i++) {
          store.saveProgress(l.id, doc.version, i, {
            'practice': {'seed': 3, 'current': 0, 'right': 0},
          });
          await t.pumpWidget(testApp(store, content: content));
          await settle(t);
          await open(t, '/lesson/${l.id}');
          await expectLater(t, meetsGuideline(androidTapTargetGuideline), reason: '${l.id} card $i');
          await expectLater(t, meetsGuideline(labeledTapTargetGuideline), reason: '${l.id} card $i');
          await t.pumpWidget(const SizedBox());
        }
      }
      handle.dispose();
    });

    // Flutter's own contrast checker samples anti-aliased pixels, so small text reads as low
    // contrast even at 15:1. This is exact: every text colour on every screen must be a design
    // token that test/contrast_test.dart in design_system proves meets WCAG AA (plan §7.2),
    // and `turmeric` is never used for text (plan §7.2: "not for text").
    testWidgets('every text colour is an AA-checked token (light and dark)', (t) async {
      phone(t);
      for (final theme in ['light', 'dark']) {
        final colors = theme == 'dark' ? GVColors.dark : GVColors.light;
        final allowed = {
          colors.ink,
          colors.inkMuted,
          colors.indigo,
          colors.kumkum,
          colors.neem,
          colors.surface,
          colors.paper,
        };
        final store = onboardedStore()..writeSetting('theme', theme);
        await t.pumpWidget(testApp(store));
        await settle(t);
        for (final path in [...screens, '/lesson/lesson.bee-swarm']) {
          await open(t, path);
          final bad = <String>{};
          for (final e in t.widgetList<RichText>(find.byType(RichText))) {
            final color = e.text.style?.color;
            final plain = e.text.toPlainText();
            // Icons are RichText too (private-use glyphs); they are not text.
            final isIcon = plain.isEmpty || plain.runes.every((r) => r >= 0xE000 && r <= 0xF8FF);
            if (!isIcon && color != null && color.a > 0.99 && !allowed.contains(color)) {
              bad.add('${e.text.toPlainText().split('\n').first} → $color');
            }
          }
          expect(bad, isEmpty, reason: '$path $theme uses non-token text colours');
        }
        await t.pumpWidget(const SizedBox());
      }
    });
  });

  group('adaptive layout (plan §7.8)', () {
    const tablets = {
      'tablet portrait 800x1280': Size(800, 1280),
      'tablet landscape 1280x800': Size(1280, 800),
      'phone landscape 915x412': Size(915, 412),
      'small phone 320x568': Size(320, 568),
    };
    for (final e in tablets.entries) {
      for (final locale in ['en', 'kn']) {
        testWidgets('${e.key} $locale: main screens and a lesson lay out without overflow', (t) async {
          phone(t, size: e.value);
          final store = onboardedStore(locale: locale, script: locale == 'kn' ? 'kannada' : 'devanagari');
          await t.pumpWidget(testApp(store));
          await settle(t);
          final wide = e.value.width >= 600;
          expect(find.byType(NavigationRail), wide ? findsOneWidget : findsNothing);
          expect(find.byType(NavigationBar), wide ? findsNothing : findsOneWidget);
          for (final path in screens) {
            await open(t, path);
            expect(t.takeException(), isNull, reason: '$path on ${e.key}');
          }
          for (final lesson in ['lesson.bee-swarm', 'lesson.kuttaka', 'lesson.cyclic-quadrilateral']) {
            final doc = openPack().lesson(lesson)!;
            for (var i = 0; i < doc.cards.length; i++) {
              store.saveProgress(lesson, doc.version, i, {
                'practice': {'seed': 3, 'current': 0, 'right': 0},
              });
              await open(t, '/lesson/$lesson');
              expect(t.takeException(), isNull, reason: '$lesson card $i on ${e.key}');
            }
          }
        });
      }
    }
  });
}
