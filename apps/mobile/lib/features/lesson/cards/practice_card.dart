import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/lesson/card_registry.dart';
import 'package:ganitaveda/shared/l10n.dart';

/// 3–5 problems with fresh numbers each time; hints go from a nudge, to the
/// classical step, to the full solution (plan §4.6 card 6). Every answer is
/// logged; the session is saved, so leaving and coming back resumes it.
class PracticeCardView extends ConsumerStatefulWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  ConsumerState<PracticeCardView> createState() => _PracticeCardViewState();
}

class _PracticeCardViewState extends ConsumerState<PracticeCardView> {
  final input = TextEditingController();
  late int sessionSeed;
  late List<Problem> problems;
  int current = 0;
  int hints = 0;
  bool solved = false;
  bool triedWrong = false;
  int firstTryRight = 0;
  CheckResult? result;
  final watch = Stopwatch()..start();

  PracticeCard get card => widget.c.card as PracticeCard;

  @override
  void initState() {
    super.initState();
    final s = widget.c.state;
    sessionSeed = (s['seed'] as int?) ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    current = (s['current'] as int?) ?? 0;
    firstTryRight = (s['right'] as int?) ?? 0;
    problems = generateSession(card.generatorId, sessionSeed, card.count, difficulties: card.difficulty);
    // Saving writes to providers, so it waits until after this build.
    if (s['seed'] == null) WidgetsBinding.instance.addPostFrameCallback((_) => _persist());
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _persist() => widget.c.setState({'seed': sessionSeed, 'current': current, 'right': firstTryRight});

  void _check() {
    if (solved || current >= problems.length) return;
    final p = problems[current];
    final r = const AnswerChecker().check(input.text, p.answer);
    setState(() => result = r);
    if (r.verdict == Verdict.unreadable) return;
    final firstTry = !triedWrong;
    ref
        .read(userStoreProvider)
        .logAttempt(
          templateId: card.templateId,
          lessonId: widget.c.lesson.id,
          seed: p.seed,
          answer: input.text,
          correct: r.isCorrect,
          hintsUsed: hints,
          ms: watch.elapsedMilliseconds,
          firstTry: firstTry,
        );
    if (r.isCorrect) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        solved = true;
        if (firstTry && hints == 0) firstTryRight++;
      });
      _persist();
    } else {
      setState(() => triedWrong = true);
    }
  }

  void _next() {
    setState(() {
      current++;
      hints = 0;
      solved = false;
      triedWrong = false;
      result = null;
      input.clear();
      watch.reset();
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    if (current >= problems.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GVSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: GVColors.of(context).neem),
              const SizedBox(height: GVSpace.m),
              Text(l.practiceDone(firstTryRight, problems.length), style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: GVSpace.l),
              if (widget.c.next != null) FilledButton(onPressed: widget.c.next, child: Text(l.next)),
            ],
          ),
        ),
      );
    }
    final p = problems[current];
    final feedback = switch (result?.verdict) {
      Verdict.correct => AnswerFeedback(kind: FeedbackKind.correct, message: l.correct),
      Verdict.correctApprox => AnswerFeedback(kind: FeedbackKind.close, message: l.correctApprox(p.answer.canonical)),
      Verdict.wrong => AnswerFeedback(kind: FeedbackKind.wrong, message: l.notQuite),
      Verdict.unreadable => AnswerFeedback(kind: FeedbackKind.wrong, message: l.unreadable),
      null => null,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(GVSpace.gutter, GVSpace.l, GVSpace.gutter, GVSpace.xxl),
      children: [
        Text(l.problemN(current + 1, problems.length), style: t.labelMedium),
        const SizedBox(height: GVSpace.s),
        Text(context.lt(p.prompt), style: t.titleMedium?.copyWith(height: 1.5)),
        const SizedBox(height: GVSpace.l),
        TextField(
          controller: input,
          readOnly: solved,
          // The number pad below types fractions and mixed numbers; the system
          // keyboard stays available for TalkBack and hardware keyboards.
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          style: t.headlineSmall,
          decoration: InputDecoration(labelText: l.yourAnswer),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: GVSpace.s),
        ?feedback,
        HintLadder(
          hints: [for (final h in p.hints) context.lt(h)],
          shown: hints,
          moreLabel: hints == 0 ? l.hint : l.anotherHint,
          onMore: solved ? null : () => setState(() => hints++),
        ),
        const SizedBox(height: GVSpace.m),
        if (solved)
          FilledButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward), label: Text(l.nextProblem))
        else
          NumberPad(controller: input, onSubmit: _check, submitLabel: l.check),
      ],
    );
  }
}
