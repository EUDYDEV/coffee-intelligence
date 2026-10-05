import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

const livingIncomeBenchmark = 2400.0;

class RevenuePage extends StatelessWidget {
  const RevenuePage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final af = repo.countries(africaOnly: true);
    final c = repo.country(repo.country(app.selectedCountry).african ? app.selectedCountry : 'ETH');
    final price = (c.arabicaShare >= .5 ? repo.series('arabica').last.v : repo.series('robusta').last.v) * 2.2046;
    final logistics = price - c.farmgateKg;
    final margin = c.margin;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('revenue_title', 'revenue_sub'),
      Reveal(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in af)
            ChoiceChip(
              label: Text('${x.flag} ${context.tr(x.nameKey)}'),
              selected: x.id == c.id,
              onSelected: (_) => app.selectCountry(x.id),
              selectedColor: p.accent.withValues(alpha: .25),
              showCheckmark: false,
            ),
        ]),
      ),
      gap16,
      Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 2), gap: 12, children: [
        KpiCard(labelKey: 'farmgate', metric: 'price_arabica', value: c.farmgateKg, decimals: 2, unit: '\$/kg', icon: Icons.sell_rounded, trend: 2.4),
        KpiCard(labelKey: 'prod_cost', metric: 'income', value: c.costKg, decimals: 2, unit: '\$/kg', icon: Icons.build_rounded, trend: 4.1, invertTrend: true),
        KpiCard(labelKey: 'margin', metric: 'income', value: margin, decimals: 2, unit: '\$/kg', icon: Icons.savings_rounded, trend: -1.3),
        KpiCard(labelKey: 'kpi_income', metric: 'income', value: c.incomeYr, unit: '\$/${context.tr('y')}', icon: Icons.payments_rounded, trend: -2.1),
      ]),
      gap24,
      Reveal(
        delay: 200,
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('waterfall_title')),
            Text(context.tr('waterfall_sub'), style: TS.bodyS(p)),
            const SizedBox(height: 10),
            BarChartW(height: 280, fmt: (v) => Fmt.usd(v.abs()), items: [
              BarItem(context.tr('wf_export'), price, p.gold),
              BarItem(context.tr('wf_logistics'), price - logistics, p.alert, from: price),
              BarItem(context.tr('wf_farmgate'), c.farmgateKg, p.accent),
              BarItem(context.tr('wf_cost'), margin, p.warn, from: c.farmgateKg),
              BarItem(context.tr('wf_margin'), margin, p.green),
            ]),
          ]),
        ),
      ),
      gap24,
      TwoCol(
        left: Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('zone_compare_margin')),
              BarChartW(height: 230, fmt: (v) => Fmt.money(v, 2), selected: af.indexWhere((x) => x.id == c.id), onTap: (i) => app.selectCountry(af[i].id), items: [for (final x in af) BarItem(x.id, x.margin, x.margin > .7 ? p.green : p.warn)]),
            ]),
          ),
        ),
        right: Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('living_income')),
              Text(context.tr('living_income_sub', [Fmt.usd(livingIncomeBenchmark, 0)]), style: TS.bodyS(p)),
              const SizedBox(height: 10),
              for (final x in af)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 92, child: Text('${x.flag} ${x.id}', style: TextStyle(color: p.text, fontWeight: FontWeight.w600))),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (x.incomeYr / livingIncomeBenchmark).clamp(0, 1)),
                        duration: context.dur(1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 12, borderRadius: BorderRadius.circular(6), color: v > .6 ? p.green : (v > .4 ? p.gold : p.alert), backgroundColor: p.border),
                      ),
                    ),
                    SizedBox(width: 64, child: Text(Fmt.pct(x.incomeYr / livingIncomeBenchmark * 100, 0), textAlign: TextAlign.right, style: TextStyle(color: p.text, fontWeight: FontWeight.w700))),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }
}
