import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ganita_core/ganita_core.dart';

/// Kolam by the mirror-curve method (plan §7.6).
///
/// Dots sit at the centres of a [width] × [height] grid of cells. A line runs
/// diagonally between edge midpoints; where an edge holds a mirror (every
/// boundary edge, plus chosen inner edges) the line bounces, otherwise it
/// crosses straight over. Only mirror layouts that give one single closed
/// curve are kept.
///
/// Coordinates are doubled: dots at (odd, odd), edge midpoints where exactly
/// one coordinate is even.
class KolamMotif {
  final int width, height;
  final Set<(int, int)> mirrors;
  final List<Offset> path;

  const KolamMotif._(this.width, this.height, this.mirrors, this.path);

  /// Deterministic in [seed]; tries mirror layouts until the curve is a single loop.
  factory KolamMotif.generate(int seed, {int width = 3, int height = 3, int density = 35}) {
    final rng = SeededRandom(seed);
    final inner = [
      for (var x = 0; x <= 2 * width; x++)
        for (var y = 0; y <= 2 * height; y++)
          if ((x.isEven != y.isEven) && x > 0 && x < 2 * width && y > 0 && y < 2 * height) (x, y),
    ];
    for (var attempt = 0; attempt < 500; attempt++) {
      final mirrors = {
        for (final e in inner)
          if (rng.chance(density)) e,
      };
      final path = traceSingle(width, height, mirrors);
      if (path != null) return KolamMotif._(width, height, mirrors, path);
    }
    // No mirrors on a 1-wide strip always closes; fall back to it.
    return KolamMotif._(1, height, const {}, traceSingle(1, height, const {})!);
  }

  static bool _isBoundary(int x, int y, int w, int h) => x == 0 || y == 0 || x == 2 * w || y == 2 * h;

  /// The single closed curve, as midpoints in order, or null if the layout
  /// makes more than one curve.
  static List<Offset>? traceSingle(int w, int h, Set<(int, int)> mirrors) {
    // A single curve passes every inner midpoint twice and bounces once off
    // every boundary midpoint.
    var expected = 0;
    for (var x = 0; x <= 2 * w; x++) {
      for (var y = 0; y <= 2 * h; y++) {
        if (x.isEven != y.isEven) expected += _isBoundary(x, y, w, h) ? 1 : 2;
      }
    }
    // Start on the bottom-left horizontal boundary edge, heading up-right.
    var x = 1, y = 0, dx = 1, dy = 1;
    final startState = (x, y, dx, dy);
    final path = <Offset>[];
    for (var steps = 0; steps <= expected; steps++) {
      path.add(Offset(x.toDouble(), y.toDouble()));
      x += dx;
      y += dy;
      if (_isBoundary(x, y, w, h) || mirrors.contains((x, y))) {
        if (x.isEven) dx = -dx;
        if (y.isEven) dy = -dy;
      }
      if ((x, y, dx, dy) == startState) {
        return path.length == expected ? path : null;
      }
    }
    return null;
  }
}

/// Several motifs laid out in a row-wrapped grid; one per finished lesson.
class KolamPainter extends CustomPainter {
  final List<KolamMotif> motifs;

  /// Drawing progress of the last motif, 0–1 (the new loop draws itself).
  final double lastProgress;
  final Color dot, line, accent;

  KolamPainter({
    required this.motifs,
    required this.lastProgress,
    required this.dot,
    required this.line,
    required this.accent,
  });

  static const columns = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (motifs.isEmpty) return;
    final rows = (motifs.length / columns).ceil();
    final cell = math.min(size.width / columns, size.height / math.max(rows, 1));
    final dotPaint = Paint()..color = dot;
    for (var i = 0; i < motifs.length; i++) {
      final m = motifs[i];
      final origin = Offset((i % columns) * cell, (i ~/ columns) * cell);
      final unit = cell / (2 * math.max(m.width, m.height) + 2);
      Offset at(Offset p) => origin + Offset((p.dx + 1) * unit, (p.dy + 1) * unit);
      for (var x = 1; x < 2 * m.width; x += 2) {
        for (var y = 1; y < 2 * m.height; y += 2) {
          canvas.drawCircle(at(Offset(x.toDouble(), y.toDouble())), unit * 0.14, dotPaint);
        }
      }
      final isLast = i == motifs.length - 1;
      final paint = Paint()
        ..color = isLast ? accent : line
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = smoothClosed([for (final p in m.path) at(p)]);
      if (isLast && lastProgress < 1) {
        for (final metric in path.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * lastProgress), paint);
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  /// A smooth closed curve through the midpoints of consecutive points,
  /// using each point as the control: rounded loops around the dots.
  static Path smoothClosed(List<Offset> pts) {
    final path = Path();
    if (pts.length < 3) return path;
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final start = mid(pts.last, pts.first);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], next = pts[(i + 1) % pts.length];
      final m = mid(p, next);
      path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(KolamPainter old) =>
      old.motifs.length != motifs.length ||
      old.lastProgress != lastProgress ||
      old.accent != accent ||
      old.line != line;
}

/// Stable 32-bit seed from a lesson id (FNV-1a), so each lesson always draws the same loop.
int seedFromId(String id) {
  var h = 0x811C9DC5;
  for (final c in id.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}
