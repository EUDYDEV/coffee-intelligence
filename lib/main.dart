import 'package:flutter/material.dart';
import 'app/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/nav.dart';

void main() {
  AppState.pageIds = navItems.map((e) => e.id).toList();
  runApp(const CoffeeIntelligenceApp());
}

class CoffeeIntelligenceApp extends StatefulWidget {
  const CoffeeIntelligenceApp({super.key});
  @override
  State<CoffeeIntelligenceApp> createState() => _CoffeeIntelligenceAppState();
}

class _CoffeeIntelligenceAppState extends State<CoffeeIntelligenceApp> {
  final AppState _state = AppState()..applyUri(Uri.base);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope sits above MaterialApp so dialogs / sheets can read it too.
    return AppScope(
      state: _state,
      child: Builder(builder: (context) {
        final s = AppScope.of(context);
        return MaterialApp(
          title: 'OIAC / IACO',
          debugShowCheckedModeBanner: false,
          themeMode: s.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeAnimationDuration: const Duration(milliseconds: 600),
          themeAnimationCurve: Curves.easeInOut,
          home: const AppShell(),
        );
      }),
    );
  }
}
