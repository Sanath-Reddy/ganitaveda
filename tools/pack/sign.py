"""Ed25519 signing of channel manifests (plan §6.5, §8.9).

The signed message is the manifest without its `signature` field, encoded as
canonical JSON: keys sorted at every level, no whitespace, UTF-8. The app's
verifier (packages/content_model/lib/src/manifest.dart) re-encodes the same way.
Manifests carry only strings, integers, booleans, lists and objects (no floats).
"""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey


def canonical(obj: object) -> bytes:
    def check(o: object) -> None:
        if isinstance(o, float):
            raise ValueError("manifests must not contain floats")
        if isinstance(o, dict):
            for v in o.values():
                check(v)
        elif isinstance(o, list):
            for v in o:
                check(v)
    check(obj)
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def b64(b: bytes) -> str:
    return base64.b64encode(b).decode("ascii")


def generate(path: Path) -> str:
    """Write a new raw 32-byte private key (base64) to `path`; return the public key."""
    key = Ed25519PrivateKey.generate()
    raw = key.private_bytes_raw()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(b64(raw) + "\n", encoding="ascii")
    os.chmod(path, 0o600)
    return b64(key.public_key().public_bytes_raw())


def load_private(text: str) -> Ed25519PrivateKey:
    return Ed25519PrivateKey.from_private_bytes(base64.b64decode(text.strip()))


def public_of(key: Ed25519PrivateKey) -> str:
    return b64(key.public_key().public_bytes_raw())


def sign_manifest(manifest: dict, key: Ed25519PrivateKey, key_id: str) -> dict:
    body = {k: v for k, v in manifest.items() if k != "signature"}
    body["key_id"] = key_id
    return dict(body, signature=b64(key.sign(canonical(body))))


def verify_manifest(manifest: dict, public_keys: dict[str, str]) -> bool:
    try:
        pub = public_keys[manifest["key_id"]]
        sig = base64.b64decode(manifest["signature"])
        body = {k: v for k, v in manifest.items() if k != "signature"}
        Ed25519PublicKey.from_public_bytes(base64.b64decode(pub)).verify(sig, canonical(body))
        return True
    except Exception:
        return False
