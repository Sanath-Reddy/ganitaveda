import 'package:flutter/material.dart';

/// Colour tokens (plan §7.2). Starting values, tuned on a real phone.
/// All text colours pass WCAG AA on [paper] and [surface] (see test/contrast_test.dart).
@immutable
class GVColors extends ThemeExtension<GVColors> {
  final Color paper, surface, leaf, ink, inkMuted, indigo, turmeric, kumkum, neem, line;

  const GVColors({
    required this.paper,
    required this.surface,
    required this.leaf,
    required this.ink,
    required this.inkMuted,
    required this.indigo,
    required this.turmeric,
    required this.kumkum,
    required this.neem,
    required this.line,
  });

  static const light = GVColors(
    paper: Color(0xFFF5EEDF),
    surface: Color(0xFFFBF7EE),
    leaf: Color(0xFFE8D6A8),
    ink: Color(0xFF1F1A14),
    inkMuted: Color(0xFF5C5346),
    indigo: Color(0xFF2C3E73),
    turmeric: Color(0xFFC98A12),
    kumkum: Color(0xFFA8322A),
    neem: Color(0xFF2C6449), // plan: #2F6B4F; darkened to pass AA on leaf
    line: Color(0xFFD9CDB6),
  );

  static const dark = GVColors(
    paper: Color(0xFF14110D),
    surface: Color(0xFF1E1A14),
    leaf: Color(0xFF3A3122),
    ink: Color(0xFFEFE6D3),
    inkMuted: Color(0xFFB7AC98),
    indigo: Color(0xFF9DB0E8),
    turmeric: Color(0xFFF0B44A),
    kumkum: Color(0xFFE5837A), // plan: #E07A6E; lightened to pass AA on leaf
    neem: Color(0xFF7CC4A0),
    line: Color(0xFF3A3328),
  );

  static GVColors of(BuildContext context) => Theme.of(context).extension<GVColors>()!;

  @override
  GVColors copyWith({
    Color? paper,
    Color? surface,
    Color? leaf,
    Color? ink,
    Color? inkMuted,
    Color? indigo,
    Color? turmeric,
    Color? kumkum,
    Color? neem,
    Color? line,
  }) => GVColors(
    paper: paper ?? this.paper,
    surface: surface ?? this.surface,
    leaf: leaf ?? this.leaf,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    indigo: indigo ?? this.indigo,
    turmeric: turmeric ?? this.turmeric,
    kumkum: kumkum ?? this.kumkum,
    neem: neem ?? this.neem,
    line: line ?? this.line,
  );

  @override
  GVColors lerp(ThemeExtension<GVColors>? other, double t) {
    if (other is! GVColors) return this;
    return GVColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      leaf: Color.lerp(leaf, other.leaf, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      turmeric: Color.lerp(turmeric, other.turmeric, t)!,
      kumkum: Color.lerp(kumkum, other.kumkum, t)!,
      neem: Color.lerp(neem, other.neem, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

abstract final class GVSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
  static const gutter = 16.0;

  /// Lesson cards are centred at about this width on large screens (plan §7.8).
  static const lessonMaxWidth = 640.0;
  static const twoPaneBreakpoint = 600.0;
  static const minTap = 48.0;
}

abstract final class GVRadius {
  static const card = 12.0, chip = 999.0, leaf = 18.0;
}

/// Motion (plan §7.5). With reduce motion on, everything becomes a short cross-fade.
class GVMotion {
  final bool reduce;

  const GVMotion({this.reduce = false});

  static const _crossFade = Duration(milliseconds: 150);

  Duration get cardSlide => reduce ? _crossFade : const Duration(milliseconds: 220);
  Duration get leafRise => reduce ? _crossFade : const Duration(milliseconds: 260);
  Duration get inkDraw => reduce ? _crossFade : const Duration(milliseconds: 750);
  Duration get answer => reduce ? _crossFade : const Duration(milliseconds: 180);
  Duration get kolamLoop => reduce ? _crossFade : const Duration(milliseconds: 1200);
  Curve get curve => reduce ? Curves.linear : Curves.easeOutCubic;

  static GVMotion of(BuildContext context) => GVMotion(reduce: MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}
