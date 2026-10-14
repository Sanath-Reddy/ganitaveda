import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/app/router.dart';
import 'package:ganitaveda/features/updates/update_runner.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';

class GanitaVedaApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GanitaVedaApp> createState() => _GanitaVedaAppState();
}

class _GanitaVedaAppState extends ConsumerState<GanitaVedaApp> {
  late final GoRouter router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale == null ? null : Locale(settings.locale!);
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) =>
          supported.firstWhere((l) => l.languageCode == device?.languageCode, orElse: () => const Locale('en')),
      themeMode: settings.themeMode,
      theme: gvTheme(Brightness.light, kannada: settings.locale == 'kn'),
      darkTheme: gvTheme(Brightness.dark, kannada: settings.locale == 'kn'),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final kannada = Localizations.localeOf(context).languageCode == 'kn';
        return Theme(
          // Kannada needs its own fonts and line heights even when it follows the phone.
          data: kannada == (settings.locale == 'kn')
              ? Theme.of(context)
              : gvTheme(Theme.of(context).brightness, kannada: kannada),
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(mq.textScaler.scale(1) * settings.textScale),
              disableAnimations: mq.disableAnimations || settings.reduceMotion,
            ),
            child: UpdateRunner(child: child!),
          ),
        );
      },
    );
  }
}
