import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/app/router.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';

/// One box, any script (plan §6.9). Results grouped by type.
class SearchScreen extends ConsumerStatefulWidget {
  const new({super.key, this.initial = ''});
  final String initial;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = controller.text.trim();
    final hits = q.isEmpty ? const <SearchHit>[] : ref.watch(contentProvider).search(q, context.lang);
    final groups = <String, List<SearchHit>>{};
    for (final h in hits) {
      groups.putIfAbsent(h.type, () => []).add(h);
    }
    String groupName(String type) => switch (type) {
      'concept' => l.resultsConcepts,
      'lesson' => l.resultsLessons,
      'verse' => l.resultsVerses,
      'person' => l.resultsPeople,
      'term' => l.resultsTerms,
      _ => l.resultsOther,
    };
    const order = ['lesson', 'concept', 'term', 'verse', 'person', 'work', 'segment', 'glossary', 'media'];
    final types = groups.keys.toList()..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    final content = ref.read(contentProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: widget.initial.isEmpty,
          decoration: InputDecoration(hintText: l.searchHint, border: InputBorder.none, filled: false),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: Readable(
        child: q.isNotEmpty && hits.isEmpty
            ? EmptyState(icon: Icons.search_off, message: l.noResults)
            : ListView(
                children: [
                  for (final type in types) ...[
                    SectionHeader(groupName(type)),
                    for (final h in groups[type]!)
                      ListTile(
                        title: Text(h.title),
                        subtitle: Text(
                          h.snippet.replaceAll('[', '').replaceAll(']', ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          if (h.type == 'term') {
                            final term = content.termsFor([h.id]).firstOrNull;
                            if (term?.conceptId != null) openEntity(context, term!.conceptId!);
                          } else if (h.type == 'segment') {
                            final verse = content.verseOfSegment(h.id);
                            if (verse != null) openEntity(context, verse);
                          } else {
                            openEntity(context, h.id);
                          }
                        },
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
