import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/verse/verse_panel.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';

/// A verse opened from anywhere (plan §4.1).
class VerseScreen extends ConsumerWidget {
  const new({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(contentProvider).verse(id);
    if (verse == null) return const NotFoundView();
    return Scaffold(
      appBar: AppBar(title: Text('${verse.workIast} ${verse.refLabel}'), actions: [BookmarkButton(verse.id)]),
      body: Readable(
        maxWidth: 1000,
        child: ListView(
          padding: const EdgeInsets.all(GVSpace.gutter),
          children: [
            VersePanel(verseId: verse.id),
            const SizedBox(height: GVSpace.l),
            Text(verse.sourceCitation, style: Theme.of(context).textTheme.bodySmall),
            if (context.isKannada)
              Padding(
                padding: const EdgeInsets.only(top: GVSpace.s),
                child: Text(context.l10n.kannadaTranslationsComing, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
