import 'package:flutter/material.dart';

/// Reader preferences (plan §4.8). Persisted in user.db's `setting` table.
@immutable
class AppSettings {
  const new({
    this.locale,
    this.classNo,
    this.script = 'devanagari',
    this.translationOrder = const {},
    this.textScale = 1.0,
    this.themeMode = ThemeMode.system,
    this.reduceMotion = false,
    this.audioAutoplay = false,
    this.wifiOnly = true,
    this.channel = 'stable',
    this.onboarded = false,
  });

  factory fromMap(Map<String, Object?> m) => AppSettings(
    locale: m['locale'] as String?,
    classNo: m['class'] as int?,
    script: (m['script'] as String?) ?? 'devanagari',
    translationOrder: {
      for (final e in ((m['translation_order'] as Map?) ?? const {}).entries)
        e.key as String: [...(e.value as List).cast<String>()],
    },
    textScale: ((m['text_scale'] as num?) ?? 1.0).toDouble(),
    themeMode: ThemeMode.values.byName((m['theme'] as String?) ?? 'system'),
    reduceMotion: (m['reduce_motion'] as bool?) ?? false,
    audioAutoplay: (m['audio_autoplay'] as bool?) ?? false,
    wifiOnly: (m['wifi_only'] as bool?) ?? true,
    channel: (m['channel'] as String?) ?? 'stable',
    onboarded: (m['onboarded'] as bool?) ?? false,
  );

  /// 'en', 'kn', or null to follow the phone.
  final String? locale;

  /// 6–12, or 0 for "not in school"; null until onboarding.
  final int? classNo;
  final String script; // devanagari | kannada | iast
  /// Translation preference order per interface language (plan §4.7).
  final Map<String, List<String>> translationOrder;
  final double textScale;
  final ThemeMode themeMode;
  final bool reduceMotion;
  final bool audioAutoplay;
  final bool wifiOnly;
  final String channel; // stable | beta
  final bool onboarded;

  Map<String, Object?> toMap() => {
    'locale': locale,
    'class': classNo,
    'script': script,
    'translation_order': translationOrder,
    'text_scale': textScale,
    'theme': themeMode.name,
    'reduce_motion': reduceMotion,
    'audio_autoplay': audioAutoplay,
    'wifi_only': wifiOnly,
    'channel': channel,
    'onboarded': onboarded,
  };

  AppSettings copyWith({
    Object? locale = _keep,
    Object? classNo = _keep,
    String? script,
    Map<String, List<String>>? translationOrder,
    double? textScale,
    ThemeMode? themeMode,
    bool? reduceMotion,
    bool? audioAutoplay,
    bool? wifiOnly,
    String? channel,
    bool? onboarded,
  }) => AppSettings(
    locale: locale == _keep ? this.locale : locale as String?,
    classNo: classNo == _keep ? this.classNo : classNo as int?,
    script: script ?? this.script,
    translationOrder: translationOrder ?? this.translationOrder,
    textScale: textScale ?? this.textScale,
    themeMode: themeMode ?? this.themeMode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    audioAutoplay: audioAutoplay ?? this.audioAutoplay,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    channel: channel ?? this.channel,
    onboarded: onboarded ?? this.onboarded,
  );

  static const _keep = Object();
}
