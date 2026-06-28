import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notifiers/typing_notifier.dart';
import 'notifiers/timer_notifier.dart';
import 'notifiers/test_notifier.dart';
import 'notifiers/settings_notifier.dart';
import 'pages/home_page.dart';
import 'pages/result_page.dart';

void main() {
  runApp(const TypePracticeApp());
}

class TypePracticeApp extends StatelessWidget {
  const TypePracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TypingNotifier()),
        ChangeNotifierProvider(create: (_) => TimerNotifier()),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
        ChangeNotifierProvider(
          create: (ctx) => TestNotifier(
            typingNotifier: ctx.read<TypingNotifier>(),
            timerNotifier: ctx.read<TimerNotifier>(),
            settings: ctx.read<SettingsNotifier>(),
          ),
        ),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (_, settings, child) => MaterialApp(
          title: '打字练习',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          initialRoute: '/',
          routes: {
            '/': (_) => const HomePage(),
            '/result': (_) => const ResultPage(),
          },
        ),
      ),
    );
  }
}
