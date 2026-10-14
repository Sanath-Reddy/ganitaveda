from tools.ingest import align


def test_parses_most_colebrooke_paragraphs_in_order():
    paras = align.colebrooke_paragraphs()
    nums = [n for n, _ in paras]
    assert len(paras) > 120, len(paras)
    assert nums == sorted(nums)
    assert nums[0] <= 14 and nums[-1] > 200


def test_number_extraction_matches_across_languages():
    sk = align.sanskrit_numbers("%pañca-aṃśas ali-kulāt %tri-aṃśas viśleṣas %tri-guṇas")
    en = align.english_numbers("one-fifth settled and one-third; three times the difference")
    assert sk == {5: 1, 3: 2}
    assert align.score(sk, en) > 0.2


def test_suggestion_window_contains_confirmed_pairs_leave_one_out():
    paras = dict(align.colebrooke_paragraphs())
    pairs = [(v, n) for v, n in align.known_pairs() if n in paras]
    assert len(pairs) >= 5
    for verse, n in pairs:
        anchors = [(m, align.verse_no(v)) for v, m in pairs if (v, m) != (verse, n)]
        assert abs(align.expected_verse(n, anchors) - align.verse_no(verse)) <= 6, (verse, n)
