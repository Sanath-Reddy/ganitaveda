import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ganita_core/ganita_core.dart';

/// Scene illustrations drawn in code: flat line drawings, one stroke weight,
/// two or three palette colours (plan §7.6). Placeholders for the designed
/// SVGs; each art id keeps its slot so swapping in the final art is local.
class SceneArt extends StatelessWidget {
  const new(this.art, {super.key});
  final String art;

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(GVRadius.card),
        ),
        child: CustomPaint(painter: _ScenePainter(art, c)),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  new(this.art, this.c);
  final String art;
  final GVColors c;

  Paint get ink => Paint()
    ..color = c.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  Paint fill(Color col) => Paint()..color = col;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final rng = SeededRandom(art.hashCode);
    switch (art) {
      case 'art.bee-swarm':
        for (final (x, col) in [(0.2, c.turmeric), (0.5, c.kumkum), (0.8, c.indigo)]) {
          final o = Offset(w * x, h * 0.72);
          canvas.drawLine(o, Offset(o.dx, h), ink);
          for (var k = 0; k < 6; k++) {
            final a = k * math.pi / 3;
            canvas.drawCircle(o + Offset(math.cos(a) * 12, math.sin(a) * 12), 8, fill(col.withValues(alpha: 0.6)));
          }
        }
        for (var i = 0; i < 15; i++) {
          canvas.drawCircle(
            Offset(w * (0.1 + rng.nextInt(80) / 100), h * (0.1 + rng.nextInt(45) / 100)),
            3,
            fill(c.ink),
          );
        }
      case 'art.ledger':
        canvas.drawLine(Offset(w / 2, h * 0.1), Offset(w / 2, h * 0.9), ink);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(Offset(w * 0.3, h * (0.8 - i * 0.12)), 12, fill(c.neem.withValues(alpha: 0.7)));
        }
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(w * 0.7, h * (0.8 - i * 0.12)),
            12,
            Paint()
              ..color = c.kumkum
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      case 'art.cord-altar':
        final a = Offset(w * 0.25, h * 0.8);
        final b = Offset(w * 0.7, h * 0.8);
        final t = Offset(w * 0.25, h * 0.2);
        canvas.drawPath(Path()..addPolygon([a, b, t], true), ink);
        for (final p in [a, b, t]) {
          canvas.drawCircle(p, 6, fill(c.turmeric));
        }
      case 'art.saffron':
        canvas.drawLine(Offset(w / 2, h * 0.85), Offset(w / 2, h * 0.25), ink);
        canvas.drawLine(Offset(w * 0.25, h * 0.25), Offset(w * 0.75, h * 0.25), ink);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.25, h * 0.45), width: 80, height: 30),
          0,
          math.pi,
          false,
          ink,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.75, h * 0.45), width: 80, height: 30),
          0,
          math.pi,
          false,
          ink,
        );
        for (var i = 0; i < 9; i++) {
          canvas.drawLine(
            Offset(w * 0.25 - 20 + i * 5, h * 0.45),
            Offset(w * 0.25 - 18 + i * 5, h * 0.4),
            Paint()
              ..color = c.kumkum
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(Offset(w * 0.75, h * 0.42), 10, fill(c.turmeric));
      case 'art.alms':
        for (var i = 0; i < 8; i++) {
          final hh = (i + 1) * h * 0.08;
          canvas.drawRect(
            Rect.fromLTWH(w * 0.1 + i * w * 0.1, h * 0.85 - hh, w * 0.06, hh),
            fill(c.turmeric.withValues(alpha: 0.7)),
          );
        }
      case 'art.bow':
        final rect = Rect.fromCircle(center: Offset(w * 0.5, h * 0.9), radius: h * 0.7);
        canvas.drawArc(
          rect,
          -math.pi * 0.85,
          math.pi * 0.7,
          false,
          Paint()
            ..color = c.turmeric
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        final p1 = rect.center + Offset(math.cos(-math.pi * 0.85), math.sin(-math.pi * 0.85)) * rect.width / 2;
        final p2 = rect.center + Offset(math.cos(-math.pi * 0.15), math.sin(-math.pi * 0.15)) * rect.width / 2;
        canvas.drawLine(p1, p2, ink);
        canvas.drawLine(
          Offset(w / 2, p1.dy),
          Offset(w / 2, h * 0.2),
          Paint()
            ..color = c.indigo
            ..strokeWidth = 3,
        );
      case 'art.circle-series':
        final o = Offset(w / 2, h / 2);
        final rad = h * 0.38;
        canvas.drawCircle(o, rad, ink);
        for (final n in [6, 12, 24]) {
          final pts = [
            for (var k = 0; k < n; k++) o + Offset(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) * rad,
          ];
          canvas.drawPath(
            Path()..addPolygon(pts, true),
            Paint()
              ..color = c.turmeric.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke,
          );
        }
      case 'art.grinding':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w / 2, h * 0.55), width: w * 0.4, height: h * 0.5),
          0,
          math.pi,
          false,
          ink,
        );
        canvas.drawLine(Offset(w * 0.3, h * 0.55), Offset(w * 0.7, h * 0.55), ink);
        canvas.drawLine(
          Offset(w * 0.55, h * 0.15),
          Offset(w * 0.5, h * 0.55),
          Paint()
            ..color = c.kumkum
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        for (var i = 0; i < 10; i++) {
          canvas.drawCircle(
            Offset(w * (0.38 + rng.nextInt(24) / 100), h * (0.6 + rng.nextInt(12) / 100)),
            2,
            fill(c.turmeric),
          );
        }
      case 'art.field-circle':
        final o = Offset(w / 2, h / 2);
        final rad = h * 0.4;
        canvas.drawCircle(o, rad, ink);
        final angs = [200, 290, 20, 110].map((d) => d * math.pi / 180);
        final pts = [for (final a in angs) o + Offset(math.cos(a), math.sin(a)) * rad];
        canvas.drawPath(Path()..addPolygon(pts, true), fill(c.neem.withValues(alpha: 0.3)));
        canvas.drawPath(Path()..addPolygon(pts, true), ink);
      case 'art.digits':
        for (final (i, d) in [3, 9, 8].indexed) {
          final r = Rect.fromCenter(center: Offset(w * (0.3 + i * 0.2), h / 2), width: w * 0.15, height: w * 0.15);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), ink);
          final tp = TextPainter(
            text: TextSpan(
              text: '$d',
              style: TextStyle(color: c.ink, fontSize: r.height * 0.6),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
        }
      default:
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.3, ink);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.art != art || old.c != c;
}
