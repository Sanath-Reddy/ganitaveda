import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/lesson/card_registry.dart';
import 'package:ganitaveda/features/lesson/scene_art.dart';
import 'package:ganitaveda/features/verse/verse_panel.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class _CardScroll extends StatelessWidget {
  const new({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(GVSpace.gutter, GVSpace.l, GVSpace.gutter, GVSpace.xxl),
    children: children,
  );
}

class SceneCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) {
    final card = c.card as SceneCard;
    return _CardScroll(
      children: [
        AspectRatio(aspectRatio: 16 / 10, child: SceneArt(card.art)),
        const SizedBox(height: GVSpace.l),
        Text(context.lt(card.text), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6)),
      ],
    );
  }
}

class ExploreCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) {
    final card = c.card as ExploreCard;
    final t = Theme.of(context).textTheme;
    final builder = exploreWidgets[card.widget];
    return _CardScroll(
      children: [
        Text(context.lt(card.prompt), style: t.titleMedium),
        if (card.goal != null)
          Padding(
            padding: const EdgeInsets.only(top: GVSpace.xs),
            child: Text(context.lt(card.goal), style: t.bodyMedium),
          ),
        const SizedBox(height: GVSpace.l),
        if (builder == null) Text(context.l10n.updateAppToSee) else builder(card.params, c.state, c.setState),
      ],
    );
  }
}

class VerseCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) {
    final card = c.card as VerseCard;
    return _CardScroll(
      children: [
        if (card.intro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: GVSpace.m),
            child: Text(context.lt(card.intro), style: Theme.of(context).textTheme.bodyLarge),
          ),
        VersePanel(verseId: card.verseId, highlight: card.highlight, showCompare: card.showCompare),
      ],
    );
  }
}

class WatchCardView extends ConsumerWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = c.card as WatchCard;
    final seg = ref.watch(contentProvider).mediaSegment(card.segmentId);
    final l = context.l10n;
    return _CardScroll(
      children: [
        if (card.optional) Text(l.watchOptional, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: GVSpace.m),
        if (seg == null)
          Text(l.videoUnavailable)
        else
          WatchTile(
            title: context.lt(seg.title),
            speaker: seg.speaker,
            source: seg.organisation,
            length: '${seg.length.inMinutes}:${(seg.length.inSeconds % 60).toString().padLeft(2, '0')}',
            onOpen: () => launchUrl(seg.uri, mode: LaunchMode.externalApplication),
          ),
      ],
    );
  }
}

class QuizCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) {
    final card = c.card as QuizCard;
    final picked = Map<String, Object?>.from(c.state);
    final t = Theme.of(context).textTheme;
    return _CardScroll(
      children: [
        for (final (qi, q) in card.questions.indexed) ...[
          Text(context.lt(q.prompt), style: t.titleMedium),
          const SizedBox(height: GVSpace.s),
          RadioGroup<int>(
            groupValue: picked['$qi'] as int?,
            onChanged: (v) {
              if (picked['$qi'] != null) return;
              c.setState({...picked, '$qi': v});
            },
            child: Column(
              children: [
                for (final (ci, choice) in q.choices.indexed)
                  RadioListTile<int>(value: ci, title: Text(context.lt(choice))),
              ],
            ),
          ),
          if (picked['$qi'] != null)
            AnswerFeedback(
              kind: picked['$qi'] == q.answer ? FeedbackKind.correct : FeedbackKind.wrong,
              message: [
                if (picked['$qi'] == q.answer) context.l10n.correct else context.lt(q.choices[q.answer]),
                if (q.why != null) context.lt(q.why),
              ].join(' '),
            ),
          const SizedBox(height: GVSpace.l),
        ],
      ],
    );
  }
}

/// Wrap-up: the key idea, where it is in the textbook, and when it comes back (plan §4.6 card 7).
class SummaryCardView extends ConsumerWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = c.card as SummaryCard;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final store = ref.watch(userStoreProvider);
    final done = ref.watch(progressProvider).byLesson[c.lesson.id]?.done ?? false;
    final templates = [for (final p in c.lesson.cards.whereType<PracticeCard>()) p.templateId];
    final due = [for (final id in templates) store.reviewState(id)?.due].whereType<DateTime>().toList()..sort();
    final next = card.next == null ? null : ref.read(contentProvider).lessonSummary(card.next!);

    return _CardScroll(
      children: [
        Text(l.keyIdea, style: t.labelLarge?.copyWith(color: GVColors.of(context).indigo)),
        const SizedBox(height: GVSpace.s),
        Text(context.lt(card.keyIdea), style: t.titleMedium?.copyWith(height: 1.5)),
        if (card.textbook != null) ...[
          const SizedBox(height: GVSpace.l),
          Text(l.inYourTextbook, style: t.labelLarge),
          Text(context.lt(card.textbook), style: t.bodyLarge),
        ],
        if (due.isNotEmpty) ...[
          const SizedBox(height: GVSpace.l),
          Text(l.comesBackOn(context.formatDate(due.first)), style: t.bodyMedium),
        ],
        const SizedBox(height: GVSpace.xl),
        if (!done)
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l.finishLesson),
            onPressed: () => _finish(context, ref, templates),
          )
        else
          Row(
            children: [
              Icon(Icons.check_circle, color: GVColors.of(context).neem),
              const SizedBox(width: GVSpace.s),
              Text(l.done, style: t.titleSmall),
            ],
          ),
        if (next != null) ...[
          const SizedBox(height: GVSpace.m),
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: Text('${l.nextLesson}: ${context.lt(next.title)}'),
            onPressed: () => context.pushReplacement('/lesson/${next.id}'),
          ),
        ],
      ],
    );
  }

  void _finish(BuildContext context, WidgetRef ref, List<String> templates) {
    final store = ref.read(userStoreProvider);
    final lesson = c.lesson;
    store.completeLesson(lesson.id, lesson.version);
    // Every practice template enters the review queue; it comes back as a fresh problem.
    for (final card in lesson.cards.whereType<PracticeCard>()) {
      if (store.reviewState(card.templateId) == null) {
        store.scheduleReview(
          templateId: card.templateId,
          generatorId: card.generatorId,
          lessonId: lesson.id,
          correct: true,
        );
      }
    }
    ref.read(progressProvider.notifier).refresh();
    final ids = store.completedLessons();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(GVSpace.xl, 0, GVSpace.xl, GVSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.kolamTitle, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(
                  height: 220,
                  child: KolamCanvas(
                    lessonIds: ids,
                    animateLast: true,
                    semanticsLabel: context.l10n.kolamCaption(ids.length),
                  ),
                ),
                Text(context.l10n.kolamCaption(ids.length)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnsupportedCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) => EmptyState(icon: Icons.system_update_alt, message: context.l10n.updateAppToSee);
}
