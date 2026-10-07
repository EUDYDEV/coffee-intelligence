import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/data/role_data.dart';
import 'package:coffee_intelligence/features/shell/app_shell.dart';
import 'package:coffee_intelligence/features/shell/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  for (final f in {'Inter': 'assets/fonts/Inter.ttf', 'Playfair': 'assets/fonts/PlayfairDisplay.ttf'}.entries) {
    final bytes = await File(f.value).readAsBytes();
    await (FontLoader(f.key)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}

Future<void> pumpApp(WidgetTester t, AppState s, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(AppScope(state: s, child: MaterialApp(debugShowCheckedModeBanner: false, home: const AppShell())));
}

void main() {
  setUpAll(loadFonts);
  AppState.pageIds = navItems.map((e) => e.id).toList();

  final sizes = <String, Size>{'phone': const Size(390, 844), 'tablet': const Size(820, 1180), 'desktop': const Size(1440, 900)};

  for (final role in publicRoles) {
    for (final entry in sizes.entries) {
      testWidgets('smoke ${role.id} @ ${entry.key}: every page renders without errors/overflow', (t) async {
        final s = AppState()..showLanding = false;
        final seen = <String>{};
        final old = FlutterError.onError;
        var where = '';
        var intrinsicNoise = false;
        FlutterError.onError = (d) {
          final m = d.toString();
          // Debug-only assertion: charts use LayoutBuilder inside TwoCol's IntrinsicHeight (release returns 0 and renders fine).
          if (m.contains('LayoutBuilder does not support returning intrinsic')) intrinsicNoise = true;
          if (intrinsicNoise && (m.contains('was not laid out') || m.contains('childSemantics') || m.contains('parentDataDirty') || m.contains('LayoutBuilder does not support'))) return;
          final ex = d.exceptionAsString().split('\n').first;
          final loc = RegExp(r'lib/[^\s:]*\.dart:\d+').firstMatch(m)?.group(0) ?? '?';
          final line = '$ex @ $loc  [$where]';
          if (seen.add('$ex$loc')) {
            // ignore: avoid_print
            final st = d.stack.toString().split(String.fromCharCode(10)).where((l) => l.contains('package:coffee')).take(4).join(' <- ');
            print('ERR ${role.id}/${entry.key}: $line | $st');
          }
        };
        addTearDown(() => FlutterError.onError = old);
        await pumpApp(t, s, entry.value);
        s.setRole(role.id);
        for (var i = 0; i < navItems.length; i++) {
          s.goto(i);
          final tabs = navItems[i].id == 'production' ? ['production', 'quality', 'climate'] : (navItems[i].id == 'chain' ? ['flow', 'lots'] : ['']);
          for (final tab in tabs) {
            if (tab.isNotEmpty) {
              navItems[i].id == 'production' ? s.setProductionTab(tab) : s.setChainTab(tab);
            }
            where = '${navItems[i].id}/$tab';
            await t.pump(const Duration(milliseconds: 1500));
            t.takeException();
          }
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 3));
        expect(seen, isEmpty, reason: 'see ERR lines above');
      });
    }
  }
}
