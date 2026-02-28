// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const WordsForNerdsApp());
}

class WordsForNerdsApp extends StatelessWidget {
  const WordsForNerdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Words For Nerds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/update-complete': (_) => const UpdateCompleteScreen(),
      },
    );
  }
}

/// Simple home so the project compiles and you can navigate to the fixed screen.
/// Replace this with your real home screen later if needed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Words For Nerds')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap below to open the screen that was failing your build.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/update-complete'),
                          child: const Text('Open UpdateCompleteScreen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ FIXED: `_Frame` is defined below, so `UpdateCompleteScreen` compiles.
/// This replaces the broken call where `_Frame` didn't exist.
class UpdateCompleteScreen extends StatelessWidget {
  const UpdateCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Frame(
      title: 'Update Complete',
      child: _UpdateCompleteBody(),
    );
  }
}

class _UpdateCompleteBody extends StatelessWidget {
  const _UpdateCompleteBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 72),
        const SizedBox(height: 12),
        const Text(
          'All set!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your changes have been applied successfully.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

/// Minimal wrapper so `_Frame(...)` is ALWAYS defined.
class _Frame extends StatelessWidget {
  final String title;
  final Widget child;

  const _Frame({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
