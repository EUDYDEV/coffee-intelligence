import 'dart:io';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/data/account_data.dart';
import 'package:coffee_intelligence/features/account/account_page.dart';
import 'package:coffee_intelligence/features/account/account_widgets.dart';
import 'package:coffee_intelligence/features/shell/app_shell.dart';
import 'package:coffee_intelligence/features/shell/nav.dart';
import 'package:coffee_intelligence/widgets/export_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String? _reg(AppState s, {String mail = 'ada@example.org', String user = 'ada'}) => s.register(
      fullName: 'Ada Kouassi',
      username: user,
      email: mail,
      password: 'Secret123',
      country: 'CIV',
      city: 'Abidjan',
      address: '',
      birth: DateTime(1990, 5, 1),
      gender: 'f',
    );

void main() {
  setUpAll(() async {
    for (final f in {'Inter': 'assets/fonts/Inter.ttf', 'Playfair': 'assets/fonts/PlayfairDisplay.ttf'}.entries) {
      final bytes = await File(f.value).readAsBytes();
      await (FontLoader(f.key)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  group('accounts (logic)', () {
    test('register → verify → signed in; password is hashed; email and username are unique', () {
      final s = AppState();
      expect(_reg(s), isNull);
      expect(s.pendingCode, hasLength(6));
      expect(s.accounts.single.passHash, isNot(contains('Secret123')));
      expect(s.me, isNull, reason: 'not signed in before the e-mail code is validated');
      expect(s.verifyCode('000000'), 'acc_err_code');
      expect(s.verifyCode(s.pendingCode!), isNull);
      expect(s.me?.email, 'ada@example.org');
      expect(s.me?.verified, isTrue);
      expect(_reg(s), 'acc_err_email_taken');
      expect(_reg(s, mail: 'other@example.org'), 'acc_err_user_taken');
    });

    test('sign in / out with e-mail or username; wrong password refused; unverified account asks for the code', () {
      final s = AppState();
      _reg(s);
      expect(s.loginVisitor('ada', 'Secret123'), 'acc_err_unverified');
      expect(s.verifyCode(s.pendingCode!), isNull);
      s.logoutVisitor();
      expect(s.me, isNull);
      expect(s.loginVisitor('ada@example.org', 'wrong'), 'acc_err_login');
      expect(s.loginVisitor('ADA', 'Secret123'), isNull);
      expect(s.me, isNotNull);
    });

    test('downloads are blocked without a subscription, allowed with one (and for the demo admin)', () {
      final s = AppState();
      expect(s.canDownload, isFalse);
      _reg(s);
      s.verifyCode(s.pendingCode!);
      expect(s.canDownload, isFalse, reason: 'account alone does not allow downloads');
      s.buyItem('csv', 'csv|market', 'momo');
      expect(s.canDownload, isFalse, reason: 'one-off payment only covers that download');
      expect(s.me!.purchases.single.amountUsd, itemPriceUsd('csv'));
      s.subscribe('pro', 'month', 'card');
      expect(s.canDownload, isTrue);
      expect(s.me!.planUntil!.isAfter(DateTime.now().add(const Duration(days: 29))), isTrue);
      s.me!.planUntil = DateTime.now().subtract(const Duration(days: 1));
      expect(s.canDownload, isFalse, reason: 'expired plan');
      final admin = AppState()..admin = true;
      expect(admin.canDownload, isTrue);
    });

    test('the 25 member countries are listed', () {
      expect(memberCountries.length, 25);
      expect(memberCountries.toSet().length, 25);
    });
  });

  group('paywall (UI)', () {
    testWidgets('export without subscription opens the paywall; one-off payment completes it', (t) async {
      t.view.physicalSize = const Size(900, 1400);
      t.view.devicePixelRatio = 1;
      final s = AppState()..showLanding = false;
      _reg(s);
      s.verifyCode(s.pendingCode!);
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: Center(child: ExportButton(pageId: 'market'))))));
      await t.tap(find.text('Exporter'));
      await t.pumpAndSettle();
      await t.tap(find.text('PDF').first);
      await t.pumpAndSettle();
      expect(find.text('Téléchargement réservé'), findsOneWidget);
      // one-off price button (PDF)
      await t.tap(find.byIcon(Icons.download_rounded).first);
      await t.pumpAndSettle();
      expect(find.text('Paiement'), findsOneWidget);
      await t.tap(find.byIcon(Icons.lock_rounded).last);
      await t.pump(const Duration(milliseconds: 1500));
      await t.pumpAndSettle();
      expect(s.me!.purchases, hasLength(1));
      expect(s.me!.purchases.first.kind, 'item');
      expect(find.text('Téléchargement réservé'), findsNothing, reason: 'dialog closed after payment');
    });

    testWidgets('signed-out visitor is asked to sign in first', (t) async {
      t.view.physicalSize = const Size(900, 1400);
      t.view.devicePixelRatio = 1;
      final s = AppState()..showLanding = false;
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: Center(child: ExportButton(pageId: 'market'))))));
      await t.tap(find.text('Exporter'));
      await t.pumpAndSettle();
      await t.tap(find.text('CSV').first);
      await t.pumpAndSettle();
      expect(find.text('Connectez-vous ou créez un compte pour continuer.'), findsOneWidget);
      await t.tap(find.text('Se connecter / créer un compte'));
      await t.pumpAndSettle();
      expect(find.text('Compte requis'), findsOneWidget);
      expect(find.text('Nom et prénoms'), findsOneWidget);
      expect(find.text('Pays (membre de l’organisation)'), findsOneWidget);
    });
  });

  testWidgets('account page renders signed out and signed in', (t) async {
    t.view.physicalSize = const Size(1200, 1800);
    t.view.devicePixelRatio = 1;
    final s = AppState()..showLanding = false;
    await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AccountPage())))));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Créer mon compte'), findsOneWidget);
    _reg(s);
    s.verifyCode(s.pendingCode!);
    s.subscribe('pro', 'year', 'bank');
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Ada Kouassi'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);
  });

  testWidgets('sign-up form: fill every field, validate the e-mail code, end up signed in', (t) async {
    t.view.physicalSize = const Size(1200, 3000);
    t.view.devicePixelRatio = 1;
    final s = AppState()..showLanding = false;
    await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AccountPage())))));
    await t.pump(const Duration(seconds: 1));

    // submitting an empty form is refused
    await t.ensureVisible(find.text('Créer mon compte'));
    await t.tap(find.text('Créer mon compte'));
    await t.pump(const Duration(milliseconds: 300));
    expect(s.accounts, isEmpty);
    expect(find.textContaining('Complétez tous les champs obligatoires'), findsOneWidget);

    Future<void> type(String label, String value) async {
      final f = find.widgetWithText(TextFormField, label);
      await t.ensureVisible(f);
      await t.enterText(f, value);
    }

    await type('Nom et prénoms', 'Ada Kouassi');
    await type('Nom d’utilisateur (pseudo)', 'ada_k');
    await type('Adresse e-mail', 'ada@example.org');
    await type('Mot de passe', 'Secret123');
    await type('Confirmer le mot de passe', 'Secret123');
    await type('Ville', 'Abidjan');

    await t.ensureVisible(find.text('Pays (membre de l’organisation)'));
    await t.tap(find.text('Pays (membre de l’organisation)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Côte d’Ivoire').last);
    await t.pumpAndSettle();

    await t.ensureVisible(find.text('Choisir une date (18 ans ou plus)'));
    await t.tap(find.text('Choisir une date (18 ans ou plus)'));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    await t.ensureVisible(find.text('Genre'));
    await t.tap(find.text('Genre'));
    await t.pumpAndSettle();
    await t.tap(find.text('Femme').last);
    await t.pumpAndSettle();

    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pump();

    await t.ensureVisible(find.text('Créer mon compte'));
    await t.tap(find.text('Créer mon compte'));
    await t.pumpAndSettle();
    expect(s.accounts.single.country, 'CIV');
    expect(s.accounts.single.username, 'ada_k');
    expect(find.text('Vérifiez votre adresse e-mail'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'Code de vérification'), s.pendingCode!);
    await t.tap(find.text('Valider le code'));
    await t.pumpAndSettle();
    expect(s.me?.email, 'ada@example.org');
    expect(find.text('Ada Kouassi'), findsWidgets);
  });

  for (final e in {'phone': const Size(360, 780), 'tablet': const Size(820, 1180), 'desktop': const Size(1440, 900)}.entries) {
    testWidgets('no overflow: paywall steps + signed-in account page @ ${e.key}', (t) async {
      t.view.physicalSize = e.value;
      t.view.devicePixelRatio = 1;
      final s = AppState()..showLanding = false;
      Future<void> pump(Widget w) async {
        await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: Scaffold(body: w))));
        await t.pump(const Duration(seconds: 1));
      }

      // 1. signed out: paywall offer → auth step
      await pump(Center(child: Builder(builder: (c) => TextButton(onPressed: () => ensureDownloadAccess(c, kind: 'pdf', ref: 'market'), child: const Text('GO')))));
      await t.tap(find.text('GO'));
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(find.text('Se connecter / créer un compte'));
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(find.text('Se connecter').last);
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(find.byIcon(Icons.arrow_back_rounded));
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(find.byIcon(Icons.close_rounded).first);
      await t.pump(const Duration(milliseconds: 700));

      // 2. signed in: paywall plan → payment step, then the account page
      _reg(s);
      s.verifyCode(s.pendingCode!);
      await t.tap(find.text('GO'));
      await t.pump(const Duration(milliseconds: 700));
      await t.ensureVisible(find.text('Choisir cette formule').first);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Choisir cette formule').first);
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(find.byIcon(Icons.close_rounded).first);
      await t.pump(const Duration(milliseconds: 700));
      s.subscribe('pro', 'year', 'card');
      await pump(const SingleChildScrollView(child: AccountPage()));
      await pump(const SingleChildScrollView(child: AccountPage()));
    });
  }

  for (final e in {'phone': const Size(360, 780), 'tablet': const Size(820, 1180)}.entries) {
    testWidgets('entrance: visitor identifies, chooses a profile, then enters the platform @ ${e.key}', (t) async {
      t.view.physicalSize = e.value;
      t.view.devicePixelRatio = 1;
      AppState.pageIds = navItems.map((n) => n.id).toList();
      final s = AppState()
        ..showLanding = false
        ..accountsReady = true;
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: const AppShell())));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Identification du visiteur'), findsOneWidget);
      expect(find.text('Centre de décision'), findsNothing, reason: 'dashboard not reachable before identification');
      await t.tap(find.text('Continuer avec Google'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Choisissez votre profil'), findsOneWidget);
      s.setRole('coop');
      await t.pump(const Duration(seconds: 2));
      expect(find.text('Identification du visiteur'), findsNothing);
      expect(s.me, isNotNull);
      s.logoutVisitor();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Identification du visiteur'), findsOneWidget, reason: 'sign-out returns to the entrance');
    });
  }
}
