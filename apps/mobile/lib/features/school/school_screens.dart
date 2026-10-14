import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// School (plan §4.3): class switcher, continue, revise today, chapters.
class SchoolScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final content = ref.watch(contentProvider);
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final classNo = settings.classNo ?? 0;
    final chapters = classNo == 0 ? <ChapterEntry>[] : content.chapters(classNo).where((c) => !c.isEmpty).toList();
    final inProgress = progress.inProgress();
    final continuing = inProgress == null ? null : content.lessonSummary(inProgress.lessonId);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSchool)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
                children: [
                  for (final c in [6, 7, 8, 9, 10, 11, 12, 0])
                    Padding(
                      padding: const EdgeInsets.only(right: GVSpace.s),
                      child: ChoiceChip(
                        label: Text(classLabel(context, c)),
                        selected: classNo == c,
                        onSelected: (_) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(classNo: c)),
                      ),
                    ),
                ],
              ),
            ),
            if (continuing != null) ...[SectionHeader(l.continueLesson), LessonRow(continuing)],
            SectionHeader(l.reviseToday),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.replay, color: GVColors.of(context).turmeric),
                  title: Text(progress.due.isEmpty ? l.nothingToRevise : l.reviseCount(progress.due.length)),
                  trailing: progress.due.isEmpty ? null : const Icon(Icons.chevron_right),
                  onTap: progress.due.isEmpty ? null : () => context.push('/review'),
                ),
              ),
            ),
            if (classNo == 0) ...[
              SectionHeader(l.allLessons),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
                child: Text(l.notInSchoolNote, style: t.bodyMedium),
              ),
              for (final lesson in content.lessons()) LessonRow(lesson),
            ] else ...[
              SectionHeader(l.chaptersForClass),
              if (chapters.isEmpty) EmptyState(icon: Icons.menu_book_outlined, message: l.noChapters),
              for (final c in chapters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter, vertical: GVSpace.xs),
                  child: Card(
                    child: ListTile(
                      title: Text(context.lt(c.title)),
                      subtitle: Text(
                        [
                          if (c.number > 0) l.chapterN(c.number) else context.lt(c.bookTitle),
                          l.lessonCount(c.lessons.length),
                          if (c.watch.isNotEmpty) '${c.watch.length} · ${l.watchShelf}',
                        ].join('  ·  '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/school/chapter/${c.id}'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChapterScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final classNo = int.tryParse(id.split('.').elementAtOrNull(1) ?? '') ?? 0;
    final chapter = ref.watch(contentProvider).chapters(classNo).where((c) => c.id == id).firstOrNull;
    if (chapter == null) return const NotFoundView();
    return Scaffold(
      appBar: AppBar(title: Text(context.lt(chapter.title))),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: Text(
                '${classLabel(context, classNo)} · ${context.lt(chapter.bookTitle)}'
                '${chapter.number > 0 ? ' · ${l.chapterN(chapter.number)}' : ''}',
              ),
            ),
            if (chapter.lessons.isNotEmpty) SectionHeader(chapter.recommended ? l.recommendedFromExplore : l.lessons),
            for (final lesson in chapter.lessons) LessonRow(lesson),
            if (chapter.watch.isNotEmpty) SectionHeader(l.watchShelf),
            for (final seg in chapter.watch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter, vertical: GVSpace.xs),
                child: WatchTile(
                  title: context.lt(seg.title),
                  speaker: seg.speaker,
                  source: seg.organisation,
                  length: '${seg.length.inMinutes} min',
                  onOpen: () => launchUrl(seg.uri, mode: LaunchMode.externalApplication),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
