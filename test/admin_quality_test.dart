import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/features/admin/admin_pages2.dart';
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

  testWidgets('data quality: validate / reject / correct update issue status', (t) async {
    t.view.physicalSize = const Size(1440, 2400);
    t.view.devicePixelRatio = 1;
    final s = AppState()..showLanding = false;
    await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: const AdminQualityPage())))));
    await t.pump(const Duration(seconds: 2));
    expect(s.issues.where((i) => i.status == 0).length, 8);

    await t.tap(find.byIcon(Icons.check_rounded).first);
    await t.pump(const Duration(milliseconds: 500));
    expect(s.issues.where((i) => i.status == 1).length, 1, reason: 'Valider');

    await t.tap(find.byIcon(Icons.close_rounded).first);
    await t.pump(const Duration(milliseconds: 500));
    expect(s.issues.where((i) => i.status == 2).length, 1, reason: 'Rejeter');

    await t.tap(find.byIcon(Icons.edit_rounded).first);
    await t.pump(const Duration(milliseconds: 600));
    await t.enterText(find.byType(TextField).last, '777');
    await t.tap(find.byType(FilledButton).last);
    await t.pump(const Duration(milliseconds: 800));
    final c = s.issues.where((i) => i.status == 3).toList();
    expect(c.length, 1, reason: 'Corriger');
    expect(c.first.corrected, 777);
    expect(s.issues.where((i) => i.status == 0).length, 5);
  });
}
