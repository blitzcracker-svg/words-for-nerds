// lib/main.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/word_entry.dart';
import 'services/library_service.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LibraryService.instance.initFromAsset();
  runApp(const WordsForNerdsApp());
}

/* ----------------------------- Session State ----------------------------- */

class SessionState {
  static final List<String> history = <String>[];
  static String? lastWord;

  static int minLetters = 1;
  static int maxLetters = 45;

  // AND filter: word must contain ALL selected letters
  static final Set<String> requiredLetters = <String>{};

  static void clearHistoryOnly() {
    history.clear();
    lastWord = null;
  }
}

/* ----------------------------- Theme + Helpers ---------------------------- */

class _Theme {
  static const bg = Color(0xFF0B0C10);
  static const panel = Color(0xFF161821);
  static const panel2 = Color(0xFF12141B);
  static const border = Color(0xFF242837);

  static const text = Color(0xFFEDEDED);
  static const muted = Color(0xFFB8B8B8);

  static const accent = Color(0xFFB06B6B); // burgundy-ish
}

final Random _rng = Random();

String _pick(List<String> xs) => xs[_rng.nextInt(xs.length)];

String _underline() {
  const chars = ['_', '-', '─'];
  final len = 18 + _rng.nextInt(10); // 18..27
  final ch = chars[_rng.nextInt(chars.length)];
  return List.filled(len, ch).join();
}

TextStyle _titleStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 34,
      letterSpacing: 1.2,
      color: _Theme.text,
      fontWeight: FontWeight.w500,
    );

TextStyle _underlineStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 14,
      letterSpacing: 1.0,
      color: _Theme.muted,
    );

TextStyle _sectionHeaderStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: _Theme.text,
      letterSpacing: 0.3,
    );

TextStyle _bodyStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      height: 1.45,
      color: _Theme.text,
    );

TextStyle _mutedStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 16,
      height: 1.35,
      color: _Theme.muted,
    );

/* -------------------------------- Buttons -------------------------------- */

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool small;
  final bool enabled;

  const _Btn(
    this.label, {
    required this.onTap,
    this.small = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = enabled ? onTap : null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: small ? 14 : 18,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: _Theme.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Theme.border, width: 1),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: _Theme.accent,
                fontSize: small ? 16 : 18,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _InlineLink(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Times New Roman',
          color: _Theme.accent,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/* --------------------------------- Frame --------------------------------- */
/*
  - All content scrolls (no overflow on small phones)
  - CLOSE APP is fixed bottom-right and never covers content
*/

class _Frame extends StatelessWidget {
  final String title;
  final String? face;
  final List<Widget> children;

  final bool showCloseApp;
  final VoidCallback? onCloseTap;

  const _Frame({
    required this.title,
    required this.children,
    this.face,
    this.showCloseApp = true,
    this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    final underlineText = _underline();

    return Scaffold(
      backgroundColor: _Theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Text(title, style: _titleStyle())),
                    const SizedBox(height: 8),
                    Center(child: Text(underlineText, style: _underlineStyle())),
                    if (face != null) ...[
                      const SizedBox(height: 14),
                      Center(child: Text(face!, style: _mutedStyle())),
                    ],
                    const SizedBox(height: 18),
                    ...children,
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (showCloseApp)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 170,
                    child: _Btn(
                      'CLOSE APP',
                      small: true,
                      onTap: onCloseTap ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CloseAppScreen()),
                            );
                          },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------------------- App ---------------------------------- */

class WordsForNerdsApp extends StatelessWidget {
  const WordsForNerdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDS FOR NERDS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Times New Roman',
        scaffoldBackgroundColor: _Theme.bg,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LaunchScreen(),
    );
  }
}

/* ------------------------------ Launch Screen ----------------------------- */

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  late final String _face;
  late final String _greeting;

  static const _faces = <String>[
    '(≧▽≦)',
    '(＾▽＾)',
    '(•‿•)',
    '(ﾉﾟ▽ﾟ)ﾉ',
    '(•̀ᴗ•́)و',
    '(｀▽´)',
  ];

  static const _greetings = <String>[
    'HELLO, LEXICON PILGRIM.',
    'GREETINGS, SYLLABLE COLLECTOR.',
    'WELCOME TO THE WORD-REALM.',
    'AH. YOU HAVE ARRIVED, VERBALLY.',
    'ENTER, FRIEND OF NUANCE.',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _greeting = _pick(_greetings);
  }

  void _goRandomWord() {
    final w = _pickRandomAllowedWord();
    if (w == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
      return;
    }

    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);

    Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  Future<void> _searchForWord() async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    if (upper.isEmpty) return;

    final entry = LibraryService.instance.lookup(upper);
    if (entry != null) {
      SessionState.lastWord = entry.word;
      if (!SessionState.history.contains(entry.word)) SessionState.history.add(entry.word);
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openUpdate() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateWordLibraryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'WORDS FOR NERDS',
      face: _face,
      children: [
        Center(child: Text(_greeting, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 22),

        _Btn('CLICK HERE FOR A RANDOM WORD', onTap: _goRandomWord),
        const SizedBox(height: 16),

        _Btn('CLICK HERE TO SEARCH FOR A WORD', onTap: _searchForWord),
        const SizedBox(height: 16),

        _Btn('RANDOMIZER SETTINGS', onTap: _openSettings),
        const SizedBox(height: 16),

        FutureBuilder<String>(
          future: LibraryService.instance.lastUpdatedLabel(),
          builder: (context, snap) {
            final raw = (snap.data ?? 'Bundled').trim();
            final label = _prettyDate(raw);
            return _Btn('UPDATE WORD LIBRARY (LAST: $label)', onTap: _openUpdate);
          },
        ),
      ],
    );
  }
}

String _prettyDate(String raw) {
  if (raw.isEmpty) return 'BUNDLED';
  if (raw.toLowerCase() == 'bundled') return 'BUNDLED';
  // if ISO date-time, show YYYY-MM-DD
  if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') return raw.substring(0, 10);
  return raw.toUpperCase();
}

/* ------------------------------- Word Screen ------------------------------ */

class WordScreen extends StatelessWidget {
  final String word;
  const WordScreen({super.key, required this.word});

  static const MethodChannel _tts = MethodChannel('words_for_nerds/tts');

  Future<void> _speak(BuildContext context, String text) async {
    try {
      final ok = await _tts.invokeMethod<bool>('speak', {'text': text});
      if (ok != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-speech unavailable on this device.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text-to-speech unavailable on this device.')),
      );
    }
  }

  void _newRandomWord(BuildContext context) {
    final w = _pickRandomAllowedWord();
    if (w == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
      return;
    }

    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openHistory(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  Future<void> _search(BuildContext context) async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    if (upper.isEmpty) return;

    final entry = LibraryService.instance.lookup(upper);
    if (entry != null) {
      SessionState.lastWord = entry.word;
      if (!SessionState.history.contains(entry.word)) SessionState.history.add(entry.word);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final WordEntry? entry = LibraryService.instance.lookup(word);
    final String title = word.toUpperCase();

    return _Frame(
      title: title,
      children: [
        _Btn('LISTEN TO WORD', onTap: () => _speak(context, title)),
        const SizedBox(height: 22),

        Text('PHONETIC PRONUNCIATION', style: _sectionHeaderStyle()),
        const SizedBox(height: 6),
        Text(entry?.phonetic ?? '(not available)', style: _bodyStyle()),
        const SizedBox(height: 16),

        Text('DEFINITION', style: _sectionHeaderStyle()),
        const SizedBox(height: 6),
        Text(entry?.definition ?? '(not available)', style: _bodyStyle()),
        const SizedBox(height: 16),

        Text('ETYMOLOGY', style: _sectionHeaderStyle()),
        const SizedBox(height: 6),
        Text(entry?.etymology ?? '(not available)', style: _bodyStyle()),
        const SizedBox(height: 16),

        Text('EXAMPLE', style: _sectionHeaderStyle()),
        const SizedBox(height: 6),
        Text(entry?.example ?? '(not available)', style: _bodyStyle()),
        const SizedBox(height: 26),

        _Btn('NEW RANDOM WORD', onTap: () => _newRandomWord(context)),
        const SizedBox(height: 14),

        _Btn('RANDOMIZER SETTINGS', onTap: () => _openSettings(context)),
        const SizedBox(height: 14),

        _Btn('HISTORY', onTap: () => _openHistory(context)),
        const SizedBox(height: 14),

        _Btn('SEARCH FOR A WORD', onTap: () => _search(context)),
      ],
    );
  }
}

/* -------------------------- Randomizer Settings Screen -------------------------- */

class RandomizerSettingsScreen extends StatefulWidget {
  const RandomizerSettingsScreen({super.key});

  @override
  State<RandomizerSettingsScreen> createState() => _RandomizerSettingsScreenState();
}

class _RandomizerSettingsScreenState extends State<RandomizerSettingsScreen> {
  late final String _face;
  late final String _quote;

  static const _faces = <String>[
    '( -_- )',
    '( •_• )',
    '(¬_¬ )',
    '(￣ー￣)',
    '(ー_ー)',
    '(ಠ_ಠ)',
  ];

  static const _quotes = <String>[
    '"Constraint is a polite form of power."',
    '"Tiny toggles, colossal consequences."',
    '"Select letters. Summon outcomes."',
    '"Narrow the gate. Watch the mind complain."',
    '"Boundaries are funny. Words hop fences."',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _quote = _pick(_quotes);
  }

  void _bumpMin(int delta) {
    setState(() {
      SessionState.minLetters = (SessionState.minLetters + delta).clamp(1, 45);
      if (SessionState.minLetters > SessionState.maxLetters) {
        SessionState.maxLetters = SessionState.minLetters;
      }
    });
  }

  void _bumpMax(int delta) {
    setState(() {
      SessionState.maxLetters = (SessionState.maxLetters + delta).clamp(1, 45);
      if (SessionState.maxLetters < SessionState.minLetters) {
        SessionState.minLetters = SessionState.maxLetters;
      }
    });
  }

  void _toggleLetter(String ch) {
    setState(() {
      if (SessionState.requiredLetters.contains(ch)) {
        SessionState.requiredLetters.remove(ch);
      } else {
        SessionState.requiredLetters.add(ch);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final letters = List.generate(26, (i) => String.fromCharCode(65 + i));

    return _Frame(
      title: 'RANDOMIZER SETTINGS',
      face: _face,
      children: [
        Center(child: Text(_quote, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 22),

        Text('MIN LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        _minMaxRow(SessionState.minLetters, onMinus: () => _bumpMin(-1), onPlus: () => _bumpMin(1)),
        const SizedBox(height: 18),

        Text('MAX LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        _minMaxRow(SessionState.maxLetters, onMinus: () => _bumpMax(-1), onPlus: () => _bumpMax(1)),
        const SizedBox(height: 22),

        Text('LETTER FILTER', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: letters.map((ch) {
            final on = SessionState.requiredLetters.contains(ch);
            return InkWell(
              onTap: () => _toggleLetter(ch),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? _Theme.panel2 : _Theme.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: on ? _Theme.accent : _Theme.border),
                ),
                child: Text(
                  ch,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: on ? _Theme.accent : _Theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 26),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _minMaxRow(int value, {required VoidCallback onMinus, required VoidCallback onPlus}) {
    return Row(
      children: [
        Expanded(child: _Btn('-', onTap: onMinus, small: true)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _Theme.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Theme.border),
            ),
            child: Center(child: Text('$value', style: _bodyStyle())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _Btn('+', onTap: onPlus, small: true)),
      ],
    );
  }
}

/* -------------------------------- History Screen ------------------------------- */

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int page = 0;
  static const int perPage = 5;

  List<String> get _sorted {
    final xs = SessionState.history.toList();
    xs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return xs;
  }

  int get maxPage {
    final count = _sorted.length;
    if (count <= perPage) return 0;
    return ((count - 1) / perPage).floor();
  }

  void _openWord(String w) {
    SessionState.lastWord = w;
    Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _clearHistoryConfirm() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClearHistoryConfirmScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final xs = _sorted;
    final start = page * perPage;
    final end = min(start + perPage, xs.length);
    final view = (start < xs.length) ? xs.sublist(start, end) : <String>[];

    return _Frame(
      title: 'HISTORY',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _navBtn('<', enabled: page > 0, onTap: () => setState(() => page--)),
            const SizedBox(width: 14),
            _navBtn('>', enabled: page < maxPage, onTap: () => setState(() => page++)),
          ],
        ),
        const SizedBox(height: 18),

        if (view.isEmpty)
          Center(child: Text('No history yet.', style: _mutedStyle()))
        else
          ...view.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Btn(w, onTap: () => _openWord(w), small: true),
              )),

        const SizedBox(height: 18),
        _Btn('CLEAR HISTORY', onTap: _clearHistoryConfirm),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _navBtn(String label, {required bool enabled, required VoidCallback onTap}) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 54,
          height: 44,
          decoration: BoxDecoration(
            color: _Theme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Theme.border),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                color: _Theme.accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------- Clear History Confirm Screen ---------------------- */

class ClearHistoryConfirmScreen extends StatefulWidget {
  const ClearHistoryConfirmScreen({super.key});

  @override
  State<ClearHistoryConfirmScreen> createState() => _ClearHistoryConfirmScreenState();
}

class _ClearHistoryConfirmScreenState extends State<ClearHistoryConfirmScreen> {
  late final String _face;
  late final String _phrase;

  static const _faces = <String>[
    '(⊙_⊙;)',
    '(；ﾟДﾟ)',
    '(°ロ°)',
    '(╯°□°）╯',
    '(；￣Д￣)',
    '(>_<)',
  ];

  static const _phrases = <String>[
    'Erase your history?',
    'Delete the lexical trail?',
    'Obliterate the record?',
    'Vanish the archive?',
    'Remove every prior generation?',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  Future<void> _confirmClear() async {
    SessionState.clearHistoryOnly();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final zenFace = _pick(const ['(－‿－)', '(￣ー￣)', '( ˘‿˘ )', '( ᵕ‿ᵕ )']);
        final msg = _pick(const [
          'History dissolved into elegant silence.',
          'The archive has been politely unmade.',
          'All prior words have been erased with decorum.',
          'A clean slate has been achieved.',
        ]);
        return AlertDialog(
          backgroundColor: _Theme.panel2,
          title: Center(child: Text(zenFace, style: _mutedStyle())),
          content: Text(msg, style: _bodyStyle(), textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OKAY', style: TextStyle(fontFamily: 'Times New Roman', color: _Theme.accent)),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LaunchScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLEAR HISTORY',
      face: _face,
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Are you sure you want to erase all words generated in this session?',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _Btn('YES, CLEAR HISTORY', onTap: _confirmClear),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/* --------------------------- No More Words Screen -------------------------- */

class NoMoreWordsScreen extends StatefulWidget {
  const NoMoreWordsScreen({super.key});

  @override
  State<NoMoreWordsScreen> createState() => _NoMoreWordsScreenState();
}

class _NoMoreWordsScreenState extends State<NoMoreWordsScreen> {
  late final String _face;
  late final String _phrase;

  static const _faces = <String>[
    '(╥﹏╥)',
    '(；＿；)',
    '(ಥ﹏ಥ)',
    '(︶︹︺)',
    '(；-；)',
    '(T_T)',
  ];

  static const _phrases = <String>[
    'No more words fit your current rules.',
    'The generator found nothing under these constraints.',
    'The pool is empty under the present settings.',
    'All eligible words have been exhausted.',
    'Nothing remains inside the current constraints.',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  void _returnToLastWord() {
    final w = SessionState.lastWord;
    if (w == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  Future<void> _search(BuildContext context) async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    if (upper.isEmpty) return;

    final entry = LibraryService.instance.lookup(upper);
    if (entry != null) {
      SessionState.lastWord = entry.word;
      if (!SessionState.history.contains(entry.word)) SessionState.history.add(entry.word);
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  void _newRandomWord(BuildContext context) {
    final w = _pickRandomAllowedWord();
    if (w == null) return;
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'NO MORE WORDS AVAILABLE',
      face: _face,
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text('Try adjusting your ', style: _mutedStyle()),
            _InlineLink('Settings', onTap: _openSettings),
            Text(' or clearing your ', style: _mutedStyle()),
            _InlineLink('History', onTap: _openHistory),
            Text(' to generate more words!', style: _mutedStyle()),
          ],
        ),
        const SizedBox(height: 22),

        _Btn('RETURN TO LAST WORD', onTap: _returnToLastWord),
        const SizedBox(height: 14),
        _Btn('NEW RANDOM WORD', onTap: () => _newRandomWord(context)),
        const SizedBox(height: 14),
        _Btn('SEARCH FOR A WORD', onTap: () => _search(context)),
      ],
    );
  }
}

/* ---------------------------- Word Not Found Screen ------------------------ */

class WordNotFoundScreen extends StatefulWidget {
  final String typed;
  const WordNotFoundScreen({super.key, required this.typed});

  @override
  State<WordNotFoundScreen> createState() => _WordNotFoundScreenState();
}

class _WordNotFoundScreenState extends State<WordNotFoundScreen> {
  int page = 0;
  static const int perPage = 5;

  List<String> get _suggestions => LibraryService.instance.suggest(widget.typed, limit: 40);

  int get maxPage {
    final count = _suggestions.length;
    if (count <= perPage) return 0;
    return ((count - 1) / perPage).floor();
  }

  void _openSuggestion(String w) {
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _newRandomWord(BuildContext context) {
    final w = _pickRandomAllowedWord();
    if (w == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
      return;
    }
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  Future<void> _returnToSearch(BuildContext context) async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    if (upper.isEmpty) return;

    final entry = LibraryService.instance.lookup(upper);
    if (entry != null) {
      SessionState.lastWord = entry.word;
      if (!SessionState.history.contains(entry.word)) SessionState.history.add(entry.word);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugg = _suggestions;
    final start = page * perPage;
    final end = min(start + perPage, sugg.length);
    final view = (start < sugg.length) ? sugg.sublist(start, end) : <String>[];

    return _Frame(
      title: 'WORD NOT FOUND',
      children: [
        Center(
          child: Text(
            'Sorry we didn’t find: ${widget.typed}',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        if (sugg.isNotEmpty) ...[
          Center(child: Text('Did you mean:', style: _sectionHeaderStyle())),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navSmall('<', enabled: page > 0, onTap: () => setState(() => page--)),
              const SizedBox(width: 14),
              _navSmall('>', enabled: page < maxPage, onTap: () => setState(() => page++)),
            ],
          ),
          const SizedBox(height: 14),
          ...view.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Btn(w, onTap: () => _openSuggestion(w), small: true),
              )),
          const SizedBox(height: 8),
        ],

        _Btn('RETURN TO SEARCH', onTap: () => _returnToSearch(context)),
        const SizedBox(height: 14),
        _Btn('NEW RANDOM WORD', onTap: () => _newRandomWord(context)),
        const SizedBox(height: 14),
        _Btn('RANDOMIZER SETTINGS', onTap: _openSettings),
        const SizedBox(height: 14),
        _Btn('HISTORY', onTap: _openHistory),
      ],
    );
  }

  Widget _navSmall(String label, {required bool enabled, required VoidCallback onTap}) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 54,
          height: 44,
          decoration: BoxDecoration(
            color: _Theme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Theme.border),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                color: _Theme.accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ Close App Screen --------------------------- */

class CloseAppScreen extends StatefulWidget {
  const CloseAppScreen({super.key});

  @override
  State<CloseAppScreen> createState() => _CloseAppScreenState();
}

class _CloseAppScreenState extends State<CloseAppScreen> {
  late final String _face;
  late final String _phrase;

  static const _faces = <String>[
    '(╯︵╰)',
    '(；_；)',
    '(｡•́︿•̀｡)',
    '(´-﹏-`)',
    '(︶︹︺)',
  ];

  static const _phrases = <String>[
    'Go gently. The words will wait.',
    'Depart with dignity; return with vocabulary.',
    'Until you return, may your mind keep its curious glow.',
    'May your next thought be kinder than your last typo.',
    'We will miss you in complete silence.',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  void _reallyClose() {
    // Clear session-only history on intentional close.
    SessionState.clearHistoryOnly();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLOSE APP',
      face: _face,
      onCloseTap: _reallyClose, // bottom-right CLOSE APP now closes for real
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Your word history will be cleared when you close the app.',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/* -------------------------- Update Word Library Flow ------------------------ */

class UpdateWordLibraryScreen extends StatelessWidget {
  const UpdateWordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final face = _pick(const ['(•_•)', '(¬‿¬)', '(ಠ‿ಠ)', '(￣ー￣)']);

    return _Frame(
      title: 'UPDATE WORD LIBRARY',
      face: face,
      children: [
        Center(
          child: Text(
            '[This is how you update this app’s word library.]',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'This can take a while depending on your connection.',
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        _Btn(
          'PROCEED',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UpdateInProgressScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class UpdateInProgressScreen extends StatefulWidget {
  const UpdateInProgressScreen({super.key});

  @override
  State<UpdateInProgressScreen> createState() => _UpdateInProgressScreenState();
}

class _UpdateInProgressScreenState extends State<UpdateInProgressScreen> {
  late final String _phrase;

  @override
  void initState() {
    super.initState();
    _phrase = _pick(const [
      'Summoning fresh lexicon…',
      'Polishing definitions…',
      'Rearranging syllables…',
      'Negotiating with the internet…',
      'Installing vocabulary…',
    ]);
    _run();
  }

  Future<void> _run() async {
    final res = await UpdateService.instance.runUpdate();
    if (!mounted) return;

    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateCompleteScreen()));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UpdateFailedScreen(message: res.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'DOWNLOADING & INSTALLING WORDS',
      showCloseApp: false, // only screen with no close app button
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class UpdateCompleteScreen extends StatelessWidget {
  const UpdateCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE COMPLETE',
      children: [
        Center(
          child: Text(
            'Update finished successfully.',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        _Btn(
          'OKAY',
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LaunchScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

class UpdateFailedScreen extends StatefulWidget {
  final String message;
  const UpdateFailedScreen({super.key, required this.message});

  @override
  State<UpdateFailedScreen> createState() => _UpdateFailedScreenState();
}

class _UpdateFailedScreenState extends State<UpdateFailedScreen> {
  late final String _phrase;

  @override
  void initState() {
    super.initState();
    _phrase = _pick(const [
      'The update stumbled dramatically and then pretended it meant to.',
      'The internet shrugged. Your library stayed safe.',
      'A splendid failure occurred. Nothing was harmed.',
      'The download evaporated. Your existing library stands unbothered.',
      'Your library refused to evolve right now.',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE DIDN’T WORK',
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: Text(widget.message, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 22),
        _Btn(
          'OKAY',
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LaunchScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

/* ------------------------------ Search Prompt ------------------------------ */

Future<String?> _promptForWord(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: _Theme.panel2,
        title: const Text(
          'SEARCH FOR A WORD',
          style: TextStyle(fontFamily: 'Times New Roman', color: _Theme.text),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontFamily: 'Times New Roman', color: _Theme.text),
          decoration: const InputDecoration(
            hintText: 'Type a word',
            hintStyle: TextStyle(fontFamily: 'Times New Roman', color: _Theme.muted),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('CANCEL', style: TextStyle(fontFamily: 'Times New Roman', color: _Theme.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('SEARCH', style: TextStyle(fontFamily: 'Times New Roman', color: _Theme.accent)),
          ),
        ],
      );
    },
  );
}

/* ---------------------------- Word Generator Logic ---------------------------- */

String? _pickRandomAllowedWord() {
  final words = LibraryService.instance.allWords;
  if (words.isEmpty) return null;

  final req = SessionState.requiredLetters;
  final minLen = SessionState.minLetters;
  final maxLen = SessionState.maxLetters;

  final candidates = <String>[];
  for (final w in words) {
    if (SessionState.history.contains(w)) continue;
    if (w.length < minLen || w.length > maxLen) continue;

    bool ok = true;
    for (final ch in req) {
      if (!w.contains(ch)) {
        ok = false;
        break;
      }
    }
    if (!ok) continue;

    candidates.add(w);
  }

  if (candidates.isEmpty) return null;
  return candidates[_rng.nextInt(candidates.length)];
}
