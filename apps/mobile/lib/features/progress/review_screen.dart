import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/data/user_store.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';

/// "Revise today": one fresh problem from each due template (plan §6.8).
class ReviewScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final List<ReviewItem> items = ref.read(progressProvider).due;
  late final int seed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  int index = 0;
  int hints = 0;
  bool answered = false;
  bool wrongOnce = false;
  CheckResult? result;
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Problem _problem() {
    final item = items[index];
    return generators[item.generatorId]!.generate(mixSeed(seed, index), (item.box + 1).clamp(1, 3));
  }

  void _check(Problem p) {
    final r = const AnswerChecker().check(input.text, p.answer);
    setState(() => result = r);
    if (r.verdict == Verdict.unreadable || answered) return;
    final store = ref.read(userStoreProvider);
    final item = items[index];
    store.logAttempt(
      templateId: item.templateId,
      lessonId: item.lessonId,
      seed: p.seed,
      answer: input.text,
      correct: r.isCorrect,
      hintsUsed: hints,
      ms: 0,
      firstTry: !wrongOnce,
    );
    if (r.isCorrect) {
      store.scheduleReview(
        templateId: item.templateId,
        generatorId: item.generatorId,
        lessonId: item.lessonId,
        correct: !wrongOnce && hints == 0,
      );
      setState(() => answered = true);
      ref.read(progressProvider.notifier).refresh();
    } else {
      setState(() => wrongOnce = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    if (items.isEmpty || index >= items.length) {
      return Scaffold(
        appBar: AppBar(title: Text(l.reviseToday)),
        body: EmptyState(icon: Icons.check_circle_outline, message: items.isEmpty ? l.nothingToRevise : l.reviewDone),
      );
    }
    final p = _problem();
    return Scaffold(
      appBar: AppBar(title: Text(l.reviseToday)),
      body: Readable(
        maxWidth: GVSpace.lessonMaxWidth,
        child: ListView(
          padding: const EdgeInsets.all(GVSpace.gutter),
          children: [
            Text(l.problemN(index + 1, items.length), style: t.labelMedium),
            const SizedBox(height: GVSpace.s),
            Text(context.lt(p.prompt), style: t.titleMedium),
            const SizedBox(height: GVSpace.l),
            TextField(
              controller: input,
              style: t.headlineSmall,
              decoration: InputDecoration(labelText: l.yourAnswer),
              onSubmitted: (_) => _check(p),
            ),
            if (result != null)
              AnswerFeedback(
                kind: result!.isCorrect ? FeedbackKind.correct : FeedbackKind.wrong,
                message: switch (result!.verdict) {
                  Verdict.correct => l.correct,
                  Verdict.correctApprox => l.correctApprox(p.answer.canonical),
                  Verdict.wrong => l.notQuite,
                  Verdict.unreadable => l.unreadable,
                },
              ),
            HintLadder(
              hints: [for (final h in p.hints) context.lt(h)],
              shown: hints,
              moreLabel: l.hint,
              onMore: answered ? null : () => setState(() => hints++),
            ),
            const SizedBox(height: GVSpace.m),
            if (answered)
              FilledButton(
                onPressed: () => setState(() {
                  index++;
                  hints = 0;
                  answered = false;
                  wrongOnce = false;
                  result = null;
                  input.clear();
                }),
                child: Text(l.nextProblem),
              )
            else
              NumberPad(controller: input, onSubmit: () => _check(p), submitLabel: l.check),
          ],
        ),
      ),
    );
  }
}
