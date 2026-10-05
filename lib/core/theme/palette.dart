import 'package:flutter/material.dart';

/// Brand colours of the Coffee Intelligence identity.
class CI {
  static const espressoDeep = Color(0xFF2B1B14);
  static const espresso = Color(0xFF4A2C20);
  static const caramel = Color(0xFFA66A3F);
  static const latte = Color(0xFFC89B72);
  static const cream = Color(0xFFF3E8D5);
  static const leaf = Color(0xFF4F6F52);
  static const forest = Color(0xFF243D2A);
  static const gold = Color(0xFFC9A45C);
  static const offWhite = Color(0xFFFAF8F3);
  static const alert = Color(0xFFB94A48);
  static const warn = Color(0xFFD08A3C);
}

/// Theme-aware palette (light = cream/beige, dark = espresso).
class Pal {
  final bool dark;
  final Color bg, bg2, surface, surface2, text, muted, border, green, accent, gold, alert, warn;
  const Pal._(this.dark, this.bg, this.bg2, this.surface, this.surface2, this.text, this.muted,
      this.border, this.green, this.accent, this.gold, this.alert, this.warn);

  static const light = Pal._(
      false,
      CI.offWhite,
      CI.cream,
      Color(0xFFFFFDF8),
      Color(0xFFF7EEDD),
      CI.espressoDeep,
      Color(0xFF7A6556),
      Color(0xFFE2D3BA),
      CI.leaf,
      CI.caramel,
      CI.gold,
      CI.alert,
      CI.warn);
  static const darkP = Pal._(
      true,
      Color(0xFF170E0A),
      Color(0xFF21140F),
      Color(0xFF2B1B14),
      Color(0xFF35221A),
      CI.cream,
      Color(0xFFB8A58F),
      Color(0xFF4A2F24),
      Color(0xFF86AB8A),
      Color(0xFFD08A55),
      CI.gold,
      Color(0xFFE0716E),
      Color(0xFFE8A559));

  static Pal of(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? darkP : light;

  Color sev(int s) => s == 0 ? alert : (s == 1 ? warn : gold);
  List<Color> get seriesColors => [accent, green, gold, const Color(0xFF8B5A7C), const Color(0xFF4F7F93)];
}
