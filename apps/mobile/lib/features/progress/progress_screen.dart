import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/app/router.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Progress (plan §4.5): the kolam, the review queue and bookmarks.
class ProgressScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(progressProvider);
    final content = ref.watch(contentProvider);
    final now = ref.watch(clockProvider)();
    String titleOf(String id) {
      final kind = id.split('.').first;
      return switch (kind) {
        'lesson' => context.lt(content.lessonSummary(id)?.title),
        'concept' => context.lt(content.concept(id)?.concept.name),
        'person' => context.lt(content.person(id)?.person.name),
        'verse' => () {
          final v = content.verse(id);
          return v == null ? id : '${v.workIast} ${v.refLabel}';
        }(),
        _ => id,
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabProgress),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/progress/settings'),
          ),
        ],
      ),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            SectionHeader(l.kolamTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(GVSpace.l),
                  child: Column(
                    children: [
                      if (p.completed.isNotEmpty)
                        SizedBox(
                          height: 120.0 * ((p.completed.length + 2) ~/ 3),
                          child: KolamCanvas(
                            lessonIds: p.completed,
                            semanticsLabel: l.kolamCaption(p.completed.length),
                          ),
                        ),
                      Text(l.kolamCaption(p.completed.length), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            SectionHeader(
              l.reviewQueue,
              trailing: p.due.isEmpty
                  ? null
                  : FilledButton(onPressed: () => context.push('/review'), child: Text(l.startReview)),
            ),
            if (p.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
                child: Text(l.nothingToRevise),
              ),
            for (final r in p.reviews)
              ListTile(
                leading: Text('${r.box}', style: Theme.of(context).textTheme.titleMedium),
                title: Text(r.lessonId == null ? r.generatorId : titleOf(r.lessonId!)),
                subtitle: Text(
                  r.due.isBefore(DateTime(now.year, now.month, now.day + 1))
                      ? l.dueToday
                      : l.dueOn(context.formatDate(r.due)),
                ),
              ),
            SectionHeader(l.bookmarks),
            if (p.bookmarks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
                child: Text(l.noBookmarks),
              ),
            for (final id in p.bookmarks)
              ListTile(
                title: Text(titleOf(id)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openEntity(context, id),
              ),
          ],
        ),
      ),
    );
  }
}
