import 'package:flutter/material.dart';
import '../../animations/flows.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/chain_photo.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class ChainPage extends StatefulWidget {
  const ChainPage({super.key});
  @override
  State<ChainPage> createState() => _ChainPageState();
}

class _ChainPageState extends State<ChainPage> {
  String _sel = 'port';
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final steps = repo.chain();
    final s = steps.firstWhere((e) => e.id == _sel);
    final totalDays = steps.fold(0.0, (a, e) => a + e.delayDays);
    final statusCol = [p.green, p.gold, p.alert][s.status];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('chain_title', 'chain_sub'),
      GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('coffee_flow'), trailing: Chip2(context.tr('lead_time', [Fmt.num(totalDays, 0)]), p.accent, icon: Icons.schedule_rounded)),
          ChainFlow(steps: steps, selected: _sel, onSelect: (id) => setState(() => _sel = id)),
          Text(context.tr('chain_hint'), style: TS.bodyS(p)),
        ]),
      ),
      gap24,
      ChainPhoto(_sel, height: context.isMobile ? 240 : 420),
      gap24,
      TwoCol(
        flexL: 4,
        flexR: 5,
        left: AnimatedSwitcher(
          duration: context.dur(350),
          child: GlassCard(
            key: ValueKey(_sel),
            accent: statusCol,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: .15)), child: Icon(chainIcons[s.id], color: p.accent)),
                const SizedBox(width: 12),
                Expanded(child: Text(context.tr(s.nameKey), style: TS.h2(p))),
                Chip2(context.tr(['status_ok', 'status_attention', 'status_risk'][s.status]), statusCol, icon: Icons.circle),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Stat(context.tr('volume'), Fmt.num(s.volumeKt, 0), 'kt')),
                Expanded(child: _Stat(context.tr('delay'), Fmt.num(s.delayDays, 0), context.tr('days'))),
                Expanded(child: _Stat(context.tr('risk_level'), Fmt.num(s.risk, 0), '/100')),
              ]),
              const SizedBox(height: 16),
              _Row(Icons.groups_rounded, context.tr('actors'), context.tr(s.actors.first)),
              _Row(Icons.place_rounded, context.tr('location'), context.tr(s.location)),
              _Row(Icons.warning_amber_rounded, context.tr('risks'), context.tr('chain_risk_${s.id}')),
            ]),
          ),
        ),
        right: Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('volume_through_chain')),
              BarChartW(
                sourceId: 'ports', unit: 'kt', legend: [(p.green, context.tr('status_ok')), (p.gold, context.tr('status_attention')), (p.alert, context.tr('status_risk'))],
                height: 260,
                selected: steps.indexWhere((e) => e.id == _sel),
                onTap: (i) => setState(() => _sel = steps[i].id),
                fmt: (v) => Fmt.num(v, 0),
                items: [for (final e in steps) BarItem(context.tr(e.nameKey).split(' ').first, e.volumeKt, [p.green, p.gold, p.alert][e.status])],
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label, value, unit;
  const _Stat(this.label, this.value, this.unit);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TS.label(p)),
      const SizedBox(height: 4),
      Text.rich(TextSpan(children: [TextSpan(text: value, style: TS.big(p, size: 24)), TextSpan(text: ' $unit', style: TS.bodyS(p))])),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: p.muted),
        const SizedBox(width: 10),
        SizedBox(width: 82, child: Text(label, style: TS.bodyS(p))),
        Expanded(child: Text(value, style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13.5))),
      ]),
    );
  }
}
