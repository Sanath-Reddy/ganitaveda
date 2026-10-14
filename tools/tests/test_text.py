import json
from pathlib import Path

import pytest

from tools.pack.text import any_script_key, deva_to, iast_to_deva, round_trips

FIXTURES = json.loads((Path(__file__).parent / "fixtures" / "ascii_keys.json").read_text(encoding="utf-8"))


@pytest.mark.parametrize("raw,key", FIXTURES)
def test_ascii_keys_shared_with_dart(raw, key):
    assert any_script_key(raw) == key


def test_scripts_from_devanagari():
    deva = iast_to_deva("kuṭṭaka")
    assert deva == "कुट्टक"
    assert deva_to("kannada", deva) == "ಕುಟ್ಟಕ"
    assert deva_to("iast", deva) == "kuṭṭaka"


def test_round_trip_holds_for_clean_devanagari():
    assert round_trips("पञ्च-अंशस् अलि-कुलात् ॥")


def test_anusvara_folds_to_class_nasal():
    assert any_script_key("aṃka") == any_script_key("aṅka") == "anka"
    assert any_script_key("saṃkhyā") == "sankhya"
