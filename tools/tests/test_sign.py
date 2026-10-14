import pytest

from tools.pack import sign


def manifest():
    return {"schema_version": 1, "content_version": "2026.11.22", "min_app_version": "1.0.0",
            "files": [{"name": "content.db", "size": 10, "sha256": "ab", "url": "https://x/y"}],
            "flags": {"semantic_search": False}}


def test_sign_and_verify(tmp_path):
    pub = sign.generate(tmp_path / "k")
    key = sign.load_private((tmp_path / "k").read_text())
    signed = sign.sign_manifest(manifest(), key, "k1")
    assert sign.verify_manifest(signed, {"k1": pub})


def test_tampering_and_wrong_key_fail(tmp_path):
    pub = sign.generate(tmp_path / "a")
    other = sign.generate(tmp_path / "b")
    key = sign.load_private((tmp_path / "a").read_text())
    signed = sign.sign_manifest(manifest(), key, "k1")
    tampered = dict(signed, content_version="2099.01.01")
    assert not sign.verify_manifest(tampered, {"k1": pub})
    assert not sign.verify_manifest(signed, {"k1": other})
    assert not sign.verify_manifest(signed, {"k2": pub})


def test_canonical_form_is_stable_and_rejects_floats():
    assert sign.canonical({"b": 1, "a": [True, "é"]}) == '{"a":[true,"é"],"b":1}'.encode()
    with pytest.raises(ValueError):
        sign.canonical({"x": 1.5})
