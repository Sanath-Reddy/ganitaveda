# 1. Offline-first, signed SQLite content packs

Status: accepted (plan §6.1–6.5)

All content ships as one read-only `content.db` built by CI from YAML. A channel
manifest lists it with size and SHA-256 and is signed with Ed25519 over canonical JSON
(keys sorted, no whitespace, UTF-8, no floats). Python (`tools/pack/sign.py`) and Dart
(`content_model/manifest.dart`) implement the same encoding, and a test verifies the
Python-signed manifest from Dart.

The app keeps the bundled baseline, the active pack and the previous one. A new pack
is staged, opened and integrity-checked before it can be activated, and a pack that
fails to open is rolled back on the next launch (`PackStore.open`).
