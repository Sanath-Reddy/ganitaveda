import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kolam.dart';
import '../tokens.dart';
import '../typography.dart';

/// Section heading with a hairline (plan §7.9: hairlines, not shadows).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(GVSpace.gutter, GVSpace.xl, GVSpace.gutter, GVSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: t.titleMedium)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The palm-leaf manuscript surface for verses (plan §4.7): a long leaf with
/// two string holes and faint ruling, drawn in code (no images).
class PalmLeafCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PalmLeafCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(28, 22, 28, 18)});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return CustomPaint(
      painter: _LeafPainter(leaf: c.leaf, line: c.line, ink: c.inkMuted),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color leaf, line, ink;
  _LeafPainter({required this.leaf, required this.line, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(GVRadius.leaf));
    canvas.drawRRect(r, Paint()..color = leaf);
    canvas.drawRRect(
      r,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final rule = Paint()
      ..color = line.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    for (var y = 14.0; y < size.height - 8; y += 34) {
      canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), rule);
    }
    final hole = Paint()..color = ink.withValues(alpha: 0.35);
    for (final x in [size.width * 0.28, size.width * 0.72]) {
      canvas.drawCircle(Offset(x, 9), 2.6, hole);
    }
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.leaf != leaf || old.line != line;
}

/// Devanagari · ಕನ್ನಡ · IAST.
class ScriptSwitch extends StatelessWidget {
  final VerseFont value;
  final ValueChanged<VerseFont> onChanged;
  const ScriptSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ink = GVColors.of(context).ink;
    return SegmentedButton<VerseFont>(
      showSelectedIcon: false,
      // Each label in its own script's face: the UI fonts carry Latin and
      // Kannada only, so Devanagari would otherwise show as empty boxes.
      segments: [
        ButtonSegment(
          value: VerseFont.devanagari,
          label: Text('देवनागरी', style: verseStyle(VerseFont.devanagari, ink, size: 15).copyWith(height: 1.2)),
          tooltip: 'Devanagari',
        ),
        ButtonSegment(
          value: VerseFont.kannada,
          label: Text('ಕನ್ನಡ', style: verseStyle(VerseFont.kannada, ink, size: 15).copyWith(height: 1.2)),
          tooltip: 'Kannada script',
        ),
        const ButtonSegment(value: VerseFont.iast, label: Text('IAST'), tooltip: 'IAST'),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.single),
    );
  }
}

/// A lesson row: title, minutes, done or not.
class LessonTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String minutesLabel;
  final bool done;
  final double? progress;
  final VoidCallback onTap;
  final String doneLabel;
  const LessonTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.minutesLabel,
    required this.done,
    this.progress,
    required this.onTap,
    required this.doneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(GVRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GVSpace.l),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleSmall),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                    const SizedBox(height: GVSpace.xs),
                    Text(minutesLabel, style: t.labelSmall),
                    if (progress != null && !done) ...[
                      const SizedBox(height: GVSpace.s),
                      LinearProgressIndicator(value: progress, minHeight: 3),
                    ],
                  ],
                ),
              ),
              if (done)
                Semantics(
                  label: doneLabel,
                  child: Icon(Icons.check_circle_outline, color: c.neem),
                )
              else
                Icon(Icons.chevron_right, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One step of a classical method beside the modern working (plan §4.6 card 4).
class MethodStepTile extends StatelessWidget {
  final int index;
  final String text;
  final String? working;
  final bool active;
  const MethodStepTile({super.key, required this.index, required this.text, this.working, this.active = true});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: active ? 1 : 0.35,
      duration: GVMotion.of(context).answer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GVSpace.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.line),
              ),
              child: Text('$index', style: t.labelMedium),
            ),
            const SizedBox(width: GVSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: t.bodyLarge),
                  if (working != null)
                    Padding(
                      padding: const EdgeInsets.only(top: GVSpace.xs),
                      child: Text(
                        working!,
                        style: t.bodyMedium?.copyWith(
                          color: c.indigo,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number pad for integers, fractions and mixed numbers (plan §7.4).
/// Typing goes into [controller]; the system keyboard is never needed.
class NumberPad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String submitLabel;
  const NumberPad({super.key, required this.controller, required this.onSubmit, required this.submitLabel});

  void _type(String s) {
    HapticFeedback.selectionClick();
    final v = controller.text;
    if (s == '⌫') {
      if (v.isNotEmpty) controller.text = v.substring(0, v.length - 1);
    } else if (s == '␣') {
      if (v.isNotEmpty && !v.endsWith(' ') && !v.contains('/')) controller.text = '$v ';
    } else {
      controller.text = v + s;
    }
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['7', '8', '9', '⌫'],
      ['4', '5', '6', '/'],
      ['1', '2', '3', '␣'],
      ['−', '0', '.', '✓'],
    ];
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    String label(String k) => switch (k) {
      '␣' => 'a b/c',
      _ => k,
    };
    String semantics(String k) => switch (k) {
      '⌫' => 'Delete',
      '/' => 'Fraction bar',
      '␣' => 'Space for a mixed number',
      '−' => 'Minus',
      '.' => 'Decimal point',
      '✓' => submitLabel,
      _ => k,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in keys)
          Row(
            children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Semantics(
                      button: true,
                      label: semantics(k),
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 52,
                        child: k == '✓'
                            ? FilledButton(onPressed: onSubmit, child: const Icon(Icons.check))
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: c.surface,
                                  padding: EdgeInsets.zero,
                                  foregroundColor: c.ink,
                                ),
                                onPressed: () => _type(k == '−' ? '-' : k),
                                child: Text(label(k), style: k == '␣' ? t.labelSmall : t.titleMedium),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Hints from a nudge, to the classical step, to the full solution (plan §4.6).
class HintLadder extends StatelessWidget {
  final List<String> hints;
  final int shown;
  final VoidCallback? onMore;
  final String moreLabel;
  const HintLadder({super.key, required this.hints, required this.shown, this.onMore, required this.moreLabel});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown && i < hints.length; i++)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: GVSpace.s),
            padding: const EdgeInsets.all(GVSpace.m),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.turmeric, width: 3)),
              color: c.surface,
            ),
            child: Text(hints[i], style: t.bodyMedium),
          ),
        if (shown < hints.length && onMore != null)
          TextButton.icon(onPressed: onMore, icon: const Icon(Icons.lightbulb_outline), label: Text(moreLabel)),
      ],
    );
  }
}

enum FeedbackKind { correct, close, wrong }

/// Answer feedback: never colour alone — icon and words too (plan §7.7).
class AnswerFeedback extends StatelessWidget {
  final FeedbackKind kind;
  final String message;
  const AnswerFeedback({super.key, required this.kind, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    final (color, icon) = switch (kind) {
      FeedbackKind.correct => (c.neem, Icons.check_circle),
      FeedbackKind.close => (c.neem, Icons.check_circle_outline),
      FeedbackKind.wrong => (c.kumkum, Icons.refresh),
    };
    return _Shake(
      active: kind == FeedbackKind.wrong,
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: GVSpace.s),
            Expanded(
              child: Text(message, style: t.bodyLarge?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shake extends StatefulWidget {
  final bool active;
  final Widget child;
  const _Shake({required this.active, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void initState() {
    super.initState();
    _maybeShake();
  }

  @override
  void didUpdateWidget(_Shake old) {
    super.didUpdateWidget(old);
    _maybeShake();
  }

  void _maybeShake() {
    if (widget.active) {
      HapticFeedback.lightImpact();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GVMotion.of(context).reduce) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) =>
          Transform.translate(offset: Offset(math.sin(_c.value * math.pi * 4) * 6 * (1 - _c.value), 0), child: child),
      child: widget.child,
    );
  }
}

/// A video segment: title, speaker, source and length; opens outside the app.
class WatchTile extends StatelessWidget {
  final String title, speaker, source, length;
  final VoidCallback onOpen;
  const WatchTile({
    super.key,
    required this.title,
    required this.speaker,
    required this.source,
    required this.length,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: Icon(Icons.play_circle_outline, color: c.indigo, size: 32),
        title: Text(title),
        subtitle: Text('$speaker · $source · $length', style: t.bodySmall),
        trailing: const Icon(Icons.open_in_new),
      ),
    );
  }
}

/// A person shown as a seal: their name as a monogram, never an invented face (plan §7.6).
class PersonSeal extends StatelessWidget {
  final String monogram;
  final double size;
  final VerseFont script;
  const PersonSeal({super.key, required this.monogram, this.size = 56, this.script = VerseFont.devanagari});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.kumkum, width: 1.5),
          color: c.surface,
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.07),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.kumkum.withValues(alpha: 0.5)),
          ),
          child: Text(monogram, style: verseStyle(script, c.kumkum, size: size * 0.36).copyWith(height: 1.1)),
        ),
      ),
    );
  }
}

/// A row on the timeline: dates with their uncertainty, the event, its source.
class TimelineRow extends StatelessWidget {
  final String dates;
  final String label;
  final String? detail;
  final String source;
  final bool last;
  const TimelineRow({
    super.key,
    required this.dates,
    required this.label,
    this.detail,
    required this.source,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: GVSpace.l),
              child: Text(dates, style: t.labelMedium, textAlign: TextAlign.right),
            ),
          ),
          SizedBox(
            width: 28,
            child: CustomPaint(
              painter: _TimelineSpine(line: c.line, dot: c.turmeric, last: last),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GVSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.bodyLarge),
                  if (detail != null) Text(detail!, style: t.bodySmall),
                  Text(source, style: t.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSpine extends CustomPainter {
  final Color line, dot;
  final bool last;
  _TimelineSpine({required this.line, required this.dot, required this.last});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, last ? 26 : size.height),
      Paint()
        ..color = line
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(x, 26), 5, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_TimelineSpine old) => old.line != line || old.dot != dot || old.last != last;
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GVSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.inkMuted),
            const SizedBox(height: GVSpace.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.inkMuted),
            ),
            if (action != null) ...[const SizedBox(height: GVSpace.l), action!],
          ],
        ),
      ),
    );
  }
}

/// The kolam canvas (plan §4.5): one loop per finished lesson; the newest
/// draws itself (1.2 s, or a cross-fade with reduce motion).
class KolamCanvas extends StatefulWidget {
  final List<String> lessonIds;
  final bool animateLast;
  final String semanticsLabel;
  const KolamCanvas({super.key, required this.lessonIds, this.animateLast = false, required this.semanticsLabel});

  @override
  State<KolamCanvas> createState() => _KolamCanvasState();
}

class _KolamCanvasState extends State<KolamCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late List<KolamMotif> _motifs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, value: widget.animateLast ? 0 : 1);
    _motifs = _build(widget.lessonIds);
  }

  List<KolamMotif> _build(List<String> ids) => [for (final id in ids) KolamMotif.generate(seedFromId(id))];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = GVMotion.of(context).kolamLoop;
    if (widget.animateLast && _c.value == 0) _c.forward();
  }

  @override
  void didUpdateWidget(KolamCanvas old) {
    super.didUpdateWidget(old);
    if (old.lessonIds.length != widget.lessonIds.length) {
      _motifs = _build(widget.lessonIds);
      if (widget.animateLast) _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: KolamPainter(
            motifs: _motifs,
            lastProgress: _c.value,
            dot: c.inkMuted,
            line: c.ink,
            accent: c.turmeric,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
