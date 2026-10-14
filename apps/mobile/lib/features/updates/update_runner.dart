import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/updates/update_service.dart';
import 'package:in_app_update/in_app_update.dart';

/// Checks for content once per launch in the background (at most once a day,
/// Wi-Fi only by default) and offers a flexible Play update when one exists (plan §8.7).
class UpdateRunner extends ConsumerStatefulWidget {
  const new({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<UpdateRunner> createState() => _UpdateRunnerState();
}

class _UpdateRunnerState extends ConsumerState<UpdateRunner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(runContentCheck(ref));
      if (!kDebugMode) unawaited(_playUpdate());
    });
  }

  Future<void> _playUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable && info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } on Object {
      // Not installed from Play (debug, sideload): nothing to do.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Runs one content check and activates a staged pack at once if no lesson is open.
Future<UpdateResult?> runContentCheck(WidgetRef ref, {bool force = false}) async {
  final service = ref.read(updateServiceProvider);
  if (service == null) return null;
  final settings = ref.read(settingsProvider);
  final result = await service.check(
    channel: settings.channel,
    currentVersion: ref.read(contentProvider).contentVersion,
    wifiOnly: settings.wifiOnly,
    force: force,
  );
  if (result.outcome == UpdateOutcome.staged && !ref.read(lessonOpenProvider)) {
    ref.read(contentProvider.notifier).activatePending();
  }
  return result;
}
