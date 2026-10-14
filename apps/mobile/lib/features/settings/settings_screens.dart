import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/config.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/updates/update_runner.dart';
import 'package:ganitaveda/features/updates/update_service.dart';
import 'package:ganitaveda/features/verse/verse_panel.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:ganitaveda/shared/widgets/common.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings (plan §4.8).
class SettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTaps = 0;
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final content = ref.watch(contentProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: GVSpace.xxl),
          children: [
            ListTile(
              title: Text(l.language),
              trailing: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'kn', label: Text('ಕನ್ನಡ')),
                ],
                selected: {s.locale ?? context.lang},
                onSelectionChanged: (v) => notifier.update((x) => x.copyWith(locale: v.single)),
              ),
            ),
            ListTile(
              title: Text(l.verseScript),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: GVSpace.s),
                child: ScriptSwitch(
                  value: fontOf(scriptOf(s.script)),
                  onChanged: (f) => notifier.update(
                    (x) => x.copyWith(
                      script: switch (f) {
                        VerseFont.devanagari => 'devanagari',
                        VerseFont.kannada => 'kannada',
                        VerseFont.iast => 'iast',
                      },
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(l.translationOrder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/progress/settings/translations'),
            ),
            ListTile(
              title: Text(l.textSize),
              subtitle: Slider(
                value: s.textScale,
                min: 1,
                max: 2,
                divisions: 4,
                label: '${(s.textScale * 100).round()}%',
                onChanged: (v) => notifier.update((x) => x.copyWith(textScale: v)),
              ),
            ),
            ListTile(
              title: Text(l.theme),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: GVSpace.s),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => notifier.update((x) => x.copyWith(themeMode: v.single)),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(l.reduceMotion),
              value: s.reduceMotion,
              onChanged: (v) => notifier.update((x) => x.copyWith(reduceMotion: v)),
            ),
            SwitchListTile(
              title: Text(l.audioAutoplay),
              value: s.audioAutoplay,
              onChanged: (v) => notifier.update((x) => x.copyWith(audioAutoplay: v)),
            ),
            SwitchListTile(
              title: Text(l.wifiOnly),
              value: s.wifiOnly,
              onChanged: (v) => notifier.update((x) => x.copyWith(wifiOnly: v)),
            ),
            ListTile(
              title: Text(l.contentVersion),
              subtitle: Text(
                '${content.contentVersion}${s.channel == 'beta' ? ' · beta' : ''} · app ${AppConfig.appVersion}',
              ),
              // Testers switch to beta content by tapping the version seven times (plan §8.8).
              onTap: () {
                if (++_versionTaps < 7) return;
                _versionTaps = 0;
                final beta = s.channel != 'beta';
                notifier.update((x) => x.copyWith(channel: beta ? 'beta' : 'stable'));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(beta ? l.betaContentOn : l.betaContentOff)));
              },
            ),
            ListTile(
              title: Text(l.checkForUpdates),
              trailing: _checking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _checking
                  ? null
                  : () async {
                      setState(() => _checking = true);
                      final result = await runContentCheck(ref, force: true);
                      if (!context.mounted) return;
                      setState(() => _checking = false);
                      final msg = switch (result?.outcome) {
                        null || UpdateOutcome.notConfigured => l.updatesNotConfigured,
                        UpdateOutcome.staged => l.updateReady,
                        UpdateOutcome.upToDate || UpdateOutcome.skippedRecently => l.upToDate,
                        UpdateOutcome.appTooOld || UpdateOutcome.unsupportedSchema => l.updateTheApp,
                        _ => l.updateFailed,
                      };
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
            ),
            ListTile(
              title: Text(l.sourcesAndLicences),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/progress/settings/sources'),
            ),
            ListTile(
              title: Text(l.reportProblem),
              trailing: const Icon(Icons.mail_outline),
              onTap: () => launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: AppConfig.reportEmail,
                  // App and content version, and nothing personal (plan §4.8).
                  queryParameters: {
                    'subject': l.reportSubject,
                    'body':
                        '\n\n---\nApp ${AppConfig.appVersion} · content ${content.contentVersion} (schema ${content.schemaVersion}) · ${context.lang}',
                  },
                ),
              ),
            ),
            ListTile(
              title: Text(l.privacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/progress/settings/privacy'),
            ),
            if (kDebugMode)
              ListTile(
                title: Text(l.debugTools),
                trailing: const Icon(Icons.build_outlined),
                onTap: () => context.push('/progress/settings/debug'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Each language has an ordered list readers can reorder (plan §4.7).
class TranslationOrderScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final infos = {for (final t in ref.watch(contentProvider).translations()) t.id: t};
    final lang = context.lang;
    final order = translationOrderFor(settings, lang, infos.keys.toList());
    void save(List<String> next) => ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(translationOrder: {...s.translationOrder, lang: next}));
    return Scaffold(
      appBar: AppBar(title: Text(l.translationOrder)),
      body: Readable(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(GVSpace.gutter), child: Text(l.translationOrderNote)),
            if (context.isKannada)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GVSpace.gutter),
                child: Text(l.kannadaTranslationsComing),
              ),
            Expanded(
              child: ReorderableListView(
                onReorderItem: (from, to) {
                  final next = [...order];
                  final item = next.removeAt(from);
                  next.insert(to, item);
                  save(next);
                },
                children: [
                  for (final (i, id) in order.indexed)
                    ListTile(
                      key: ValueKey(id),
                      title: Text('${infos[id]!.translator} (${infos[id]!.year})'),
                      subtitle: Text(l.coverage(infos[id]!.covered, infos[id]!.total)),
                      // Buttons as well as drag (plan §7.7).
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l.moveUp,
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0
                                ? null
                                : () => save(
                                    [...order]
                                      ..removeAt(i)
                                      ..insert(i - 1, id),
                                  ),
                          ),
                          IconButton(
                            tooltip: l.moveDown,
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: i == order.length - 1
                                ? null
                                : () => save(
                                    [...order]
                                      ..removeAt(i)
                                      ..insert(i + 1, id),
                                  ),
                          ),
                        ],
                      ),
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

/// Every source, translator, licence and video channel (plan §9.3).
class SourcesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final content = ref.watch(contentProvider);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.sourcesAndLicences)),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.all(GVSpace.gutter),
          children: [
            Text(l.licenceNote, style: t.bodyLarge),
            for (final s in content.sources()) ...[
              const Divider(height: GVSpace.xl),
              Text(s.citation, style: t.bodyMedium),
              if (s.attribution != null) Text(s.attribution!, style: t.bodySmall),
              Text(s.licenceName, style: t.labelSmall),
              if (s.url != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => launchUrl(Uri.parse(s.url!), mode: LaunchMode.externalApplication),
                    child: Text(s.url!, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
            const Divider(height: GVSpace.xl),
            Text(l.fontsLicence, style: t.bodyMedium),
            TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
                applicationVersion: AppConfig.appVersion,
              ),
              child: Text(l.openSourceLicences),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.privacyPolicy)),
    body: Readable(
      child: ListView(
        padding: const EdgeInsets.all(GVSpace.gutter),
        children: [Text(context.l10n.privacyText, style: Theme.of(context).textTheme.bodyLarge)],
      ),
    ),
  );
}
