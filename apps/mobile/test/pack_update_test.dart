import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganitaveda/features/updates/pack_store.dart';
import 'package:ganitaveda/features/updates/update_service.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Pack update and rollback (plan §6.5, release checklist: "Pack N → N+1
/// updates over the air; a corrupted pack rolls back"). Uses the pack and
/// manifest built and signed by tools/pack.
void main() {
  final buildDir = Directory('../../build/pack');
  late Directory tmp;
  late Uint8List packBytes;
  late String manifest;
  late Map<String, String> keys;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gv_pack_');
    packBytes = File('${buildDir.path}/content.db').readAsBytesSync();
    manifest = File('${buildDir.path}/manifest.json').readAsStringSync();
    final key = File('${buildDir.path}/public_key.txt').readAsStringSync().trim().split(' ');
    keys = {key[0]: key[1]};
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  PackStore store() => PackStore(Directory('${tmp.path}/packs')..createSync(recursive: true));

  UpdateService service(
    PackStore s,
    http.Client client, {
    String appVersion = '1.0.0',
    Map<String, String>? publicKeys,
  }) => UpdateService(
    store: s,
    user: UserStore.inMemory(),
    config: UpdateConfig(
      baseUrl: Uri.parse('https://cdn.test/'),
      publicKeys: publicKeys ?? keys,
      appVersion: appVersion,
    ),
    client: client,
    isOnWifi: () async => true,
  );

  MockClient cdn({String? manifestBody, Uint8List? body}) => MockClient((req) async {
    if (req.url.path.endsWith('.json')) return http.Response(manifestBody ?? manifest, 200);
    return http.Response.bytes(body ?? packBytes, 200);
  });

  test('the bundled baseline opens offline on first run', () {
    final s = store()..installBaseline(packBytes, '2000.01.01');
    final opened = s.open();
    expect(opened.dir, 'baseline');
    expect(opened.repo.lessons(), hasLength(10));
  });

  test('a newer signed pack is downloaded, verified, staged and activated on next open', () async {
    final s = store()..installBaseline(packBytes, '2000.01.01');
    final result = await service(s, cdn()).check(channel: 'stable', currentVersion: '2000.01.01', wifiOnly: true);
    expect(result.outcome, UpdateOutcome.staged);
    expect(s.pendingDir, isNotNull);
    final opened = s.open();
    expect(opened.events.single, startsWith('activated:'));
    expect(opened.dir, isNot('baseline'));
  });

  test('same version is up to date; checks are at most daily unless forced', () async {
    final s = store()..installBaseline(packBytes, '2000.01.01');
    final svc = service(s, cdn());
    final current = RegExp('"content_version": "([^"]+)"').firstMatch(manifest)![1]!;
    expect(
      (await svc.check(channel: 'stable', currentVersion: current, wifiOnly: true)).outcome,
      UpdateOutcome.upToDate,
    );
    expect(
      (await svc.check(channel: 'stable', currentVersion: current, wifiOnly: true)).outcome,
      UpdateOutcome.skippedRecently,
    );
    expect(
      (await svc.check(channel: 'stable', currentVersion: current, wifiOnly: true, force: true)).outcome,
      UpdateOutcome.upToDate,
    );
  });

  test('a tampered manifest or an unknown key is ignored', () async {
    final s = store();
    final tampered = manifest.replaceFirst('"min_app_version": "1.0.0"', '"min_app_version": "0.0.1"');
    expect(
      (await service(
        s,
        cdn(manifestBody: tampered),
      ).check(channel: 'stable', currentVersion: '0', wifiOnly: false)).outcome,
      UpdateOutcome.invalidSignature,
    );
    expect(
      (await service(
        s,
        cdn(),
        publicKeys: {'k9': keys.values.first},
      ).check(channel: 'stable', currentVersion: '0', wifiOnly: false)).outcome,
      UpdateOutcome.invalidSignature,
    );
  });

  test('an app older than min_app_version is told to update', () async {
    final s = store();
    final r = await service(
      s,
      cdn(),
      appVersion: '0.1.0',
    ).check(channel: 'stable', currentVersion: '0', wifiOnly: false);
    expect(r.outcome, UpdateOutcome.appTooOld);
  });

  test('a download with the wrong hash is rejected', () async {
    final s = store();
    final corrupt = Uint8List.fromList([...packBytes]..[5000] ^= 0xFF);
    final r = await service(s, cdn(body: corrupt)).check(channel: 'stable', currentVersion: '0', wifiOnly: false);
    expect(r.outcome, UpdateOutcome.hashMismatch);
    expect(s.pendingDir, isNull);
  });

  test('a pack that fails to open is rolled back to the last good one', () async {
    final s = store()..installBaseline(packBytes, '2000.01.01');
    await service(s, cdn()).check(channel: 'stable', currentVersion: '2000.01.01', wifiOnly: false);
    final pending = s.pendingDir!;
    // Corrupt it after staging, as a failed write or bad storage would.
    File('${tmp.path}/packs/$pending/content.db').writeAsBytesSync(Uint8List(4096));
    final opened = s.open();
    expect(opened.dir, 'baseline');
    expect(opened.events, contains('rolled-back:$pending'));
    expect(s.pendingDir, isNull);
  });

  test('no Wi-Fi, no download (when Wi-Fi only is on)', () async {
    final s = store();
    final svc = UpdateService(
      store: s,
      user: UserStore.inMemory(),
      config: UpdateConfig(baseUrl: Uri.parse('https://cdn.test/'), publicKeys: keys, appVersion: '1.0.0'),
      client: cdn(),
      isOnWifi: () async => false,
    );
    expect(
      (await svc.check(channel: 'stable', currentVersion: '0', wifiOnly: true)).outcome,
      UpdateOutcome.skippedNoWifi,
    );
  });
}
