import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ganitaveda/shared/l10n.dart';
import 'package:go_router/go_router.dart';

/// Tabs: School, Explore, Progress. A navigation rail at 600 dp and wider (plan §7.8).
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final destinations = [
      (Icons.school_outlined, Icons.school, l.tabSchool),
      (Icons.explore_outlined, Icons.explore, l.tabExplore),
      (Icons.auto_awesome_mosaic_outlined, Icons.auto_awesome_mosaic, l.tabProgress),
    ];
    final wide = MediaQuery.sizeOf(context).width >= GVSpace.twoPaneBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in destinations) NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
        ],
      ),
    );
  }
}
