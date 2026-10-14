import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/features/lesson/card_registry.dart';

/// The app's renderer, widget, algorithm and generator registries must match
/// tools/schemas/registry.yaml, which the pack validator checks lessons against.
Set<String> section(String yaml, String name, {bool keys = false}) {
  final lines = yaml.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('$name:'));
  final out = <String>{};
  for (final l in lines.skip(start + 1)) {
    if (l.isNotEmpty && !l.startsWith(' ')) break;
    final m = keys ? RegExp('^  ([a-z_]+):').firstMatch(l) : RegExp(r'^  - (\S+)').firstMatch(l);
    if (m != null) out.add(m[1]!);
  }
  return out;
}

void main() {
  final yaml = File('../../tools/schemas/registry.yaml').readAsStringSync();

  test('card types', () => expect(cardRenderers.keys.toSet(), section(yaml, 'card_types', keys: true)));
  test('explore widgets', () => expect(exploreWidgets.keys.toSet(), section(yaml, 'widgets', keys: true)));
  test('algorithms', () => expect(algorithms.keys.toSet(), section(yaml, 'algorithms')));
  test('generators', () => expect(generators.keys.toSet(), section(yaml, 'generators')));
}
