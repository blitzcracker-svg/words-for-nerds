class WordEntry {
  final String word;
  final String phonetic;
  final String definition;
  final String etymology;
  final String example;
  final String source;

  const WordEntry({
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.etymology,
    required this.example,
    required this.source,
  });

  factory WordEntry.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString().trim();
    return WordEntry(
      word: s(j['word']).toUpperCase(),
      phonetic: s(j['phonetic']),
      definition: s(j['definition']),
      etymology: s(j['etymology']),
      example: s(j['example']),
      source: s(j['source']).isEmpty ? 'Offline library' : s(j['source']),
    );
  }
}
