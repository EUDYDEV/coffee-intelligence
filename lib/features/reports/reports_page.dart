import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../../widgets/layout.dart';

const _reports = [
  ('market', Icons.candlestick_chart_rounded),
  ('production', Icons.spa_rounded),
  ('sustain', Icons.eco_rounded),
  ('risks', Icons.shield_rounded),
  ('africa', Icons.public_rounded),
  ('monthly', Icons.calendar_month_rounded),
];

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  String? _id;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _c.duration = context.calm ? const Duration(milliseconds: 600) : const Duration(milliseconds: 5200);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _generate(String id) {
    setState(() => _id = id);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final cards = Grid(columns: context.cols(desktop: 3, tablet: 2, mobile: 1), gap: 14, children: [
      for (var i = 0; i < _reports.length; i++)
        Reveal(
          delay: i * 70,
          child: GlassCard(
            selected: _id == _reports[i].$1,
            onTap: () => _generate(_reports[i].$1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: p.accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Icon(_reports[i].$2, color: p.accent)),
                const Spacer(),
                Chip2('PDF', p.muted),
              ]),
              const SizedBox(height: 14),
              Text(context.tr('rep_${_reports[i].$1}'), style: TS.h2(p).copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(context.tr('rep_${_reports[i].$1}_d'), style: TS.bodyS(p)),
              const SizedBox(height: 14),
              Row(children: [Icon(Icons.auto_awesome_rounded, size: 15, color: p.gold), const SizedBox(width: 6), Text(context.tr('generate'), style: TextStyle(color: p.gold, fontWeight: FontWeight.w700, fontSize: 12.5))]),
            ]),
          ),
        ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('reports_title', 'reports_sub'),
      cards,
      if (_id != null) ...[
        gap24,
        AnimatedBuilder(animation: _c, builder: (_, __) => _Generation(id: _id!, t: _c.value)),
      ],
    ]);
  }
}

class _Generation extends StatelessWidget {
  final String id;
  final double t;
  const _Generation({required this.id, required this.t});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const stages = ['gen_collect', 'gen_analyze', 'gen_generate', 'gen_ready'];
    final idx = (t * 4).floor().clamp(0, 3);
    final done = t >= 1;
    return GlassCard(
      accent: done ? p.green : p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('rep_$id')),
        Row(children: [
          for (var i = 0; i < stages.length; i++) ...[
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: context.dur(300),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < idx || done ? p.green : (i == idx ? p.gold : p.surface2), border: Border.all(color: i <= idx || done ? Colors.transparent : p.border)),
                  child: Icon(i < idx || done ? Icons.check_rounded : [Icons.cloud_download_rounded, Icons.analytics_rounded, Icons.edit_document, Icons.task_alt_rounded][i], size: 19, color: i <= idx || done ? Colors.white : p.muted),
                ),
                const SizedBox(height: 6),
                Text(context.tr(stages[i]), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500, color: i <= idx || done ? p.text : p.muted)),
              ]),
            ),
            if (i < stages.length - 1)
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: LinearProgressIndicator(value: ((t * 4 - i)).clamp(0.0, 1.0), minHeight: 3, color: p.green, backgroundColor: p.border))),
          ],
        ]),
        if (done) ...[
          const SizedBox(height: 20),
          _Preview(id: id),
        ],
      ]),
    );
  }
}

class _Preview extends StatelessWidget {
  final String id;
  const _Preview({required this.id});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final af = repo.countries(africaOnly: true);
    final paper = p.dark ? const Color(0xFF3A2A20) : const Color(0xFFFFFEFA);
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 16 : 28),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: p.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const OrgLogo(height: 34, framed: false),
          const SizedBox(width: 10),
          Text('COFFEE INTELLIGENCE', style: TS.label(p)),
          const Spacer(),
          const DemoTag(),
        ]),
        const SizedBox(height: 14),
        Text(context.tr('rep_$id'), style: TS.h1(p).copyWith(fontSize: 26)),
        Text('${context.tr('rep_period')} · ${context.tr('rep_generated')}', style: TS.bodyS(p)),
        const Divider(height: 28),
        Text(context.tr('rep_summary').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 6),
        Text(context.tr('rep_${id}_sum', [Fmt.usd(3.1)]), style: TextStyle(color: p.text, fontSize: 14, height: 1.55)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _K(context.tr('kpi_price'), Fmt.usd(repo.series('arabica').last.v), p)),
          Expanded(child: _K(context.tr('kpi_prod'), '${Fmt.num(repo.africaProduction(), 0)} kt', p)),
          Expanded(child: _K(context.tr('kpi_income'), Fmt.usd(repo.africaIncome(), 0), p)),
        ]),
        const SizedBox(height: 14),
        BarChartW(height: 170, fmt: (v) => Fmt.num(v, 0), items: [for (final c in af) BarItem(c.id, c.prodKt, p.accent)]),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          PrimaryButton(context.tr('download_pdf'), icon: Icons.download_rounded, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('pdf_demo_note'))));
          }),
          PrimaryButton(context.tr('share'), icon: Icons.share_rounded, outlined: true, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('pdf_demo_note'))));
          }),
        ]),
      ]),
    );
  }
}

class _K extends StatelessWidget {
  final String l, v;
  final Pal p;
  const _K(this.l, this.v, this.p);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.toUpperCase(), style: TS.label(p), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(v, style: TS.big(p, size: 20)),
      ]);
}
