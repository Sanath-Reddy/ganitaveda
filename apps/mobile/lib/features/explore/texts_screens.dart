import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/verse/verse_panel.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

class TextsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.texts)),
    body: ListView(
      children: [
        for (final w in ref.watch(contentProvider).works())
          ListTile(
            title: Text(w.titleIast),
            subtitle: Text(context.lt(w.title)),
            onTap: () => context.push('/text/${w.id}'),
          ),
      ],
    ),
  );
}

/// A text: what it is, its sections, and its source and licence.
class WorkScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final w = ref.watch(contentProvider).works().where((w) => w.id == id).firstOrNull;
    if (w == null) return const NotFoundView();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(w.titleIast)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.lt(w.title)} · ${yearRange(w.yearFrom, w.yearTo, kannada: context.isKannada)}',
                    style: t.labelLarge,
                  ),
                  const SizedBox(height: GVSpace.s),
                  Text(context.lt(w.about), style: t.bodyLarge),
                  const SizedBox(height: GVSpace.s),
                  Text(w.source.citation, style: t.bodySmall),
                  if (w.source.attribution != null) Text(w.source.attribution!, style: t.bodySmall),
                  TextButton(onPressed: () => context.push('/person/${w.authorId}'), child: Text(l.mathematicians)),
                ],
              ),
            ),
            SectionHeader(l.readingRoom),
            for (final (sid, label, count) in w.sections)
              ListTile(
                title: Text(context.lt(label)),
                subtitle: Text(l.versesCount(count)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/section/$sid'),
              ),
          ],
        ),
      ),
    );
  }
}

/// The reading room: verse by verse in the reader's script, with translation (plan §4.4).
class ReadingRoomScreen extends ConsumerWidget {
  const new({required this.sectionId, super.key});
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verses = ref.watch(contentProvider).versesOfSection(sectionId);
    if (verses.isEmpty) return const NotFoundView();
    return Scaffold(
      appBar: AppBar(title: Text(verses.first.workIast)),
      body: Readable(
        maxWidth: 1000,
        child: ListView.separated(
          padding: const EdgeInsets.all(GVSpace.gutter),
          itemCount: verses.length,
          separatorBuilder: (_, _) => const Divider(height: GVSpace.xxl),
          itemBuilder: (context, i) => VersePanel(verseId: verses[i].id),
        ),
      ),
    );
  }
}
