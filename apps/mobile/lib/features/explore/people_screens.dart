import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Monogram for the seal: the first akṣara of the name in the reader's script.
String monogram(PersonSummary p, {required bool kannada}) {
  final name = kannada ? p.name.kn : p.name.en;
  final runes = name.runes.toList();
  final out = StringBuffer()..writeCharCode(runes.first);
  // Keep combining marks (vowel signs, virama + next consonant) with the first letter.
  for (var i = 1; i < runes.length; i++) {
    final c = runes[i];
    final mark = (c >= 0x0C81 && c <= 0x0C83) || (c >= 0x0CBC && c <= 0x0CD6) || (c >= 0x0300 && c <= 0x036F);
    if (!mark) break;
    out.writeCharCode(c);
  }
  return out.toString();
}

class PeopleScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(contentProvider).people();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.mathematicians)),
      body: Readable(
        child: ListView(
          children: [
            for (final p in people)
              ListTile(
                leading: PersonSeal(
                  monogram: monogram(p, kannada: context.isKannada),
                  size: 44,
                  script: context.isKannada ? VerseFont.kannada : VerseFont.iast,
                ),
                title: Text(context.lt(p.name)),
                subtitle: Text(context.lt(p.datesLabel)),
                onTap: () => context.push('/person/${p.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

class PersonScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final page = ref.watch(contentProvider).person(id);
    if (page == null) return const NotFoundView();
    final t = Theme.of(context).textTheme;
    final p = page.person;
    Widget people(String title, List<PersonSummary> list) => list.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title),
              Wrap(
                spacing: GVSpace.s,
                children: [
                  for (final x in list)
                    ActionChip(label: Text(context.lt(x.name)), onPressed: () => context.push('/person/${x.id}')),
                ],
              ),
            ],
          );
    return Scaffold(
      appBar: AppBar(title: Text(context.lt(p.name)), actions: [BookmarkButton(p.id)]),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(GVSpace.gutter, 0, GVSpace.gutter, GVSpace.xxl),
          children: [
            Row(
              children: [
                PersonSeal(
                  monogram: monogram(p, kannada: context.isKannada),
                  size: 72,
                  script: context.isKannada ? VerseFont.kannada : VerseFont.iast,
                ),
                const SizedBox(width: GVSpace.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nameIast, style: verseStyle(VerseFont.iast, GVColors.of(context).ink, size: 22)),
                      Text(context.lt(p.datesLabel), style: t.labelLarge),
                      if (page.place != null) Text('${l.place}: ${context.lt(page.place)}', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GVSpace.l),
            Text(context.lt(page.summary), style: t.bodyLarge),
            const SizedBox(height: GVSpace.s),
            Text(l.noPortraitNote, style: t.bodySmall),
            if (page.works.isNotEmpty) ...[
              SectionHeader(l.works),
              for (final (wid, title) in page.works)
                ListTile(
                  title: Text(context.lt(title)),
                  onTap: () => context.push('/text/$wid'),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
            people(l.teachers, page.teachers),
            people(l.students, page.students),
            if (page.concepts.isNotEmpty) ...[
              SectionHeader(l.relatedConcepts),
              Wrap(
                spacing: GVSpace.s,
                children: [
                  for (final k in page.concepts)
                    ActionChip(label: Text(context.lt(k.name)), onPressed: () => context.push('/concept/${k.id}')),
                ],
              ),
            ],
            SectionHeader(l.sources),
            for (final s in page.sources)
              Text('${s.citation}${s.note == null ? '' : ' (${s.note})'}', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Teacher–student lineage (plan §4.4): every person with a known teacher,
/// grouped into chains from the root teacher down.
class LineageScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final pages = {for (final p in content.people()) p.id: content.person(p.id)!};
    final roots = pages.values.where((p) => p.teachers.isEmpty && p.students.isNotEmpty).toList();
    final t = Theme.of(context).textTheme;
    final c = GVColors.of(context);
    List<Widget> branch(PersonPage p, int depth) => [
      Padding(
        padding: EdgeInsets.only(left: depth * 28.0, top: GVSpace.s),
        child: InkWell(
          onTap: () => context.push('/person/${p.person.id}'),
          child: Row(
            children: [
              if (depth > 0) Icon(Icons.subdirectory_arrow_right, color: c.inkMuted),
              PersonSeal(
                monogram: monogram(p.person, kannada: context.isKannada),
                size: 40,
                script: context.isKannada ? VerseFont.kannada : VerseFont.iast,
              ),
              const SizedBox(width: GVSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.lt(p.person.name), style: t.titleSmall),
                    Text(context.lt(p.person.datesLabel), style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      for (final s in p.students) ...branch(pages[s.id]!, depth + 1),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.lineage)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.all(GVSpace.gutter),
          children: [for (final r in roots) ...branch(r, 0)],
        ),
      ),
    );
  }
}
