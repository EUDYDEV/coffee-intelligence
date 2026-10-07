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
    final gov = govFor(c);
    final avg = af.map(sustainFor).fold(0.0, (a, s) => a + s.overall) / af.length;
    final dims = <(String, double)>[
      ('sd_cert', b.certification),
      ('sd_income', b.livingIncome),
      ('sd_yield', b.yieldPractice),
      ('sd_forest', b.forest),
      ('sd_emissions', b.emissions),
      ('sd_coverage', b.coverage),
      ('sd_governance', b.governance),
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
                RingGauge(b.overall, size: 190, color: CI.gold, textColor: CI.cream, caption: '/100', pulse: true),
                const SizedBox(height: 14),
                Text('${c.flag} ${context.tr(c.nameKey)}', style: const TextStyle(color: CI.cream, fontFamily: TS.display, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(context.tr('vs_avg', [Fmt.num(b.overall - avg, 1)]), style: TextStyle(color: CI.cream.withValues(alpha: .7), fontSize: 12.5)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  SizedBox(width: 150, child: _Pillar('E · ${context.tr('environment')}', b.environment, Icons.park_rounded)),
                  SizedBox(width: 150, child: _Pillar('S · ${context.tr('social')}', b.social, Icons.diversity_3_rounded)),
                  SizedBox(width: 150, child: _Pillar('G · ${context.tr('governance')}', b.governance, Icons.gavel_rounded)),
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
          accent: p.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('gov_title'), trailing: Chip2('G ${Fmt.num(b.governance, 0)}/100', p.gold)),
            Text(context.tr('gov_sub', [context.tr(c.nameKey)]), style: TS.bodyS(p)),
            const SizedBox(height: 12),
            Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 1), gap: 12, children: [
              for (final it in [
                ('gov_transparency', gov.transparency, '/100'),
                ('gov_coop', gov.coopGovernance, '/100'),
                ('gov_compliance', gov.compliance, '/100'),
                ('gov_audit', gov.audit, '/100'),
                ('gov_traceability', gov.traceability, '/100'),
                ('gov_grievance', gov.grievance, '/100'),
                ('gov_controls', gov.controlFreq, 'gov_per_year'),
                ('gov_audit_cov', gov.auditCoverage, '%'),
              ])
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(it.$1).toUpperCase(), style: TS.label(p), maxLines: 2),
                    const SizedBox(height: 6),
                    AnimatedCounter(it.$2, suffix: ' ${it.$3 == 'gov_per_year' ? context.tr('gov_per_year') : it.$3}', style: TS.big(p, size: 22)),
                    const SizedBox(height: 6),
                    if (it.$3 != 'gov_per_year') ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (it.$2 / 100).clamp(0.0, 1.0), minHeight: 6, color: it.$2 > 60 ? p.green : (it.$2 > 40 ? p.gold : p.alert), backgroundColor: p.border)),
                  ]),
                ),
            ]),
            const SizedBox(height: 8),
            Text(context.tr('gov_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
          ]),
        ),
      ),
      gap24,
      Reveal(
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('sustain_compare')),
            BarChartW(
                sourceId: 'certs', unit: '/100',height: 230, fmt: (v) => Fmt.num(v, 0), selected: af.indexWhere((x) => x.id == c.id), onTap: (i) => app.selectCountry(af[i].id), items: [for (final x in af) BarItem(x.id, sustainFor(x).overall, p.green)]),
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
