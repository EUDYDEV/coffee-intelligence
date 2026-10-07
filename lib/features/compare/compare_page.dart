import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/countries_data.dart';
import '../../data/demo/market_data.dart';
import '../../data/demo/quality_data.dart';
import '../../data/demo/sustainability_data.dart';
import '../../models/models.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

typedef _Row = (String, double, double, bool, String Function(double));

/// Unified metric record so any level (country / region / cooperative / producer) can be compared.
class _Ent {
  final String id, label, qkey;
  final double production; // tonnes
  final double yieldKgHa, cost, income, margin, quality, cert, sustain, deforest, emissions, price, climate;
  final List<double> evolution; // index 100 = first season
  const _Ent(this.id, this.label, this.qkey, this.production, this.yieldKgHa, this.cost, this.income, this.margin, this.quality, this.cert, this.sustain, this.deforest, this.emissions, this.price, this.climate, this.evolution);
}

List<double> _evo(String key, double growth) {
  final r = Lcg(key.codeUnits.fold(0, (a, b) => (a * 31 + b) % 9973) + 7);
  var v = 100.0;
  return [
    for (var i = 0; i < 8; i++)
      i == 0 ? 100.0 : (v = v * (1 + growth + r.noise(.03)))
  ];
}

_Ent _entCountry(BuildContext c, Country k) {
  final s = sustainFor(k);
  return _Ent(k.id, '${k.flag} ${c.tr(k.nameKey)}', k.id, k.prodKt * 1000, k.yieldKgHa, k.costKg, k.incomeYr, k.margin, qualityFor(k.id).score, k.certPct, s.overall, k.deforestRisk, s.emissions, k.farmgateKg, k.climateRisk,
      [for (final v in k.prodHistory) v / k.prodHistory.first * 100]);
}

_Ent _entRegion(BuildContext c, Country k, Region r) {
  final s = sustainFor(k);
  final key = '${k.id}:${r.name}';
  return _Ent(key, '${r.name} (${k.id})', key, k.prodKt * 1000 * r.share, k.yieldKgHa * (.88 + r.share * .6), k.costKg * (.95 + r.share * .2), k.incomeYr * (.9 + r.share), k.margin * (.9 + r.share * .3), qualityFor(key).score,
      (k.certPct * (.8 + r.share)).clamp(2, 90).toDouble(), s.overall - 2 + r.share * 8, k.deforestRisk * (.9 + r.share * .5), s.emissions, k.farmgateKg, k.climateRisk + (r.share - .25) * 20, _evo(key, .02));
}

_Ent _entCoop(BuildContext c, CoopProfile p) {
  final k = countryById(p.coop.country);
  final s = sustainFor(k);
  return _Ent(p.coop.id, p.coop.name, p.coop.id, p.productionT, p.yieldKgHa, p.costKg, p.incomeYr, p.margin, qualityFor(p.coop.id).score, p.certPct, s.overall + (p.certPct - k.certPct) * .15, k.deforestRisk, s.emissions,
      k.farmgateKg * (.95 + p.margin * .05), p.climateRisk, _evo(p.coop.id, .025));
}

_Ent _entProducer(BuildContext c, Producer p) {
  final co = demoCoops.firstWhere((x) => x.id == p.coopId);
  final cp = coopProfile(co);
  final k = countryById(co.country);
  final s = sustainFor(k);
  return _Ent(p.id, p.name, co.id, p.kg / 1000, p.yieldKgHa, cp.costKg, p.incomeYr, cp.margin * (p.yieldKgHa / cp.yieldKgHa), qualityFor(co.id).score, cp.certPct, s.overall, k.deforestRisk, s.emissions, k.farmgateKg, cp.climateRisk, _evo(p.id, .02));
}

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});
  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  String _mode = 'multi'; // multi | mine
  String _level = 'country';
  final List<String> _sel = ['KEN', 'ETH', 'UGA'];
  String _coop = '';
  int _refIdx = 0;

  List<_Ent> _all(BuildContext c) {
    switch (_level) {
      case 'region':
        return [for (final k in demoCountries.where((x) => x.african)) for (final r in k.regions) _entRegion(c, k, r)];
      case 'coop':
        return [for (final p in coopProfiles()) _entCoop(c, p)];
      case 'producer':
        return [for (final co in demoCoops.take(6)) for (final p in producersOf(co.id).take(3)) _entProducer(c, p)];
      default:
        return [for (final k in demoCountries) _entCountry(c, k)];
    }
  }

  void _setLevel(BuildContext c, String l) {
    setState(() {
      _level = l;
      _sel.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('compare_title', 'compare_sub',
          trailing: Segmented<String>(values: const ['multi', 'mine'], selected: _mode, label: (v) => context.tr('cmp_mode_$v'), onChanged: (v) => setState(() => _mode = v))),
      if (_mode == 'multi') _multi(context, p) else _mine(context, p),
    ]);
  }

  // ---------------------------------------------------------------- multi
  Widget _multi(BuildContext context, Pal p) {
    final all = _all(context);
    if (_sel.isEmpty || !_sel.every((id) => all.any((e) => e.id == id))) {
      _sel
        ..clear()
        ..addAll(all.take(3).map((e) => e.id));
    }
    final es = [for (final id in _sel) all.firstWhere((e) => e.id == id)];
    final colors = p.seriesColors;
    Color col(int i) => colors[i % colors.length];
    List<(String, double, Color)> ent(double Function(_Ent) f) => [for (var i = 0; i < es.length; i++) (es[i].label.length > 12 ? es[i].label.substring(0, 11) : es[i].label, f(es[i]), col(i))];
    String prodFmt(double t) => t >= 1000 ? '${Fmt.num(t / 1000, 1)} kt' : '${Fmt.num(t, 1)} t';
    double norm(double v, double mx) => mx == 0 ? 0 : (v / mx * 100).clamp(6, 100).toDouble();
    double mx(double Function(_Ent) f) => es.map(f).reduce((a, b) => a > b ? a : b);
    double tasting(_Ent e) {
      final q = qualityFor(e.qkey);
      return (q.acidity + q.body + q.aroma + q.sweetness) / 4;
    }

    final selector = Wrap(spacing: 8, runSpacing: 8, children: [
      for (final e in all)
        FilterChip(
          label: Text(e.label),
          selected: _sel.contains(e.id),
          showCheckmark: false,
          selectedColor: _sel.contains(e.id) ? col(_sel.indexOf(e.id)).withValues(alpha: .35) : null,
          onSelected: (v) => setState(() {
            if (v) {
              if (_sel.length >= 4) _sel.removeAt(0);
              _sel.add(e.id);
            } else if (_sel.length > 1) {
              _sel.remove(e.id);
            }
          }),
        ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Segmented<String>(values: const ['country', 'region', 'coop', 'producer'], selected: _level, label: (v) => context.tr('ql_$v'), onChanged: (v) => _setLevel(context, v)),
      const SizedBox(height: 4),
      Text(context.tr('cmp_levels_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
      gap16,
      selector,
      gap16,
      Wrap(spacing: 14, children: [for (var i = 0; i < es.length; i++) LegendDot(col(i), es[i].label)]),
      gap16,
      TwoCol(
        flexL: 5,
        flexR: 6,
        left: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_profile')),
            Center(
              child: RadarW(
                size: context.isMobile ? 290 : 340,
                axes: [context.tr('cmp_prod'), context.tr('cmp_yield'), context.tr('cmp_income'), context.tr('cmp_margin'), context.tr('cmp_quality'), context.tr('cmp_cert'), context.tr('cmp_sustain')],
                series: [
                  for (var i = 0; i < es.length; i++)
                    RadarSeries(es[i].label, [
                      norm(es[i].production, mx((e) => e.production)),
                      norm(es[i].yieldKgHa, mx((e) => e.yieldKgHa)),
                      norm(es[i].income, mx((e) => e.income)),
                      norm(es[i].margin, mx((e) => e.margin)),
                      norm(es[i].quality - 60, 40),
                      norm(es[i].cert, mx((e) => e.cert)),
                      es[i].sustain.clamp(5, 100).toDouble(),
                    ], col(i)),
                ],
              ),
            ),
            Text(context.tr('cmp_radar_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
          ]),
        ),
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_metrics')),
            CompareRow(label: context.tr('cmp_prod'), entries: ent((e) => e.production), fmt: prodFmt),
            CompareRow(label: '${context.tr('cmp_yield')} (kg/ha)', entries: ent((e) => e.yieldKgHa), fmt: (v) => Fmt.num(v, 0)),
            CompareRow(label: '${context.tr('cmp_cost')} (${Fmt.unit(r'$/kg')})', entries: ent((e) => e.cost), fmt: (v) => Fmt.money(v, 2), lowerIsBetter: true),
            CompareRow(label: '${context.tr('cmp_income')} (${Fmt.sym}/${context.tr('y')})', entries: ent((e) => e.income), fmt: (v) => Fmt.money(v, 0)),
            CompareRow(label: '${context.tr('cmp_margin')} (${Fmt.unit(r'$/kg')})', entries: ent((e) => e.margin), fmt: (v) => Fmt.money(v, 2)),
            CompareRow(label: '${context.tr('cmp_quality')} (/100)', entries: ent((e) => e.quality), fmt: (v) => Fmt.num(v, 1)),
            CompareRow(label: '${context.tr('cmp_tasting')} (/10)', entries: ent(tasting), fmt: (v) => Fmt.num(v, 1)),
            CompareRow(label: '${context.tr('cmp_cert')} (%)', entries: ent((e) => e.cert), fmt: (v) => Fmt.num(v, 0)),
            CompareRow(label: context.tr('cmp_sustain'), entries: ent((e) => e.sustain), fmt: (v) => Fmt.num(v, 0)),
            CompareRow(label: '${context.tr('cmp_deforest')} (/100)', entries: ent((e) => e.deforest), fmt: (v) => Fmt.num(v, 0), lowerIsBetter: true),
            CompareRow(label: '${context.tr('cmp_emissions')} (/100)', entries: ent((e) => e.emissions), fmt: (v) => Fmt.num(v, 0)),
            CompareRow(label: '${context.tr('cmp_price')} (${Fmt.unit(r'$/kg')})', entries: ent((e) => e.price), fmt: (v) => Fmt.money(v, 2)),
          ]),
        ),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('cmp_evolution')),
          LineChartW(
            height: 260,
            sourceId: 'production',
            unit: 'index 100',
            dates: [for (var i = 0; i < 8; i++) DateTime(2019 + i, 7, 1)],
            yFmt: (v) => Fmt.num(v, 0),
            series: [for (var i = 0; i < es.length; i++) ChartSeries(es[i].label, es[i].evolution, col(i), fill: false)],
          ),
          Text(context.tr('cmp_index_note'), style: TS.bodyS(p)),
        ]),
      ),
    ]);
  }

  // ---------------------------------------------------------------- my coop vs reference
  Widget _mine(BuildContext context, Pal p) {
    final app = context.app;
    final profiles = coopProfiles();
    if (_coop.isEmpty) _coop = app.myCoop;
    final me = profiles.firstWhere((x) => x.coop.id == _coop);
    final myQ = qualityFor(me.coop.id).score;
    final peers = profiles.where((x) => x.coop.country == me.coop.country && x.region == me.region && x.coop.id != me.coop.id).toList();
    final region = benchOf(peers);
    final national = benchOf(profiles.where((x) => x.coop.country == me.coop.country && x.coop.id != me.coop.id).toList());
    final refs = <(String, Bench, Color)>[
      if (peers.isNotEmpty) (context.tr('cmp_region_avg'), region, p.gold),
      (context.tr('cmp_national_avg'), national, p.green),
      (context.tr('cmp_intl_ref'), intlBench, p.muted),
    ];
    final refIdx = _refIdx.clamp(0, refs.length - 1);
    final ref = refs[refIdx];

    // label key, mine, reference, higher is better, formatter
    final rows = <_Row>[
      ('cmp_prod', me.productionT, ref.$2.production, true, (v) => '${Fmt.num(v, 0)} t'),
      ('cmp_yield', me.yieldKgHa, ref.$2.yield, true, (v) => '${Fmt.num(v, 0)} kg/ha'),
      ('cmp_quality', myQ, ref.$2.quality, true, (v) => Fmt.num(v, 1)),
      ('cmp_income', me.incomeYr, ref.$2.income, true, (v) => Fmt.usd(v, 0)),
      ('cmp_cert', me.certPct, ref.$2.cert, true, (v) => '${Fmt.num(v, 0)} %'),
      ('cmp_margin', me.margin, ref.$2.margin, true, (v) => Fmt.usd(v, 2)),
      ('cmp_cost', me.costKg, ref.$2.cost, false, (v) => Fmt.usd(v, 2)),
      ('cmp_climate', me.climateRisk, ref.$2.climate, false, (v) => '${Fmt.num(v, 0)}/100'),
    ];
    double delta(double a, double b) => b == 0 ? 0 : (a / b - 1) * 100;
    double good(_Row r) => (r.$4 ? 1 : -1) * delta(r.$2, r.$3);
    final strengths = [for (final r in rows) if (good(r) >= 3) r];
    final weaknesses = [for (final r in rows) if (good(r) <= -3) r];
    List<(String, double, Color)> bars(double Function(Bench) f, double mine) => [(context.tr('cmp_mine_short'), mine, p.accent), for (final r in refs) (r.$1.split(' ').first, f(r.$2), r.$3)];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: context.isMobile ? double.infinity : 360,
          child: DropdownButtonFormField<String>(
            initialValue: _coop,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.tr('cmp_my_coop'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            items: [for (final x in profiles) DropdownMenuItem(value: x.coop.id, child: Text('${x.coop.name} · ${x.coop.country}'))],
            onChanged: (v) => setState(() {
              _coop = v ?? _coop;
              app.setMyCoop(_coop);
            }),
          ),
        ),
        Segmented<int>(values: List.generate(refs.length, (i) => i), selected: refIdx, label: (i) => refs[i].$1, onChanged: (i) => setState(() => _refIdx = i)),
      ]),
      gap16,
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.forest, CI.espressoDeep])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${me.coop.name}  ${context.tr('vs')}  ${ref.$1}'.toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .7), letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final r in rows)
              Builder(builder: (_) {
                final d = delta(r.$2, r.$3);
                final ok = good(r) >= 0;
                return Container(
                  width: 168,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(14), border: Border.all(color: (ok ? p.green : p.alert).withValues(alpha: .6))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(r.$1).toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${d >= 0 ? '+' : ''}${Fmt.num(d, 0)} %', style: TextStyle(fontFamily: TS.display, fontSize: 26, fontWeight: FontWeight.w800, color: ok ? const Color(0xFF9CC9A0) : const Color(0xFFE8908E))),
                    Text('${r.$5(r.$2)} / ${r.$5(r.$3)}', style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 11)),
                  ]),
                );
              }),
          ]),
        ]),
      ),
      gap24,
      TwoCol(
        left: GlassCard(
          accent: p.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_strengths')),
            if (strengths.isEmpty) Text(context.tr('cmp_none'), style: TS.bodyS(p)),
            for (final r in strengths)
              Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(Icons.trending_up_rounded, color: p.green, size: 20), const SizedBox(width: 10), Expanded(child: Text(context.tr(r.$1), style: TS.h3(p))), TrendBadge(good(r))])),
          ]),
        ),
        right: GlassCard(
          accent: p.alert,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_weaknesses')),
            if (weaknesses.isEmpty) Text(context.tr('cmp_none'), style: TS.bodyS(p)),
            for (final r in weaknesses)
              Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(Icons.trending_down_rounded, color: p.alert, size: 20), const SizedBox(width: 10), Expanded(child: Text(context.tr(r.$1), style: TS.h3(p))), TrendBadge(good(r))])),
            if (weaknesses.isNotEmpty) ...[
              const Divider(height: 22),
              Text(context.tr('cmp_reco').toUpperCase(), style: TS.label(p)),
              const SizedBox(height: 6),
              Text(context.tr('cmp_reco_text', [context.tr(weaknesses.first.$1)]), style: TextStyle(color: p.text, fontSize: 13, height: 1.45)),
            ],
          ]),
        ),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('cmp_bars')),
          CompareRow(label: '${context.tr('cmp_yield')} (kg/ha)', entries: bars((b) => b.yield, me.yieldKgHa), fmt: (v) => Fmt.num(v, 0)),
          CompareRow(label: '${context.tr('cmp_income')} (${Fmt.sym}/${context.tr('y')})', entries: bars((b) => b.income, me.incomeYr), fmt: (v) => Fmt.money(v, 0)),
          CompareRow(label: '${context.tr('cmp_quality')} (/100)', entries: bars((b) => b.quality, myQ), fmt: (v) => Fmt.num(v, 1)),
          CompareRow(label: '${context.tr('cmp_cert')} (%)', entries: bars((b) => b.cert, me.certPct), fmt: (v) => Fmt.num(v, 0)),
          Text(context.tr('cmp_bench_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
        ]),
      ),
    ]);
  }
}
