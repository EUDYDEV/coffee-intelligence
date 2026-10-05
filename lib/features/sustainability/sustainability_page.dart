import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/sustainability_data.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class SustainabilityPage extends StatelessWidget {
  const SustainabilityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final af = repo.countries(africaOnly: true);
    final c = repo.country(repo.country(app.selectedCountry).african ? app.selectedCountry : 'ETH');
    final b = sustainFor(c);
    final avg = af.map(sustainFor).fold(0.0, (a, s) => a + s.overall) / af.length;
    final dims = <(String, double)>[
      ('sd_cert', b.certification),
      ('sd_income', b.livingIncome),
      ('sd_yield', b.yieldPractice),
      ('sd_forest', b.forest),
      ('sd_emissions', b.emissions),
      ('sd_coverage', b.coverage),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('sustain_title', 'sustain_sub'),
      Reveal(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in af)
            ChoiceChip(label: Text('${x.flag} ${context.tr(x.nameKey)}'), selected: x.id == c.id, onSelected: (_) => app.selectCountry(x.id), selectedColor: p.green.withValues(alpha: .3), showCheckmark: false),
        ]),
      ),
      gap16,
      TwoCol(
        flexL: 4,
        flexR: 6,
        left: Reveal(
          delay: 100,
          child: GestureDetector(
            onTap: () => showTrust(context, 'sustain', b.overall, context.tr('sustain_index'), '/100'),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.forest, Color(0xFF1B2D20)])),
              child: Column(children: [
                Text(context.tr('sustain_index').toUpperCase(), style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 11, color: CI.cream.withValues(alpha: .7))),
                const SizedBox(height: 14),
                RingGauge(b.overall, size: 190, color: CI.gold, caption: '/100', pulse: true),
                const SizedBox(height: 14),
                Text('${c.flag} ${context.tr(c.nameKey)}', style: const TextStyle(color: CI.cream, fontFamily: TS.display, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(context.tr('vs_avg', [Fmt.num(b.overall - avg, 1)]), style: TextStyle(color: CI.cream.withValues(alpha: .7), fontSize: 12.5)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _Pillar(context.tr('social'), b.social, Icons.diversity_3_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _Pillar(context.tr('environment'), b.environment, Icons.park_rounded)),
                ]),
              ]),
            ),
          ),
        ),
        right: Reveal(
          delay: 200,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('sustain_dims')),
              Center(child: RadarW(size: context.isMobile ? 290 : 330, axes: [for (final d in dims) context.tr(d.$1)], series: [RadarSeries(c.id, [for (final d in dims) d.$2], p.green)])),
            ]),
          ),
        ),
      ),
      gap24,
      Grid(columns: context.cols(desktop: 3, tablet: 2, mobile: 1), children: [
        for (var i = 0; i < dims.length; i++)
          Reveal(
            delay: i * 80,
            child: GlassCard(
              accent: p.green,
              child: Row(children: [
                RingGauge(dims[i].$2, size: 76, color: dims[i].$2 > 60 ? p.green : (dims[i].$2 > 40 ? p.gold : p.alert)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr(dims[i].$1), style: TS.h3(p)),
                  const SizedBox(height: 3),
                  Text(context.tr('${dims[i].$1}_d'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
                ])),
              ]),
            ),
          ),
      ]),
      gap24,
      Reveal(
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('sustain_compare')),
            BarChartW(height: 230, fmt: (v) => Fmt.num(v, 0), selected: af.indexWhere((x) => x.id == c.id), onTap: (i) => app.selectCountry(af[i].id), items: [for (final x in af) BarItem(x.id, sustainFor(x).overall, p.green)]),
            const SizedBox(height: 6),
            Wrap(children: [for (final x in af) Padding(padding: const EdgeInsets.only(right: 12), child: Text('${x.id}: ${Fmt.pct(x.certPct, 0)} ${context.tr('certified')}', style: TS.bodyS(p).copyWith(fontSize: 11.5)))]),
          ]),
        ),
      ),
    ]);
  }
}

class _Pillar extends StatelessWidget {
  final String label;
  final double v;
  final IconData icon;
  const _Pillar(this.label, this.v, this.icon);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: CI.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: CI.cream.withValues(alpha: .8), fontSize: 12))),
          AnimatedCounter(v, style: const TextStyle(color: CI.cream, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
      );
}
