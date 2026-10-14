import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Explore (plan §4.4): search, areas, texts, mathematicians, timeline.
class ExploreScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final content = ref.watch(contentProvider);
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabExplore)),
      body: Readable(
        maxWidth: 1000,
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: TextField(
                readOnly: true,
                onTap: () => context.push('/explore/search'),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchHint),
              ),
            ),
            SectionHeader(l.areas),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: GridView.count(
                crossAxisCount: width >= 900 ? 4 : (width >= GVSpace.twoPaneBreakpoint ? 3 : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: GVSpace.s,
                crossAxisSpacing: GVSpace.s,
                childAspectRatio: 1.25,
                children: [
                  for (final a in content.areas())
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(GVRadius.card),
                        onTap: () => context.push('/explore/area/${a.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(GVSpace.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.lt(a.name), style: t.titleSmall),
                              Text(a.sanskritIast, style: verseStyle(VerseFont.iast, c.turmeric, size: 17)),
                              const Spacer(),
                              Text(
                                context.lt(a.blurb),
                                style: t.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SectionHeader(l.texts),
            for (final w in content.works())
              _NavRow(
                title: w.titleIast,
                subtitle: '${context.lt(w.title)} · ${yearRange(w.yearFrom, w.yearTo, kannada: context.isKannada)}',
                onTap: () => context.push('/text/${w.id}'),
              ),
            SectionHeader(l.mathematicians),
            _NavRow(
              title: l.mathematicians,
              subtitle: '${content.people().length}',
              onTap: () => context.push('/explore/people'),
            ),
            _NavRow(title: l.lineage, onTap: () => context.push('/explore/lineage')),
            _NavRow(title: l.timeline, onTap: () => context.push('/explore/timeline')),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const new({required this.title, required this.onTap, this.subtitle});
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter, vertical: GVSpace.xs),
    child: Card(
      child: ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}

class AreaScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final area = content.areas().where((a) => a.id == id).firstOrNull;
    if (area == null) return const NotFoundView();
    final lessons = content.lessons().where((lesson) => lesson.areaId == id);
    return Scaffold(
      appBar: AppBar(title: Text(context.lt(area.name))),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
              child: Text('${area.sanskritIast} · ${context.lt(area.blurb)}'),
            ),
            for (final k in content.concepts(areaId: id))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter, vertical: GVSpace.xs),
                child: Card(
                  child: ListTile(
                    title: Text(context.lt(k.name)),
                    subtitle: Text('${k.classicalIast} · ${context.lt(k.summary)}'),
                    onTap: () => context.push('/concept/${k.id}'),
                  ),
                ),
              ),
            if (lessons.isNotEmpty) SectionHeader(context.l10n.lessons),
            for (final lesson in lessons) LessonRow(lesson),
          ],
        ),
      ),
    );
  }
}
