import 'dart:io';

import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

/// The pack validator and the app must agree on generator ids
/// (tools/schemas/registry.yaml is the single list).
void main() {
  test('generator ids match tools/schemas/registry.yaml', () {
    final yaml = File('../../tools/schemas/registry.yaml').readAsStringSync();
    final section = yaml.split('generators:').last;
    final ids = RegExp(r'^\s+-\s+(\S+)\s*$', multiLine: true).allMatches(section).map((m) => m[1]).toSet();
    expect(ids, generators.keys.toSet());
  });
}
