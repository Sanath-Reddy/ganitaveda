import 'dart:async';

import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/onboarding/onboarding_screen.dart';
import 'package:ganitaveda/shared/data/settings.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

VerseScript scriptOf(String s) =>
    VerseScript.values.firstWhere((v) => v.name == s, orElse: () => VerseScript.devanagari);

VerseFont fontOf(VerseScript s) => switch (s) {
  VerseScript.devanagari => VerseFont.devanagari,
  VerseScript.kannada => VerseFont.kannada,
  VerseScript.iast => VerseFont.iast,
};

/// The reader's translation order for the current language, with any new
/// translations appended (plan §4.7).
List<String> translationOrderFor(AppSettings s, String lang, List<String> available) {
  final saved = s.translationOrder[lang] ?? defaultTranslationOrder(available);
  return [...saved.where(available.contains), ...available.where((t) => !saved.contains(t))];
}

/// Picks the first translation in the reader's order that covers the verse.
({Segment? chosen, bool fellBack}) chooseSegment(List<Segment> segments, List<String> order) {
  for (var i = 0; i < order.length; i++) {
    final hit = segments.where((s) => s.translationId == order[i]).firstOrNull;
    if (hit != null) return (chosen: hit, fellBack: i > 0);
  }
  return (chosen: segments.firstOrNull, fellBack: false);
}

/// A verse on a palm leaf with its script switch, translation, terms and source.
class VersePanel extends ConsumerWidget {
  const new({required this.verseId, super.key, this.highlight = const [], this.showCompare = true});
  final String verseId;
  final List<String> highlight;
  final bool showCompare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final content = ref.watch(contentProvider);
    final settings = ref.watch(settingsProvider);
    final verse = content.verse(verseId);
    if (verse == null) return Text(l.notFound);
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    final script = scriptOf(settings.script);
    final segments = content.segmentsFor(verse.id);
    final order = translationOrderFor(settings, context.lang, [for (final t in content.translations()) t.id]);
    final choice = chooseSegment(segments, order);
    final terms = content.termsFor(highlight);
    final wide = MediaQuery.sizeOf(context).width >= GVSpace.twoPaneBreakpoint;

    final leaf = Semantics(
      label: '${verse.workIast} ${verse.refLabel}',
      child: PalmLeafCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: GVMotion.of(context).leafRise,
              child: SelectableText(
                verse.text(script),
                key: ValueKey(script),
                style: verseStyle(fontOf(script), c.ink),
              ),
            ),
            const SizedBox(height: GVSpace.s),
            Text(l.sourceLine(context.lt(verse.workTitle), verse.refLabel, verse.licenceName), style: t.labelSmall),
            if (verse.review != 'approved') Text(l.verseUnreviewed, style: t.labelSmall?.copyWith(color: c.kumkum)),
          ],
        ),
      ),
    );

    final translation = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (choice.chosen == null)
          Text(l.noTranslationYet, style: t.bodyMedium)
        else
          _SegmentView(segment: choice.chosen!, fellBack: choice.fellBack),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ScriptSwitch(
                value: fontOf(script),
                onChanged: (f) => ref
                    .read(settingsProvider.notifier)
                    .update(
                      (s) => s.copyWith(
                        script: switch (f) {
                          VerseFont.devanagari => 'devanagari',
                          VerseFont.kannada => 'kannada',
                          VerseFont.iast => 'iast',
                        },
                      ),
                    ),
              ),
            ),
            _AudioButton(verseId: verse.id, autoplay: settings.audioAutoplay),
          ],
        ),
        const SizedBox(height: GVSpace.m),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leaf),
              const SizedBox(width: GVSpace.l),
              Expanded(child: translation),
            ],
          )
        else ...[
          leaf,
          const SizedBox(height: GVSpace.m),
          translation,
        ],
        if (terms.isNotEmpty) ...[
          const SizedBox(height: GVSpace.m),
          Text(l.verseTerms, style: t.labelMedium),
          Wrap(
            spacing: GVSpace.s,
            children: [
              for (final term in terms)
                ActionChip(
                  label: Text(
                    term.inScript(script),
                    style: verseStyle(fontOf(script), c.ink, size: 16).copyWith(height: 1.2),
                  ),
                  onPressed: () => showTermSheet(context, term, script),
                ),
            ],
          ),
        ],
        Wrap(
          spacing: GVSpace.s,
          children: [
            if (showCompare && segments.length > 1)
              TextButton.icon(
                icon: const Icon(Icons.compare_arrows),
                label: Text(l.compare),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DraggableScrollableSheet(
                    expand: false,
                    builder: (context, controller) => ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(GVSpace.l),
                      children: [
                        for (final s in segments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: GVSpace.l),
                            child: _SegmentView(segment: s),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (choice.chosen != null)
              TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: Text(l.aboutTranslation),
                onPressed: () => showAboutTranslation(context, ref, choice.chosen!.translationId),
              ),
          ],
        ),
      ],
    );
  }
}

class _SegmentView extends StatelessWidget {
  const new({required this.segment, this.fellBack = false});
  final Segment segment;
  final bool fellBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GVColors.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('${segment.translator} (${segment.year})', style: t.labelLarge)),
            if (context.isKannada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.s, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(GVRadius.chip),
                ),
                child: Text(l.englishLabel, style: t.labelSmall),
              ),
          ],
        ),
        if (fellBack) Text(l.fallbackTranslation, style: t.bodySmall),
        const SizedBox(height: GVSpace.xs),
        // Translations stay in their original English (plan §4.7, Kannada mode).
        Text(
          segment.text,
          style: t.bodyLarge?.copyWith(fontFamily: 'AnekLatin', package: 'design_system'),
          locale: const Locale('en'),
        ),
        const SizedBox(height: GVSpace.xs),
        Text([if (segment.label != null) segment.label!, l.pageN(segment.page)].join(' · '), style: t.labelSmall),
        if (segment.status == 'ocr-draft') Text(l.ocrDraft, style: t.labelSmall?.copyWith(color: c.kumkum)),
        if (segment.glossary.isNotEmpty)
          Wrap(
            spacing: GVSpace.s,
            children: [
              for (final g in segment.glossary)
                ActionChip(
                  avatar: const Icon(Icons.menu_book_outlined, size: 16),
                  label: Text(g.headword),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.fromLTRB(GVSpace.xl, 0, GVSpace.xl, GVSpace.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.headword, style: t.titleLarge),
                          const SizedBox(height: GVSpace.s),
                          Text(context.lt(g.note), style: t.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

void showTermSheet(BuildContext context, Term term, VerseScript script) {
  final c = GVColors.of(context);
  final t = Theme.of(context).textTheme;
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(GVSpace.xl, 0, GVSpace.xl, GVSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(term.devanagari, style: verseStyle(VerseFont.devanagari, c.ink, size: 26)),
            Text('${term.kannada}  ·  ${term.iast}', style: verseStyle(VerseFont.kannada, c.inkMuted, size: 18)),
            const SizedBox(height: GVSpace.m),
            Text(context.lt(term.gloss), style: t.bodyLarge),
            if (term.conceptId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    unawaited(context.push('/concept/${term.conceptId}'));
                  },
                  child: Text(context.l10n.openConcept),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void showAboutTranslation(BuildContext context, WidgetRef ref, String translationId) {
  final info = ref.read(contentProvider).translations().firstWhere((t) => t.id == translationId);
  final t = Theme.of(context).textTheme;
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GVSpace.xl, 0, GVSpace.xl, GVSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${info.translator} (${info.year})', style: t.titleLarge),
              const SizedBox(height: GVSpace.s),
              Text(context.lt(info.about), style: t.bodyLarge),
              if (info.styleNote != null)
                Padding(
                  padding: const EdgeInsets.only(top: GVSpace.s),
                  child: Text(context.lt(info.styleNote), style: t.bodyMedium),
                ),
              const SizedBox(height: GVSpace.s),
              Text(context.l10n.coverage(info.covered, info.total), style: t.labelMedium),
              Text(info.licenceName, style: t.labelSmall),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Recitation for lesson verses (plan §4.7). Shown only when a recording is bundled.
class _AudioButton extends StatefulWidget {
  const new({required this.verseId, required this.autoplay});
  final String verseId;
  final bool autoplay;

  @override
  State<_AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<_AudioButton> {
  AudioPlayer? _player;
  bool _available = false;

  String get _asset => 'assets/audio/${widget.verseId}.opus';

  /// The asset manifest, read once: recordings are optional, so look them up
  /// rather than trying to load a file that may not exist.
  static Future<Set<String>>? _assets;

  @override
  void initState() {
    super.initState();
    _assets ??= AssetManifest.loadFromAssetBundle(rootBundle).then((m) => m.listAssets().toSet());
    unawaited(
      _assets!.then((assets) {
        if (!mounted || !assets.contains(_asset)) return;
        setState(() => _available = true);
        if (widget.autoplay) unawaited(_play());
      }),
    );
  }

  Future<void> _play() async {
    _player ??= AudioPlayer();
    await _player!.setAsset(_asset);
    await _player!.play();
  }

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _available
      ? IconButton(tooltip: context.l10n.listen, icon: const Icon(Icons.volume_up_outlined), onPressed: _play)
      : const SizedBox.shrink();
}
