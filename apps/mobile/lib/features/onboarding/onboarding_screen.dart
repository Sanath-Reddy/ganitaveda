import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Three choices: language, class, verse script (plan §4.2). No sign-up.
class OnboardingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  String? language;
  int? classNo;
  String? script;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final lang = language ?? context.lang;
    final effectiveScript = script ?? (lang == 'kn' ? 'kannada' : 'devanagari');

    Widget choice(String label, VoidCallback onTap, {required bool selected, TextStyle? style}) => Padding(
      padding: const EdgeInsets.only(bottom: GVSpace.s),
      child: Semantics(
        selected: selected,
        button: true,
        child: Card(
          color: selected ? GVColors.of(context).leaf : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(GVRadius.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(GVSpace.l),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: style ?? t.titleSmall)),
                  if (selected) const Icon(Icons.check),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final pages = [
      (
        l.onboardingLanguageTitle,
        null as String?,
        [
          choice('English', () => _setLanguage('en'), selected: lang == 'en'),
          choice('ಕನ್ನಡ', () => _setLanguage('kn'), selected: lang == 'kn'),
        ],
      ),
      (
        l.onboardingClassTitle,
        l.onboardingClassNote,
        [
          Wrap(
            spacing: GVSpace.s,
            runSpacing: GVSpace.s,
            children: [
              for (final c in [6, 7, 8, 9, 10, 11, 12, 0])
                ChoiceChip(
                  label: Text(classLabel(context, c)),
                  selected: classNo == c,
                  onSelected: (_) => setState(() => classNo = c),
                ),
            ],
          ),
        ],
      ),
      (
        l.onboardingScriptTitle,
        l.onboardingScriptNote,
        [
          choice(
            'भास्करः  ·  ${l.scriptDevanagari}',
            () => setState(() => script = 'devanagari'),
            selected: effectiveScript == 'devanagari',
            style: verseStyle(VerseFont.devanagari, GVColors.of(context).ink, size: 18),
          ),
          choice(
            'ಭಾಸ್ಕರಃ  ·  ${l.scriptKannada}',
            () => setState(() => script = 'kannada'),
            selected: effectiveScript == 'kannada',
            style: verseStyle(VerseFont.kannada, GVColors.of(context).ink, size: 18),
          ),
          choice(
            'Bhāskaraḥ  ·  ${l.scriptIast}',
            () => setState(() => script = 'iast'),
            selected: effectiveScript == 'iast',
            style: verseStyle(VerseFont.iast, GVColors.of(context).ink, size: 20),
          ),
        ],
      ),
    ];
    final (title, note, children) = pages[step];
    final canGoOn = step != 1 || classNo != null;

    return Scaffold(
      body: SafeArea(
        child: Readable(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.all(GVSpace.xl),
            children: [
              const SizedBox(height: GVSpace.xl),
              Text(l.appTitle, style: t.labelLarge?.copyWith(color: GVColors.of(context).turmeric)),
              const SizedBox(height: GVSpace.s),
              Semantics(header: true, child: Text(title, style: t.headlineSmall)),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: GVSpace.s),
                  child: Text(note, style: t.bodyMedium),
                ),
              const SizedBox(height: GVSpace.xl),
              ...children,
              const SizedBox(height: GVSpace.xl),
              Row(
                children: [
                  if (step > 0) TextButton(onPressed: () => setState(() => step--), child: Text(l.back)),
                  const Spacer(),
                  FilledButton(
                    onPressed: canGoOn
                        ? () => step < 2 ? setState(() => step++) : _finish(lang, effectiveScript)
                        : null,
                    child: Text(step < 2 ? l.next : l.start),
                  ),
                ],
              ),
              if (step == 2)
                Padding(
                  padding: const EdgeInsets.only(top: GVSpace.l),
                  child: Text(l.noSignUp, style: t.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setLanguage(String code) {
    setState(() => language = code);
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(locale: code));
  }

  void _finish(String lang, String chosenScript) {
    final translations = ref.read(contentProvider).translations();
    ref
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            locale: lang,
            classNo: classNo,
            script: chosenScript,
            translationOrder: s.translationOrder.isNotEmpty
                ? s.translationOrder
                : {
                    for (final l in ['en', 'kn']) l: defaultTranslationOrder([for (final t in translations) t.id]),
                  },
            onboarded: true,
          ),
        );
    context.go('/school');
  }
}

/// Colebrooke, Taylor, Clark, then anything newer (plan §4.7).
List<String> defaultTranslationOrder(List<String> available) {
  const preferred = ['translation.colebrooke-1817', 'translation.taylor-1816', 'translation.clark-1930'];
  return [...preferred.where(available.contains), ...available.where((t) => !preferred.contains(t))];
}
