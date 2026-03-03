import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/word_entry.dart';
import 'services/library_service.dart';
import 'services/update_service.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LibraryService.instance.initFromAsset();
  runApp(const WordsForNerdsApp());
}

/// Session-only memory (clears when the OS kills the app / user closes it).
class SessionState {
  static final List<String> history = <String>[];
  static String? lastWord;

  // Randomizer settings (default on app launch)
  static int minLen = 1;
  static int maxLen = 45;

  // Letter filter: if empty => all letters allowed.
  // If user selects multiple letters => word must contain ALL selected letters (AND).
  static final Set<String> requiredLetters = <String>{};
}

class WordsForNerdsApp extends StatelessWidget {
  const WordsForNerdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDS FOR NERDS',
      debugShowCheckedModeBanner: true,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Times New Roman',
        scaffoldBackgroundColor: _Colors.bg,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LaunchScreen(),
    );
  }
}

/* ----------------------------- VISUAL CONSTANTS ---------------------------- */

class _Colors {
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
  final len = 14 + _rng.nextInt(10); // 14..23
  return List.filled(len, '_').join();
}

TextStyle _titleStyle() => const TextStyle(
      fontSize: 34,
      letterSpacing: 1.2,
      color: _Colors.text,
      fontWeight: FontWeight.w500,
    );

TextStyle _underlineStyle() => const TextStyle(
      fontSize: 14,
      letterSpacing: 1.0,
      color: _Colors.muted,
    );

TextStyle _sectionHeaderStyle() => const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _Colors.text,
      letterSpacing: 0.3,
    );

TextStyle _bodyStyle() => const TextStyle(
      fontSize: 18,
      height: 1.45,
      color: _Colors.text,
    );

TextStyle _mutedStyle() => const TextStyle(
      fontSize: 16,
      height: 1.35,
      color: _Colors.muted,
    );

/* --------------------------------- BUTTONS -------------------------------- */

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
            color: _Colors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Colors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 2),
                color: Colors.black26,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _Colors.accent,
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
          color: _Colors.accent,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/* ---------------------------------- FRAME --------------------------------- */
/*
  This is the universal layout fix:

  - All content scrolls (so no overflow on small phones).
  - CLOSE APP sits in a dedicated bottom-right strip OUTSIDE the scroll area
    (so it never covers your bottom buttons).
*/

class _Frame extends StatelessWidget {
  final String title;
  final String underlineText;
  final String? face;
  final List<Widget> children;

  final bool showCloseApp;
  final VoidCallback? onCloseApp;

  const _Frame({
    required this.title,
    required this.underlineText,
    required this.children,
    this.face,
    this.showCloseApp = true,
    this.onCloseApp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
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

            // Fixed bottom-right Close App strip (prevents overlap)
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
                      onTap: onCloseApp ??
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

/* ------------------------------- LAUNCH SCREEN ------------------------------ */

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  late final String _face;
  late final String _quote;

  static const _launchFaces = <String>[
    '(≧▽≦)',
    '(＾▽＾)',
    '(•‿•)',
    '(¬‿¬)',
    '(ง’̀-’̀)ง',
    '(ᵔᴥᵔ)',
  ];

  static const _launchQuotes = <String>[
    '"Lexical evolution is a strange little mirror."',
    '"Words are small machines for moving thought."',
    '"Vocabulary grows where curiosity lingers."',
    '"A single syllable can change a whole mood."',
    '"Meaning is slippery; that is why this is fun."',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_launchFaces);
    _quote = _pick(_launchQuotes);
  }

  void _goWord(BuildContext context) {
    final w = _pickRandomAllowedWord();
    if (w == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
      return;
    }
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
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

  Future<void> _openSettings(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  Future<void> _openUpdate(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateWordLibraryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'WORDS FOR NERDS',
      underlineText: _underline(),
      face: _face,
      children: [
        Center(child: Text(_quote, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 22),

        _Btn('CLICK HERE FOR A RANDOM WORD', onTap: () => _goWord(context)),
        const SizedBox(height: 16),

        _Btn('CLICK HERE TO SEARCH FOR A WORD', onTap: () => _search(context)),
        const SizedBox(height: 16),

        _Btn('RANDOMIZER SETTINGS', onTap: () => _openSettings(context)),
        const SizedBox(height: 16),

        FutureBuilder<String>(
          future: LibraryService.instance.lastUpdatedLabel(),
          builder: (context, snap) {
            final raw = snap.data ?? 'Bundled';
            final nice = _prettyIsoOrBundled(raw);
            return _Btn(
              'UPDATE WORD LIBRARY (LAST: $nice)',
              onTap: () => _openUpdate(context),
            );
          },
        ),
      ],
    );
  }
}

String _prettyIsoOrBundled(String raw) {
  if (raw == 'Bundled') return 'BUNDLED';
  // raw is ISO like 2026-03-03T...
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw.toUpperCase();
}

/* ------------------------------- WORD SCREEN ------------------------------- */

class WordScreen extends StatefulWidget {
  final String word;
  const WordScreen({super.key, required this.word});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> with RouteAware {
  static const MethodChannel _tts = MethodChannel('words_for_nerds/tts');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r is PageRoute) routeObserver.subscribe(this, r);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      final ok = await _tts.invokeMethod<bool>('speak', {'text': text});
      if (ok != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-speech unavailable on this device.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text-to-speech unavailable on this device.')),
      );
    }
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

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openHistory(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final WordEntry? entry = LibraryService.instance.lookup(widget.word);
    final title = widget.word.toUpperCase();

    return _Frame(
      title: title,
      underlineText: _underline(),
      children: [
        _Btn('LISTEN TO WORD', onTap: () => _speak(title)),
        const SizedBox(height: 22),

        Text('DICTIONARY', style: _sectionHeaderStyle()),
        const SizedBox(height: 6),
        Text(entry?.dictionary ?? 'Offline library', style: _bodyStyle()),
        const SizedBox(height: 16),

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

/* ---------------------------- RANDOMIZER SETTINGS --------------------------- */

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
    '(¬‿¬ )',
    '(ಠ_ಠ)',
    '(︶︹︺)',
  ];

  static const _quotes = <String>[
    '"Constraint is a polite form of power."',
    '"You are not limited; the letters are."',
    '"Narrow the gate. Watch the mind complain."',
    '"Your rules, your reality, your vocabulary."',
    '"Reduce the pool. Increase the surprise."',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _quote = _pick(_quotes);
  }

  void _bumpMin(int delta) {
    setState(() {
      SessionState.minLen = (SessionState.minLen + delta).clamp(1, 45);
      if (SessionState.minLen > SessionState.maxLen) {
        SessionState.maxLen = SessionState.minLen;
      }
    });
  }

  void _bumpMax(int delta) {
    setState(() {
      SessionState.maxLen = (SessionState.maxLen + delta).clamp(1, 45);
      if (SessionState.maxLen < SessionState.minLen) {
        SessionState.minLen = SessionState.maxLen;
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
      underlineText: _underline(),
      face: _face,
      children: [
        Center(child: Text(_quote, style: _mutedStyle(), textAlign: TextAlign.center)),
        const SizedBox(height: 22),

        Text('MIN LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        _minMaxRow(SessionState.minLen, onMinus: () => _bumpMin(-1), onPlus: () => _bumpMin(1)),
        const SizedBox(height: 18),

        Text('MAX LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        _minMaxRow(SessionState.maxLen, onMinus: () => _bumpMax(-1), onPlus: () => _bumpMax(1)),
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
                  color: on ? _Colors.panel2 : _Colors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: on ? _Colors.accent : _Colors.border),
                ),
                child: Text(
                  ch,
                  style: TextStyle(
                    color: on ? _Colors.accent : _Colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
        Expanded(
          child: _Btn('-', onTap: onMinus, small: true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _Colors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Colors.border),
            ),
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 18, color: _Colors.text),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Btn('+', onTap: onPlus, small: true),
        ),
      ],
    );
  }
}

/* --------------------------------- HISTORY -------------------------------- */

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
      underlineText: _underline(),
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
            color: _Colors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Colors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: _Colors.accent, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------- CLEAR HISTORY CONFIRM -------------------------- */

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
    '(ಠ_ಠ;)',
    '(；￣Д￣)',
    '(°ロ°)',
    '(╯°□°）╯',
    '(；´ﾟдﾟ)',
  ];

  static const _phrases = <String>[
    'Erase everything you have conjured?',
    'Incinerate your lexical trail?',
    'Annihilate this session’s footprints?',
    'Turn your history into mist?',
    'Commit a tidy little obliteration?',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  Future<void> _confirmClear() async {
    SessionState.history.clear();
    SessionState.lastWord = null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final zenFace = _pick(const ['(－‿－)', '(＿ ＿)', '(￣ー￣)', '( ˘‿˘ )']);
        final msg = _pick(const [
          'History dissolved into dignified nothingness.',
          'The archive has vanished with exquisite calm.',
          'All prior words now reside in pure silence.',
          'Your trail is gone; the mind feels lighter.',
        ]);
        return AlertDialog(
          backgroundColor: _Colors.panel2,
          title: Center(child: Text(zenFace, style: _mutedStyle())),
          content: Text(
            msg,
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OKAY', style: TextStyle(color: _Colors.accent)),
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
      underlineText: _underline(),
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

/* --------------------------- NO MORE WORDS SCREEN -------------------------- */

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
    'The generator has exhausted its available universe.',
    'All eligible words have been politely consumed.',
    'Nothing remains inside the current constraints.',
    'The pool is empty; the silence is real.',
    'No more words fit your present rules.',
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
    if (w == null) return; // still none
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'NO MORE WORDS AVAILABLE',
      underlineText: _underline(),
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

/* ---------------------------- WORD NOT FOUND SCREEN ------------------------ */

class WordNotFoundScreen extends StatefulWidget {
  final String typed;
  const WordNotFoundScreen({super.key, required this.typed});

  @override
  State<WordNotFoundScreen> createState() => _WordNotFoundScreenState();
}

class _WordNotFoundScreenState extends State<WordNotFoundScreen> {
  int page = 0;
  static const int perPage = 5;

  List<String> get _suggestions => LibraryService.instance.suggestSmart(widget.typed, limit: 40);

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
      underlineText: _underline(),
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
              _navBtn('<', enabled: page > 0, onTap: () => setState(() => page--)),
              const SizedBox(width: 14),
              _navBtn('>', enabled: page < maxPage, onTap: () => setState(() => page++)),
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
            color: _Colors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Colors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: _Colors.accent, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ CLOSE APP SCREEN --------------------------- */

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
    '(︶︹︺)',
    '(´-﹏-`)',
  ];

  static const _phrases = <String>[
    'May your next thought be kinder than your last typo.',
    'Until you return, may your mind keep its curious glow.',
    'Go gently. The words will wait.',
    'If you miss us, we will pretend we didn’t.',
    'Depart with dignity; return with vocabulary.',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  void _reallyClose() {
    // Clear session-only history on intentional close.
    SessionState.history.clear();
    SessionState.lastWord = null;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLOSE APP',
      underlineText: _underline(),
      face: _face,
      // Close button should still be uniform bottom-right like all screens.
      showCloseApp: true,
      onCloseApp: _reallyClose,
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

/* -------------------------- UPDATE WORD LIBRARY FLOW ------------------------ */

class UpdateWordLibraryScreen extends StatefulWidget {
  const UpdateWordLibraryScreen({super.key});

  @override
  State<UpdateWordLibraryScreen> createState() => _UpdateWordLibraryScreenState();
}

class _UpdateWordLibraryScreenState extends State<UpdateWordLibraryScreen> {
  late final String _face;

  static const _curiousFaces = <String>[
    '(•_•)',
    '( •_•)>⌐■-■',
    '(¬‿¬)',
    '(ಠ‿ಠ)',
    '(￣ー￣)',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_curiousFaces);
  }

  void _begin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UpdateInProgressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE WORD LIBRARY',
      underlineText: _underline(),
      face: _face,
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
        _Btn('PROCEED', onTap: _begin),
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

  static const _downloadPhrases = <String>[
    'Summoning fresh lexicon from the void…',
    'Polishing definitions until they shine…',
    'Rearranging your universe of words…',
    'Unfolding a new chapter of syllables…',
    'Installing vocabulary with suspicious enthusiasm…',
  ];

  @override
  void initState() {
    super.initState();
    _phrase = _pick(_downloadPhrases);
    _run();
  }

  Future<void> _run() async {
    final res = await UpdateService().runUpdatePlaceholder();
    if (!mounted) return;

    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateCompleteScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateFailedScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'DOWNLOADING & INSTALLING WORDS',
      underlineText: _underline(),
      // No CLOSE APP button on the in-progress screen.
      showCloseApp: false,
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
      underlineText: _underline(),
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
  const UpdateFailedScreen({super.key});

  @override
  State<UpdateFailedScreen> createState() => _UpdateFailedScreenState();
}

class _UpdateFailedScreenState extends State<UpdateFailedScreen> {
  late final String _phrase;

  static const _phrases = <String>[
    'The update stumbled dramatically and then pretended it meant to.',
    'Your library remained intact, despite the universe’s brief chaos.',
    'We tried. The internet shrugged. The words stayed safe.',
    'A splendid failure occurred. Nothing was harmed. Probably.',
    'The download evaporated. Your existing library stands unbothered.',
  ];

  @override
  void initState() {
    super.initState();
    _phrase = _pick(_phrases);
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE DIDN’T WORK',
      underlineText: _underline(),
      children: [
        Center(child: Text(_phrase, style: _mutedStyle(), textAlign: TextAlign.center)),
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

/* ------------------------- SEARCH PROMPT + GENERATOR ------------------------ */

Future<String?> _promptForWord(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: _Colors.panel2,
        title: const Text('SEARCH FOR A WORD', style: TextStyle(color: _Colors.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: _Colors.text),
          decoration: const InputDecoration(
            hintText: 'Type a word',
            hintStyle: TextStyle(color: _Colors.muted),
          ),
          onSubmitted: (_) {
            Navigator.of(ctx).pop(controller.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('CANCEL', style: TextStyle(color: _Colors.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('SEARCH', style: TextStyle(color: _Colors.accent)),
          ),
        ],
      );
    },
  );
}

String? _pickRandomAllowedWord() {
  final words = LibraryService.instance.allWordsSorted(); // already sorted
  if (words.isEmpty) return null;

  final req = SessionState.requiredLetters;
  final minLen = SessionState.minLen;
  final maxLen = SessionState.maxLen;

  final candidates = <String>[];
  for (final w in words) {
    if (SessionState.history.contains(w)) continue;
    if (w.length < minLen || w.length > maxLen) continue;

    // AND letter filter: must include all selected letters.
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
