import 'package:flutter/material.dart';
import 'palette.dart';

class TS {
  static const display = 'Playfair';
  static const body = 'Inter';

  static TextStyle h1(Pal p) =>
      TextStyle(fontFamily: display, fontSize: 34, fontWeight: FontWeight.w700, color: p.text, height: 1.1);
  static TextStyle h2(Pal p) =>
      TextStyle(fontFamily: display, fontSize: 22, fontWeight: FontWeight.w600, color: p.text, height: 1.2);
  static TextStyle h3(Pal p) =>
      TextStyle(fontFamily: body, fontSize: 15, fontWeight: FontWeight.w600, color: p.text);
  static TextStyle bodyS(Pal p) =>
      TextStyle(fontFamily: body, fontSize: 13, color: p.muted, height: 1.4);
  static TextStyle label(Pal p) => TextStyle(
      fontFamily: body, fontSize: 10.5, letterSpacing: 1.3, fontWeight: FontWeight.w600, color: p.muted);
  static TextStyle big(Pal p, {double size = 30}) => TextStyle(
      fontFamily: display, fontSize: size, fontWeight: FontWeight.w700, color: p.text, height: 1.05);
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Pal.darkP : Pal.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: TS.body,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CI.caramel,
      brightness: b,
      primary: p.accent,
      secondary: p.green,
      surface: p.surface,
    ),
    dividerColor: p.border,
    splashFactory: InkSparkle.splashFactory,
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.border,
      thumbColor: p.gold,
      overlayColor: p.accent.withValues(alpha: .15),
      trackHeight: 5,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: CI.espressoDeep, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: CI.cream, fontSize: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.gold : p.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.green : p.border),
    ),
  );
}
