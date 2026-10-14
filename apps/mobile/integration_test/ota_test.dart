/// On-device over-the-air content update and rollback (plan §6.5, release checklist).
///
/// Needs a signed pack served by a local server and a debug build that trusts its key:
///
///   python -m tools.pack build --version 2026.10.16 --out build/pack-ota --base-url http://10.0.2.2:8765
///   python -m tools.pack publish --channel stable --out build/pack-ota --cdn build/cdn-ota
///   (cd build/cdn-ota && python -m http.server 8765 &)
///   flutter test integration_test/ota_test.dart -d EMULATOR_ID \
///     --dart-define=CONTENT_BASE_URL=http://10.0.2.2:8765 --dart-define=PACK_DEV_PUBLIC_KEY=BASE64_FROM_public_key.txt
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganitaveda/app/app.dart';
import 'package:ganitaveda/app/bootstrap.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/updates/update_runner.dart';
import 'package:ganitaveda/features/updates/update_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

Future<ProviderContainer> launch(WidgetTester t) async {
  final overrides = await bootstrap();
  await t.pumpWidget(ProviderScope(overrides: overrides, child: const GanitaVedaApp()));
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  return ProviderScope.containerOf(t.element(find.byType(GanitaVedaApp)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled pack → signed update from the CDN → restart → corrupted pack rolls back', (t) async {
    // 1. A fresh install starts on the bundled baseline, then its launch-time check (at most once a day)
    //    downloads, verifies, stages and activates the newer signed pack by itself.
    var c = await launch(t);
    for (var i = 0; i < 300 && c.read(contentProvider).contentVersion != '2026.10.16'; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(c.read(contentProvider).contentVersion, '2026.10.16', reason: 'auto update from http://10.0.2.2');
    expect(c.read(contentProvider).lessons(), hasLength(10));
    expect(c.read(userStoreProvider).packHistory().map((e) => e.$2), containsAll(['staged', 'active']));

    // 2. Nothing newer: a forced check says up to date.
    final ref = t.element(find.byType(GanitaVedaApp)) as WidgetRef;
    expect((await runContentCheck(ref, force: true))?.outcome, UpdateOutcome.upToDate);

    // 3. Restart: the updated pack is the active one.
    await t.pumpWidget(const SizedBox());
    c = await launch(t);
    expect(c.read(contentProvider).contentVersion, '2026.10.16');

    // 4. Corrupt the active pack on disk (a failed write, bad storage) and restart: roll back to the baseline.
    final support = await getApplicationSupportDirectory();
    final active = Directory('${support.path}/packs')
        .listSync()
        .whereType<Directory>()
        .firstWhere((d) => d.path.endsWith('2026.10.16'));
    File('${active.path}/content.db').writeAsBytesSync(List.filled(8192, 0));
    await t.pumpWidget(const SizedBox());
    c = await launch(t);
    expect(c.read(contentProvider).contentVersion, '2026.10.15', reason: 'rolled back to the bundled baseline');
    expect(c.read(contentProvider).lessons(), hasLength(10));
    expect(c.read(userStoreProvider).packHistory().map((e) => e.$2), contains('rolled-back:2026.10.16'));
  });
}
