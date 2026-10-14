import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';

/// Centres content at a readable width on tablets and landscape (plan §7.8).
class Readable extends StatelessWidget {
  const new({required this.child, super.key, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class NotFoundView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: EmptyState(icon: Icons.search_off, message: context.l10n.notFound),
  );
}

/// A lesson row wired to progress.
class LessonRow extends ConsumerWidget {
  const new(this.lesson, {super.key});
  final LessonSummary lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).byLesson[lesson.id];
    final doc = progress == null ? null : ref.read(contentProvider).lesson(lesson.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter, vertical: GVSpace.xs),
      child: LessonTile(
        title: context.lt(lesson.title),
        subtitle: context.lt(lesson.subtitle),
        minutesLabel: context.l10n.minutes(lesson.minutes),
        done: progress?.done ?? false,
        progress: (progress != null && doc != null && !progress.done)
            ? (progress.cardIndex + 1) / doc.cards.length
            : null,
        doneLabel: context.l10n.done,
        onTap: () => context.push('/lesson/${lesson.id}'),
      ),
    );
  }
}

class BookmarkButton extends ConsumerWidget {
  const new(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(progressProvider).bookmarks.contains(id);
    return IconButton(
      tooltip: on ? context.l10n.removeBookmark : context.l10n.bookmark,
      icon: Icon(on ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () {
        ref.read(userStoreProvider).setBookmark(id, on: !on);
        ref.read(progressProvider.notifier).refresh();
      },
    );
  }
}

String classLabel(BuildContext context, int classNo) =>
    classNo == 0 ? context.l10n.notInSchool : context.l10n.classN(classNo);
