import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/update_service.dart';
import 'services/library_service.dart';
import 'models/word_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LibraryService.instance.initFromAsset();
  runApp(const WordsForNerdsApp());
}

class WordsForNerdsApp extends StatelessWidget {
  const WordsForNerdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Words For Nerds',
      debugShowCheckedModeBanner: true,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0F12),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Times New Roman'),
      ),
      home: const LaunchScreen(),
    );
  }
}

/// In-memory session state (does NOT clear when you switch apps).
class SessionState {
  static final List<String> history = [];
  static String? lastWord;
}

void _openCloseApp(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
}

Future<String?> _promptForWord(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('SEARCH FOR A WORD'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
          decoration: const InputDecoration(hintText: 'Type a word'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

List<String> _allWords() => LibraryService.instance.allWordsSorted();

WordEntry? _entry(String word) => LibraryService.instance.lookup(word);

/// Picks a random word that has NOT been used this session.
/// Returns null when exhausted.
String? _pickRandomUnusedWord() {
  final used = SessionState.history.toSet();
  final remaining = _allWords().where((w) => !used.contains(w)).toList();
  if (remaining.isEmpty) return null;
  remaining.shuffle(Random());
  return remaining.first;
}

/// Generates a new random word with NO repeats.
/// If exhausted, shows NO MORE WORDS AVAILABLE.
void _pushRandomWordOrNoMore(BuildContext context, {bool replace = false}) {
  final w = _pickRandomUnusedWord();
  if (w == null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoMoreWordsAvailableScreen()),
    );
    return;
  }

  SessionState.lastWord = w;
  if (!SessionState.history.contains(w)) SessionState.history.add(w);

  final route = MaterialPageRoute(builder: (_) => WordScreen(word: w));
  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  void _search(BuildContext context) async {
    final result = await _promptForWord(context);
    if (result == null) return;

    final typed = result.trim();
    if (typed.isEmpty) return;

    final upper = typed.toUpperCase();
    final e = _entry(upper);

    if (e != null) {
      SessionState.lastWord = e.word;
      if (!SessionState.history.contains(e.word)) SessionState.history.add(e.word);
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: e.word)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'WORDS FOR NERDS',
      face: '(≧◡≦)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"Lexical evolution is a strange little mirror."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('CLICK HERE FOR A RANDOM WORD', onTap: () => _pushRandomWordOrNoMore(context)),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('CLICK HERE TO SEARCH FOR A WORD', onTap: () => _search(context)),
        _Btn('UPDATE WORD LIBRARY (LAST: 2026-02-20)', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateWordLibraryScreen()));
        }),
      ],
    );
  }
}

class WordScreen extends StatelessWidget {
  final String word;
  const WordScreen({super.key, required this.word});

  void _search(BuildContext context) async {
    final result = await _promptForWord(context);
    if (result == null) return;

    final typed = result.trim();
    if (typed.isEmpty) return;

    final upper = typed.toUpperCase();
    final e = _entry(upper);

    if (e != null) {
      SessionState.lastWord = e.word;
      if (!SessionState.history.contains(e.word)) SessionState.history.add(e.word);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: e.word)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry(word);

    final source = e?.source ?? 'Offline library';
    final phonetic = e?.phonetic ?? '';
    final definition = e?.definition ?? '';
    final etymology = e?.etymology ?? '';
    final example = e?.example ?? '';

    return _Frame(
      title: word,
      underlineStyle: UnderlineStyle.short,
      onCloseApp: () => _openCloseApp(context),
      children: [
        _Btn('LISTEN TO WORD', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TTS placeholder (offline)')),
          );
        }),
        const SizedBox(height: 14),
        _LabelBlock(heading: 'DICTIONARY', body: source),
        _LabelBlock(heading: 'PHONETIC PRONUNCIATION', body: phonetic),
        _LabelBlock(heading: 'DEFINITION', body: definition),
        _LabelBlock(heading: 'ETYMOLOGY', body: etymology),
        _LabelBlock(heading: 'EXAMPLE', body: example),
        const SizedBox(height: 10),
        _Btn('NEW RANDOM WORD', onTap: () => _pushRandomWordOrNoMore(context, replace: true)),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('SEARCH FOR A WORD', onTap: () => _search(context)),
        _Btn('HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
      ],
    );
  }
}

class NoMoreWordsAvailableScreen extends StatelessWidget {
  const NoMoreWordsAvailableScreen({super.key});

  static const List<String> _sadFaces = [
    '(;_;)',
    '(T_T)',
    '(:\')',
    '(._.)',
    '(x_x)',
    '(>_<)',
  ];

  static String _pickFace() => _sadFaces[Random().nextInt(_sadFaces.length)];

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'NO MORE WORDS AVAILABLE',
      face: _pickFace(),
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"Alas. The generator has stared into the void,\nand the void returned… zero results."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        const Text(
          'Try adjusting your RANDOMIZER SETTINGS or clearing\nyour HISTORY to generate more words!',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class WordNotFoundScreen extends StatefulWidget {
  final String typed;
  const WordNotFoundScreen({super.key, required this.typed});

  @override
  State<WordNotFoundScreen> createState() => _WordNotFoundScreenState();
}

class _WordNotFoundScreenState extends State<WordNotFoundScreen> {
  static const int pageSize = 5;
  int pageIndex = 0;

  // ✅ Updated to smart suggestions
  List<String> get _suggestions =>
      LibraryService.instance.suggestSmart(widget.typed, limit: 30);

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    final totalPages = (suggestions.length / pageSize).ceil().clamp(1, 9999);

    final start = pageIndex * pageSize;
    final end = min(start + pageSize, suggestions.length);
    final view = suggestions.isEmpty ? <String>[] : suggestions.sublist(start, end);

    return _Frame(
      title: 'WORD NOT FOUND',
      face: '(o_O)   (._.)?',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text('Sorry, we didn’t find:', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('"${widget.typed}"', textAlign: TextAlign.center),
        const SizedBox(height: 14),
        const Text('Did you mean:', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        if (suggestions.isNotEmpty && totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (pageIndex > 0)
                _MiniNavBtn('◀', onTap: () => setState(() => pageIndex--))
              else
                const SizedBox(width: 60),
              if (pageIndex < totalPages - 1)
                _MiniNavBtn('▶', onTap: () => setState(() => pageIndex++))
              else
                const SizedBox(width: 60),
            ],
          ),
        if (suggestions.isEmpty)
          const Text('(No suggestions found.)', textAlign: TextAlign.center)
        else
          for (final s in view)
            _Btn(s, onTap: () {
              SessionState.lastWord = s;
              if (!SessionState.history.contains(s)) SessionState.history.add(s);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: s)));
            }),
        const SizedBox(height: 10),
        _Btn('RETURN TO SEARCH', onTap: () async {
          final result = await _promptForWord(context);
          if (result == null) return;
          final upper = result.trim().toUpperCase();
          if (upper.isEmpty) return;

          final e = _entry(upper);
          if (e != null) {
            SessionState.lastWord = e.word;
            if (!SessionState.history.contains(e.word)) SessionState.history.add(e.word);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: e.word)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
          }
        }),
        _Btn('NEW RANDOM WORD', onTap: () => _pushRandomWordOrNoMore(context, replace: true)),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
      ],
    );
  }
}

class RandomizerSettingsScreen extends StatelessWidget {
  const RandomizerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'RANDOMIZER SETTINGS',
      face: '(－_－) z z z',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text('WORD LENGTH RANGE', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('MIN  [◀]  1  [▶]', textAlign: TextAlign.center),
        const Text('MAX  [◀] 45  [▶]', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const Text('LETTER FILTER', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('[A][B][C][D][E][F][G][H][I]', textAlign: TextAlign.center),
        const Text('[J][K][L][M][N][O][P][Q][R]', textAlign: TextAlign.center),
        const Text('[S][T][U][V][W][X][Y][Z]', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const Text('"Tiny constraints, enormous consequences."', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int pageSize = 5;
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Display alphabetically (case-insensitive)
    final items = List<String>.from(SessionState.history)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final totalPages = (items.length / pageSize).ceil().clamp(1, 9999);

    final start = pageIndex * pageSize;
    final end = min(start + pageSize, items.length);
    final view = items.sublist(start, end);

    return _Frame(
      title: 'HISTORY',
      onCloseApp: () => _openCloseApp(context),
      children: [
        if (totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (pageIndex > 0)
                _MiniNavBtn('◀', onTap: () => setState(() => pageIndex--))
              else
                const SizedBox(width: 60),
              if (pageIndex < totalPages - 1)
                _MiniNavBtn('▶', onTap: () => setState(() => pageIndex++))
              else
                const SizedBox(width: 60),
            ],
          ),
        const SizedBox(height: 10),
        for (final w in view)
          _Btn(w, onTap: () {
            SessionState.lastWord = w;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
          }),
        const SizedBox(height: 14),
        _Btn('CLEAR HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ClearHistoryConfirmScreen()));
        }),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class ClearHistoryConfirmScreen extends StatelessWidget {
  const ClearHistoryConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLEAR HISTORY?',
      face: '(⊙_⊙;)   (ﾟoﾟ;;)   (꒪꒫꒪)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"Erase your super-generations from existence…\npermanently… with your finger… right now?"',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('YES, CLEAR HISTORY', onTap: () {
          SessionState.history.clear();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryClearedScreen()));
        }),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class HistoryClearedScreen extends StatelessWidget {
  const HistoryClearedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'HISTORY CLEARED',
      face: '(─‿─)   (｡-‿-｡)   (._.)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"Your lexical footprints have been gently\nun-footprinted."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        _Btn('OKAY', onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (_) => false,
          );
        }),
      ],
    );
  }
}

class UpdateWordLibraryScreen extends StatelessWidget {
  const UpdateWordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE WORD LIBRARY',
      face: '(._.)?   (o_o)?   (?-?)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          'This will refresh words, definitions,\npronunciations, and add newly found entries.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text('[this is how you update this app’s word library]', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('This may take up to:  A WHILE', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('Last updated:  2026-02-20', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        _Btn('PROCEED', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateInProgressScreen()));
        }),
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
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = UpdateService();
      final result = await svc.runUpdatePlaceholder();

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateCompleteScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateFailedScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'DOWNLOADING & INSTALLING WORDS',
      face: '( ._. )  ( -_- )  ( ^_^ )',
      showCloseApp: false,
      children: const [
        Text(
          '"The library is being politely wrestled into\na newer shape. Please do not blink aggressively."',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 14),
        Text('PROGRESS:  [██████████░░░░░░░░░░░░]', textAlign: TextAlign.center),
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
      face: '(^_^)   (^-^)   (._.)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"Behold: refreshed definitions, newly found\nwords, and general lexical glow."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        _Btn('OKAY', onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (_) => false,
          );
        }),
      ],
    );
  }
}

class UpdateFailedScreen extends StatelessWidget {
  const UpdateFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'UPDATE DIDN’T WORK',
      face: '(x_x)   (o_o;)   (._.)',
      onCloseApp: () => _openCloseApp(context),
      children: [
        const Text(
          '"The update tripped over its own vocabulary\nand face-planted into the concept of ‘no.’"',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'No connection detected. Try again when you’re online.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        _Btn('OKAY', onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (_) => false,
          );
        }),
      ],
    );
  }
}

class CloseAppScreen extends StatelessWidget {
  const CloseAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'CLOSE APP',
      face: '( •︵• )   (｡•́︿•̀｡)   (づ_ど)',
      onCloseApp: () {
        SessionState.history.clear();
        SessionState.lastWord = null;
        SystemNavigator.pop();
      },
      children: [
        const Text(
          '"I shall remain here, quietly holding the shape\nof your unfinished sentences, until you return."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your word history will be cleared when you close\nthe app.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

/// UI helpers

enum UnderlineStyle { normal, short }

class _Frame extends StatelessWidget {
  final String title;
  final UnderlineStyle underlineStyle;
  final String face;
  final List<Widget> children;

  final VoidCallback? onCloseApp;
  final bool showCloseApp;

  const _Frame({
    required this.title,
    this.underlineStyle = UnderlineStyle.normal,
    this.face = '',
    required this.children,
    this.onCloseApp,
    this.showCloseApp = true,
  });

  @override
  Widget build(BuildContext context) {
    final underline = underlineStyle == UnderlineStyle.short ? '─────────' : '────────────────────';
    final bottomPad = (showCloseApp && onCloseApp != null) ? 90.0 : 18.0;

    return Scaffold(
      floatingActionButton: (showCloseApp && onCloseApp != null)
          ? _CornerBtn('CLOSE APP', onTap: onCloseApp!)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(underline, textAlign: TextAlign.center),
              if (face.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(face, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool small;

  const _Btn(this.text, {required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 4 : 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1C22),
          foregroundColor: const Color(0xFFB86B6B),
          padding: EdgeInsets.symmetric(vertical: small ? 10 : 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CornerBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _CornerBtn(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1C22),
        foregroundColor: const Color(0xFFB86B6B),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _MiniNavBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _MiniNavBtn(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1C22),
          foregroundColor: const Color(0xFFB86B6B),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _LabelBlock extends StatelessWidget {
  final String heading;
  final String body;
  const _LabelBlock({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
