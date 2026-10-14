import 'package:flutter/material.dart';

/// Font families bundled with the app (plan §7.3). Bundled, never system fonts,
/// so Indic shaping is the same on every phone brand.
abstract final class GVFonts {
  static const package = 'design_system';
  static const latin = 'AnekLatin';
  static const kannadaUi = 'AnekKannada';
  static const devanagariVerse = 'TiroDevanagariSanskrit';
  static const kannadaVerse = 'TiroKannada';

  /// Tiro Kannada carries Latin with every IAST diacritic.
  static const iast = 'TiroKannada';
}

enum VerseFont { devanagari, kannada, iast }

/// Type scale (plan §7.3). Kannada body text gets more line height.
TextTheme gvTextTheme({required bool kannada, required Color ink, required Color muted}) {
  final family = kannada ? GVFonts.kannadaUi : GVFonts.latin;
  final fallback = kannada ? [GVFonts.latin] : [GVFonts.kannadaUi];
  TextStyle s(double size, double line, {FontWeight w = FontWeight.w400, Color? color}) => TextStyle(
    fontFamily: family,
    package: GVFonts.package,
    // TextStyle prefixes fallbacks with the package too.
    fontFamilyFallback: fallback,
    fontSize: size,
    height: line / size,
    fontWeight: w,
    fontVariations: [FontVariation.weight(w.value.toDouble())],
    color: color ?? ink,
  );
  final bodyLine = kannada ? 26.0 : 24.0;
  return TextTheme(
    displaySmall: s(30, kannada ? 42 : 38, w: FontWeight.w600),
    headlineSmall: s(24, kannada ? 36 : 32, w: FontWeight.w600),
    titleLarge: s(22, kannada ? 33 : 30, w: FontWeight.w600),
    titleMedium: s(18, kannada ? 28 : 26, w: FontWeight.w600),
    titleSmall: s(16, kannada ? 26 : 24, w: FontWeight.w600),
    bodyLarge: s(16, bodyLine),
    bodyMedium: s(15, kannada ? 24 : 22),
    bodySmall: s(13, kannada ? 21 : 18, color: muted),
    labelLarge: s(15, kannada ? 22 : 20, w: FontWeight.w600),
    labelMedium: s(14, kannada ? 22 : 20, w: FontWeight.w500),
    labelSmall: s(12, kannada ? 18 : 16, w: FontWeight.w500, color: muted),
  );
}

/// Verse text: 21/34 (plan §7.3), in the script's own classical face.
TextStyle verseStyle(VerseFont font, Color ink, {double size = 21}) => TextStyle(
  fontFamily: switch (font) {
    VerseFont.devanagari => GVFonts.devanagariVerse,
    VerseFont.kannada => GVFonts.kannadaVerse,
    VerseFont.iast => GVFonts.iast,
  },
  package: GVFonts.package,
  fontSize: font == VerseFont.iast ? size * 0.86 : size,
  height: 34 / 21,
  fontStyle: font == VerseFont.iast ? FontStyle.italic : FontStyle.normal,
  color: ink,
);
