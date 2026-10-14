import 'dart:io';
import 'dart:typed_data';

import 'package:content_model/content_model.dart';
import 'package:test/test.dart';

void main() {
  test('canonical JSON matches the Python signer', () {
    expect(
      canonicalJson({
        'b': 1,
        'a': [true, 'é', null],
      }),
      '{"a":[true,"é",null],"b":1}',
    );
    expect(() => canonicalJson({'x': 1.5}), throwsArgumentError);
  });

  test('verifies the manifest signed by tools/pack (cross-language)', () async {
    final dir = '../../build/pack';
    final m = Manifest.parse(File('$dir/manifest.json').readAsStringSync());
    final keyLine = File('$dir/public_key.txt').readAsStringSync().trim().split(' ');
    final keys = {keyLine[0]: keyLine[1]};
    expect(await m.verify(keys), isTrue);
    expect(await m.verify({'other': keyLine[1]}), isFalse);

    // Any change to the signed body breaks it.
    final tampered = Manifest.parse(
      File('$dir/manifest.json')
          .readAsStringSync()
          .replaceFirst('"min_app_version": "1.0.0"', '"min_app_version": "0.0.1"'),
    );
    expect(await tampered.verify(keys), isFalse);

    // The file hash in the manifest matches the pack.
    final bytes = File('$dir/content.db').readAsBytesSync();
    expect(sha256Hex(Uint8List.fromList(bytes)), m.contentDb.sha256);
    expect(m.contentDb.size, bytes.length);
  });

  test('version comparison', () {
    expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), lessThan(0));
  });
}
