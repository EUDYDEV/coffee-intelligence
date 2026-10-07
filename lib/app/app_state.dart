import 'package:flutter/material.dart';
import '../core/format.dart';
import '../data/admin_data.dart';
import '../models/models.dart';

/// Global UI state (theme, language, motion, navigation, user-created alerts).
class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  String lang = 'fr';
  bool reduceMotion = false;
  bool showLanding = true;
  bool presentation = false;
  bool autoPlay = false;
  int page = 0;
  String selectedCountry = 'ETH';
  final List<UserAlert> userAlerts = [];

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
    adminView = true;
    showLogin = false;
    showLanding = false;
    adminPage = 0;
    addLog('log_login', adminUser);
    notifyListeners();
    return true;
  }

  void logout() {
    addLog('log_logout', '');
    admin = false;
    adminView = false;
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
