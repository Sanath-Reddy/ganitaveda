import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:content_model/content_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/config.dart';
import 'package:ganitaveda/features/updates/pack_store.dart';
import 'package:ganitaveda/features/updates/update_service.dart';
import 'package:ganitaveda/shared/data/settings.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:http/http.dart' as http;

/// Overridden in bootstrap with the opened stores (and in tests with fakes).
final userStoreProvider = Provider<UserStore>((ref) => throw UnimplementedError('userStoreProvider'));
final packStoreProvider = Provider<PackStore?>((ref) => null);
final initialContentProvider = Provider<ContentRepository>((ref) => throw UnimplementedError('initialContentProvider'));

/// The active content pack. Replaced when a staged pack is activated.
final contentProvider = NotifierProvider<ContentNotifier, ContentRepository>(ContentNotifier.new);

class ContentNotifier extends Notifier<ContentRepository> {
  @override
  ContentRepository build() => ref.watch(initialContentProvider);

  /// Switches to a newly staged pack at once (used when no lesson is open).
  void activatePending() {
    final store = ref.read(packStoreProvider);
    if (store == null || store.pendingDir == null) return;
    final opened = store.open();
    final old = state;
    state = opened.repo;
    old.close();
    ref.read(userStoreProvider).logPack(opened.repo.contentVersion, 'active');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.fromMap(ref.watch(userStoreProvider).readSettings());

  void update(AppSettings Function(AppSettings s) change) {
    final next = change(state);
    final store = ref.read(userStoreProvider);
    for (final e in next.toMap().entries) {
      store.writeSetting(e.key, e.value);
    }
    state = next;
  }
}

/// Progress derived from user.db, refreshed after anything is saved.
@immutable
class ProgressSnapshot {
  const new(this.completed, this.byLesson, this.reviews, this.due, this.bookmarks);
  final List<String> completed;
  final Map<String, LessonProgress> byLesson;
  final List<ReviewItem> reviews;
  final List<ReviewItem> due;
  final List<String> bookmarks;

  LessonProgress? inProgress() {
    final open = byLesson.values.where((p) => !p.done).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return open.isEmpty ? null : open.first;
  }
}

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final progressProvider = NotifierProvider<ProgressNotifier, ProgressSnapshot>(ProgressNotifier.new);

class ProgressNotifier extends Notifier<ProgressSnapshot> {
  @override
  ProgressSnapshot build() => _read();

  ProgressSnapshot _read() {
    final s = ref.read(userStoreProvider);
    final now = ref.read(clockProvider)();
    return ProgressSnapshot(
      s.completedLessons(),
      {for (final p in s.allProgress()) p.lessonId: p},
      s.reviewItems(),
      s.dueReviews(now),
      s.bookmarks(),
    );
  }

  void refresh() => state = _read();
}

final updateServiceProvider = Provider<UpdateService?>((ref) {
  final store = ref.watch(packStoreProvider);
  if (store == null) return null;
  return UpdateService(
    store: store,
    user: ref.watch(userStoreProvider),
    config: UpdateConfig(
      baseUrl: AppConfig.contentBaseUrl,
      publicKeys: AppConfig.packPublicKeys,
      appVersion: AppConfig.appVersion,
    ),
    client: http.Client(),
    isOnWifi: () async {
      final r = await Connectivity().checkConnectivity();
      return r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);
    },
  );
});

/// True while a lesson is on screen: a staged pack then waits for the next launch.
final lessonOpenProvider = NotifierProvider<FlagNotifier, bool>(FlagNotifier.new);

class FlagNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// False once the provider container has been disposed.
  bool get mounted => ref.mounted;

  // A method, not a setter, so call sites read as an action.
  // ignore: use_setters_to_change_properties
  void set({required bool value}) => state = value;
}
