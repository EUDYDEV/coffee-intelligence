import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/features/shell/app_shell.dart';
import 'package:coffee_intelligence/features/shell/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    for (final f in {'Inter': 'assets/fonts/Inter.ttf', 'Playfair': 'assets/fonts/PlayfairDisplay.ttf'}.entries) {
      final bytes = await File(f.value).readAsBytes();
      await (FontLoader(f.key)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });
  AppState.pageIds = navItems.map((e) => e.id).toList();
  final sizes = <String, Size>{'phone': const Size(360, 780), 'landscape': const Size(780, 360), 'tablet': const Size(820, 1180)};
  for (final screen in ['login', 'chooser', 'admin-landscape', 'coop-landscape']) {
    for (final e in sizes.entries) {
      testWidgets('$screen @ ${e.key}', (t) async {
        t.view.physicalSize = e.value;
        t.view.devicePixelRatio = 1;
        final s = AppState()..showLanding = false;
        final errs = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) => errs.add('${d.exceptionAsString().split('\n').first} @ ${RegExp(r'lib/[^\s:]*\.dart:\d+').firstMatch(d.toString())?.group(0)}');
        addTearDown(() => FlutterError.onError = old);
        if (screen == 'login') s.openLogin();
        if (screen == 'chooser') { s.login('', ''); }
        if (screen == 'admin-landscape') { s.login('', ''); s.showRoleChooser = false; s.setAdminView(true); }
        if (screen == 'coop-landscape') { s.setRole('coop'); }
        await t.pumpWidget(AppScope(state: s, child: MaterialApp(debugShowCheckedModeBanner: false, home: const AppShell())));
        await t.pump(const Duration(seconds: 2));
        if (screen.endsWith('landscape')) {
          for (var i = 0; i < 4; i++) { screen.startsWith('admin') ? s.gotoAdmin(i) : s.goto(i); await t.pump(const Duration(seconds: 1)); }
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 3));
        // ignore: avoid_print
        for (final x in errs.toSet()) { print('ERR $screen/${e.key}: $x'); }
        expect(errs, isEmpty);
      });
    }
  }
}
