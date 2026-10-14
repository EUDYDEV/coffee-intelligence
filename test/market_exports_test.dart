import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/features/market/market_page.dart';
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
  for (final e in {'phone': const Size(390, 844), 'desktop': const Size(1440, 900)}.entries) {
    testWidgets('Market page shows the exports indicator @ ${e.key}', (t) async {
      t.view.physicalSize = e.value;
      t.view.devicePixelRatio = 1;
      final s = AppState()..showLanding = false;
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MarketPage())))));
      await t.pump(const Duration(seconds: 2));
      expect(find.text('EXPORTATIONS (PAYS MEMBRES)'), findsOneWidget);
    });
  }
}
