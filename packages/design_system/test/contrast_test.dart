import 'dart:math' as math;
import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [('light', GVColors.light), ('dark', GVColors.dark)]) {
    test('$name: text colours pass WCAG AA (4.5:1) on paper, surface and leaf', () {
      for (final bg in [c.paper, c.surface, c.leaf]) {
        for (final (label, fg) in [
          ('ink', c.ink),
          ('ink-muted', c.inkMuted),
          ('indigo', c.indigo),
          ('kumkum', c.kumkum),
          ('neem', c.neem),
        ]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$name $label on $bg');
        }
      }
    });
  }
}
