import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/countries_data.dart';
import '../../data/demo/quality_data.dart';
import '../../data/demo/sustainability_data.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../shell/nav.dart';

/// Banner telling which profile is simulated and what the platform puts first for it.
class RoleBanner extends StatelessWidget {
  const RoleBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final r = app.roleDef;
    Widget ctxPicker() {
      if (r.id == 'coop') {
        return SizedBox(
          width: 250,
          child: DropdownButtonFormField<String>(
            initialValue: app.myCoop,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.tr('cmp_my_coop'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: [for (final c in demoCoops) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => app.setMyCoop(v ?? app.myCoop),
          ),
        );
      }
      if (r.id == 'board') {
        return SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: app.myCountry,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.tr('role_my_country'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: [for (final c in demoCountries.where((x) => x.african)) DropdownMenuItem(value: c.id, child: Text('${c.flag} ${context.tr(c.nameKey)}'))],
            onChanged: (v) => app.setMyCountry(v ?? app.myCountry),
          ),
        );
      }
      return const SizedBox();
    }

    return Reveal(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: r.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(18), border: Border.all(color: r.color.withValues(alpha: .5))),
        child: Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: r.color.withValues(alpha: .2), shape: BoxShape.circle), child: Icon(r.icon, color: r.color)),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.isMobile ? context.w - 100 : 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${context.tr('role_profile').toUpperCase()} · ${context.tr(r.nameKey)}', style: TS.label(p).copyWith(color: r.color)),
                const SizedBox(height: 2),
                Text(context.tr('${r.id}_focus'), style: TS.bodyS(p).copyWith(fontSize: 13, color: p.text)),
              ]),
            ),
          ]),
          ctxPicker(),
        ]),
      ),
    );
  }
}

List<Widget> roleKpis(BuildContext context) {
  final app = context.app;
  final arab = repo.series('arabica');
  final spark = arab.sublist(arab.length - 12).map((e) => e.v).toList();
  final af = repo.countries(africaOnly: true);
  double avg(double Function(Country) f) => af.fold(0.0, (a, c) => a + f(c)) / af.length;
  Widget k(String label, double v, String unit, IconData icon, {int d = 0, double? trend, bool inv = false, List<double>? sp, String metric = 'default'}) =>
      KpiCard(labelKey: label, metric: metric, value: v, unit: unit, decimals: d, trend: trend, invertTrend: inv, icon: icon, spark: sp);
  switch (app.role) {
    case 'coop':
      final co = demoCoops.firstWhere((c) => c.id == app.myCoop);
      final pr = coopProfile(co);
      return [
        k('rk_my_prod', pr.productionT, 't', Icons.spa_rounded, trend: 3.1, metric: 'production'),
        k('kpi_yield', pr.yieldKgHa, 'kg/ha', Icons.grass_rounded, trend: 1.4),
        k('kpi_income', pr.incomeYr, r'$', Icons.payments_rounded, trend: -2.3, metric: 'income'),
        k('prod_cost', pr.costKg, r'$/kg', Icons.build_rounded, d: 2, trend: 4.0, inv: true),
        k('rk_quality', qualityFor(co.id).score, '/100', Icons.coffee_rounded, d: 1, trend: 1.2),
        k('rk_certified', pr.certPct, '%', Icons.verified_rounded, trend: 2.0),
      ];
    case 'exporter':
      final best = repo.countries().map((c) => c.differential).reduce((a, b) => a > b ? a : b);
      final tc = repo.transportCosts().values.fold(0.0, (a, b) => a + b) / repo.transportCosts().length;
      final port = repo.chain().firstWhere((s) => s.id == 'port');
      return [
        k('kpi_price', arab.last.v, r'$/lb', Icons.show_chart_rounded, d: 2, trend: (arab.last.v / arab[arab.length - 2].v - 1) * 100, sp: spark, metric: 'price_arabica'),
        k('rk_best_diff', best / 100, r'$/lb', Icons.stacked_line_chart_rounded, d: 2, trend: 2.2),
        k('rk_freight', tc, r'$/t', Icons.local_shipping_rounded, trend: 5.4, inv: true),
        k('rk_available', repo.africaExports(), 'kt', Icons.inventory_2_rounded, trend: -4.8, metric: 'exports'),
        k('rk_port_delay', port.delayDays + 4, 'j', Icons.anchor_rounded, trend: 12.0, inv: true),
        k('kpi_forecast', repo.forecast('price').forecast.last.v, r'$/lb', Icons.query_stats_rounded, d: 2, trend: 8.7),
      ];
    case 'roaster':
      final bestQ = af.map((c) => qualityFor(c.id).score).reduce((a, b) => a > b ? a : b);
      final delivered = demoLots.where((l) => l.progress >= 10).length;
      return [
        k('rk_best_quality', bestQ, '/100', Icons.workspace_premium_rounded, d: 1, trend: 0.8),
        k('kpi_price', arab.last.v, r'$/lb', Icons.show_chart_rounded, d: 2, trend: (arab.last.v / arab[arab.length - 2].v - 1) * 100, sp: spark, metric: 'price_arabica'),
        k('rk_available', repo.africaExports(), 'kt', Icons.inventory_2_rounded, trend: -4.8, metric: 'exports'),
        k('rk_certified', avg((c) => c.certPct), '%', Icons.verified_rounded, trend: 1.6),
        k('rk_traced', delivered / demoLots.length * 100, '%', Icons.route_rounded, trend: 6.0),
        k('rk_supply_risk', repo.chain().fold(0.0, (a, s) => a + s.risk) / repo.chain().length, '/100', Icons.warning_amber_rounded, trend: 3.0, inv: true),
      ];
    case 'ngo':
      return [
        k('rk_income_vs_living', avg((c) => c.incomeYr) / 2400 * 100, '%', Icons.payments_rounded, trend: -1.8, metric: 'income'),
        k('rk_certified', avg((c) => c.certPct), '%', Icons.verified_rounded, trend: 1.6),
        k('rk_deforest', avg((c) => c.deforestRisk), '/100', Icons.forest_rounded, trend: 2.4, inv: true),
        k('rk_emissions', avg((c) => sustainFor(c).emissions), '/100', Icons.cloud_rounded, trend: .8),
        k('sustain_index', af.fold(0.0, (a, c) => a + sustainFor(c).overall) / af.length, '/100', Icons.eco_rounded, trend: 1.1, metric: 'sustain'),
        k('rk_risk_zones', af.where((c) => c.climateRisk > 62 || c.deforestRisk > 45).length.toDouble(), '/ 6', Icons.crisis_alert_rounded, trend: 16.0, inv: true),
      ];
    default: // national board
      final c = countryById(app.myCountry);
      return [
        k('rk_nat_prod', c.prodKt, 'kt', Icons.spa_rounded, trend: 3.4, metric: 'production', sp: c.prodHistory),
        k('kpi_exports', c.exportsKt, 'kt', Icons.directions_boat_rounded, trend: -4.8, metric: 'exports'),
        k('kpi_producers', c.producersK, 'k', Icons.people_alt_rounded, trend: 1.2),
        k('kpi_income', c.incomeYr, r'$', Icons.payments_rounded, trend: -2.1, metric: 'income'),
        k('kpi_climate', c.climateRisk, '/100', Icons.cloud_rounded, trend: 6.2, inv: true, metric: 'climate'),
        k('sustain_index', sustainFor(c).overall, '/100', Icons.eco_rounded, trend: 1.1, metric: 'sustain'),
      ];
  }
}

/// Role-specific panel under the KPIs (what that user group cares about most).
class RolePanel extends StatelessWidget {
  const RolePanel({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final af = repo.countries(africaOnly: true);
    Widget quick() {
      final ids = app.roleDef.primary.skip(1).take(4).toList();
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final id in ids)
          GestureDetector(
            onTap: () => app.goto(navIndex(id)),
            child: Chip2(context.tr(navItems[navIndex(id)].labelKey), p.accent, icon: navItems[navIndex(id)].icon),
          ),
      ]);
    }

    switch (app.role) {
      case 'coop':
        final co = demoCoops.firstWhere((c) => c.id == app.myCoop);
        final me = coopProfile(co);
        final peers = coopProfiles().where((x) => x.coop.country == co.country && x.coop.id != co.id).toList();
        final nat = benchOf(peers);
        final k = countryById(co.country);
        return TwoCol(
          left: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_vs_nat')),
              CompareRow(label: '${context.tr('cmp_yield')} (kg/ha)', entries: [(context.tr('cmp_mine_short'), me.yieldKgHa, p.accent), (context.tr('cmp_national_avg').split(' ').first, nat.yield, p.green)], fmt: (v) => Fmt.num(v, 0)),
              CompareRow(label: '${context.tr('cmp_income')} (${Fmt.sym})', entries: [(context.tr('cmp_mine_short'), me.incomeYr, p.accent), (context.tr('cmp_national_avg').split(' ').first, nat.income, p.green)], fmt: (v) => Fmt.money(v, 0)),
              CompareRow(label: '${context.tr('cmp_quality')} (/100)', entries: [(context.tr('cmp_mine_short'), qualityFor(co.id).score, p.accent), (context.tr('cmp_national_avg').split(' ').first, nat.quality, p.green)], fmt: (v) => Fmt.num(v, 1)),
              PrimaryButton(context.tr('rp_full_compare'), icon: Icons.compare_arrows_rounded, outlined: true, onTap: () => app.goto(navIndex('compare'))),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_zone_alerts', [context.tr(k.nameKey)])),
              for (final a in repo.alerts().where((a) => a.category == 'weather' || a.category == 'production').take(3))
                Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.only(top: 5), width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: p.sev(a.severity))), const SizedBox(width: 10), Expanded(child: Text(context.tr(a.titleKey), style: TS.h3(p).copyWith(fontSize: 13.5))), Text(context.tr('ago', [a.ago]), style: TS.bodyS(p).copyWith(fontSize: 11))])),
              quick(),
            ]),
          ),
        );
      case 'exporter':
        final tc = repo.transportCosts();
        return TwoCol(
          left: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_freight_ports')),
              BarChartW(height: 230, sourceId: 'ports', unit: '${Fmt.sym}/t', legend: [(p.green, context.tr('transport_costs'))], fmt: (v) => Fmt.usd(v, 0), items: [for (final pt in repo.ports()) BarItem(pt.name, tc[pt.id]!, p.green)]),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_logistic_risks')),
              for (final s in repo.chain().where((s) => s.status > 0))
                Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(Icons.warning_amber_rounded, color: s.status == 2 ? p.alert : p.warn, size: 20), const SizedBox(width: 10), Expanded(child: Text('${context.tr(s.nameKey)} · ${context.tr('chain_risk_${s.id}')}', style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13))), Text('${Fmt.num(s.delayDays, 0)} j', style: TS.h3(p))])),
              quick(),
            ]),
          ),
        );
      case 'roaster':
        final ranking = [...repo.countries()]..sort((a, b) => qualityFor(b.id).score.compareTo(qualityFor(a.id).score));
        return TwoCol(
          flexL: 6,
          flexR: 4,
          left: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_origins_quality')),
              BarChartW(height: 250, sourceId: 'coops', unit: '/100', legend: [(p.accent, context.tr('africa')), (p.muted, context.tr('world'))], fmt: (v) => Fmt.num(v, 1), items: [for (final c in ranking) BarItem('${c.flag} ${c.id}', qualityFor(c.id).score, c.african ? p.accent : p.muted)]),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_availability')),
              for (final c in af.take(6)) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 90, child: Text('${c.flag} ${c.id}', style: TS.h3(p).copyWith(fontSize: 13))), Expanded(child: Text('${Fmt.num(c.exportsKt, 0)} kt · ${Fmt.num(c.certPct, 0)} % ${context.tr('certified')}', style: TS.bodyS(p)))])),
              const SizedBox(height: 8),
              PrimaryButton(context.tr('rp_open_lots'), icon: Icons.route_rounded, outlined: true, onTap: () {
                app.setChainTab('lots');
                app.goto(navIndex('chain'));
              }),
            ]),
          ),
        );
      case 'ngo':
        final z = [...af]..sort((a, b) => (b.climateRisk + b.deforestRisk).compareTo(a.climateRisk + a.deforestRisk));
        return TwoCol(
          left: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_risk_zones')),
              for (final c in z)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(width: 100, child: Text('${c.flag} ${context.tr(c.nameKey)}', overflow: TextOverflow.ellipsis, style: TS.h3(p).copyWith(fontSize: 13))),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (c.climateRisk + c.deforestRisk) / 200, minHeight: 10, color: (c.climateRisk + c.deforestRisk) > 110 ? p.alert : p.warn, backgroundColor: p.border))),
                    SizedBox(width: 90, child: Text('${Fmt.num(c.climateRisk, 0)} / ${Fmt.num(c.deforestRisk, 0)}', textAlign: TextAlign.right, style: TS.bodyS(p))),
                  ]),
                ),
              Text(context.tr('rp_risk_legend'), style: TS.bodyS(p).copyWith(fontSize: 11)),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_indicator_trend')),
              LineChartW(
                height: 220,
                sourceId: 'survey',
                unit: 'index 100',
                dates: [for (var i = 0; i < 8; i++) DateTime(2019 + i, 7, 1)],
                yFmt: (v) => Fmt.num(v, 0),
                series: [
                  ChartSeries(context.tr('kpi_income'), const [100, 103, 101, 106, 104, 102, 101, 99], p.accent, fill: false),
                  ChartSeries(context.tr('rk_certified'), const [100, 108, 115, 121, 130, 138, 147, 156], p.green, fill: false),
                  ChartSeries(context.tr('rk_deforest'), const [100, 102, 105, 104, 108, 110, 111, 113], p.alert, fill: false),
                ],
              ),
              quick(),
            ]),
          ),
        );
      default: // board
        final c = countryById(app.myCountry);
        final world = [...repo.countries()]..sort((a, b) => b.prodKt.compareTo(a.prodKt));
        final top = world.take(5).toList();
        if (!top.any((x) => x.id == c.id)) top.add(c);
        return TwoCol(
          left: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_intl_compare', [context.tr(c.nameKey)])),
              BarChartW(height: 230, sourceId: 'production', unit: 'kt', legend: [(p.accent, context.tr(c.nameKey)), (p.muted, context.tr('world'))], fmt: (v) => Fmt.num(v, 0), items: [for (final x in top) BarItem('${x.flag} ${x.id}', x.prodKt, x.id == c.id ? p.accent : p.muted)]),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('rp_regions', [context.tr(c.nameKey)])),
              for (final r in c.regions)
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 100, child: Text(r.name, style: TS.h3(p).copyWith(fontSize: 13))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: r.share / .45, minHeight: 10, color: p.green, backgroundColor: p.border))), SizedBox(width: 70, child: Text('${Fmt.num(c.prodKt * r.share, 0)} kt', textAlign: TextAlign.right, style: TS.bodyS(p)))])),
              const SizedBox(height: 10),
              quick(),
            ]),
          ),
        );
    }
  }
}

