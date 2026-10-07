import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo/sustainability_data.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});
  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final List<String> _sel = ['KEN', 'ETH', 'UGA'];
  String _mode = 'country';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final all = repo.countries();
    final cs = [for (final id in _sel) repo.country(id)];
    final colors = p.seriesColors;
    Color col(int i) => colors[i % colors.length];
    String nm(Country c) => context.tr(c.nameKey);

    List<(String, double, Color)> ent(double Function(Country) f) => [for (var i = 0; i < cs.length; i++) (cs[i].id, f(cs[i]), col(i))];

    final selector = Wrap(spacing: 8, runSpacing: 8, children: [
      for (final c in all)
        FilterChip(
          label: Text('${c.flag} ${c.id}'),
          selected: _sel.contains(c.id),
          showCheckmark: false,
          selectedColor: _sel.contains(c.id) ? col(_sel.indexOf(c.id)).withValues(alpha: .35) : null,
          onSelected: (v) => setState(() {
            if (v) {
              if (_sel.length >= 4) _sel.removeAt(0);
              _sel.add(c.id);
            } else if (_sel.length > 1) {
              _sel.remove(c.id);
            }
          }),
        ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('compare_title', 'compare_sub',
          trailing: Segmented<String>(values: const ['country', 'region', 'coop'], selected: _mode, label: (v) => context.tr('cmp_$v'), onChanged: (v) => setState(() => _mode = v))),
      if (_mode == 'country') ...[
        selector,
        gap16,
        Reveal(
          child: Wrap(spacing: 14, children: [for (var i = 0; i < cs.length; i++) LegendDot(col(i), '${cs[i].flag} ${nm(cs[i])}')]),
        ),
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
                  axes: [context.tr('cmp_prod'), context.tr('cmp_yield'), context.tr('cmp_income'), context.tr('cmp_margin'), context.tr('cmp_cert'), context.tr('cmp_sustain')],
                  series: [
                    for (var i = 0; i < cs.length; i++)
                      RadarSeries(cs[i].id, [
                        (cs[i].prodKt / 800 * 100).clamp(8, 100).toDouble(),
                        (cs[i].yieldKgHa / 1800 * 100).clamp(8, 100).toDouble(),
                        (cs[i].incomeYr / 4000 * 100).clamp(8, 100).toDouble(),
                        (cs[i].margin / 1.2 * 100).clamp(8, 100).toDouble(),
                        cs[i].certPct * 1.6,
                        sustainFor(cs[i]).overall,
                      ], col(i)),
                  ],
                ),
              ),
            ]),
          ),
          right: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('cmp_metrics')),
              CompareRow(label: '${context.tr('cmp_prod')} (kt)', entries: ent((c) => c.prodKt), fmt: (v) => Fmt.num(v, 0)),
              CompareRow(label: '${context.tr('cmp_yield')} (kg/ha)', entries: ent((c) => c.yieldKgHa), fmt: (v) => Fmt.num(v, 0)),
              CompareRow(label: '${context.tr('cmp_income')} (\$/${context.tr('y')})', entries: ent((c) => c.incomeYr), fmt: (v) => Fmt.money(v, 0)),
              CompareRow(label: '${context.tr('cmp_cost')} (\$/kg)', entries: ent((c) => c.costKg), fmt: (v) => Fmt.money(v, 2), lowerIsBetter: true),
              CompareRow(label: '${context.tr('cmp_cert')} (%)', entries: ent((c) => c.certPct), fmt: (v) => Fmt.num(v, 0)),
              CompareRow(label: context.tr('cmp_sustain'), entries: ent((c) => sustainFor(c).overall), fmt: (v) => Fmt.num(v, 0)),
              CompareRow(label: context.tr('kpi_producers') + ' (k)', entries: ent((c) => c.producersK), fmt: (v) => Fmt.num(v, 0)),
            ]),
          ),
        ),
        gap24,
        Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('cmp_evolution')),
              LineChartW(
                sourceId: 'production', unit: 'index',
                height: 260,
                dates: [for (var i = 0; i < 8; i++) DateTime(2019 + i, 7, 1)],
                yFmt: (v) => Fmt.num(v, 0),
                series: [for (var i = 0; i < cs.length; i++) ChartSeries(cs[i].id, [for (final v in cs[i].prodHistory) v / cs[i].prodHistory.first * 100], col(i), fill: false)],
              ),
              Text(context.tr('cmp_index_note'), style: TS.bodyS(p)),
            ]),
          ),
        ),
      ] else if (_mode == 'region') ...[
        selector,
        gap16,
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_region_vol')),
            BarChartW(
                sourceId: 'production', unit: 'kt',height: 300, fmt: (v) => Fmt.num(v, 1), items: [
              for (var i = 0; i < cs.length; i++)
                for (final r in cs[i].regions) BarItem(r.name, cs[i].prodKt * r.share, col(i)),
            ]),
            const SizedBox(height: 6),
            Wrap(children: [for (var i = 0; i < cs.length; i++) LegendDot(col(i), nm(cs[i]))]),
          ]),
        ),
      ] else ...[
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cmp_coop_vol')),
            BarChartW(
                sourceId: 'coops', unit: 't',height: 320, fmt: (v) => Fmt.num(v, 0), items: [
              for (final k in repo.coops()) BarItem(k.name.split(' ').first, k.volumeT, [p.accent, p.green, p.gold, const Color(0xFF8B5A7C), const Color(0xFF4F7F93), p.warn][repo.countries(africaOnly: true).indexWhere((c) => c.id == k.country)]),
            ]),
            Text(context.tr('cmp_coop_note'), style: TS.bodyS(p)),
          ]),
        ),
      ],
    ]);
  }
}
