import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/updates/pack_store.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:path_provider/path_provider.dart';

/// Opens user.db and the best content pack before the first frame (plan §6.5:
/// a baseline pack ships in the app, so it works offline from the first launch).
Future<List<Override>> bootstrap() async {
  final support = await getApplicationSupportDirectory();
  final user = UserStore.open('${support.path}/user.db');

  final store = PackStore(Directory('${support.path}/packs')..createSync(recursive: true));
  final manifest = jsonDecode(await rootBundle.loadString('assets/packs/manifest.json')) as Map<String, dynamic>;
  final bundled = await rootBundle.load('assets/packs/content.db');
  store.installBaseline(
    bundled.buffer.asUint8List(bundled.offsetInBytes, bundled.lengthInBytes),
    manifest['content_version'] as String,
  );

  final opened = store.open();
  for (final e in opened.events) {
    user.logPack(opened.repo.contentVersion, e);
  }
  store.prune();

  return [
    userStoreProvider.overrideWithValue(user),
    packStoreProvider.overrideWithValue(store),
    initialContentProvider.overrideWithValue(opened.repo),
  ];
}
