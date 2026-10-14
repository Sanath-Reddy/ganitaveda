from tools.ingest.gretil import clean_iast


def test_markup_is_stripped_and_notes_kept():
    raw = "%pañca-aṃśas ali-kulāt @agamat/\nkānte @vada// [śārdūlavikrīḍita] Lil_55"
    text, notes = clean_iast(raw)
    assert text == "pañca-aṃśas ali-kulāt agamat |\nkānte vada ||"
    assert notes == ["śārdūlavikrīḍita"]


def test_editorial_numbers_removed():
    text, _ = clean_iast("gadyāṇakas tad-%dvayam #indra-14-tulyais vallais/")
    assert "14" not in text and "indra-tulyais" in text


def test_bracketed_verse_kept_with_note():
    text, notes = clean_iast("[kṛti-saṃyogāt yuti-vargam/\ntena yutas// cb.99] BSS_18.98")
    assert text.startswith("kṛti-saṃyogāt")
    assert "bracketed in the edition" in notes and "Colebrooke numbers this 99" in notes
