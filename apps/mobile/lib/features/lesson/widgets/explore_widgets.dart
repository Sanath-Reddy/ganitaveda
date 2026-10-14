import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ganita_core/ganita_core.dart';

import 'package:ganitaveda/shared/l10n.dart';

typedef StateMap = Map<String, Object?>;
typedef ExploreWidgetBuilder = Widget Function(StateMap params, StateMap state, void Function(StateMap) onState);

Rational _rat(Object? v) => v is int ? r(v) : Rational.parse('$v');

/// A labelled − value + control: every drag in the explorers has these buttons
/// as an alternative (plan §7.7), and TalkBack reads the value.
class Stepper extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.slider = true,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool slider;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: t.labelLarge)),
            IconButton.outlined(
              tooltip: l.decrease,
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 56,
              child: Semantics(
                label: label,
                value: '$value',
                child: Text('$value', textAlign: TextAlign.center, style: t.titleLarge),
              ),
            ),
            IconButton.outlined(
              tooltip: l.increase,
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (slider && max - min <= 200)
          ExcludeSemantics(
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const new({required this.child, this.aspect = 1.4});
  final Widget child;
  final double aspect;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: GVColors.of(context).surface,
      border: Border.all(color: GVColors.of(context).line),
      borderRadius: BorderRadius.circular(GVRadius.card),
    ),
    child: AspectRatio(aspectRatio: aspect, child: child),
  );
}

class _Result extends StatelessWidget {
  const new(this.text, {this.good = false});
  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GVSpace.m),
        child: Row(
          children: [
            if (good)
              Padding(
                padding: const EdgeInsets.only(right: GVSpace.s),
                child: Icon(Icons.check_circle, color: c.neem),
              ),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: good ? c.neem : c.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 1. swarm

class SwarmExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parts = [for (final p in params['parts']! as List) _rat(p)];
    final m = (params['difference_multiplier'] as int?) ?? 0;
    final rem = _rat(params['remainder']);
    final range = (params['range']! as List).cast<int>();
    final n = (state['n'] as int?) ?? range[0] + 7;
    final whole = r(n);
    final a = whole * parts[0];
    final b = whole * parts[1];
    final third = (b - a).abs() * r(m);
    final left = whole - a - b - third;
    final even = a.isInteger && b.isInteger;
    final found = even && left == rem;
    final c = GVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: CustomPaint(
            painter: _SwarmPainter(
              total: n,
              groups: even ? [a.toInt(), b.toInt(), third.toInt()] : const [],
              colors: [c.turmeric, c.indigo, c.kumkum],
              loose: c.inkMuted,
            ),
          ),
        ),
        _Result(
          found
              ? l.swarmFound(rem.toString())
              : even
              ? l.swarmGroups('$a', '$b', '$third', left.toMixedString())
              : l.swarmUneven(n),
          good: found,
        ),
        Stepper(label: l.swarmSize(n), value: n, min: range[0], max: range[1], onChanged: (v) => onState({'n': v})),
      ],
    );
  }
}

class _SwarmPainter extends CustomPainter {
  new({required this.total, required this.groups, required this.colors, required this.loose});
  final int total;
  final List<int> groups;
  final List<Color> colors;
  final Color loose;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = SeededRandom(total);
    final clusters = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.3),
    ];
    var drawn = 0;
    for (var g = 0; g < groups.length; g++) {
      final p = Paint()..color = colors[g];
      canvas.drawCircle(clusters[g], 16, Paint()..color = colors[g].withValues(alpha: 0.15));
      for (var i = 0; i < groups[g] && drawn < total; i++, drawn++) {
        final ang = rng.nextInt(360) * math.pi / 180;
        final rad = 18 + rng.nextInt(28).toDouble();
        canvas.drawCircle(clusters[g] + Offset(math.cos(ang) * rad, math.sin(ang) * rad), 3.2, p);
      }
    }
    final lp = Paint()..color = loose;
    for (; drawn < total; drawn++) {
      canvas.drawCircle(
        Offset(size.width * (0.35 + rng.nextInt(30) / 100), size.height * (0.15 + rng.nextInt(20) / 100)),
        3.2,
        lp,
      );
    }
  }

  @override
  bool shouldRepaint(_SwarmPainter old) => old.total != total || old.groups.toString() != groups.toString();
}

// ---------------------------------------------------------------- 2. number line

class NumberLineExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final range = (params['range']! as List).cast<int>();
    final a = (state['a'] as int?) ?? 5;
    final b = (state['b'] as int?) ?? -3;
    final op = (state['op'] as String?) ?? '+';
    final canDivide = b != 0 && a % b == 0;
    final result = op == '÷' && !canDivide ? null : apply(op, r(a), r(b));
    final c = GVColors.of(context);
    void set(StateMap s) => onState({'a': a, 'b': b, 'op': op, ...s});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 3,
          child: CustomPaint(
            painter: _LinePainter(
              range: range,
              a: a,
              b: b,
              result: result?.toDouble(),
              ink: c.ink,
              fortune: c.neem,
              debt: c.kumkum,
              accent: c.indigo,
            ),
          ),
        ),
        _Result(
          result == null ? '$a ÷ ($b)' : l.result('$a $op ${b < 0 ? '($b)' : '$b'} = ${result.toMixedString()}'),
          good: result != null && result.isZero,
        ),
        if (result != null) Text(context.lt(ruleFor(op, r(a), r(b))), style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: GVSpace.m),
        SegmentedButton<String>(
          segments: [
            for (final o in ['+', '−', '×', '÷']) ButtonSegment(value: o, label: Text(o)),
          ],
          selected: {op},
          onSelectionChanged: (s) => set({'op': s.single}),
        ),
        Stepper(label: l.fortune, value: a, min: 0, max: range[1], onChanged: (v) => set({'a': v})),
        Stepper(label: l.debt, value: b, min: range[0], max: 0, onChanged: (v) => set({'b': v})),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  new({
    required this.range,
    required this.a,
    required this.b,
    required this.result,
    required this.ink,
    required this.fortune,
    required this.debt,
    required this.accent,
  });
  final List<int> range;
  final int a;
  final int b;
  final double? result;
  final Color ink;
  final Color fortune;
  final Color debt;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = range[0] * 2.0;
    final hi = range[1] * 2.0;
    double x(num v) => 16 + (v.clamp(lo, hi) - lo) / (hi - lo) * (size.width - 32);
    final y = size.height * 0.62;
    final line = Paint()
      ..color = ink
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(x(lo), y), Offset(x(hi), y), line);
    for (var v = lo.toInt(); v <= hi; v += 2) {
      canvas.drawLine(Offset(x(v), y - (v == 0 ? 8 : 4)), Offset(x(v), y + (v == 0 ? 8 : 4)), line);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(color: ink, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x(0) - tp.width / 2, y + 10));
    canvas.drawCircle(Offset(x(a), y - 18), 6, Paint()..color = fortune);
    canvas.drawCircle(Offset(x(b), y - 18), 6, Paint()..color = debt);
    if (result != null) {
      canvas.drawCircle(Offset(x(result!), y), 7, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.a != a || old.b != b || old.result != result;
}

// ---------------------------------------------------------------- 3. triangle

class TriangleExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final start = (params['start']! as List).cast<int>();
    final a = (state['a'] as int?) ?? start[0];
    final b = (state['b'] as int?) ?? start[1];
    final sq = a * a + b * b;
    final cExact = exactSqrt(r(sq));
    final c = GVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: CustomPaint(
            painter: _TrianglePainter(a: a, b: b, ink: c.ink, sq: [c.turmeric, c.indigo, c.neem]),
          ),
        ),
        _Result(
          '$a² + $b² = ${a * a} + ${b * b} = $sq  →  ${l.hypotenuse} = ${cExact?.toString() ?? '√$sq ≈ ${math.sqrt(sq).toStringAsFixed(2)}'}'
          '${cExact != null ? '. ${l.wholeNumberTriangle}' : ''}',
          good: cExact != null,
        ),
        Stepper(label: l.side, value: a, min: 1, max: 24, onChanged: (v) => onState({'a': v, 'b': b})),
        Stepper(label: l.upright, value: b, min: 1, max: 24, onChanged: (v) => onState({'a': a, 'b': v})),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  new({required this.a, required this.b, required this.ink, required this.sq});
  final int a;
  final int b;
  final Color ink;
  final List<Color> sq;

  @override
  void paint(Canvas canvas, Size size) {
    // Unit coordinates: right angle at the origin, side along x, upright along y (up is negative).
    const pA = Offset.zero;
    final pB = Offset(a.toDouble(), 0);
    final pC = Offset(0, -b.toDouble());
    final sideSq = [pA, pB, pB + Offset(0, a.toDouble()), pA + Offset(0, a.toDouble())];
    final upSq = [pA, pC, pC - Offset(b.toDouble(), 0), pA - Offset(b.toDouble(), 0)];
    final d = pC - pB;
    final out = Offset(-d.dy, d.dx); // (b, -a): points away from the triangle
    final hypSq = [pB, pC, pC + out, pB + out];
    final all = [...sideSq, ...upSq, ...hypSq];
    final minX = all.map((p) => p.dx).reduce(math.min);
    final maxX = all.map((p) => p.dx).reduce(math.max);
    final minY = all.map((p) => p.dy).reduce(math.min);
    final maxY = all.map((p) => p.dy).reduce(math.max);
    final scale = math.min((size.width - 24) / (maxX - minX), (size.height - 24) / (maxY - minY));
    Offset map(Offset p) => Offset(12 + (p.dx - minX) * scale, 12 + (p.dy - minY) * scale);
    Path poly(List<Offset> pts) => Path()..addPolygon([for (final p in pts) map(p)], true);
    for (final (pts, color) in [(sideSq, sq[0]), (upSq, sq[1]), (hypSq, sq[2])]) {
      canvas.drawPath(poly(pts), Paint()..color = color.withValues(alpha: 0.2));
      canvas.drawPath(
        poly(pts),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawPath(
      poly([pA, pB, pC]),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.a != a || old.b != b;
}

// ---------------------------------------------------------------- 4. ratio balance

class RatioBalanceExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final start = params['start']! as List;
    final pramana = _rat(start[0]);
    final phala = _rat(start[1]);
    final iccha = (state['iccha'] as int?) ?? _rat(start[2]).toInt();
    final fruit = phala * r(iccha) / pramana;
    final perOne = phala / pramana;
    final c = GVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 2,
          child: CustomPaint(
            painter: _BalancePainter(left: pramana.toDouble(), right: r(iccha).toDouble(), ink: c.ink, pan: c.turmeric),
          ),
        ),
        _Result('${l.measure} ${pramana.toMixedString()} → ${l.fruit} ${phala.toMixedString()}'),
        _Result(
          '${l.desire} $iccha → ${l.fruitOfDesire} ${fruit.toMixedString()}  (1 → ${perOne.toMixedString()})',
          good: iccha == 1,
        ),
        Stepper(label: l.desire, value: iccha, min: 1, max: 30, onChanged: (v) => onState({'iccha': v})),
      ],
    );
  }
}

class _BalancePainter extends CustomPainter {
  new({required this.left, required this.right, required this.ink, required this.pan});
  final double left;
  final double right;
  final Color ink;
  final Color pan;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final top = size.height * 0.25;
    canvas.drawLine(Offset(cx, size.height * 0.9), Offset(cx, top), p);
    final beam = size.width * 0.36;
    canvas.drawLine(Offset(cx - beam, top), Offset(cx + beam, top), p);
    for (final (x, w) in [(cx - beam, left), (cx + beam, right)]) {
      final h = 10 + math.min(40, w * 3).toDouble();
      canvas.drawLine(Offset(x, top), Offset(x, top + 30), p);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, top + 30 + h / 2), width: 60, height: h),
        Paint()..color = pan.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_BalancePainter old) => old.left != left || old.right != right;
}

// ---------------------------------------------------------------- 5. sequence builder

class SequenceExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final start = (params['start']! as List).cast<int>();
    final a = (state['a'] as int?) ?? start[0];
    final d = (state['d'] as int?) ?? start[1];
    final n = (state['n'] as int?) ?? start[2];
    final terms = [for (var k = 0; k < n; k++) a + k * d];
    final sum = terms.fold<int>(0, (s, v) => s + v);
    final c = GVColors.of(context);
    void set(StateMap s) => onState({'a': a, 'd': d, 'n': n, ...s});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 2,
          child: CustomPaint(
            painter: _BarsPainter(terms: terms, ink: c.ink, a: c.turmeric, b: c.indigo),
          ),
        ),
        _Result(l.sumIs('$sum', '${a + terms.last}')),
        Stepper(label: l.firstTerm, value: a, min: 1, max: 20, onChanged: (v) => set({'a': v})),
        Stepper(label: l.increaseBy, value: d, min: 0, max: 10, onChanged: (v) => set({'d': v})),
        Stepper(label: l.termCount, value: n, min: 2, max: 30, onChanged: (v) => set({'n': v})),
      ],
    );
  }
}

/// Each term stacked with its mirror image: every column is first + last tall,
/// so the sum is (first + last) × terms ÷ 2.
class _BarsPainter extends CustomPainter {
  new({required this.terms, required this.ink, required this.a, required this.b});
  final List<int> terms;
  final Color ink;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final pair = (terms.first + terms.last).toDouble();
    final unit = size.height * 0.9 / (pair == 0 ? 1 : pair);
    final w = size.width / terms.length;
    for (var i = 0; i < terms.length; i++) {
      final h1 = terms[i] * unit;
      final h2 = terms[terms.length - 1 - i] * unit;
      canvas.drawRect(Rect.fromLTWH(i * w + 1, size.height - h1, w - 2, h1), Paint()..color = a.withValues(alpha: 0.8));
      canvas.drawRect(
        Rect.fromLTWH(i * w + 1, size.height - h1 - h2, w - 2, h2),
        Paint()..color = b.withValues(alpha: 0.3),
      );
    }
    final top = size.height - pair * unit;
    canvas.drawLine(
      Offset(0, top),
      Offset(size.width, top),
      Paint()
        ..color = ink
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.terms.toString() != terms.toString();
}

// ---------------------------------------------------------------- 6. chord

class ChordExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final radius = (params['radius'] as int?) ?? 3438;
    final steps = (params['steps'] as int?) ?? 24;
    final rows = jyaTable(radius: radius, steps: steps);
    final k = ((state['k'] as int?) ?? 4).clamp(1, steps);
    final row = rows[k - 1];
    final c = GVColors.of(context);
    final deg = row.arcMinutes / 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 1.2,
          child: CustomPaint(
            painter: _ChordPainter(angle: deg * math.pi / 180, ink: c.ink, chord: c.turmeric, half: c.indigo),
          ),
        ),
        _Result(l.arcStep(k, deg.toStringAsFixed(2)), good: k == steps ~/ 3),
        _Result(l.halfChordValues('${row.halfChord}', row.modern.toStringAsFixed(1))),
        Stepper(
          label: l.arcStep(k, deg.toStringAsFixed(2)),
          value: k,
          min: 1,
          max: steps,
          onChanged: (v) => onState({'k': v}),
        ),
      ],
    );
  }
}

class _ChordPainter extends CustomPainter {
  new({required this.angle, required this.ink, required this.chord, required this.half});
  final double angle;
  final Color ink;
  final Color chord;
  final Color half;

  @override
  void paint(Canvas canvas, Size size) {
    final rad = math.min(size.width, size.height) * 0.4;
    final o = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(o, rad, p);
    canvas.drawLine(o - Offset(rad, 0), o + Offset(rad, 0), p..color = ink.withValues(alpha: 0.4));
    final top = o + Offset(rad * math.cos(angle), -rad * math.sin(angle));
    final bottom = o + Offset(rad * math.cos(angle), rad * math.sin(angle));
    canvas.drawLine(
      top,
      bottom,
      Paint()
        ..color = chord
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      top,
      Offset(top.dx, o.dy),
      Paint()
        ..color = half
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      Rect.fromCircle(center: o, radius: rad),
      -angle,
      angle * 2,
      false,
      Paint()
        ..color = chord
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawLine(o, top, p..color = ink);
  }

  @override
  bool shouldRepaint(_ChordPainter old) => old.angle != angle;
}

// ---------------------------------------------------------------- 7. series plot

class SeriesExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final maxTerms = (params['max_terms'] as int?) ?? 50;
    final n = (state['n'] as int?) ?? 5;
    final corrected = (state['corrected'] as bool?) ?? false;
    final values = [for (var k = 1; k <= n; k++) (corrected ? madhavaSum(k).corrected : madhavaSum(k).pi).toDouble()];
    final c = GVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 1.8,
          child: CustomPaint(
            painter: _SeriesPainter(values: values, ink: c.ink, line: c.indigo, pi: c.turmeric),
          ),
        ),
        _Result(l.piEstimate(values.last.toStringAsFixed(8)), good: (values.last - math.pi).abs() < 0.0005),
        SwitchListTile(
          title: Text(l.endCorrection),
          value: corrected,
          onChanged: (v) => onState({'n': n, 'corrected': v}),
        ),
        Stepper(
          label: l.termsShown(n),
          value: n,
          min: 1,
          max: maxTerms,
          onChanged: (v) => onState({'n': v, 'corrected': corrected}),
        ),
      ],
    );
  }
}

class _SeriesPainter extends CustomPainter {
  new({required this.values, required this.ink, required this.line, required this.pi});
  final List<double> values;
  final Color ink;
  final Color line;
  final Color pi;

  @override
  void paint(Canvas canvas, Size size) {
    const lo = 2.6;
    const hi = 4.1;
    double y(double v) => size.height - (v.clamp(lo, hi) - lo) / (hi - lo) * size.height;
    canvas.drawLine(
      Offset(0, y(math.pi)),
      Offset(size.width, y(math.pi)),
      Paint()
        ..color = pi
        ..strokeWidth = 1.5,
    );
    final w = size.width / math.max(values.length, 2);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final pt = Offset(i * w + w / 2, y(values[i]));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      canvas.drawCircle(pt, 2.5, Paint()..color = line);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_SeriesPainter old) =>
      old.values.length != values.length || old.values.lastOrNull != values.lastOrNull;
}

// ---------------------------------------------------------------- 8. division table

class DivisionTableExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final start = (params['start']! as List).cast<int>();
    final rows = <(int, int, int, int)>[];
    var x = start[0];
    var y = start[1];
    while (y != 0) {
      rows.add((x, y, x ~/ y, x % y));
      final t = x % y;
      x = y;
      y = t;
    }
    final shown = ((state['shown'] as int?) ?? 1).clamp(1, rows.length);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          border: TableBorder(horizontalInside: BorderSide(color: GVColors.of(context).line)),
          children: [
            for (final (a, b, q, rem) in rows.take(shown))
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(GVSpace.s),
                    child: Text('$a = $b × $q + $rem', style: t.titleMedium),
                  ),
                ],
              ),
          ],
        ),
        if (shown == rows.length) _Result(l.lastRemainder(rows.last.$2), good: true),
        const SizedBox(height: GVSpace.m),
        Row(
          children: [
            FilledButton(
              onPressed: shown < rows.length ? () => onState({'shown': shown + 1}) : null,
              child: Text(l.divideStep),
            ),
            const SizedBox(width: GVSpace.s),
            TextButton(onPressed: () => onState({'shown': 1}), child: Text(l.reset)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 9. cyclic quadrilateral

class CyclicQuadExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  static const _start = [200, 290, 20, 110];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final angles = [for (var i = 0; i < 4; i++) (state['a$i'] as int?) ?? _start[i]];
    final sorted = [...angles]..sort();
    final pts = [for (final a in sorted) Offset(math.cos(a * math.pi / 180), -math.sin(a * math.pi / 180))];
    double dist(Offset p, Offset q) => (p - q).distance;
    final sides = [for (var i = 0; i < 4; i++) dist(pts[i], pts[(i + 1) % 4])];
    double shoelace() {
      var s = 0.0;
      for (var i = 0; i < 4; i++) {
        s += pts[i].dx * pts[(i + 1) % 4].dy - pts[(i + 1) % 4].dx * pts[i].dy;
      }
      return s.abs() / 2;
    }

    final semi = sides.reduce((a, b) => a + b) / 2;
    final brahma = math.sqrt(sides.map((s) => semi - s).reduce((a, b) => a * b));
    final gross = (sides[0] + sides[2]) / 2 * (sides[1] + sides[3]) / 2;
    final c = GVColors.of(context);
    final sel = (state['sel'] as int?) ?? 0;
    void set(StateMap s) => onState({for (var i = 0; i < 4; i++) 'a$i': angles[i], 'sel': sel, ...s});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          aspect: 1.2,
          child: CustomPaint(
            painter: _QuadPainter(points: pts, ink: c.ink, fill: c.turmeric),
          ),
        ),
        _Result(l.trueArea(shoelace().toStringAsFixed(3))),
        _Result(l.brahmaguptaArea(brahma.toStringAsFixed(3)), good: true),
        _Result(l.grossArea(gross.toStringAsFixed(3)), good: (gross - shoelace()).abs() < 0.001),
        SegmentedButton<int>(
          segments: [for (var i = 0; i < 4; i++) ButtonSegment(value: i, label: Text(l.corner(i + 1)))],
          selected: {sel},
          onSelectionChanged: (s) => set({'sel': s.single}),
        ),
        Stepper(
          label: '${l.corner(sel + 1)} °',
          value: angles[sel],
          min: 0,
          max: 359,
          onChanged: (v) => set({'a$sel': v}),
        ),
      ],
    );
  }
}

class _QuadPainter extends CustomPainter {
  new({required this.points, required this.ink, required this.fill});
  final List<Offset> points;
  final Color ink;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rad = math.min(size.width, size.height) * 0.42;
    final o = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      o,
      rad,
      Paint()
        ..color = ink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke,
    );
    final path = Path()..addPolygon([for (final p in points) o + p * rad], true);
    canvas.drawPath(path, Paint()..color = fill.withValues(alpha: 0.25));
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (final p in points) {
      canvas.drawCircle(o + p * rad, 5, Paint()..color = fill);
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.points.toString() != points.toString();
}

// ---------------------------------------------------------------- 10. digit arrangement

class DigitArrangeExplorer extends StatelessWidget {
  const new({required this.params, required this.state, required this.onState, super.key});
  final StateMap params;
  final StateMap state;
  final void Function(StateMap) onState;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = (params['digits']! as List).cast<int>();
    final building = [...?(state['building'] as List?)?.cast<int>()]; // indices used
    final found = [...?(state['found'] as List?)?.cast<int>()];
    final total = ankapasha(digits).count.toInt();
    final t = Theme.of(context).textTheme;
    void set(List<int> b, List<int> f) => onState({'building': b, 'found': f});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          building.map((i) => digits[i]).join().padRight(digits.length, '·'),
          style: t.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: GVSpace.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < digits.length; i++)
              Padding(
                padding: const EdgeInsets.all(GVSpace.xs),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: building.contains(i)
                        ? null
                        : () {
                            final b = [...building, i];
                            if (b.length == digits.length) {
                              final number = int.parse(b.map((j) => digits[j]).join());
                              set([], {...found, number}.toList()..sort());
                            } else {
                              set(b, found);
                            }
                          },
                    child: Text('${digits[i]}', style: t.titleLarge),
                  ),
                ),
              ),
          ],
        ),
        _Result(l.numbersFound(found.length, total), good: found.length == total),
        Wrap(
          spacing: GVSpace.s,
          runSpacing: GVSpace.s,
          children: [for (final n in found) Chip(label: Text('$n'))],
        ),
        if (found.length == total) _Result('Σ = ${found.fold<int>(0, (s, v) => s + v)}', good: true),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => set([], []), child: Text(l.clear)),
        ),
      ],
    );
  }
}
