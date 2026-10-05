import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/sustainability_data.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

class _Msg {
  final bool user;
  final String text;
  final List<String> used;
  _Msg(this.user, this.text, [this.used = const []]);
}

/// "Coffee Intelligence Assistant": answers only from the local demo data — a simulation of the future feature.
class AssistantPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AssistantPanel({super.key, required this.onClose});
  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final List<_Msg> _msgs = [];
  final TextEditingController _in = TextEditingController();
  final ScrollController _sc = ScrollController();
  bool _typing = false;
  bool _greeted = false;

  static const _suggestions = ['q_top_prod', 'q_income', 'q_risk', 'q_price'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_greeted) {
      _greeted = true;
      _msgs.add(_Msg(false, context.tr('as_hello')));
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _sc.dispose();
    super.dispose();
  }

  (String, List<String>) _answer(String q) {
    final s = q.toLowerCase();
    bool has(List<String> k) => k.any(s.contains);
    final af = repo.countries(africaOnly: true);
    final all = repo.countries();
    if (has(['revenu', 'income', 'baisse', 'decline', 'drop', 'falling', 'revenue'])) {
      return (context.tr('as_income', [Fmt.usd(repo.africaIncome(), 0)]), [context.tr('kpi_income'), context.tr('farmgate'), context.tr('prod_cost')]);
    }
    if (has(['risque', 'risk', 'danger', 'region', 'région'])) {
      final c = [...af]..sort((a, b) => b.climateRisk.compareTo(a.climateRisk));
      return (context.tr('as_risk', [context.tr(c.first.nameKey), Fmt.num(c.first.climateRisk, 0), Fmt.num(c.first.deforestRisk, 0), context.tr(c[1].nameKey)]), [context.tr('kpi_climate'), context.tr('sd_forest'), context.tr('risk_radar')]);
    }
    if (has(['prix', 'price', 'cours', 'évolu', 'evolu', 'arabica', 'robusta'])) {
      final a = repo.series('arabica');
      return (context.tr('as_price', [Fmt.usd(a.last.v), Fmt.pct((a.last.v / a[a.length - 2].v - 1) * 100, 1, true), Fmt.pct((a.last.v / a[a.length - 13].v - 1) * 100, 1, true), Fmt.usd(repo.forecast('price').forecast.last.v)]), [context.tr('ind_arabica'), context.tr('fc_price'), context.tr('market_title')]);
    }
    if (has(['durab', 'sustain', 'certif', 'green', 'vert'])) {
      final c = [...af]..sort((a, b) => sustainFor(b).overall.compareTo(sustainFor(a).overall));
      return (context.tr('as_sustain', [context.tr(c.first.nameKey), Fmt.num(sustainFor(c.first).overall, 0), context.tr(c.last.nameKey), Fmt.num(sustainFor(c.last).overall, 0)]), [context.tr('sustain_index'), context.tr('certified')]);
    }
    if (has(['anomal', 'alerte', 'alert', 'incident'])) {
      final n = repo.anomalies().length;
      return (context.tr('as_anom', [n, context.tr(repo.anomalies().first.titleKey)]), [context.tr('anomalies_title'), context.tr('alerts_title')]);
    }
    if (has(['prévi', 'previ', 'forecast', 'predict', 'futur', 'future'])) {
      final f = repo.forecast('price');
      return (context.tr('as_forecast', [Fmt.usd(f.forecast.last.v), Fmt.usd(f.lower.last), Fmt.usd(f.upper.last)]), [context.tr('fc_price'), context.tr('fc_range')]);
    }
    if (has(['produi', 'produc', 'plus', 'most', 'top', 'largest', 'pays', 'country'])) {
      final a = [...af]..sort((x, y) => y.prodKt.compareTo(x.prodKt));
      final w = [...all]..sort((x, y) => y.prodKt.compareTo(x.prodKt));
      return (context.tr('as_prod', [context.tr(a.first.nameKey), Fmt.num(a.first.prodKt, 0), context.tr(a[1].nameKey), Fmt.num(a[1].prodKt, 0), context.tr(w.first.nameKey)]), [context.tr('kpi_prod'), context.tr('prod_by_country')]);
    }
    return (context.tr('as_fallback'), const []);
  }

  void _send(String text) {
    if (text.trim().isEmpty || _typing) return;
    setState(() {
      _msgs.add(_Msg(true, text));
      _typing = true;
      _in.clear();
    });
    _toEnd();
    Timer(Duration(milliseconds: context.calm ? 50 : 900), () {
      if (!mounted) return;
      final a = _answer(text);
      setState(() {
        _msgs.add(_Msg(false, a.$1, a.$2));
        _typing = false;
      });
      _toEnd();
    });
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final mobile = context.isMobile;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: mobile ? double.infinity : 400,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: mobile ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(24),
          border: Border.all(color: p.gold.withValues(alpha: .6)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 30)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(mobile ? 24 : 23)),
              gradient: const LinearGradient(colors: [CI.forest, CI.espressoDeep]),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: CI.gold),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('assistant_name'), style: const TextStyle(color: CI.cream, fontWeight: FontWeight.w800, fontFamily: TS.display, fontSize: 16)),
                Text(context.tr('assistant_sim'), style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 11)),
              ])),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded, color: CI.cream)),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: _sc,
              padding: const EdgeInsets.all(14),
              children: [
                for (final m in _msgs) _Bubble(m),
                if (_typing) const _Typing(),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final k in _suggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(label: Text(context.tr(k), style: const TextStyle(fontSize: 12)), onPressed: () => _send(context.tr(k))),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _in,
                  onSubmitted: _send,
                  decoration: InputDecoration(hintText: context.tr('ask_hint'), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: () => _send(_in.text), style: IconButton.styleFrom(backgroundColor: p.accent), icon: const Icon(Icons.arrow_upward_rounded)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg m;
  const _Bubble(this.m);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Reveal(
      child: Align(
        alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 310),
          decoration: BoxDecoration(
            color: m.user ? p.accent : p.surface2,
            borderRadius: BorderRadius.circular(16),
            border: m.user ? null : Border.all(color: p.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.text, style: TextStyle(color: m.user ? Colors.white : p.text, fontSize: 13.5, height: 1.45)),
            if (m.used.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(context.tr('indicators_used').toUpperCase(), style: TS.label(p).copyWith(fontSize: 9.5)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final u in m.used) Chip2(u, p.green, icon: Icons.analytics_rounded)]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(16)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: p.muted.withValues(alpha: .3 + .7 * ((_c.value * 3 - i).clamp(0, 1) as double)))),
          ]),
        ),
      ),
    );
  }
}
