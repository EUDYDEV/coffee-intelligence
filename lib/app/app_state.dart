import 'package:flutter/material.dart';
import '../core/format.dart';
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
