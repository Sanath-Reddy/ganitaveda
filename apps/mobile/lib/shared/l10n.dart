import 'package:flutter/widgets.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  bool get isKannada => lang == 'kn';

  /// Picks the text for the current interface language (English if Kannada is missing).
  String lt(LText? t) => t == null ? '' : t.of(lang);

  String formatDate(DateTime d) => DateFormat.yMMMd(lang).format(d);
}

/// Dates with their uncertainty, e.g. "c. 1340–1425", "628", "800–400 BCE".
String yearRange(int from, int to, {bool kannada = false}) {
  String y(int v) => v < 0 ? '${-v}' : '$v';
  final bce = kannada ? 'ಕ್ರಿ.ಪೂ.' : 'BCE';
  if (from == to) return from < 0 ? (kannada ? '$bce ${y(from)}' : '${y(from)} $bce') : y(from);
  if (from < 0 && to < 0) return kannada ? '$bce ${y(from)}–${y(to)}' : '${y(from)}–${y(to)} $bce';
  if (from < 0) return kannada ? '$bce ${y(from)} – ${y(to)}' : '${y(from)} $bce – ${y(to)}';
  return '${y(from)}–${y(to)}';
}
