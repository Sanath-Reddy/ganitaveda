import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:content_model/content_model.dart';
import 'package:sqlite3/sqlite3.dart';

/// Where content packs live on the phone (plan §6.5):
///
///   packs/baseline/      the pack bundled with the app, copied out on first run
///   `packs/<version>/`   downloaded packs
///   packs/staging/       a download being verified
///   `packs/state.json`   `{"active": dir, "previous": dir, "pending": dir}`
///
/// A pack is activated on the next launch (or at once if no lesson is open),
/// the previous one is kept, and a pack that fails to open is rolled back.
class PackStore {
  new(this.root);
  final Directory root;

  File get _stateFile => File('${root.path}/state.json');

  Map<String, String?> _readState() {
    if (!_stateFile.existsSync()) return {};
    try {
      return Map<String, String?>.from(jsonDecode(_stateFile.readAsStringSync()) as Map);
    } on FormatException {
      return {};
    }
  }

  void _writeState(Map<String, String?> s) {
    final tmp = File('${_stateFile.path}.tmp')..writeAsStringSync(jsonEncode(s), flush: true);
    tmp.renameSync(_stateFile.path);
  }

  String _dbPath(String dir) => '${root.path}/$dir/content.db';

  /// Copies the bundled pack out if it is missing or older than the one in the app.
  void installBaseline(Uint8List bundled, String bundledVersion) {
    final dir = Directory('${root.path}/baseline')..createSync(recursive: true);
    final versionFile = File('${dir.path}/version');
    final current = versionFile.existsSync() ? versionFile.readAsStringSync() : null;
    if (current == null || compareVersions(bundledVersion, current) > 0 || !File(_dbPath('baseline')).existsSync()) {
      final tmp = File('${dir.path}/content.db.tmp')..writeAsBytesSync(bundled, flush: true);
      tmp.renameSync(_dbPath('baseline'));
      versionFile.writeAsStringSync(bundledVersion);
    }
  }

  /// Opens the best usable pack: pending (if [activatePending]), then active,
  /// then previous, then baseline. Rolls back automatically on failure.
  ({SqliteContentRepository repo, String dir, List<String> events}) open({bool activatePending = true}) {
    final state = _readState();
    final events = <String>[];
    final candidates = <String>[
      if (activatePending && state['pending'] != null) state['pending']!,
      ?state['active'],
      ?state['previous'],
      'baseline',
    ];
    for (final dir in candidates.toSet()) {
      final repo = tryOpen(_dbPath(dir));
      if (repo == null) {
        events.add('failed:$dir');
        continue;
      }
      // A pack older than the bundled baseline is never preferred over it.
      if (dir != 'baseline') {
        final baseline = File('${root.path}/baseline/version');
        if (baseline.existsSync() && compareVersions(repo.contentVersion, baseline.readAsStringSync()) < 0) {
          repo.close();
          events.add('older-than-baseline:$dir');
          continue;
        }
      }
      final pending = activatePending ? state['pending'] : null;
      if (dir == pending) {
        _writeState({'active': dir, 'previous': state['active'], 'pending': null});
        events.add('activated:$dir');
      } else {
        final next = {...state};
        if (pending != null) {
          next['pending'] = null; // it failed to open: drop it
          events.add('rolled-back:$pending');
        }
        if (dir != state['active']) {
          next['active'] = dir;
          next['previous'] = null;
          if (state['active'] != null) events.add('rolled-back:${state['active']}');
        }
        if (next.toString() != state.toString()) _writeState(next);
      }
      return (repo: repo, dir: dir, events: events);
    }
    throw StateError('No usable content pack (tried $candidates)');
  }

  /// Opens and checks a pack database; null if it is missing or broken.
  static SqliteContentRepository? tryOpen(String path) {
    if (!File(path).existsSync()) return null;
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      final ok = db.select('PRAGMA integrity_check').first.values.first;
      if (ok != 'ok') {
        db.close();
        return null;
      }
      final repo = SqliteContentRepository(db);
      if (repo.schemaVersion < 1) {
        repo.close();
        return null;
      }
      return repo;
    } on Object {
      return null;
    }
  }

  Directory stagingDir() {
    final d = Directory('${root.path}/staging');
    if (d.existsSync()) d.deleteSync(recursive: true);
    return d..createSync(recursive: true);
  }

  /// Moves a verified staging pack into place and marks it pending.
  String promoteStaging(String contentVersion) {
    final target = Directory('${root.path}/$contentVersion');
    if (target.existsSync()) target.deleteSync(recursive: true);
    Directory('${root.path}/staging').renameSync(target.path);
    final s = _readState();
    _writeState({...s, 'pending': contentVersion});
    return contentVersion;
  }

  String? get activeDir => _readState()['active'];
  String? get pendingDir => _readState()['pending'];

  /// Deletes downloaded packs that are neither active, previous nor pending.
  void prune() {
    final s = _readState();
    final keep = {'baseline', 'staging', ?s['active'], ?s['previous'], ?s['pending']};
    for (final e in root.listSync().whereType<Directory>()) {
      final name = e.uri.pathSegments.where((p) => p.isNotEmpty).last;
      if (!keep.contains(name)) e.deleteSync(recursive: true);
    }
  }
}
