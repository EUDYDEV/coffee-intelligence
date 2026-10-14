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

    test('front-end sign-in is always accepted: existing account found, unknown identifier opens a demo account', () {
      final s = AppState();
      _reg(s);
      expect(s.loginVisitor('ada', 'anything'), isNull);
      expect(s.me?.email, 'ada@example.org');
      expect(s.me?.verified, isTrue);
      s.logoutAll();
      expect(s.me, isNull);
      expect(s.loginVisitor('', ''), isNull, reason: 'empty fields accepted');
      expect(s.me, isNotNull);
      s.logoutAll();
      expect(s.loginVisitor('kofi@example.org', 'x'), isNull);
      expect(s.me?.email, 'kofi@example.org');
    });

    test('partners: private spaces only for partners; public users stay in the public space', () {
      final s = AppState()..showLanding = false;
      s.loginVisitor('ada', '');
      s.enterAfterAuth();
      expect(s.role, 'public');
      s.setRole('coop');
      expect(s.role, 'public', reason: 'a public user cannot open a partner space');
      s.logoutAll();
      s.loginPartner('Union Sidama', 'p-01');
      expect(s.partner, isTrue);
      expect(s.showRoleChooser, isTrue);
      s.setRole('exporter');
      expect(s.role, 'exporter');
      expect(s.canDownload, isTrue, reason: 'downloads included for partners');
      s.logoutAll();
      expect(s.partner, isFalse);
      expect(s.role, 'public');
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
      expect(find.text('Géolocalisation approximative'.toUpperCase()), findsOneWidget);
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
    expect(find.text('Ada Kouassi'), findsWidgets);
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
    await type('Adresse', 'Rue des Jardins, Cocody');
    await type('Ville', 'Abidjan');

    await t.ensureVisible(find.text('Pays'));
    await t.tap(find.text('Pays'));
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
    testWidgets('entrance: public user goes to the public space; partner chooses a private space @ ${e.key}', (t) async {
      t.view.physicalSize = e.value;
      t.view.devicePixelRatio = 1;
      AppState.pageIds = navItems.map((n) => n.id).toList();
      final s = AppState()
        ..showLanding = false
        ..accountsReady = true;
      await t.pumpWidget(AppScope(state: s, child: MaterialApp(home: const AppShell())));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Identification du visiteur'), findsOneWidget);
      // public user: sign-in tab, empty fields accepted
      await t.tap(find.text('Se connecter').first);
      await t.pump(const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Me connecter'));
      await t.tap(find.text('Me connecter'));
      await t.pump(const Duration(seconds: 2));
      expect(s.me, isNotNull);
      expect(s.role, 'public');
      expect(find.text('Identification du visiteur'), findsNothing);
      expect(find.text('Choisissez votre espace partenaire'), findsNothing);
      // sign out → entrance; partner tab
      s.logoutAll();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Identification du visiteur'), findsOneWidget);
      await t.tap(find.text('Espace partenaire'));
      await t.pump(const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Accéder à l’espace partenaire'));
      await t.tap(find.text('Accéder à l’espace partenaire'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Choisissez votre espace partenaire'), findsOneWidget);
      s.setRole('roaster');
      await t.pump(const Duration(seconds: 2));
      expect(s.role, 'roaster');
      s.logoutAll();
      await t.pump(const Duration(seconds: 1));
    });
  }
}
