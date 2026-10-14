import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/lesson/card_registry.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Full-screen lesson (plan §4.6, §6.6). Swipe or tap Next; leave at any point.
/// The current card and every card's state are saved on each change.
class LessonPlayer extends ConsumerStatefulWidget {
  const new({required this.lessonId, super.key});
  final String lessonId;

  @override
  ConsumerState<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<LessonPlayer> {
  LessonDoc? doc;
  late PageController controller;
  late FlagNotifier _lessonOpen;
  int index = 0;
  final Map<String, Map<String, Object?>> cardState = {};

  @override
  void initState() {
    super.initState();
    doc = ref.read(contentProvider).lesson(widget.lessonId);
    final saved = ref.read(userStoreProvider).progress(doc?.id ?? widget.lessonId);
    if (doc != null && saved != null && !saved.done) {
      index = saved.cardIndex.clamp(0, doc!.cards.length - 1);
      // State from an older version of the lesson is dropped; the position is kept.
      if (saved.lessonVersion == doc!.version) {
        for (final e in saved.state.entries) {
          cardState[e.key] = Map<String, Object?>.from(e.value! as Map);
        }
      }
    }
    controller = PageController(initialPage: index);
    _lessonOpen = ref.read(lessonOpenProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lessonOpen.set(value: true));
  }

  @override
  void dispose() {
    controller.dispose();
    // Never write a provider while the tree is being torn down; every way out of
    // a lesson (close button, back, go(), next lesson) passes through here.
    unawaited(
      Future.microtask(() {
        // The whole app may be gone too (tests, hot restart): then there is nothing to reset.
        if (_lessonOpen.mounted) _lessonOpen.set(value: false);
      }),
    );
    super.dispose();
  }

  void _save() {
    final d = doc;
    if (d == null) return;
    final store = ref.read(userStoreProvider);
    if (store.progress(d.id)?.done ?? false) return;
    store.saveProgress(d.id, d.version, index, cardState);
    ref.read(progressProvider.notifier).refresh();
  }

  void _goTo(int i) {
    final reduce = GVMotion.of(context).reduce;
    if (reduce) {
      controller.jumpToPage(i);
    } else {
      controller.animateToPage(i, duration: GVMotion.of(context).cardSlide, curve: Curves.easeOutCubic);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/school');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = doc;
    if (d == null) return const NotFoundView();
    final l = context.l10n;
    final n = d.cards.length;
    final compact = MediaQuery.textScalerOf(context).scale(16) > 24 || MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: l.closeLesson, icon: const Icon(Icons.close), onPressed: _close),
        title: Text(context.lt(d.title)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Semantics(
            label: l.cardOf(index + 1, n),
            child: LinearProgressIndicator(value: (index + 1) / n, minHeight: 3),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: n,
                onPageChanged: (i) {
                  setState(() => index = i);
                  _save();
                },
                itemBuilder: (context, i) {
                  final card = d.cards[i];
                  return Readable(
                    maxWidth: card is VerseCard || card is MethodCard ? 1000 : GVSpace.lessonMaxWidth,
                    child: buildCard(
                      context,
                      CardContext(
                        lesson: d,
                        card: card,
                        state: cardState[card.id] ?? const {},
                        setState: (s) {
                          setState(() => cardState[card.id] = s);
                          _save();
                        },
                        next: i < n - 1 ? () => _goTo(i + 1) : null,
                        close: _close,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GVSpace.gutter, GVSpace.s, GVSpace.gutter, GVSpace.m),
              child: Row(
                children: [
                  // Large text sizes and Kannada labels: buttons drop their words
                  // (tooltips keep them for TalkBack) and the counter shrinks.
                  if (compact)
                    IconButton.outlined(
                      tooltip: l.back,
                      onPressed: index > 0 ? () => _goTo(index - 1) : null,
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    TextButton.icon(
                      onPressed: index > 0 ? () => _goTo(index - 1) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l.back),
                    ),
                  Expanded(
                    child: Text(
                      l.cardOf(index + 1, n),
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (compact)
                    IconButton.filled(
                      tooltip: l.next,
                      onPressed: index < n - 1 ? () => _goTo(index + 1) : null,
                      icon: const Icon(Icons.arrow_forward),
                    )
                  else
                    FilledButton.icon(
                      onPressed: index < n - 1 ? () => _goTo(index + 1) : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(l.next),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
