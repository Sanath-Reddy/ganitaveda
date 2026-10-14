import 'dart:convert';
import 'dart:io';

import 'package:ganita_core/ganita_core.dart';
import 'package:test/test.dart';

void main() {
  test('keys match the Python pack builder (shared fixtures)', () {
    final file = File('../../tools/tests/fixtures/ascii_keys.json');
    final cases = (jsonDecode(file.readAsStringSync()) as List).cast<List>();
    expect(cases, isNotEmpty);
    for (final c in cases) {
      expect(asciiKey(c[0] as String), c[1], reason: c[0] as String);
    }
  });

  test('scripts to IAST', () {
    expect(indicToIast('कुट्टक'), 'kuṭṭaka');
    expect(indicToIast('ಕುಟ್ಟಕ'), 'kuṭṭaka');
    expect(indicToIast('भुज-कोटि-कर्ण'), 'bhuja-koṭi-karṇa');
    expect(indicToIast('ಶ್ರೇಢೀ'), 'śreḍhī');
  });

  test('FTS query', () {
    expect(ftsQuery('rule of three'), '{text keys}: "rule"* "of"* "three"*');
    expect(ftsQuery('  '), '');
  });
}
