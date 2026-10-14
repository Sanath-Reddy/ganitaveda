import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashing;
import 'package:cryptography/cryptography.dart';

/// Canonical JSON for signing, identical to `canonical()` in tools/pack/sign.py:
/// keys sorted at every level, no whitespace, UTF-8. Floats are rejected.
String canonicalJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v) {
    if (v == null || v is bool || v is String) {
      out.write(jsonEncode(v));
    } else if (v is int) {
      out.write(v);
    } else if (v is double) {
      throw ArgumentError('Manifests must not contain floats');
    } else if (v is List) {
      out.write('[');
      for (var i = 0; i < v.length; i++) {
        if (i > 0) out.write(',');
        write(v[i]);
      }
      out.write(']');
    } else if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      out.write('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) out.write(',');
        out.write(jsonEncode(keys[i]));
        out.write(':');
        write(v[keys[i]]);
      }
      out.write('}');
    } else {
      throw ArgumentError('Unsupported value $v');
    }
  }

  write(value);
  return out.toString();
}

class PackFile {
  final String name;
  final int size;
  final String sha256;
  final Uri url;

  const PackFile(this.name, this.size, this.sha256, this.url);
}

/// A channel manifest (plan Appendix A.4).
class Manifest {
  final Map<String, Object?> raw;
  final int schemaVersion;
  final String contentVersion;
  final String minAppVersion;
  final List<PackFile> files;
  final Map<String, Object?> flags;
  final String keyId;
  final String signature;

  Manifest._(
    this.raw,
    this.schemaVersion,
    this.contentVersion,
    this.minAppVersion,
    this.files,
    this.flags,
    this.keyId,
    this.signature,
  );

  static Manifest parse(String text) {
    final j = jsonDecode(text) as Map<String, Object?>;
    return Manifest._(
      j,
      j['schema_version'] as int,
      j['content_version'] as String,
      j['min_app_version'] as String,
      [
        for (final f in (j['files'] as List).cast<Map>())
          PackFile(f['name'] as String, f['size'] as int, f['sha256'] as String, Uri.parse(f['url'] as String)),
      ],
      Map<String, Object?>.from((j['flags'] as Map?) ?? const {}),
      j['key_id'] as String,
      j['signature'] as String,
    );
  }

  /// True if the signature is valid for one of [publicKeys] (key id → base64).
  Future<bool> verify(Map<String, String> publicKeys) async {
    final pub = publicKeys[keyId];
    if (pub == null) return false;
    try {
      final body = Map<String, Object?>.from(raw)..remove('signature');
      final message = utf8.encode(canonicalJson(body));
      return await Ed25519().verify(
        message,
        signature: Signature(
          base64Decode(signature),
          publicKey: SimplePublicKey(base64Decode(pub), type: KeyPairType.ed25519),
        ),
      );
    } on FormatException {
      return false;
    }
  }

  PackFile get contentDb => files.firstWhere((f) => f.name == 'content.db');
}

String sha256Hex(Uint8List bytes) => hashing.sha256.convert(bytes).toString();

/// Compares dotted versions: `1.2.10` > `1.2.9`.
int compareVersions(String a, String b) {
  final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  for (var i = 0; i < 4; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
