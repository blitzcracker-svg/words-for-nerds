import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/update_service.dart';

void main() {
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
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Times New Roman',
            ),
      ),
      home: const LaunchScreen(),
    );
  }
}

/// In-memory session state (does not clear when you switch apps).
class SessionState {
  static final List<String> history = [];
  static String? lastWord;
}

/// Simple placeholder word pool for testing navigation.
/// (We will replace this later with your real offline library + update flow.)
const List<String> demoWords = [
  'EPHEMERAL',
  'ETHEREAL',
  'ZEPHYR',
  'LABYRINTH',
  'ZENITH',
  'EFFERVESCENT',
  'OBFUSCATE',
  'PANACEA',
  'MELLIFLUOUS',
  'LIMINAL',
  'SYCOPHANT',
];

String randomDemoWord() => demoWords[Random().nextInt(demoWords.length)];

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  void _goWord(BuildContext context) {
    final w = randomDemoWord();
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _search(BuildContext context) async {
    final result = await _promptForWord(context);
    if (result == null) return;

    final upper = result.trim().toUpperCase();
    if (upper.isEmpty) return;

    if (demoWords.contains(upper)) {
      SessionState.lastWord = upper;
      if (!SessionState.history.contains(upper)) SessionState.history.add(upper);
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordScreen(word: upper)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'WORDS FOR NERDS',
      face: '(≧◡≦)',
      children: [
        const Text(
          '"Lexical evolution is a strange little mirror."',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('CLICK HERE FOR A RANDOM WORD', onTap: () => _goWord(context)),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('CLICK HERE TO SEARCH FOR A WORD', onTap: () => _search(context)),
        _Btn('UPDATE WORD LIBRARY (LAST: 2026-02-20)', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateWordLibraryScreen()));
        }),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
      ],
    );
  }
}

class WordScreen extends StatelessWidget {
  final String word;
  const WordScreen({super.key, required this.word});

  void _newRandom(BuildContext context) {
    final w = randomDemoWord();
    SessionState.lastWord = w;
    if (!SessionState.history.contains(w)) SessionState.history.add(w);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
  }

  void _search(BuildContext context) async {
    final result = await _promptForWord(context);
    if (result == null) return;
    final upper = result.trim().toUpperCase();
    if (upper.isEmpty) return;

    if (demoWords.contains(upper)) {
      SessionState.lastWord = upper;
      if (!SessionState.history.contains(upper)) SessionState.history.add(upper);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: upper)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: word,
      underlineStyle: UnderlineStyle.short,
      face: '',
      children: [
        _Btn('LISTEN TO WORD', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TTS placeholder (offline)')),
          );
        }),
        const SizedBox(height: 14),
        const _LabelBlock(heading: 'DICTIONARY', body: 'Merriam-Webster'),
        const _LabelBlock(heading: 'PHONETIC PRONUNCIATION', body: 'ih-FEM-uh-rəl'),
        const _LabelBlock(heading: 'DEFINITION', body: 'lasting for a very short time'),
        const _LabelBlock(heading: 'ETYMOLOGY', body: 'from Greek “ephemeros” (lasting a day)'),
        const _LabelBlock(heading: 'EXAMPLE', body: '“The fog was ephemeral, fading before noon.”'),
        const SizedBox(height: 10),
        _Btn('NEW RANDOM WORD', onTap: () => _newRandom(context)),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('SEARCH FOR A WORD', onTap: () => _search(context)),
        _Btn('HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
      ],
    );
  }
}

class WordNotFoundScreen extends StatelessWidget {
  final String typed;
  const WordNotFoundScreen({super.key, required this.typed});

  List<String> _suggestions() {
    // Placeholder suggestions (we’ll replace with real “did you mean” later).
    return demoWords.toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions();

    // Paging: 5 per page (like history). For now we show page 1.
    const pageSize = 5;
    final totalPages = (suggestions.length / pageSize).ceil();
    final pageIndex = 0;

    final start = pageIndex * pageSize;
    final end = min(start + pageSize, suggestions.length);
    final view = suggestions.sublist(start, end);

    return _Frame(
      title: 'WORD NOT FOUND',
      face: '(o_O)   (._.)?',
      children: [
        const Text('Sorry, we didn’t find:', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('"$typed"', textAlign: TextAlign.center),
        const SizedBox(height: 14),
        const Text('Did you mean:', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        if (totalPages > 1)
          const Align(
            alignment: Alignment.centerRight,
            child: Text('[ ▶ ]'),
          ),
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
          if (demoWords.contains(upper)) {
            SessionState.lastWord = upper;
            if (!SessionState.history.contains(upper)) SessionState.history.add(upper);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: upper)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordNotFoundScreen(typed: upper)));
          }
        }),
        _Btn('NEW RANDOM WORD', onTap: () {
          final w = randomDemoWord();
          SessionState.lastWord = w;
          if (!SessionState.history.contains(w)) SessionState.history.add(w);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
        }),
        _Btn('RANDOMIZER SETTINGS', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RandomizerSettingsScreen()));
        }),
        _Btn('HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = SessionState.history;
    const pageSize = 5;
    final showArrows = items.length > pageSize;
    final visible = items.take(pageSize).toList();

    return _Frame(
      title: 'HISTORY',
      children: [
        if (showArrows)
          const Align(
            alignment: Alignment.centerRight,
            child: Text('[ ▶ ]'),
          ),
        const SizedBox(height: 10),
        for (final w in visible)
          _Btn(w, onTap: () {
            SessionState.lastWord = w;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordScreen(word: w)));
          }),
        const SizedBox(height: 14),
        _Btn('CLEAR HISTORY', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ClearHistoryConfirmScreen()));
        }),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
      children: [
        const Text(
          '“Erase your super-generations from existence…\npermanently… with your finger… right now?”',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('YES, CLEAR HISTORY', onTap: () {
          SessionState.history.clear();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryClearedScreen()));
        }),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
      children: [
        const Text('“Your lexical footprints have been gently\nun-footprinted.”', textAlign: TextAlign.center),
        const SizedBox(height: 14),
        _Btn('OKAY', onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (_) => false,
          );
        }),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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

    // Start update after first frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = UpdateService();
      final result = await svc.runUpdatePlaceholder();

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UpdateCompleteScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UpdateFailedScreen()),
        );
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
          '“The library is being politely wrestled into\na newer shape. Please do not blink aggressively.”',
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
      children: [
        const Text(
          '“Behold: refreshed definitions, newly found\nwords, and general lexical glow.”',
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
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
      children: [
        const Text(
          '“The update tripped over its own vocabulary\nand face-planted into the concept of ‘no.’”',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text('(Your library has been restored to its previous\nstate.)', textAlign: TextAlign.center),
        const SizedBox(height: 14),
        _Btn('OKAY', onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (_) => false,
          );
        }),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAppScreen()));
          }),
        )
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
      children: [
        const Text(
          '“I shall remain here, quietly holding the shape\nof your unfinished sentences, until you return.”',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your word history will be cleared when you close\nthe app.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Btn('BACK TO LAST SCREEN', onTap: () => Navigator.pop(context)),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _Btn('CLOSE APP', small: true, onTap: () {
            SessionState.history.clear();
            SessionState.lastWord = null;
            SystemNavigator.pop();
          }),
        )
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
  final bool showCloseApp;

  const _Frame({
    required this.title,
    this.underlineStyle = UnderlineStyle.normal,
    this.face = '',
    required this.children,
    this.showCloseApp = true,
  });

  @override
  Widget build(BuildContext context) {
    final underline = underlineStyle == UnderlineStyle.short ? '─────────' : '────────────────────';

    return Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
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
