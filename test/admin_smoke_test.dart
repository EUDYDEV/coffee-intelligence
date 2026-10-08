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
  final sizes = <String, Size>{'phone': const Size(360, 780), 'tablet': const Size(820, 1180), 'desktop': const Size(1440, 900)};
  for (final lang in ['fr', 'en']) {
    for (final e in sizes.entries) {
      testWidgets('admin $lang @ ${e.key}', (t) async {
        t.view.physicalSize = e.value;
        t.view.devicePixelRatio = 1;
        final s = AppState()..showLanding = false;
        s.setLang(lang);
        s.login('', '');
        s.showRoleChooser = false;
        s.setAdminView(true);
        final seen = <String>{};
        var where = '';
        final old = FlutterError.onError;
        var noise = false;
        FlutterError.onError = (d) {
          final m = d.toString();
          if (m.contains('LayoutBuilder does not support returning intrinsic')) noise = true;
          if (noise && (m.contains('was not laid out') || m.contains('childSemantics') || m.contains('parentDataDirty') || m.contains('LayoutBuilder does not support'))) return;
          final ex = d.exceptionAsString().split('\n').first;
          final loc = RegExp(r'lib/[^\s:]*\.dart:\d+').firstMatch(m)?.group(0) ?? '?';
          if (seen.add('$ex$loc')) {
            final st = d.stack.toString().split(String.fromCharCode(10)).where((l) => l.contains('package:coffee')).take(3).join(' <- ');
            // ignore: avoid_print
            print('ERR admin/$lang/${e.key}: $ex @ $loc [$where] | $st');
          }
        };
        addTearDown(() => FlutterError.onError = old);
        await t.pumpWidget(AppScope(state: s, child: MaterialApp(debugShowCheckedModeBanner: false, home: const AppShell())));
        await t.pump(const Duration(seconds: 1));
        for (var i = 0; i < 11; i++) {
          s.gotoAdmin(i);
          where = 'adminPage $i';
          await t.pump(const Duration(milliseconds: 1500));
          t.takeException();
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 3));
        expect(seen, isEmpty);
      });
    }
  }
}
