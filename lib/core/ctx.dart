import 'package:flutter/material.dart';
import '../app/app_state.dart';
import 'format.dart';
import 'i18n/strings.dart';
import 'theme/palette.dart';

extension Ctx on BuildContext {
  AppState get app => AppScope.of(this);
  Pal get pal => Pal.of(this);
  double get w => MediaQuery.sizeOf(this).width;
  bool get isMobile => w < 700;
  bool get isTablet => w >= 700 && w < 1100;
  bool get isDesktop => w >= 1100;

  /// Translate [key] in the current language. `{0}`, `{1}`… are replaced by [args].
  String tr(String key, [List<Object> args = const []]) {
    var s = Strings.t(app.lang, key);
    for (var i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', '${args[i]}');
    }
    if (Fmt.sym != r'$') s = s.replaceAll(r'$', Fmt.sym);
    return s;
  }

  /// Animation duration honouring the "reduce animations" setting.
  Duration dur(int ms) => app.reduceMotion ? const Duration(milliseconds: 1) : Duration(milliseconds: ms);
  bool get calm => app.reduceMotion;

  /// Number of columns for card grids.
  int cols({int desktop = 4, int tablet = 2, int mobile = 1}) =>
      isDesktop ? desktop : (isTablet ? tablet : mobile);
}
