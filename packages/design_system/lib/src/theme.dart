import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// The app theme: ink on paper, one accent per screen, hairlines not shadows (plan §7.1, §7.9).
ThemeData gvTheme(Brightness brightness, {bool kannada = false}) {
  final c = brightness == Brightness.dark ? GVColors.dark : GVColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.indigo,
    onPrimary: c.surface,
    secondary: c.turmeric,
    onSecondary: c.ink,
    error: c.kumkum,
    onError: c.surface,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    outline: c.line,
    outlineVariant: c.line,
    surfaceContainerLowest: c.paper,
    surfaceContainerLow: c.paper,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.leaf,
  );
  final text = gvTextTheme(kannada: kannada, ink: c.ink, muted: c.inkMuted);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(GVRadius.card),
    side: BorderSide(color: c.line),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.paper,
    canvasColor: c.paper,
    textTheme: text,
    extensions: [c],
    splashFactory: InkRipple.splashFactory,
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    cardTheme: CardThemeData(color: c.surface, elevation: 0, margin: EdgeInsets.zero, shape: shape),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.leaf,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.ink : c.inkMuted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.leaf,
      selectedLabelTextStyle: text.labelMedium,
      unselectedLabelTextStyle: text.labelMedium?.copyWith(color: c.inkMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.indigo,
        foregroundColor: c.surface,
        minimumSize: const Size(GVSpace.minTap, GVSpace.minTap),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GVRadius.card)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.indigo,
        minimumSize: const Size(GVSpace.minTap, GVSpace.minTap),
        side: BorderSide(color: c.line),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GVRadius.card)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.indigo,
        minimumSize: const Size(GVSpace.minTap, GVSpace.minTap),
        textStyle: text.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: c.leaf,
        selectedForegroundColor: c.ink,
        foregroundColor: c.inkMuted,
        side: BorderSide(color: c.line),
        minimumSize: const Size(GVSpace.minTap, GVSpace.minTap),
        textStyle: text.labelMedium,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.leaf,
      side: BorderSide(color: c.line),
      labelStyle: text.labelMedium,
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GVRadius.card),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GVRadius.card),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GVRadius.card),
        borderSide: BorderSide(color: c.indigo, width: 2),
      ),
      hintStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(GVRadius.leaf))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: c.paper),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkMuted,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall,
      minVerticalPadding: GVSpace.m,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.surface : c.inkMuted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.indigo : c.line),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.turmeric, linearTrackColor: c.line),
  );
}
