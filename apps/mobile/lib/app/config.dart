import 'package:flutter/foundation.dart';

/// Build-time configuration, passed with --dart-define (see docs/building.md).
abstract final class AppConfig {
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

  /// CDN root for content packs. Empty means updates are off (the bundled pack is used).
  static const _contentBaseUrl = String.fromEnvironment('CONTENT_BASE_URL');
  static Uri? get contentBaseUrl =>
      _contentBaseUrl.isEmpty ? null : Uri.parse('${_contentBaseUrl.replaceAll(RegExp(r'/+$'), '')}/');

  /// Release keys (current and next) are added when the signing key is
  /// generated in Week 8 (plan §11). Until then release builds use only the
  /// bundled pack.
  static const _releaseKeys = <String, String>{};

  /// A developer's own key from `python -m tools.pack keygen`, trusted by debug builds only.
  static const _devKey = String.fromEnvironment('PACK_DEV_PUBLIC_KEY');

  static Map<String, String> get packPublicKeys => {
    ..._releaseKeys,
    if (kDebugMode && _devKey.isNotEmpty) 'dev': _devKey,
  };

  /// The team's address for problem reports; empty leaves the recipient for the user to fill in.
  static const reportEmail = String.fromEnvironment('REPORT_EMAIL');
}
