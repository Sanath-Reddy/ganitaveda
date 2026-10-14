import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ganitaveda/app/app.dart';
import 'package:ganitaveda/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font licences ship with the app (plan §9.3).
  LicenseRegistry.addLicense(() async* {
    for (final (fonts, file) in [
      (['Anek Latin', 'Anek Kannada'], 'OFL-Anek.txt'),
      (['Tiro Devanagari Sanskrit', 'Tiro Kannada'], 'OFL-Tiro.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks(fonts, await rootBundle.loadString('packages/design_system/assets/fonts/$file'));
    }
  });
  final overrides = await bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const GanitaVedaApp()));
}
