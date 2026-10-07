import 'package:flutter/material.dart';
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
