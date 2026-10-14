import 'dart:io';
import 'dart:typed_data';

import 'package:content_model/content_model.dart';
import 'package:ganitaveda/features/updates/pack_store.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:http/http.dart' as http;

/// Schema versions this app can read: the current one and the previous one (plan §6.2).
const supportedSchemas = {1};

enum UpdateOutcome {
  notConfigured,
  skippedRecently,
  skippedNoWifi,
  upToDate,
  invalidSignature,
  unsupportedSchema,
  appTooOld,
  downloadFailed,
  hashMismatch,
  brokenPack,
  staged,
}

class UpdateResult {
  const new(this.outcome, [this.version]);
  final UpdateOutcome outcome;
  final String? version;
}

class UpdateConfig {
  const new({required this.baseUrl, required this.publicKeys, required this.appVersion});

  /// CDN root holding `/channels/<channel>.json` and `/packs/...`; null disables updates.
  final Uri? baseUrl;

  /// Key id → base64 Ed25519 public key. The app carries the current and next
  /// key so the signing key can be rotated (plan §8.9).
  final Map<String, String> publicKeys;
  final String appVersion;
}

class UpdateService {
  new({
    required this.store,
    required this.user,
    required this.config,
    required this.client,
    required this.isOnWifi,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final PackStore store;
  final UserStore user;
  final UpdateConfig config;
  final http.Client client;
  final Future<bool> Function() isOnWifi;
  final DateTime Function() clock;

  static const _lastCheckKey = 'last_update_check';

  Future<UpdateResult> check({
    required String channel,
    required String currentVersion,
    required bool wifiOnly,
    bool force = false,
  }) async {
    final base = config.baseUrl;
    if (base == null || config.publicKeys.isEmpty) return const UpdateResult(UpdateOutcome.notConfigured);

    final now = clock();
    final last = user.readSettings()[_lastCheckKey] as int?;
    if (!force && last != null && now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < const Duration(days: 1)) {
      return const UpdateResult(UpdateOutcome.skippedRecently);
    }
    if (wifiOnly && !await isOnWifi()) return const UpdateResult(UpdateOutcome.skippedNoWifi);
    user.writeSetting(_lastCheckKey, now.millisecondsSinceEpoch);

    // 1. Manifest: ignore it unless the signature is valid.
    final Manifest manifest;
    try {
      final res = await client.get(base.resolve('channels/$channel.json')).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const UpdateResult(UpdateOutcome.downloadFailed);
      manifest = Manifest.parse(res.body);
    } on Object {
      return const UpdateResult(UpdateOutcome.downloadFailed);
    }
    if (!await manifest.verify(config.publicKeys)) return const UpdateResult(UpdateOutcome.invalidSignature);
    if (!supportedSchemas.contains(manifest.schemaVersion)) {
      return UpdateResult(UpdateOutcome.unsupportedSchema, manifest.contentVersion);
    }
    if (compareVersions(manifest.minAppVersion, config.appVersion) > 0) {
      return UpdateResult(UpdateOutcome.appTooOld, manifest.contentVersion);
    }
    final pending = store.pendingDir;
    if (compareVersions(manifest.contentVersion, currentVersion) <= 0 || pending == manifest.contentVersion) {
      return UpdateResult(UpdateOutcome.upToDate, manifest.contentVersion);
    }

    // 2. Download to staging and check size and hash.
    final file = manifest.contentDb;
    final staging = store.stagingDir();
    final Uint8List bytes;
    try {
      final res = await client.get(file.url).timeout(const Duration(minutes: 5));
      if (res.statusCode != 200) return const UpdateResult(UpdateOutcome.downloadFailed);
      bytes = res.bodyBytes;
    } on Object {
      return const UpdateResult(UpdateOutcome.downloadFailed);
    }
    if (bytes.length != file.size || sha256Hex(bytes) != file.sha256) {
      user.logPack(manifest.contentVersion, 'hash-mismatch');
      return UpdateResult(UpdateOutcome.hashMismatch, manifest.contentVersion);
    }
    final dbPath = '${staging.path}/content.db';
    File(dbPath).writeAsBytesSync(bytes, flush: true);

    // 3. Open it and run an integrity check before it can ever be activated.
    final repo = PackStore.tryOpen(dbPath);
    if (repo == null || repo.contentVersion != manifest.contentVersion) {
      repo?.close();
      user.logPack(manifest.contentVersion, 'broken');
      return UpdateResult(UpdateOutcome.brokenPack, manifest.contentVersion);
    }
    repo.close();
    store.promoteStaging(manifest.contentVersion);
    user.logPack(manifest.contentVersion, 'staged');
    return UpdateResult(UpdateOutcome.staged, manifest.contentVersion);
  }
}
