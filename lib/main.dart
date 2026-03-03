import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/word_entry.dart';
import 'services/library_service.dart';
import 'services/update_service.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LibraryService.instance.initFromAsset();
  runApp(const WordsForNerdsApp());
}

/// Session-only memory (clears when the OS kills the app / user closes it).
class SessionState {
  static final List<String> history = [];
  static String? lastWord;

  // Randomizer settings (default on app launch)
  static int minLen = 1;
  static int maxLen = 45;

  // Letter filter: if empty => all letters allowed.
  // If user selects multiple letters => word must contain ALL selected letters (AND).
  static final Set<String> requiredLetters = {};
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

String _pick<T>(List<T> xs) => xs[_rng.nextInt(xs.length)] as String;

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
      child: const Text(
        '',
        style: TextStyle(
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
  Universal layout fix:
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
                      onTap: onCloseApp ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CloseAppScreen()),
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

  static const _launchFaces = [
    '(≧▽≦)',
    '(＾▽＾)',
    '(•‿•)',
    '(¬‿¬)',
    '(ง’̀-’̀)ง',
    '(ᵔᴥᵔ)',
  ];

  static const _launchQuotes = [
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
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
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
      if (!SessionState.history.contains(entry.word)) {
        SessionState.history.add(entry.word);
      }
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openUpdate(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const UpdateWordLibraryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'WORDS FOR NERDS',
      underlineText: _underline(),
      face: _face,
      children: [
        Center(
            child: Text(_quote,
                style: _mutedStyle(), textAlign: TextAlign.center)),
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
      final ok = await _tts.invokeMethod('speak', {'text': text});
      if (ok != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Text-to-speech unavailable on this device.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Text-to-speech unavailable on this device.')),
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
      if (!SessionState.history.contains(entry.word)) {
        SessionState.history.add(entry.word);
      }
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _newRandomWord(BuildContext context) {
    final w = _pickRandomAllowedWord();
    if (w == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()));
      return;
    }
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
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
        // FIX: WordEntry model does not include a dictionary field.
        Text('Offline library', style: _bodyStyle()),
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
  State<RandomizerSettingsScreen> createState() =>
      _RandomizerSettingsScreenState();
}

class _RandomizerSettingsScreenState extends State<RandomizerSettingsScreen> {
  late final String _face;
  late final String _quote;

  static const _faces = [
    '( -_- )',
    '( •_• )',
    '(¬_¬ )',
    '(¬‿¬ )',
    '(ಠ_ಠ)',
    '(︶︹︺)',
  ];

  static const _quotes = [
    '"Constraint is a polite form of power."',
    '"You are not limited; the letters are."',
    '"Narrow the gate. Watch the mind complain."',
    '"Your rules, your reality, your vocabulary."',
    '"Reduce the pool. Enormous consequences."',
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

  void _toggleLetter(String letter) {
    setState(() {
      if (SessionState.requiredLetters.contains(letter)) {
        SessionState.requiredLetters.remove(letter);
      } else {
        SessionState.requiredLetters.add(letter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final letters = List<String>.generate(
      26,
      (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
    );

    return _Frame(
      title: 'RANDOMIZER SETTINGS',
      underlineText: _underline(),
      face: _face,
      children: [
        Center(
          child: Text(
            _quote,
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),

        Text('MIN LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Btn('◀', onTap: () => _bumpMin(-1), small: true)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _Colors.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Colors.border),
                ),
                child: Center(
                  child: Text(
                    '${SessionState.minLen}',
                    style: _bodyStyle(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _Btn('▶', onTap: () => _bumpMin(1), small: true)),
          ],
        ),

        const SizedBox(height: 18),

        Text('MAX LETTERS', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Btn('◀', onTap: () => _bumpMax(-1), small: true)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _Colors.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Colors.border),
                ),
                child: Center(
                  child: Text(
                    '${SessionState.maxLen}',
                    style: _bodyStyle(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _Btn('▶', onTap: () => _bumpMax(1), small: true)),
          ],
        ),

        const SizedBox(height: 22),

        Text('LETTER FILTER', style: _sectionHeaderStyle()),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: letters.map((L) {
            final on = SessionState.requiredLetters.contains(L);
            return InkWell(
              onTap: () => _toggleLetter(L),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: on ? _Colors.panel : _Colors.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: on ? _Colors.accent : _Colors.border),
                ),
                child: Center(
                  child: Text(
                    L,
                    style: TextStyle(
                      color: on ? _Colors.accent : _Colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/* -------------------------------- HISTORY SCREEN ---------------------------- */

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int pageSize = 5;
  int page = 0;

  List<String> get _sortedHistory {
    final xs = List<String>.from(SessionState.history);
    xs.sort((a, b) => a.compareTo(b));
    return xs;
  }

  @override
  Widget build(BuildContext context) {
    final xs = _sortedHistory;
    final totalPages = (xs.isEmpty) ? 1 : ((xs.length - 1) ~/ pageSize) + 1;
    page = page.clamp(0, totalPages - 1);

    final start = page * pageSize;
    final end = min(start + pageSize, xs.length);
    final slice = xs.isEmpty ? <String>[] : xs.sublist(start, end);

    return _Frame(
      title: 'HISTORY',
      underlineText: _underline(),
      children: [
        Row(
          children: [
            Expanded(
              child: _Btn(
                '◀ PREV',
                small: true,
                enabled: page > 0,
                onTap: () {
                  setState(() => page = max(0, page - 1));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Btn(
                'NEXT ▶',
                small: true,
                enabled: page < totalPages - 1,
                onTap: () {
                  setState(() => page = min(totalPages - 1, page + 1));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        if (slice.isEmpty)
          Center(
            child: Text(
              '(No words yet.)',
              style: _mutedStyle(),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...slice.map((w) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _Btn(
                w,
                onTap: () {
                  SessionState.lastWord = w;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WordScreen(word: w)),
                  );
                },
              ),
            );
          }),

        const SizedBox(height: 6),
        _Btn(
          'CLEAR HISTORY',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ClearHistoryConfirmScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/* ------------------------ CLEAR HISTORY CONFIRM SCREEN ---------------------- */

class ClearHistoryConfirmScreen extends StatefulWidget {
  const ClearHistoryConfirmScreen({super.key});

  @override
  State<ClearHistoryConfirmScreen> createState() =>
      _ClearHistoryConfirmScreenState();
}

class _ClearHistoryConfirmScreenState extends State<ClearHistoryConfirmScreen> {
  late final String _face;
  late final String _phrase;

  static const _faces = [
    '(⊙_⊙;)',
    '(ﾟoﾟ;)',
    '(；ﾟДﾟ)',
    '(⚆_⚆)',
    '(ʘᗩʘ’)',
    '(⊙﹏⊙)',
  ];

  static const _phrases = [
    'Erase every last lexical breadcrumb?',
    'Delete the trail of your super-generations?',
    'Purge the record of your wordly adventures?',
    'Incinerate your history with one tap?',
    'Commit vocabulary oblivion?',
  ];

  @override
  void initState() {
    super.initState();
    _face = _pick(_faces);
    _phrase = _pick(_phrases);
  }

  void _confirmClear() {
    SessionState.history.clear();
    SessionState.lastWord = null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final zenFaces = [
          '(￣ー￣)',
          '( ˘‿˘ )',
          '(－‸ლ)',
          '(⎵_⎵)',
          '( ͡° ͜ʖ ͡°)',
        ];
        final phrases = [
          'History dissolved into elegant silence.',
          'Your lexicon trail has been gently unmade.',
          'The archive evaporated—clean slate, nerd.',
          'Past words: respectfully yeeted into the void.',
          'A pristine absence now occupies your log.',
        ];

        return AlertDialog(
          backgroundColor: _Colors.panel,
          title: Center(
            child: Text(
              _pick(zenFaces),
              style: _mutedStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          content: Text(
            _pick(phrases),
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LaunchScreen()),
                  (_) => false,
                );
              },
              child: Text(
                'OKAY',
                style: TextStyle(color: _Colors.accent, letterSpacing: 0.8),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLEAR HISTORY',
      underlineText: _underline(),
      face: _face,
      children: [
        Center(
          child: Text(
            _phrase,
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        _Btn('YES, CLEAR HISTORY', onTap: _confirmClear),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/* --------------------------- UPDATE WORD LIBRARY ---------------------------- */

class UpdateWordLibraryScreen extends StatefulWidget {
  const UpdateWordLibraryScreen({super.key});

  @override
  State<UpdateWordLibraryScreen> createState() => _UpdateWordLibraryScreenState();
}

class _UpdateWordLibraryScreenState extends State<UpdateWordLibraryScreen> {
  bool _started = false;

  Future<void> _startUpdate() async {
    if (_started) return;
    setState(() => _started = true);

    final res = await UpdateService.instance.runUpdate();

    if (!mounted) return;
    if (res.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UpdateCompleteScreen(message: res.message)),
      );
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
      title: 'UPDATE WORD LIBRARY',
      underlineText: _underline(),
      showCloseApp: false,
      children: [
        const SizedBox(height: 6),
        Text(
          '[This is how your app’s word library is updated. It will replace outdated words and definitions with the latest versions, and add any missing words. Nothing else.]',
          style: _mutedStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _Btn(
          _started ? 'UPDATING…' : 'BEGIN UPDATE',
          onTap: _started ? null : _startUpdate,
          enabled: !_started,
        ),
        const SizedBox(height: 14),
        _Btn(
          'BACK TO LAST SCREEN',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class UpdateCompleteScreen extends StatelessWidget {
  final String message;
  const UpdateCompleteScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE COMPLETE',
      underlineText: _underline(),
      showCloseApp: false,
      children: [
        Text(
          message,
          style: _bodyStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        _Btn(
          'OKAY',
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LaunchScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

class UpdateFailedScreen extends StatelessWidget {
  final String message;
  const UpdateFailedScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final phrases = [
      'The library update tripped over its own shoelaces and faceplanted gracefully.',
      'A tiny network gremlin stole your update and sprinted into the dark.',
      'The update attempted transcendence and instead achieved mild confusion.',
      'Your word library sighed, shrugged, and refused to evolve right now.',
      'The download got lost in the void between “now” and “almost.”',
    ];

    return _Frame(
      title: 'UPDATE DIDN’T WORK',
      underlineText: _underline(),
      showCloseApp: false,
      children: [
        Text(
          _pick(phrases),
          style: _mutedStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: _bodyStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        _Btn(
          'OKAY',
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LaunchScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

/* ----------------------------- NO MORE WORDS SCREEN ------------------------- */

class NoMoreWordsScreen extends StatelessWidget {
  const NoMoreWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faces = [
      '(╥_╥)',
      '(ಥ_ಥ)',
      '(；_；)',
      '(╯︵╰,)',
      '(；ω；)',
      '(¬_¬ )',
    ];
    final phrases = [
      'No more words remain within your current constraints.',
      'The generator rummaged the archive and found… nothing.',
      'All eligible words have been exhausted (for now).',
      'Your settings and history have narrowed the universe to zero.',
      'The pool is empty, yet your curiosity persists.',
    ];

    return _Frame(
      title: 'NO MORE WORDS AVAILABLE',
      underlineText: _underline(),
      face: _pick(faces),
      children: [
        Center(
          child: Text(
            _pick(phrases),
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Try adjusting your ',
          style: _mutedStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _InlineLink(
                'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()),
                  );
                },
              ),
              Text(
                ' or clearing your ',
                style: _mutedStyle(),
              ),
              _InlineLink(
                'History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              Text(
                ' to generate more words!',
                style: _mutedStyle(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* --------------------------- WORD NOT FOUND SCREEN -------------------------- */

class WordNotFoundScreen extends StatefulWidget {
  final String typed;
  const WordNotFoundScreen({super.key, required this.typed});

  @override
  State<WordNotFoundScreen> createState() => _WordNotFoundScreenState();
}

class _WordNotFoundScreenState extends State<WordNotFoundScreen> {
  static const int pageSize = 5;
  int page = 0;

  List<String> get _suggestions {
    return LibraryService.instance.suggest(widget.typed, limit: 25);
  }

  @override
  Widget build(BuildContext context) {
    final sug = _suggestions;
    final totalPages = (sug.isEmpty) ? 1 : ((sug.length - 1) ~/ pageSize) + 1;
    page = page.clamp(0, totalPages - 1);

    final start = page * pageSize;
    final end = min(start + pageSize, sug.length);
    final slice = sug.isEmpty ? <String>[] : sug.sublist(start, end);

    return _Frame(
      title: 'WORD NOT FOUND',
      underlineText: _underline(),
      children: [
        Center(
          child: Text(
            'Sorry we didn’t find\n${widget.typed}',
            style: _bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        if (slice.isNotEmpty) ...[
          Center(
            child: Text(
              'Did you mean:',
              style: _sectionHeaderStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Btn(
                  '◀ PREV',
                  small: true,
                  enabled: page > 0,
                  onTap: () => setState(() => page = max(0, page - 1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Btn(
                  'NEXT ▶',
                  small: true,
                  enabled: page < totalPages - 1,
                  onTap: () => setState(() => page = min(totalPages - 1, page + 1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...slice.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Btn(
                  w,
                  onTap: () {
                    SessionState.lastWord = w;
                    if (!SessionState.history.contains(w)) SessionState.history.add(w);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WordScreen(word: w)),
                    );
                  },
                ),
              )),
          const SizedBox(height: 10),
        ],
        _Btn(
          'RETURN TO SEARCH',
          onTap: () async {
            final typed = await _promptForWord(context);
            if (typed == null) return;
            final up = typed.trim().toUpperCase();
            if (up.isEmpty) return;
            final entry = LibraryService.instance.lookup(up);
            if (entry != null) {
              SessionState.lastWord = entry.word;
              if (!SessionState.history.contains(entry.word)) {
                SessionState.history.add(entry.word);
              }
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => WordScreen(word: entry.word)));
            } else {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: up)));
            }
          },
        ),
        const SizedBox(height: 14),
        _Btn(
          'NEW RANDOM WORD',
          onTap: () {
            final w = _pickRandomAllowedWord();
            if (w == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NoMoreWordsScreen()),
              );
              return;
            }
            SessionState.lastWord = w;
            if (!SessionState.history.contains(w)) SessionState.history.add(w);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WordScreen(word: w)),
            );
          },
        ),
        const SizedBox(height: 14),
        _Btn(
          'RANDOMIZER SETTINGS',
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
          },
        ),
        const SizedBox(height: 14),
        _Btn(
          'HISTORY',
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          },
        ),
      ],
    );
  }
}

/* ------------------------------ CLOSE APP SCREEN ---------------------------- */

class CloseAppScreen extends StatelessWidget {
  const CloseAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faces = [
      '(；︵；)',
      '(╯︵╰,)',
      '(；_；)',
      '(ಥ﹏ಥ)',
      '(；д；)',
      '(；ω；)',
    ];

    final phrases = [
      'Until next time—may your vocabulary expand in splendid silence.',
      'We will miss you, warmly, and with unreasonable linguistic intensity.',
      'May your day be coherent, your thoughts articulate, and your words abundant.',
      'Depart gently; your history will dissolve the moment you close the app.',
      'Farewell, noble nerd—return when the lexicon calls.',
    ];

    return _Frame(
      title: 'CLOSE APP',
      underlineText: _underline(),
      face: _pick(faces),
      children: [
        Center(
          child: Text(
            _pick(phrases),
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Warning: your word history will be cleared upon exiting the app.',
            style: _mutedStyle(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        _Btn(
          'CLOSE APP',
          onTap: () {
            SessionState.history.clear();
            SessionState.lastWord = null;
            SystemNavigator.pop();
          },
        ),
        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
      onCloseApp: () {
        // We're already on Close App screen; do nothing.
      },
    );
  }
}

/* -------------------------- RANDOM PICK / FILTER LOGIC ---------------------- */

bool _passesRandomizer(String w) {
  final len = w.length;
  if (len < SessionState.minLen || len > SessionState.maxLen) return false;

  if (SessionState.requiredLetters.isNotEmpty) {
    for (final L in SessionState.requiredLetters) {
      if (!w.contains(L)) return false;
    }
  }
  return true;
}

String? _pickRandomAllowedWord() {
  final all = LibraryService.instance.allWords;

  final candidates = <String>[];
  for (final w in all) {
    if (_passesRandomizer(w) && !SessionState.history.contains(w)) {
      candidates.add(w);
    }
  }
  if (candidates.isEmpty) return null;
  return candidates[_rng.nextInt(candidates.length)];
}

/* ----------------------------- SEARCH PROMPT UI ----------------------------- */

Future<String?> _promptForWord(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _Colors.panel,
      title: const Text(
        'SEARCH FOR A WORD',
        style: TextStyle(color: _Colors.text),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: _Colors.text),
        decoration: const InputDecoration(
          hintText: 'Type a word',
          hintStyle: TextStyle(color: _Colors.muted),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: Text('CANCEL', style: TextStyle(color: _Colors.accent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text('SEARCH', style: TextStyle(color: _Colors.accent)),
        ),
      ],
    ),
  );
}
