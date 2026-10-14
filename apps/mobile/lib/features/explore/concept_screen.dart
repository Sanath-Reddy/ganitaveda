import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/verse/verse_panel.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Concept page (plan §4.4): explanation, names, verses in date order,
/// lessons, related ideas, people and sources.
class ConceptScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final page = ref.watch(contentProvider).concept(id);
    if (page == null) return const NotFoundView();
    final settings = ref.watch(settingsProvider);
    final script = scriptOf(settings.script);
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    String role(String r) => switch (r) {
      'rule' => l.roleRule,
      'example' => l.roleExample,
      _ => l.roleMention,
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.lt(page.concept.name)), actions: [BookmarkButton(page.concept.id)]),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(GVSpace.gutter, 0, GVSpace.gutter, GVSpace.xxl),
          children: [
            Text(page.concept.classicalIast, style: verseStyle(VerseFont.iast, c.turmeric, size: 24)),
            const SizedBox(height: GVSpace.s),
            Text('${l.modernName}: ${context.lt(page.modernName)}', style: t.labelLarge),
            const SizedBox(height: GVSpace.m),
            Text(context.lt(page.concept.summary), style: t.titleMedium),
            const SizedBox(height: GVSpace.s),
            Text(context.lt(page.body), style: t.bodyLarge),
            if (page.lessons.isNotEmpty) ...[
              SectionHeader(l.lessons),
              for (final lesson in page.lessons) LessonRow(lesson),
            ],
            if (page.verses.isNotEmpty) SectionHeader(l.versesInOrder),
            for (final (v, r) in page.verses)
              Card(
                child: ListTile(
                  title: Text(
                    v.text(script),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: verseStyle(fontOf(script), c.ink, size: 17).copyWith(height: 1.5),
                  ),
                  subtitle: Text('${v.workIast} ${v.refLabel} · ${role(r)}'),
                  onTap: () => context.push('/verse/${v.id}'),
                ),
              ),
            if (page.related.isNotEmpty) ...[
              SectionHeader(l.relatedConcepts),
              Wrap(
                spacing: GVSpace.s,
                children: [
                  for (final (k, _) in page.related)
                    ActionChip(label: Text(context.lt(k.name)), onPressed: () => context.push('/concept/${k.id}')),
                ],
              ),
            ],
            if (page.people.isNotEmpty) ...[
              SectionHeader(l.people),
              Wrap(
                spacing: GVSpace.s,
                children: [
                  for (final p in page.people)
                    ActionChip(label: Text(context.lt(p.name)), onPressed: () => context.push('/person/${p.id}')),
                ],
              ),
            ],
            if (page.sources.isNotEmpty) ...[
              SectionHeader(l.sources),
              for (final s in page.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: GVSpace.s),
                  child: Text('${s.citation}${s.note == null ? '' : ' (${s.note})'}', style: t.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
