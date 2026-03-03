class WordEntry {
  final String word;
  final String phonetic;
  final String definition;
  final String etymology;
  final String example;

  const WordEntry({
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.etymology,
    required this.example,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v == null) ? '' : v.toString();

    return WordEntry(
      word: s(json['word']).trim().toUpperCase(),
      phonetic: s(json['phonetic']).trim(),
      definition: s(json['definition']).trim(),
      etymology: s(json['etymology']).trim(),
      example: s(json['example']).trim(),
    );
  }
}
