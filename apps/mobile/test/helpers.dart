import 'package:content_model/content_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganitaveda/app/app.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/data/user_store.dart';

/// The baseline pack the app bundles (built by `python -m tools.pack build`).
const packPath = 'assets/packs/content.db';

SqliteContentRepository openPack() => SqliteContentRepository.open(packPath);

UserStore onboardedStore({String locale = 'en', int classNo = 6, String script = 'devanagari'}) {
  final s = UserStore.inMemory();
  for (final e in {
    'onboarded': true,
    'locale': locale,
    'class': classNo,
    'script': script,
    'translation_order': {
      'en': ['translation.colebrooke-1817', 'translation.taylor-1816', 'translation.clark-1930'],
      'kn': ['translation.colebrooke-1817', 'translation.taylor-1816', 'translation.clark-1930'],
    },
  }.entries) {
    s.writeSetting(e.key, e.value);
  }
  return s;
}

Widget testApp(UserStore store, {SqliteContentRepository? content, DateTime? now}) => ProviderScope(
  overrides: [
    userStoreProvider.overrideWithValue(store),
    initialContentProvider.overrideWithValue(content ?? openPack()),
    if (now != null) clockProvider.overrideWithValue(() => now),
  ],
  child: const GanitaVedaApp(),
);

/// Loads the real fonts so text has real metrics (and goldens look like the app).
Future<void> loadAppFonts() async {
  const fonts = {
    'packages/design_system/AnekLatin': 'AnekLatin.ttf',
    'packages/design_system/AnekKannada': 'AnekKannada.ttf',
    'packages/design_system/TiroDevanagariSanskrit': 'TiroDevanagariSanskrit-Regular.ttf',
    'packages/design_system/TiroKannada': 'TiroKannada-Regular.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key)..addFont(rootBundle.load('packages/design_system/assets/fonts/${e.value}'));
    await loader.load();
  }
  // The Material icon font, so goldens show icons rather than placeholder boxes.
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Sets a phone-sized surface.
void phone(WidgetTester tester, {Size size = const Size(412, 915), double textScale = 1}) {
  tester.view.physicalSize = size * 2.625;
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
