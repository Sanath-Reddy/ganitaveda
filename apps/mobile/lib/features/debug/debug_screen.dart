import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';

/// Development builds only (plan §8.8): content inspector, card gallery,
/// generator playground with seed control, channel switch.
class DebugScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  String generator = generators.keys.first;
  int seed = 1;
  int difficulty = 1;

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final store = ref.watch(userStoreProvider);
    final settings = ref.watch(settingsProvider);
    final t = Theme.of(context).textTheme;
    final p = generators[generator]!.generate(seed, difficulty);
    final cardTypes = <String, (String, int)>{};
    for (final s in content.lessons()) {
      final doc = content.lesson(s.id)!;
      for (final (i, c) in doc.cards.indexed) {
        cardTypes.putIfAbsent(c.type, () => (s.id, i));
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.debugTools)),
      body: ListView(
        padding: const EdgeInsets.all(GVSpace.gutter),
        children: [
          Text('Content inspector', style: t.titleMedium),
          Text(
            'content ${content.contentVersion} · schema ${content.schemaVersion} · ${content.lessons().length} lessons · '
            '${content.concepts().length} concepts · ${content.people().length} people',
          ),
          Text(
            'user.db v${store.version} · ${store.attemptCount()} attempts · ${store.reviewItems().length} review items',
          ),
          for (final (v, status) in store.packHistory().take(5)) Text('pack $v: $status', style: t.bodySmall),
          const Divider(height: GVSpace.xl),
          Text('Channel', style: t.titleMedium),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'stable', label: Text('stable')),
              ButtonSegment(value: 'beta', label: Text('beta')),
            ],
            selected: {settings.channel},
            onSelectionChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(channel: v.single)),
          ),
          const Divider(height: GVSpace.xl),
          Text('Card gallery: first card of each type', style: t.titleMedium),
          Wrap(
            spacing: GVSpace.s,
            children: [
              for (final e in cardTypes.entries)
                ActionChip(
                  label: Text(e.key),
                  onPressed: () {
                    ref
                        .read(userStoreProvider)
                        .saveProgress(e.value.$1, content.lesson(e.value.$1)!.version, e.value.$2, const {});
                    unawaited(context.push('/lesson/${e.value.$1}'));
                  },
                ),
            ],
          ),
          const Divider(height: GVSpace.xl),
          Text('Generator playground', style: t.titleMedium),
          DropdownButton<String>(
            value: generator,
            isExpanded: true,
            items: [for (final id in generators.keys) DropdownMenuItem(value: id, child: Text(id))],
            onChanged: (v) => setState(() => generator = v!),
          ),
          Row(
            children: [
              Text('seed $seed'),
              IconButton(
                onPressed: () => setState(() => seed = (seed - 1).clamp(0, 1 << 30)),
                icon: const Icon(Icons.remove),
              ),
              IconButton(onPressed: () => setState(() => seed++), icon: const Icon(Icons.add)),
              const Spacer(),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {difficulty},
                onSelectionChanged: (v) => setState(() => difficulty = v.single),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(GVSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.prompt.en, style: t.bodyLarge),
                  Text(p.prompt.kn, style: t.bodyMedium),
                  const SizedBox(height: GVSpace.s),
                  Text('answer: ${p.answer.canonical}', style: t.titleSmall),
                  for (final h in p.hints) Text('• ${h.en}', style: t.bodySmall),
                ],
              ),
            ),
          ),
          Text(
            'Registered card types: ${LessonCard.fromJson({
              'id': 'x',
              'type': 'summary',
              'key_idea': {'en': ''},
            }).runtimeType}',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
