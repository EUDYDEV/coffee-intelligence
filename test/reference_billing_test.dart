import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/core/i18n/strings.dart';
import 'package:coffee_intelligence/data/account_data.dart';
import 'package:coffee_intelligence/data/reference_data.dart';
import 'package:coffee_intelligence/features/account/account_page.dart';
import 'package:coffee_intelligence/features/reference/reference_page.dart';
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

  test('catalogue: 25 focal points (one per member country), every indicator documented in FR and EN', () {
    expect(focalPoints.map((f) => f.country).toSet(), memberCountries.toSet());
    expect(focalPoints.length, 25);
    for (final i in indicatorCatalogue) {
      for (final lang in ['fr', 'en']) {
        for (final k in [i.nameKey, i.defKey, i.methodKey]) {
          expect(Strings.t(lang, k), isNot(k), reason: '$lang $k');
          expect(Strings.t(lang, k).length, greaterThan(3), reason: '$lang $k');
        }
      }
    }
    for (final f in focalPoints) {
      expect(Strings.t('fr', f.titleKey), isNot(f.titleKey));
    }
  });

  for (final e in {'phone': const Size(390, 844), 'desktop': const Size(1440, 900)}.entries) {
    testWidgets('reference page: three tabs render @ ${e.key}', (t) async {
      t.view.physicalSize = e.value;
      t.view.devicePixelRatio = 1;
      final s = AppState()..showLanding = false;
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ReferencePage())))));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Pays membres'), findsWidgets);
      await t.tap(find.text('Points focaux'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Awa Koné'), findsOneWidget);
      await t.tap(find.text('Indicateurs'));
      await t.pump(const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Rendement'));
      await t.tap(find.text('Rendement'));
      await t.pump(const Duration(milliseconds: 900));
      expect(find.text('MODE DE CALCUL'), findsOneWidget);
    });
  }

  testWidgets('billing details are saved on the account and used by the receipt/payment', (t) async {
    t.view.physicalSize = const Size(1200, 3000);
    t.view.devicePixelRatio = 1;
    final s = AppState()..showLanding = false;
    s.loginVisitor('ada', '');
    s.subscribe('pro', 'year', 'momo');
    await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AccountPage())))));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Données de facturation et de paiement'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('Annuel'), findsWidgets);
    s.saveBilling({'name': 'Union Sidama', 'method': 'card'});
    expect(s.me!.billing['name'], 'Union Sidama');
    expect(Account.fromJson(s.me!.toJson()).billing['method'], 'card');
  });
}
