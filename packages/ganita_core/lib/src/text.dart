/// Text in both interface languages. Generated problems, method steps and
/// hints are written in English and Kannada (plan §5.4).
class LText {
  final String en;
  final String kn;

  const LText(this.en, this.kn);

  String of(String locale) => locale == 'kn' ? kn : en;

  /// Replaces `{name}` placeholders in both languages.
  LText fill(Map<String, Object> values) => LText(_fill(en, values), _fill(kn, values));

  static String _fill(String template, Map<String, Object> values) =>
      template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
        final v = values[m[1]];
        if (v == null) throw ArgumentError('No value for {${m[1]}} in "$template"');
        return '$v';
      });

  /// Joins two texts with a space in each language.
  LText operator +(LText other) => LText('$en ${other.en}', '$kn ${other.kn}');

  Map<String, String> toJson() => {'en': en, 'kn': kn};

  @override
  String toString() => en;

  @override
  bool operator ==(Object other) => other is LText && other.en == en && other.kn == kn;

  @override
  int get hashCode => Object.hash(en, kn);
}
