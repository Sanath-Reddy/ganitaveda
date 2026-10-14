/// Search keys shared with tools/pack/text.py: a query in Devanagari, Kannada
/// script, IAST or plain English folds to the same plain-ASCII key, which is
/// what the pack indexes (plan §6.9). Fixtures in
/// tools/tests/fixtures/ascii_keys.json keep the two in step.
library;

const _virama = 0x094D; // Kannada ್ maps here too

// Shared offsets: Kannada = Devanagari + 0x0380 for the letters used here.
const _vowels = {
  0x0905: 'a',
  0x0906: 'ā',
  0x0907: 'i',
  0x0908: 'ī',
  0x0909: 'u',
  0x090A: 'ū',
  0x090B: 'ṛ',
  0x0960: 'ṝ',
  0x090C: 'ḷ',
  0x090E: 'e',
  0x090F: 'e',
  0x0910: 'ai',
  0x0912: 'o',
  0x0913: 'o',
  0x0914: 'au',
};
const _signs = {
  0x093E: 'ā',
  0x093F: 'i',
  0x0940: 'ī',
  0x0941: 'u',
  0x0942: 'ū',
  0x0943: 'ṛ',
  0x0944: 'ṝ',
  0x0946: 'e',
  0x0947: 'e',
  0x0948: 'ai',
  0x094A: 'o',
  0x094B: 'o',
  0x094C: 'au',
};
const _consonants = {
  0x0915: 'k',
  0x0916: 'kh',
  0x0917: 'g',
  0x0918: 'gh',
  0x0919: 'ṅ',
  0x091A: 'c',
  0x091B: 'ch',
  0x091C: 'j',
  0x091D: 'jh',
  0x091E: 'ñ',
  0x091F: 'ṭ',
  0x0920: 'ṭh',
  0x0921: 'ḍ',
  0x0922: 'ḍh',
  0x0923: 'ṇ',
  0x0924: 't',
  0x0925: 'th',
  0x0926: 'd',
  0x0927: 'dh',
  0x0928: 'n',
  0x092A: 'p',
  0x092B: 'ph',
  0x092C: 'b',
  0x092D: 'bh',
  0x092E: 'm',
  0x092F: 'y',
  0x0930: 'r',
  0x0932: 'l',
  0x0933: 'ḷ',
  0x0935: 'v',
  0x0936: 'ś',
  0x0937: 'ṣ',
  0x0938: 's',
  0x0939: 'h',
};
const _other = {0x0902: 'ṃ', 0x0903: 'ḥ', 0x0901: 'm̐', 0x093D: "'", 0x0964: '|', 0x0965: '||'};

int? _toDeva(int c) {
  if (c >= 0x0900 && c <= 0x097F) return c;
  if (c >= 0x0C80 && c <= 0x0CFF) return c - 0x0380;
  return null;
}

/// Devanagari or Kannada script to IAST; other characters pass through.
String indicToIast(String input) {
  final out = StringBuffer();
  final runes = input.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final c = runes[i];
    final d = _toDeva(c);
    if (d == null) {
      out.writeCharCode(c);
      continue;
    }
    if (_consonants.containsKey(d)) {
      out.write(_consonants[d]);
      final next = i + 1 < runes.length ? _toDeva(runes[i + 1]) : null;
      if (next != null && _signs.containsKey(next)) {
        out.write(_signs[next]);
        i++;
      } else if (next == _virama) {
        i++;
      } else {
        out.write('a');
      }
    } else if (_vowels.containsKey(d)) {
      out.write(_vowels[d]);
    } else if (_other.containsKey(d)) {
      out.write(_other[d]);
    } else if (d >= 0x0966 && d <= 0x096F) {
      out.write(d - 0x0966);
    }
  }
  return out.toString();
}

const _anusvara = [('kg', 'ṅ'), ('cj', 'ñ'), ('ṭḍ', 'ṇ'), ('td', 'n'), ('pb', 'm')];

const _fold = {
  'ā': 'a',
  'ī': 'i',
  'ū': 'u',
  'ṛ': 'r',
  'ṝ': 'r',
  'ḷ': 'l',
  'ṃ': 'm',
  'ḥ': 'h',
  'ṅ': 'n',
  'ñ': 'n',
  'ṭ': 't',
  'ḍ': 'd',
  'ṇ': 'n',
  'ś': 's',
  'ṣ': 's',
  'ē': 'e',
  'ō': 'o',
  'é': 'e',
  'è': 'e',
  'á': 'a',
  'à': 'a',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ö': 'o',
  'ç': 'c',
};

/// Plain-ASCII key, identical to `any_script_key` in tools/pack/text.py.
String asciiKey(String input) {
  var s = indicToIast(input).toLowerCase();
  // Strip combining marks left by decomposed input (e.g. m̐).
  s = s.replaceAll(RegExp('[̀-ͯ]'), '');
  for (final (stops, nasal) in _anusvara) {
    s = s.replaceAllMapped(RegExp('ṃ(?=[$stops])'), (_) => nasal);
  }
  final out = StringBuffer();
  for (final ch in s.split('')) {
    out.write(_fold[ch] ?? ch);
  }
  return out.toString().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim().replaceAll(RegExp(' +'), ' ');
}

/// An FTS5 query matching every word of [input] as a prefix, in the text or the keys.
String ftsQuery(String input) {
  final words = asciiKey(input).split(' ').where((w) => w.isNotEmpty);
  if (words.isEmpty) return '';
  return '{text keys}: ${words.map((w) => '"$w"*').join(' ')}';
}
