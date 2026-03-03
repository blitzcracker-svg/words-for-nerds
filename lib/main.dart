// lib/main.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/word_entry.dart';
import 'services/library_service.dart';
import 'services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    runApp(const WordsForNerdsApp());
  }, (error, stack) {
    // Keep silent (minimal). BootGate will show an error screen if init fails.
  });
}

class WordsForNerdsApp extends StatelessWidget {
  const WordsForNerdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDS FOR NERDS',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _Theme.bg,
        fontFamily: 'Times New Roman',
      ),
      home: const BootGate(),
    );
  }
}

/* ----------------------------- Session State ---------------------------- */

class SessionState {
  static final List<String> history = <String>[];
  static String? lastWord;

  static int minLetters = 1;
  static int maxLetters = 45;

  // Letters user requires to appear in the word (AND)
  static final Set<String> requiredLetters = <String>{};

  static void clearSession() {
    history.clear();
    lastWord = null;
    minLetters = 1;
    maxLetters = 45;
    requiredLetters.clear();
  }
}

/* --------------------------------- Theme -------------------------------- */

class _Theme {
  static const Color bg = Colors.black;
  static const Color panel = Color(0xFF14161A);
  static const Color panel2 = Color(0xFF111216);
  static const Color text = Color(0xFFEDEDED);
  static const Color muted = Color(0xFFB9B9B9);
  static const Color btnText = Color(0xFF8B3A3A); // burgundy
  static const Color border = Color(0xFF2B2E35);

  static const double radius = 18;
}

/* ------------------------------ Random Pools ---------------------------- */

final Random _rng = Random();

String _underline() {
  const chars = ['_', '-', '─', '—'];
  final len = 18 + _rng.nextInt(12); // 18..29
  final ch = chars[_rng.nextInt(chars.length)];
  return List.filled(len, ch).join();
}

String _pick(List<String> items) => items[_rng.nextInt(items.length)];

final List<String> _facesHappy = [
  '(≧ω≦)',
  '(＾▽＾)',
  '(•‿•)',
  '(ᵔᴥᵔ)',
  '(✿◕‿◕)',
  '(ﾉ◕ヮ◕)ﾉ',
  '(ง ͠° ͟ʖ ͡°)ง',
  '(｀▽´)',
  '(•̀ᴗ•́)و',
  '(ﾉﾟ▽ﾟ)ﾉ',
];

final List<String> _facesInquisitive = [
  '(¬‿¬)',
  '(•_•)',
  '(•_•) ( •_•)>⌐■-■',
  '(￢_￢)',
  '(ಠ_ಠ)',
  '(ʘ‿ʘ)',
  '(⊙_☉)',
  '(・_・;)',
  '(•͈⌔•͈)',
  '(~_~;)',
];

final List<String> _facesSad = [
  '(；＿；)',
  '(╥_╥)',
  '(ಥ﹏ಥ)',
  '(T_T)',
  '(；﹏；)',
  '(︶︹︺)',
  '(；︵；)',
  '(╯︵╰)',
  '(；-；)',
  '(;_;)',
];

final List<String> _facesAloof = [
  '(=_=)',
  '(¬_¬)',
  '(・_・)',
  '(￣ー￣)',
  '(ー_ー)',
  '(=_=) zZ',
  '(._.)',
  '( ͡° ͜ʖ ͡°)',
  '(￣.￣)',
  '( -_- )',
];

final List<String> _facesPanic = [
  '(⊙﹏⊙)',
  '(；ﾟДﾟ)',
  '(°ロ°)',
  '(╯°□°）╯',
  '(☉_☉)',
  '(; ﾟДﾟ)',
  '(°□°;)',
  '(；￣Д￣)',
  '(ᗒᗣᗕ)՞',
  '(>_<)',
];

final List<String> _facesZen = [
  '(－‸ლ)',
  '(˘⌣˘)',
  '( ᵕ‿ᵕ )',
  '(´－｀)',
  '(¯―¯)',
  '(￣︶￣)',
  '( •‿• )',
  '(˙‿˙)',
  '(⌁‿⌁)',
  '( -‿- )',
];

final List<String> _greetings = [
  'HELLO, LEXICON PILGRIM.',
  'WELCOME TO THE WORD-REALM.',
  'GREETINGS, SYLLABLE COLLECTOR.',
  'SALUTATIONS, MEANING-SEEKER.',
  'AH. YOU HAVE ARRIVED, VERBALLY.',
  'ENTER, FRIEND OF NUANCE.',
  'TODAY WE GROW A NEW TONGUE.',
  'WELCOME. MAY YOUR WORDS BE WEIRD.',
  'HELLO. LET US IMPROVE YOUR MOUTH-BRAIN.',
  'GREETINGS. THE DICTIONARY AWAITS.',
];

final List<String> _launchQuotes = [
  '"Vocabulary growth is a quiet kind of rebellion."',
  '"A word is a small tool that moves a large mind."',
  '"Every new term is a new handle on reality."',
  '"Language expands where curiosity refuses to stop."',
  '"Meaning is a mirror—this app just tilts it."',
  '"The brain likes new words. The ego pretends it doesn’t."',
  '"Today: fewer blanks. Tomorrow: fewer limits."',
  '"Your lexicon is a living organism. Feed it."',
  '"Precision is power, disguised as syllables."',
  '"One word at a time: the inner world upgrades."',
];

final List<String> _settingsQuotes = [
  '"Adjust the constraints. Observe the mind squirm, then stretch."',
  '"Choose your limits. Then watch language step over them anyway."',
  '"Tiny toggles, colossal consequences."',
  '"The generator obeys. The ego negotiates."',
  '"Filter the chaos. Manufacture revelation."',
  '"You are the architect of what gets allowed to exist."',
  '"Select letters. Summon outcomes. Pretend it was inevitable."',
  '"Boundaries are funny. Words love hopping fences."',
  '"Dial the parameters. Reality gets more articulate."',
  '"Constrain the search. Expand the self. Somehow both."',
];

final List<String> _updateTeases = [
  'Hunting fresher words in the wild…',
  'Shaking the library tree for new leaves…',
  'Negotiating with the universe for sharper definitions…',
  'Asking the internet politely for more language…',
  'Gathering syllables. One packet at a time…',
  'Coaxing updates into existence…',
  'Summoning a newer lexicon…',
];

final List<String> _noMorePhrases = [
  'No more words match your current constraints.',
  'The generator searched. Reality shrugged.',
  'Your filters are too mighty. Nothing survives them.',
  'The word-pool is empty under these rules.',
  'Language tapped out—temporarily.',
  'Constraint victory: zero results.',
];

final List<String> _historyClearPhrases = [
  'This will erase your history. Like it never happened.',
  'Are you sure you want to un-remember these words?',
  'This is the big red button, but in polite font.',
  'Your history is about to vanish into tasteful silence.',
  'Confirm: obliterate the evidence of learning.',
  'Proceed to delete the footprints of your lexicon-journey?',
];

final List<String> _historyClearedPhrases = [
  'History dissolved into elegant nothingness.',
  'The archive has been politely unmade.',
  'Your word-trail has been vaporized with decorum.',
  'All prior generations: respectfully erased.',
  'The record is gone. The mind remains.',
  'Clean slate achieved; meaning remains undefeated.',
];

/* ------------------------------- Boot Gate ------------------------------ */

class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await LibraryService.instance.initFromAsset();
      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const LaunchScreen();

    if (_error == null) {
      return const Scaffold(
        backgroundColor: _Theme.bg,
        body: Center(
          child: Text(
            'Loading…',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 22,
              color: _Theme.text,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _Theme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Startup failed:\n\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 18,
              color: _Theme.text,
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ UI Helpers ------------------------------ */

TextStyle _titleStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 38,
      letterSpacing: 1.0,
      color: _Theme.text,
      fontWeight: FontWeight.w500,
    );

TextStyle _hStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      color: _Theme.text,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );

TextStyle _bodyStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      color: _Theme.text,
      height: 1.4,
    );

TextStyle _mutedStyle() => const TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      color: _Theme.muted,
      height: 1.4,
    );

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
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
    final padV = small ? 14.0 : 18.0;
    final fontSize = small ? 16.0 : 18.0;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: 18),
          decoration: BoxDecoration(
            color: _Theme.panel,
            borderRadius: BorderRadius.circular(_Theme.radius),
            border: Border.all(color: _Theme.border, width: 1),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: fontSize,
                letterSpacing: 0.8,
                color: _Theme.btnText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CornerBtn(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: _Btn(label, onTap: onTap, small: true),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _ArrowBtn(this.label, {required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _Btn(
        label,
        onTap: onTap,
        small: true,
        enabled: enabled,
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? face;
  final Widget? cornerCloseApp;
  final bool addBottomClearance;

  const _Frame({
    required this.title,
    required this.children,
    this.face,
    this.cornerCloseApp,
    this.addBottomClearance = true,
  });

  @override
  Widget build(BuildContext context) {
    final underline = _underline();

    return Scaffold(
      backgroundColor: _Theme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(title, textAlign: TextAlign.center, style: _titleStyle()),
                  const SizedBox(height: 8),
                  Text(underline,
                      textAlign: TextAlign.center, style: _mutedStyle()),
                  if (face != null) ...[
                    const SizedBox(height: 12),
                    Text(face!,
                        textAlign: TextAlign.center, style: _mutedStyle()),
                  ],
                  const SizedBox(height: 18),
                  ...children,
                  if (addBottomClearance) const SizedBox(height: 110),
                ],
              ),
            ),
            if (cornerCloseApp != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: cornerCloseApp!,
              ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Navigation Helpers -------------------------- */

Future<String?> _promptForWord(BuildContext context) async {
  final ctrl = TextEditingController();
  String? result;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final face = _pick(_facesInquisitive);
      final quote = 'A small spell: reveal a word.';
      return AlertDialog(
        backgroundColor: _Theme.panel2,
        title: Column(
          children: [
            Text('SEARCH FOR A WORD',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 18,
                  color: _Theme.text,
                  letterSpacing: 1,
                )),
            const SizedBox(height: 8),
            Text(_underline(),
                textAlign: TextAlign.center, style: _mutedStyle()),
            const SizedBox(height: 10),
            Text(face, textAlign: TextAlign.center, style: _mutedStyle()),
            const SizedBox(height: 8),
            Text(quote, textAlign: TextAlign.center, style: _mutedStyle()),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 18,
            color: _Theme.text,
          ),
          decoration: const InputDecoration(
            hintText: 'Type a word',
            hintStyle: TextStyle(
              fontFamily: 'Times New Roman',
              color: _Theme.muted,
            ),
          ),
          onSubmitted: (_) {
            result = ctrl.text.trim();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = null;
              Navigator.pop(ctx);
            },
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: _Theme.btnText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              result = ctrl.text.trim();
              Navigator.pop(ctx);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: _Theme.btnText,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result?.trim().isEmpty == true ? null : result;
}

String? _generateNextWord() {
  final all = LibraryService.instance.allWords;

  final minL = SessionState.minLetters;
  final maxL = SessionState.maxLetters;
  final req = SessionState.requiredLetters.map((e) => e.toUpperCase()).toList();

  final pool = <String>[];

  for (final w in all) {
    if (w.length < minL || w.length > maxL) continue;
    if (SessionState.history.contains(w)) continue;

    bool ok = true;
    for (final r in req) {
      if (!w.contains(r)) {
        ok = false;
        break;
      }
    }
    if (!ok) continue;

    pool.add(w);
  }

  if (pool.isEmpty) return null;
  return pool[_rng.nextInt(pool.length)];
}

/* -------------------------------- Screens -------------------------------- */

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  String _lastUpdated = 'Bundled';

  @override
  void initState() {
    super.initState();
    _loadLastUpdated();
  }

  Future<void> _loadLastUpdated() async {
    final v = await LibraryService.instance.lastUpdatedLabel();
    if (mounted) setState(() => _lastUpdated = v);
  }

  void _goRandomWord() {
    final w = _generateNextWord() ?? _pick(LibraryService.instance.allWords);
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordScreen(word: w)),
    );
  }

  void _goSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()),
    );
  }

  Future<void> _search() async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    final entry = LibraryService.instance.lookup(upper);

    if (entry != null) {
      SessionState.lastWord = upper;
      if (!SessionState.history.contains(upper)) SessionState.history.add(upper);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WordScreen(word: upper)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)),
      );
    }
  }

  Future<void> _updateLibrary() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateInProgressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesHappy);
    final greeting = _pick(_greetings);
    final quote = _pick(_launchQuotes);

    return _Frame(
      title: 'WORDS FOR NERDS',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text(greeting, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 10),
        Text(quote, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 28),

        _Btn('CLICK HERE FOR A RANDOM WORD', onTap: _goRandomWord),
        const SizedBox(height: 18),

        _Btn('CLICK HERE TO SEARCH FOR A WORD', onTap: _search),
        const SizedBox(height: 18),

        _Btn('RANDOMIZER SETTINGS', onTap: _goSettings),
        const SizedBox(height: 22),

        _Btn('UPDATE WORD LIBRARY (LAST: $_lastUpdated)', onTap: _updateLibrary),
      ],
    );
  }
}

/* ------------------------------- Word Screen ------------------------------ */

class WordScreen extends StatefulWidget {
  final String word;

  const WordScreen({super.key, required this.word});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  static const MethodChannel _tts =
      MethodChannel('words_for_nerds/tts'); // must match MainActivity.kt

  Future<void> _speak(String text) async {
    try {
      await _tts.invokeMethod('speak', {'text': text});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Text-to-speech unavailable on this device.',
            style: TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
    }
  }

  void _newRandomWord() {
    final w = _generateNextWord();
    if (w == null) {
      Navigator.push(
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
  }

  void _goSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()),
    );
  }

  void _goHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  Future<void> _search() async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.trim().toUpperCase();
    final entry = LibraryService.instance.lookup(upper);

    if (entry != null) {
      SessionState.lastWord = upper;
      if (!SessionState.history.contains(upper)) SessionState.history.add(upper);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WordScreen(word: upper)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = LibraryService.instance.lookup(widget.word);

    // Fallback (shouldn't happen if library is consistent)
    final WordEntry safe = entry ??
        WordEntry(
          word: widget.word,
          phonetic: '',
          definition: '',
          etymology: '',
          example: '',
        );

    return _Frame(
      title: safe.word,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        _Btn('LISTEN TO WORD', onTap: () => _speak(safe.word)),
        const SizedBox(height: 26),

        Align(alignment: Alignment.centerLeft, child: Text('DICTIONARY', style: _hStyle())),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: Text('Offline library', style: _bodyStyle())),
        const SizedBox(height: 18),

        Align(alignment: Alignment.centerLeft, child: Text('PHONETIC PRONUNCIATION', style: _hStyle())),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: Text(safe.phonetic.isEmpty ? '-' : safe.phonetic, style: _bodyStyle())),
        const SizedBox(height: 18),

        Align(alignment: Alignment.centerLeft, child: Text('DEFINITION', style: _hStyle())),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: Text(safe.definition.isEmpty ? '-' : safe.definition, style: _bodyStyle())),
        const SizedBox(height: 18),

        Align(alignment: Alignment.centerLeft, child: Text('ETYMOLOGY', style: _hStyle())),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: Text(safe.etymology.isEmpty ? '-' : safe.etymology, style: _bodyStyle())),
        const SizedBox(height: 18),

        Align(alignment: Alignment.centerLeft, child: Text('EXAMPLE', style: _hStyle())),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: Text(safe.example.isEmpty ? '-' : safe.example, style: _bodyStyle())),
        const SizedBox(height: 26),

        _Btn('NEW RANDOM WORD', onTap: _newRandomWord),
        const SizedBox(height: 18),

        _Btn('RANDOMIZER SETTINGS', onTap: _goSettings),
        const SizedBox(height: 18),

        _Btn('HISTORY', onTap: _goHistory),
        const SizedBox(height: 18),

        _Btn('SEARCH FOR A WORD', onTap: _search),
      ],
    );
  }
}

/* --------------------------- Randomizer Settings -------------------------- */

class RandomizerSettingsScreen extends StatefulWidget {
  const RandomizerSettingsScreen({super.key});

  @override
  State<RandomizerSettingsScreen> createState() =>
      _RandomizerSettingsScreenState();
}

class _RandomizerSettingsScreenState extends State<RandomizerSettingsScreen> {
  void _setMin(int v) {
    v = v.clamp(1, 45);
    if (v > SessionState.maxLetters) v = SessionState.maxLetters;
    setState(() => SessionState.minLetters = v);
  }

  void _setMax(int v) {
    v = v.clamp(1, 45);
    if (v < SessionState.minLetters) v = SessionState.minLetters;
    setState(() => SessionState.maxLetters = v);
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
    final face = _pick(_facesAloof);
    final quote = _pick(_settingsQuotes);

    return _Frame(
      title: 'RANDOMIZER SETTINGS',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text(quote, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 22),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('MIN LETTERS', style: _hStyle()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ArrowBtn('<', onTap: () => _setMin(SessionState.minLetters - 1)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _Theme.panel,
                  borderRadius: BorderRadius.circular(_Theme.radius),
                  border: Border.all(color: _Theme.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${SessionState.minLetters}',
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      color: _Theme.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ArrowBtn('>', onTap: () => _setMin(SessionState.minLetters + 1)),
          ],
        ),
        const SizedBox(height: 18),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('MAX LETTERS', style: _hStyle()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ArrowBtn('<', onTap: () => _setMax(SessionState.maxLetters - 1)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _Theme.panel,
                  borderRadius: BorderRadius.circular(_Theme.radius),
                  border: Border.all(color: _Theme.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${SessionState.maxLetters}',
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      color: _Theme.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ArrowBtn('>', onTap: () => _setMax(SessionState.maxLetters + 1)),
          ],
        ),
        const SizedBox(height: 24),

        Align(alignment: Alignment.centerLeft, child: Text('LETTER FILTER', style: _hStyle())),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(26, (i) {
            final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
            final on = SessionState.requiredLetters.contains(letter);

            return GestureDetector(
              onTap: () => _toggleLetter(letter),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: on ? _Theme.panel2 : _Theme.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: on ? _Theme.btnText : _Theme.border,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      color: on ? _Theme.btnText : _Theme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 26),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context), small: true),
      ],
    );
  }
}

/* --------------------------------- History -------------------------------- */

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _page = 0;
  static const int _perPage = 5;

  List<String> get _sorted {
    final copy = List<String>.from(SessionState.history);
    copy.sort();
    return copy;
  }

  int get _pageCount {
    final total = _sorted.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _perPage) + 1;
  }

  List<String> _pageItems() {
    final list = _sorted;
    final start = _page * _perPage;
    if (start >= list.length) return const [];
    final end = min(start + _perPage, list.length);
    return list.sublist(start, end);
  }

  void _openWord(String w) {
    SessionState.lastWord = w;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordScreen(word: w)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems();

    return _Frame(
      title: 'HISTORY',
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Row(
          children: [
            _ArrowBtn(
              'PREV',
              enabled: _page > 0,
              onTap: () => setState(() => _page = max(0, _page - 1)),
            ),
            const SizedBox(width: 10),
            _ArrowBtn(
              'NEXT',
              enabled: _page < _pageCount - 1,
              onTap: () => setState(() => _page = min(_pageCount - 1, _page + 1)),
            ),
          ],
        ),
        const SizedBox(height: 18),

        if (items.isEmpty)
          Text('No history yet.', textAlign: TextAlign.center, style: _mutedStyle())
        else
          ...items.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Btn(w, onTap: () => _openWord(w), small: true),
              )),

        const SizedBox(height: 16),

        _Btn('CLEAR HISTORY', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClearHistoryConfirmScreen()),
          );
        }, small: true),

        const SizedBox(height: 14),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context), small: true),
      ],
    );
  }
}

/* ------------------------ Clear History Confirmation ----------------------- */

class ClearHistoryConfirmScreen extends StatelessWidget {
  const ClearHistoryConfirmScreen({super.key});

  void _confirm(BuildContext context) {
    SessionState.history.clear();
    SessionState.lastWord = null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final face = _pick(_facesZen);
        final phrase = _pick(_historyClearedPhrases);

        return AlertDialog(
          backgroundColor: _Theme.panel2,
          title: Column(
            children: [
              Text('HISTORY CLEARED',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 18,
                    color: _Theme.text,
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 8),
              Text(_underline(),
                  textAlign: TextAlign.center, style: _mutedStyle()),
              const SizedBox(height: 10),
              Text(face, textAlign: TextAlign.center, style: _mutedStyle()),
            ],
          ),
          content: Text(
            phrase,
            textAlign: TextAlign.center,
            style: _mutedStyle(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LaunchScreen()),
                  (r) => false,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  color: _Theme.btnText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesPanic);
    final phrase = _pick(_historyClearPhrases);

    return _Frame(
      title: 'CLEAR HISTORY',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text(
          phrase,
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
        const SizedBox(height: 22),

        _Btn('YES, CLEAR HISTORY', onTap: () => _confirm(context)),
        const SizedBox(height: 18),

        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context), small: true),
      ],
    );
  }
}

/* ----------------------------- No More Words ----------------------------- */

class NoMoreWordsScreen extends StatelessWidget {
  const NoMoreWordsScreen({super.key});

  void _goLastWord(BuildContext context) {
    final w = SessionState.lastWord;
    if (w == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LaunchScreen()),
        (r) => false,
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WordScreen(word: w)),
    );
  }

  void _goSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()),
    );
  }

  void _goHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesSad);
    final phrase = _pick(_noMorePhrases);

    return _Frame(
      title: 'NO MORE WORDS AVAILABLE',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text(phrase, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 14),
        Text(
          'Try adjusting your',
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
        const SizedBox(height: 10),
        _Btn('RANDOMIZER SETTINGS', onTap: () => _goSettings(context), small: true),
        const SizedBox(height: 10),
        Text(
          'or clearing your',
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
        const SizedBox(height: 10),
        _Btn('HISTORY', onTap: () => _goHistory(context), small: true),
        const SizedBox(height: 22),

        _Btn('RETURN TO LAST WORD', onTap: () => _goLastWord(context)),
      ],
    );
  }
}

/* ----------------------------- Word Not Found ---------------------------- */

class WordNotFoundScreen extends StatefulWidget {
  final String typed;

  const WordNotFoundScreen({super.key, required this.typed});

  @override
  State<WordNotFoundScreen> createState() => _WordNotFoundScreenState();
}

class _WordNotFoundScreenState extends State<WordNotFoundScreen> {
  int _page = 0;
  static const int _perPage = 5;

  List<String> get _suggestions =>
      LibraryService.instance.suggest(widget.typed, limit: 40);

  int get _pageCount {
    final total = _suggestions.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _perPage) + 1;
  }

  List<String> _pageItems() {
    final list = _suggestions;
    final start = _page * _perPage;
    if (start >= list.length) return const [];
    final end = min(start + _perPage, list.length);
    return list.sublist(start, end);
  }

  Future<void> _search(BuildContext context) async {
    final typed = await _promptForWord(context);
    if (typed == null) return;

    final upper = typed.toUpperCase();
    final entry = LibraryService.instance.lookup(upper);

    if (entry != null) {
      SessionState.lastWord = upper;
      if (!SessionState.history.contains(upper)) SessionState.history.add(upper);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WordScreen(word: upper)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)),
      );
    }
  }

  void _openSuggestion(String w) {
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WordScreen(word: w)),
    );
  }

  void _newRandomWord() {
    final w = _generateNextWord();
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
  }

  void _goSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()),
    );
  }

  void _goHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems();

    return _Frame(
      title: 'WORD NOT FOUND',
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text('Sorry we didn’t find', textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 10),
        Text('"${widget.typed}"', textAlign: TextAlign.center, style: _bodyStyle()),
        const SizedBox(height: 18),

        if (_suggestions.isNotEmpty) ...[
          Text('Did you mean', textAlign: TextAlign.center, style: _mutedStyle()),
          const SizedBox(height: 12),

          Row(
            children: [
              _ArrowBtn(
                'PREV',
                enabled: _page > 0,
                onTap: () => setState(() => _page = max(0, _page - 1)),
              ),
              const SizedBox(width: 10),
              _ArrowBtn(
                'NEXT',
                enabled: _page < _pageCount - 1,
                onTap: () => setState(() => _page = min(_pageCount - 1, _page + 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...items.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Btn(w, onTap: () => _openSuggestion(w), small: true),
              )),
        ],

        const SizedBox(height: 18),
        _Btn('RETURN TO SEARCH', onTap: () => _search(context)),
        const SizedBox(height: 14),
        _Btn('NEW RANDOM WORD', onTap: _newRandomWord),
        const SizedBox(height: 14),
        _Btn('RANDOMIZER SETTINGS', onTap: _goSettings),
        const SizedBox(height: 14),
        _Btn('HISTORY', onTap: _goHistory),
      ],
    );
  }
}

/* ---------------------------- Update Library Flow ------------------------- */

class UpdateInProgressScreen extends StatefulWidget {
  const UpdateInProgressScreen({super.key});

  @override
  State<UpdateInProgressScreen> createState() => _UpdateInProgressScreenState();
}

class _UpdateInProgressScreenState extends State<UpdateInProgressScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final tease = _pick(_updateTeases);
    // show a frame immediately
    await Future.delayed(const Duration(milliseconds: 250));

    final res = await UpdateService.instance.runUpdate();

    if (!mounted) return;

    if (res.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UpdateCompleteScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UpdateFailedScreen(message: res.message)),
      );
    }

    // tease variable just ensures we "use" randomness each run
    // (kept minimal; no extra UI state required)
    if (tease.isEmpty) {}
  }

  @override
  Widget build(BuildContext context) {
    final tease = _pick(_updateTeases);

    // NO close app button on this screen (per requirement)
    return _Frame(
      title: 'UPDATING WORD LIBRARY',
      face: _pick(_facesInquisitive),
      cornerCloseApp: null,
      children: [
        Text(
          tease,
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
        const SizedBox(height: 18),
        const LinearProgressIndicator(
          minHeight: 6,
          backgroundColor: _Theme.border,
          color: _Theme.btnText,
        ),
        const SizedBox(height: 18),
        Text(
          'Downloading & installing words…',
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
      ],
    );
  }
}

class UpdateCompleteScreen extends StatelessWidget {
  const UpdateCompleteScreen({super.key});

  void _ok(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LaunchScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesHappy);

    return _Frame(
      title: 'UPDATE COMPLETE',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text('Update successful.', textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 22),
        _Btn('OKAY', onTap: () => _ok(context)),
      ],
    );
  }
}

class UpdateFailedScreen extends StatelessWidget {
  final String message;
  const UpdateFailedScreen({super.key, required this.message});

  void _ok(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LaunchScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesSad);
    final phrase = 'The update failed. The lexicon remains intact.';

    return _Frame(
      title: 'UPDATE DIDN’T WORK',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CloseAppScreen()),
        );
      }),
      children: [
        Text(phrase, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 22),
        _Btn('OKAY', onTap: () => _ok(context)),
      ],
    );
  }
}

/* ------------------------------ Close App -------------------------------- */

class CloseAppScreen extends StatelessWidget {
  const CloseAppScreen({super.key});

  void _closeNow(BuildContext context) {
    // Clear history upon exiting
    SessionState.history.clear();
    SessionState.lastWord = null;

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final face = _pick(_facesZen);
    final goodbye = 'May your next word arrive at the perfect moment.';

    return _Frame(
      title: 'CLOSE APP',
      face: face,
      cornerCloseApp: _CornerBtn('CLOSE APP', onTap: () => _closeNow(context)),
      children: [
        Text(goodbye, textAlign: TextAlign.center, style: _mutedStyle()),
        const SizedBox(height: 14),
        Text(
          'Your word history will be cleared when you close the app.',
          textAlign: TextAlign.center,
          style: _mutedStyle(),
        ),
        const SizedBox(height: 22),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}
