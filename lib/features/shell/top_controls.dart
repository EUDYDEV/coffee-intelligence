import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';

class LangToggle extends StatelessWidget {
  const LangToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final lang = context.app.lang;
    Widget seg(String code) => GestureDetector(
          onTap: () => context.app.setLang(code),
          child: AnimatedContainer(
            duration: context.dur(250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: lang == code ? p.accent : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Text(code.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .8, color: lang == code ? Colors.white : p.muted)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('fr'), seg('en')]),
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: context.app.toggleTheme,
      child: Container(
        width: 36,
        height: 34,
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.border)),
        child: AnimatedSwitcher(
          duration: context.dur(400),
          transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: .5, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: c)),
          child: Icon(p.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, key: ValueKey(p.dark), size: 18, color: p.gold),
        ),
      ),
    );
  }
}

/// Currency selector (FCFA by default). Rates are indicative demo values.
class CurrencyPicker extends StatelessWidget {
  final bool compact;
  const CurrencyPicker({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return PopupMenuButton<String>(
      tooltip: context.tr('set_currency'),
      color: p.surface,
      onSelected: app.setCurrency,
      itemBuilder: (_) => [
        for (final c in currencies)
          PopupMenuItem(
            value: c.code,
            child: Row(children: [
              SizedBox(width: 52, child: Text(c.code, style: TextStyle(fontWeight: FontWeight.w800, color: c.code == Fmt.cur.code ? p.accent : p.text))),
              Expanded(child: Text(app.lang == 'fr' ? c.fr : c.en, style: TextStyle(color: p.text, fontSize: 13))),
              Text(c.symbol, style: TextStyle(color: p.muted)),
            ]),
          ),
        PopupMenuItem(enabled: false, child: Text(context.tr('currency_note'), style: TextStyle(fontSize: 10.5, color: p.muted))),
      ],
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.currency_exchange_rounded, size: 15, color: p.gold),
          const SizedBox(width: 6),
          Text(Fmt.cur.code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.text)),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: p.muted),
        ]),
      ),
    );
  }
}
