import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/app/router.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';

/// When ideas were written down, each with its source; dates carry their uncertainty.
class TimelineScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(contentProvider).timeline();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.timeline)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: GVSpace.l),
          children: [
            for (final (i, e) in events.indexed)
              InkWell(
                onTap: e.links.isEmpty ? null : () => openEntity(context, e.links.first),
                child: TimelineRow(
                  dates: yearRange(e.yearFrom, e.yearTo, kannada: context.isKannada),
                  label: context.lt(e.label),
                  detail: e.detail == null ? e.region : '${e.region} · ${context.lt(e.detail)}',
                  source: e.source.citation.split('(').first.trim(),
                  last: i == events.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
