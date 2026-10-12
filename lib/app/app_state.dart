import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/account_data.dart';
import '../core/format.dart';
import '../data/admin2_data.dart';
import '../data/admin_data.dart';
import '../data/role_data.dart';
import '../models/models.dart';

/// Global UI state (theme, language, motion, navigation, user-created alerts).
class AppState extends ChangeNotifier {
  /// Page ids in navigation order (set once by the navigation module).
  static List<String> pageIds = const [];
  static const exportable = {'decision', 'market', 'production', 'revenue', 'sustain', 'certs', 'chain', 'map', 'compare', 'forecast', 'anomalies', 'alerts', 'sources'};
  static String? currentPageId(int i) => i >= 0 && i < pageIds.length ? pageIds[i] : null;

  ThemeMode themeMode = ThemeMode.light;
  String lang = 'fr';
  bool reduceMotion = false;
  bool showLanding = true;
  bool presentation = false;
  bool autoPlay = false;
  int page = 0;
  String selectedCountry = 'ETH';
  final List<UserAlert> userAlerts = [];

  GlobalKey exportKey = GlobalKey(); // page content captured for PNG export

  // ---- simulated profile (role) ----
  String role = 'board';
  String myCoop = 'c2'; // cooperative of the "farmer / cooperative" profile
  String myCountry = 'CIV'; // country of the "national board" profile
  String productionTab = 'production'; // production | quality | climate
  String chainTab = 'flow'; // flow | lots
  String selectedLot = '';
  bool showRoleChooser = false;
  bool navExpanded = false;
  final Map<String, List<int>> kpiOrder = {}; // per profile, drag-and-drop order of the KPI cards
  void setKpiOrder(List<int> o) {
    kpiOrder[role] = o;
    notifyListeners();
  }

  RoleDef get roleDef => roleById(role);
  bool isRestricted(String pageId) => roleDef.restricted.contains(pageId);

  void setRole(String id, {bool go = true}) {
    role = id;
    guideDone.add('gc_profile');
    final r = roleById(id);
    productionTab = r.productionTab;
    chainTab = r.chainTab;
    showRoleChooser = false;
    showLanding = false;
    if (id == 'admin' && admin) {
      adminView = true;
    } else {
      adminView = false;
      if (go) page = 0; // decision center is always first
    }
    addLog('log_role', id);
    notifyListeners();
  }

  void openRoleChooser() {
    showRoleChooser = true;
    notifyListeners();
  }

  void setMyCoop(String id) {
    myCoop = id;
    notifyListeners();
  }

  void setMyCountry(String id) {
    myCountry = id;
    notifyListeners();
  }

  void setProductionTab(String t) {
    productionTab = t;
    notifyListeners();
  }

  void setChainTab(String t, {String? lot}) {
    chainTab = t;
    if (lot != null) selectedLot = lot;
    notifyListeners();
  }

  void toggleNav() {
    navExpanded = !navExpanded;
    notifyListeners();
  }

  // ---- extra admin / demo state ----
  final Map<String, Map<String, bool>> perms = {for (final r in roles) r.id: Map<String, bool>.of(r.perms)};
  final List<AppUser> users = seedUsers();
  final List<SourceOps> sourceOps = seedSourceOps();
  final List<QualityIssue> issues = seedIssues();
  final List<KpiDef> kpis = seedKpis();
  final List<AlertRule> rules = seedRules();
  final List<ReportSchedule> schedules = seedSchedules();

  // ---- admin (front-end demo only: NOT real security) ----
  static const demoAdminUser = 'admin';
  static const demoAdminPass = 'coffee2026';
  String adminUser = demoAdminUser;
  bool showLogin = false; // login screen visible
  bool admin = false; // logged in
  bool adminView = false; // admin area (vs. public view while logged in)
  int adminPage = 0;
  String adminDataset = 'prices';
  final List<DataSet> datasets = buildDatasets();
  final List<ManualEntry> manual = [];
  final List<Order> orders = _seedOrders();
  final List<LogEntry> log = [];

  static List<Order> _seedOrders() {
    final now = DateTime.now();
    final seed = [
      ('Café Import SA', 'prices', 1800.0, 150),
      ("Ministère de l'Agriculture", 'production', 1400.0, 128),
      ('Torréfaction Atlas', 'forecast', 2200.0, 96),
      ('Fondation Café Durable', 'sustain', 1500.0, 70),
      ('AgriTrade Logistics', 'chain', 800.0, 52),
      ('Université de Cocody', 'costs', 1200.0, 30),
      ('Banque Agricole du Golfe', 'forecast', 2200.0, 12),
    ];
    return [for (final s in seed) Order(s.$1, s.$2, s.$3, now.subtract(Duration(days: s.$4)))];
  }

  // ---- guide: self-assessment checklist ----
  bool guideHint = true; // "new here?" banner on the decision center
  void dismissGuideHint() {
    guideHint = false;
    notifyListeners();
  }

  final Set<String> guideDone = {};
  void toggleGuide(String id, bool on) {
    on ? guideDone.add(id) : guideDone.remove(id);
    notifyListeners();
  }

  // ---- visitor accounts & subscriptions (front-end demo: stored locally, no server, no real payment) ----
  final List<Account> accounts = [];
  Account? me; // signed-in visitor
  String? pendingEmail; // account waiting for its (simulated) e-mail verification code
  String? pendingCode;
  bool persistAccounts = false; // set by main(); tests keep everything in memory
  bool requireAccount = true; // visitors identify / register before entering the platform (?skipgate=1 for automated tests)
  bool accountsReady = false; // saved accounts restored from this device

  /// After sign-up / sign-in at the entrance: choose a profile, then the platform opens.
  void enterAfterAuth() {
    showRoleChooser = true;
    notifyListeners();
  }

  /// Free browsing for everyone; downloads need an active subscription (the demo admin is never blocked).
  bool get canDownload => admin || (me?.hasActivePlan ?? false);

  Future<void> loadAccounts() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('oiac_accounts');
      if (raw != null) {
        accounts
          ..clear()
          ..addAll([for (final j in jsonDecode(raw) as List) Account.fromJson(j as Map<String, dynamic>)]);
      }
      final sid = sp.getString('oiac_session');
      me = sid == null ? null : accounts.where((a) => a.id == sid && a.verified).firstOrNull;
      persistAccounts = true;
    } catch (_) {
      persistAccounts = false;
    }
    accountsReady = true;
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    if (!persistAccounts) return;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('oiac_accounts', jsonEncode([for (final a in accounts) a.toJson()]));
      if (me == null) {
        await sp.remove('oiac_session');
      } else {
        await sp.setString('oiac_session', me!.id);
      }
    } catch (_) {}
  }

  Account? _byEmail(String e) => accounts.where((a) => a.email == e.trim().toLowerCase()).firstOrNull;

  /// Creates the account and "sends" a verification code. Returns an error key, or null when OK.
  String? register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String country,
    required String city,
    required String address,
    required DateTime birth,
    required String gender,
  }) {
    final mail = email.trim().toLowerCase();
    if (_byEmail(mail) != null) return 'acc_err_email_taken';
    if (accounts.any((a) => a.username.toLowerCase() == username.trim().toLowerCase())) return 'acc_err_user_taken';
    final salt = newSalt();
    accounts.add(Account(
      id: newId('u'),
      fullName: fullName.trim(),
      username: username.trim(),
      email: mail,
      passHash: hashPassword(password, salt),
      salt: salt,
      country: country,
      city: city.trim(),
      address: address.trim(),
      gender: gender,
      birth: birth,
      created: DateTime.now(),
    ));
    pendingEmail = mail;
    pendingCode = newCode();
    addLog('log_register', mail);
    _saveAccounts();
    notifyListeners();
    return null;
  }

  /// New code for an account that is not verified yet.
  void resendCode(String email) {
    pendingEmail = email.trim().toLowerCase();
    pendingCode = newCode();
    notifyListeners();
  }

  String? verifyCode(String code) {
    final a = pendingEmail == null ? null : _byEmail(pendingEmail!);
    if (a == null || pendingCode == null || code.trim() != pendingCode) return 'acc_err_code';
    a.verified = true;
    me = a;
    guideDone.add('gc_account');
    pendingEmail = null;
    pendingCode = null;
    addLog('log_visitor_in', a.email);
    _saveAccounts();
    notifyListeners();
    return null;
  }

  /// Sign in with e-mail or username + password. Returns an error key, or null when OK.
  String? loginVisitor(String id, String password) {
    final k = id.trim().toLowerCase();
    final a = accounts.where((x) => x.email == k || x.username.toLowerCase() == k).firstOrNull;
    if (a == null || a.social != null && password.isEmpty) return 'acc_err_login';
    if (hashPassword(password, a.salt) != a.passHash) return 'acc_err_login';
    if (!a.verified) {
      resendCode(a.email);
      return 'acc_err_unverified';
    }
    me = a;
    addLog('log_visitor_in', a.email);
    _saveAccounts();
    notifyListeners();
    return null;
  }

  /// Simulated Google / Apple sign-in: creates (or reuses) a demo account, already verified.
  Account socialLogin(String provider, {required String country}) {
    final mail = 'demo.${provider.toLowerCase()}@example.org';
    var a = _byEmail(mail);
    if (a == null) {
      final salt = newSalt();
      a = Account(
        id: newId('u'),
        fullName: provider == 'google' ? 'Utilisateur Google (démo)' : 'Utilisateur Apple (démo)',
        username: 'demo_$provider',
        email: mail,
        passHash: hashPassword(newCode(), salt),
        salt: salt,
        country: country,
        city: '',
        address: '',
        gender: 'n',
        birth: DateTime(1990, 1, 1),
        created: DateTime.now(),
        verified: true,
        social: provider,
      );
      accounts.add(a);
    }
    me = a;
    addLog('log_visitor_in', mail);
    _saveAccounts();
    notifyListeners();
    return a;
  }

  void logoutVisitor() {
    me = null;
    page = 0;
    showRoleChooser = false;
    _saveAccounts();
    notifyListeners();
  }

  /// Simulated payment of a subscription (no money moves).
  void subscribe(String planId, String cycle, String method) {
    final a = me;
    if (a == null) return;
    final def = planById(planId);
    final price = cycle == 'year' ? def.yearUsd : def.monthUsd;
    a.plan = planId;
    a.cycle = cycle;
    a.planUntil = DateTime.now().add(Duration(days: cycle == 'year' ? 365 : 30));
    a.purchases.insert(0, Purchase(newId('p'), 'plan', '${def.nameKey}|$cycle', price, method, DateTime.now()));
    addLog('log_subscribe', '$planId/$cycle');
    _saveAccounts();
    notifyListeners();
  }

  /// Simulated one-off payment for a single download.
  void buyItem(String kind, String label, String method) {
    final a = me;
    if (a == null) return;
    a.purchases.insert(0, Purchase(newId('p'), 'item', label, itemPriceUsd(kind), method, DateTime.now()));
    addLog('log_purchase', label);
    _saveAccounts();
    notifyListeners();
  }

  void openLogin() {
    showLogin = true;
    notifyListeners();
  }

  void closeLogin() {
    showLogin = false;
    notifyListeners();
  }

  /// Front-end demo: sign-in always succeeds, even with empty fields.
  bool login(String u, String p) {
    adminUser = u.trim().isEmpty ? demoAdminUser : u.trim();
    admin = true;
    adminView = false;
    showLogin = false;
    showLanding = false;
    showRoleChooser = true; // login → choose a role → matching workspace
    adminPage = 0;
    addLog('log_login', adminUser);
    notifyListeners();
    return true;
  }

  void logout() {
    addLog('log_logout', '');
    admin = false;
    adminView = false;
    showRoleChooser = false;
    if (role == 'admin') role = 'board';
    page = 0;
    notifyListeners();
  }

  void setAdminView(bool v) {
    adminView = v;
    notifyListeners();
  }

  void gotoAdmin(int i, {String? dataset}) {
    adminPage = i;
    if (dataset != null) adminDataset = dataset;
    notifyListeners();
  }

  void addLog(String key, String detail) => log.insert(0, LogEntry(key, detail));

  void addManual(ManualEntry e) {
    manual.insert(0, e);
    addLog('log_add', e.dataset);
    notifyListeners();
  }

  void removeManual(ManualEntry e) {
    manual.remove(e);
    addLog('log_remove', e.dataset);
    notifyListeners();
  }

  void touch() => notifyListeners();

  void sell(DataSet d, String buyer) {
    orders.insert(0, Order(buyer, d.id, d.priceUsd, DateTime.now()));
    addLog('log_sale', d.id);
    notifyListeners();
  }

  /// Deep links such as ?enter=1&role=coop&page=production&tab=quality&lang=en (handy for demos and tests).
  void applyUri(Uri u) {
    final q = u.queryParameters;
    if (q['lang'] != null) setLang(q['lang']!);
    if (q['theme'] == 'dark') themeMode = ThemeMode.dark;
    if (q['cur'] != null) {
      final c = currencies.where((x) => x.code == q['cur']).firstOrNull;
      if (c != null) Fmt.cur = c;
    }
    if (q['enter'] == '1') showLanding = false;
    if (q['skipgate'] == '1') requireAccount = false;
    if (q['admin'] == '1') {
      admin = true;
      showLanding = false;
    }
    if (q['role'] != null && roles.any((r) => r.id == q['role'])) {
      role = q['role']!;
      final r = roleById(role);
      productionTab = r.productionTab;
      chainTab = r.chainTab;
      showLanding = false;
      if (role == 'admin') {
        admin = true;
        adminView = true;
      }
    }
    if (q['tab'] != null) {
      productionTab = q['tab']!;
      if (q['tab'] == 'lots' || q['tab'] == 'flow') chainTab = q['tab']!;
    }
    if (q['apage'] != null) {
      admin = true;
      adminView = true;
      showLanding = false;
      adminPage = int.tryParse(q['apage']!) ?? 0;
    }
    if (q['page'] != null) {
      final i = pageIds.indexOf(q['page']!);
      if (i >= 0) {
        page = i;
        showLanding = false;
      }
    }
  }

  void setLang(String l) {
    lang = l;
    Fmt.lang = l;
    notifyListeners();
  }

  void setCurrency(String code) {
    Fmt.cur = currencies.firstWhere((c) => c.code == code);
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setReduce(bool v) {
    reduceMotion = v;
    notifyListeners();
  }

  void goto(int i) {
    page = i;
    showLanding = false;
    notifyListeners();
  }

  void enter() {
    showLanding = false;
    notifyListeners();
  }

  void openLanding() {
    showLanding = true;
    presentation = false;
    notifyListeners();
  }

  void selectCountry(String id) {
    selectedCountry = id;
    notifyListeners();
  }

  void setPresentation(bool v) {
    presentation = v;
    if (v) {
      showLanding = false;
      page = 0; // the tour starts on the decision center
    }
    if (!v) autoPlay = false;
    notifyListeners();
  }

  void setAutoPlay(bool v) {
    autoPlay = v;
    notifyListeners();
  }

  void addAlert(UserAlert a) {
    userAlerts.insert(0, a);
    notifyListeners();
  }

  void removeAlert(UserAlert a) {
    userAlerts.remove(a);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
