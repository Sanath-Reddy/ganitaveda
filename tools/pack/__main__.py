"""GanitaVeda pack builder.

  python -m tools.pack validate [--release]
  python -m tools.pack build [--release] [--version 2026.11.22] [--out build/pack]
  python -m tools.pack publish --channel beta [--out build/pack] [--cdn build/cdn] [--base-url URL]
  python -m tools.pack bundle            (copy the built pack into the app)
  python -m tools.pack keygen PATH
  python -m tools.pack verify MANIFEST
  python -m tools.pack coverage

Signing key: $PACK_SIGNING_KEY (base64 raw Ed25519) with $PACK_KEY_ID, or
--key FILE --key-id ID. Without either, a development key is generated in
build/dev-signing.key with key id "dev"; only debug builds of the app trust it.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
from datetime import date
from pathlib import Path

from . import sign
from .build import SCHEMA_VERSION, build, coverage_report
from .load import ROOT, load
from .validate import validate

BUILD = ROOT / "build"
DEV_KEY = BUILD / "dev-signing.key"


def _print_report(r) -> None:
    for w in r.warnings:
        print(f"warning: {w}")
    for e in r.errors:
        print(f"error: {e}")
    print(json.dumps(r.stats, ensure_ascii=False))
    print(f"{len(r.errors)} errors, {len(r.warnings)} warnings")


def _key(args) -> tuple[object, str]:
    if os.environ.get("PACK_SIGNING_KEY"):
        return sign.load_private(os.environ["PACK_SIGNING_KEY"]), os.environ.get("PACK_KEY_ID", "k1")
    if args.key:
        return sign.load_private(Path(args.key).read_text()), args.key_id
    if not DEV_KEY.exists():
        pub = sign.generate(DEV_KEY)
        print(f"generated development key {DEV_KEY} (public {pub})")
    return sign.load_private(DEV_KEY.read_text()), "dev"


def cmd_validate(args) -> int:
    c, dupes = load()
    r = validate(c, dupes, release=args.release)
    _print_report(r)
    return 0 if r.ok else 1


def cmd_build(args) -> int:
    c, dupes = load()
    r = validate(c, dupes, release=args.release)
    _print_report(r)
    if not r.ok:
        return 1
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    version = args.version or date.today().strftime("%Y.%m.%d")
    db = out / "content.db"
    stats = build(c, db, version)
    data = db.read_bytes()
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "content_version": version,
        "min_app_version": args.min_app_version,
        "files": [{"name": "content.db", "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                   "url": f"{args.base_url.rstrip('/')}/packs/{SCHEMA_VERSION}/{version}/content.db"}],
        "flags": {"semantic_search": False},
    }
    key, key_id = _key(args)
    signed = sign.sign_manifest(manifest, key, key_id)
    (out / "manifest.json").write_text(json.dumps(signed, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (out / "public_key.txt").write_text(f"{key_id} {sign.public_of(key)}\n")
    print(f"built {db} ({stats['bytes']:,} bytes): {stats}")
    if stats["bytes"] > 15 * 1024 * 1024:
        print("error: content.db is over the 15 MB budget (plan §8.6)")
        return 1
    return 0


def cmd_publish(args) -> int:
    """Lay the pack out as the CDN expects: /packs/<schema>/<version>/ and /channels/<channel>.json.
    Uploading that tree is the CI job's business (Cloudflare R2 or GitHub Releases, plan §14)."""
    src = Path(args.out)
    manifest = json.loads((src / "manifest.json").read_text(encoding="utf-8"))
    cdn = Path(args.cdn)
    dest = cdn / "packs" / str(manifest["schema_version"]) / manifest["content_version"]
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src / "content.db", dest / "content.db")
    (cdn / "channels").mkdir(parents=True, exist_ok=True)
    (cdn / "channels" / f"{args.channel}.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"published {manifest['content_version']} to {args.channel} under {cdn}")
    return 0


def cmd_bundle(args) -> int:
    """Copy the built pack into the app as its offline baseline (plan §6.5)."""
    src = Path(args.out)
    dest = ROOT / "apps" / "mobile" / "assets" / "packs"
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("content.db", "manifest.json"):
        shutil.copy2(src / name, dest / name)
    print(f"bundled {src} into {dest}")
    return 0


def cmd_keygen(args) -> int:
    pub = sign.generate(Path(args.path))
    print(f"private key written to {args.path} (keep it out of the repository)\npublic key: {pub}")
    return 0


def cmd_verify(args) -> int:
    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    keys = dict(line.split() for line in Path(args.keys).read_text().splitlines() if line.strip())
    ok = sign.verify_manifest(manifest, keys)
    print("signature ok" if ok else "signature INVALID")
    return 0 if ok else 1


def cmd_coverage(args) -> int:
    c, _ = load()
    print(f"{'translation':28} {'work':34} {'covered':>8} {'total':>6} {'lesson verses':>14}")
    for row in coverage_report(c):
        pct = 100.0 * row["covered"] / row["total"] if row["total"] else 0
        print(f"{row['translation']:28} {row['work']:34} {row['covered']:>8} {row['total']:>6} "
              f"{row['lesson_verses_covered']:>6}/{row['lesson_verses']:<6} {pct:5.1f}%")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python -m tools.pack", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("validate")
    v.add_argument("--release", action="store_true", help="also require reviews and 100%% Kannada")
    v.set_defaults(fn=cmd_validate)
    b = sub.add_parser("build")
    b.add_argument("--release", action="store_true")
    b.add_argument("--version")
    b.add_argument("--out", default=str(BUILD / "pack"))
    b.add_argument("--min-app-version", default="1.0.0")
    # The real host is decided in Week 8 (plan §14); CI passes --base-url.
    b.add_argument("--base-url", default="https://cdn.ganitaveda.invalid")
    b.add_argument("--key")
    b.add_argument("--key-id", default="k1")
    b.set_defaults(fn=cmd_build)
    pb = sub.add_parser("publish")
    pb.add_argument("--channel", choices=["beta", "stable"], required=True)
    pb.add_argument("--out", default=str(BUILD / "pack"))
    pb.add_argument("--cdn", default=str(BUILD / "cdn"))
    pb.set_defaults(fn=cmd_publish)
    bu = sub.add_parser("bundle")
    bu.add_argument("--out", default=str(BUILD / "pack"))
    bu.set_defaults(fn=cmd_bundle)
    k = sub.add_parser("keygen")
    k.add_argument("path")
    k.set_defaults(fn=cmd_keygen)
    ve = sub.add_parser("verify")
    ve.add_argument("manifest")
    ve.add_argument("--keys", default=str(BUILD / "pack" / "public_key.txt"))
    ve.set_defaults(fn=cmd_verify)
    cv = sub.add_parser("coverage")
    cv.set_defaults(fn=cmd_coverage)
    args = p.parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
