import 'dart:async';
import 'package:flutter/material.dart';
import '../../animations/flows.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});
  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  double _refresh = 1;
  Timer? _t;

  void _runRefresh() {
    _t?.cancel();
    setState(() => _refresh = 0);
    _t = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) return t.cancel();
      setState(() => _refresh = (_refresh + .035).clamp(0.0, 1.0));
      if (_refresh >= 1) t.cancel();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final src = repo.sources();
    final active = src.where((s) => s.active).length;
    final avgQ = src.fold(0.0, (a, s) => a + s.quality) / src.length;
    final confCol = [p.alert, p.gold, p.green];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('sources_title', 'sources_sub', trailing: PrimaryButton(context.tr('simulate_refresh'), icon: Icons.sync_rounded, onTap: _runRefresh)),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('data_arrival')),
          const DataConvergence(height: 400),
        ]),
      ),
      gap24,
      Grid(columns: context.cols(desktop: 3, tablet: 3, mobile: 1), gap: 12, children: [
        KpiCard(labelKey: 'src_active', metric: 'default', value: active.toDouble(), unit: '/ ${src.length}', icon: Icons.hub_rounded),
        KpiCard(labelKey: 'src_quality', metric: 'default', value: avgQ, unit: '%', icon: Icons.verified_rounded),
        KpiCard(labelKey: 'src_latency', metric: 'default', value: 24, unit: 'min', icon: Icons.schedule_rounded),
      ]),
      gap24,
      if (_refresh < 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassCard(
            accent: p.gold,
            child: Row(children: [
              Icon(Icons.sync_rounded, color: p.gold),
              const SizedBox(width: 12),
              Expanded(child: LinearProgressIndicator(value: _refresh, minHeight: 8, borderRadius: BorderRadius.circular(4), color: p.gold, backgroundColor: p.border)),
              const SizedBox(width: 12),
              Text(context.tr('refreshing', [Fmt.num(_refresh * 100, 0)]), style: TS.h3(p)),
            ]),
          ),
        ),
      GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          if (!context.isMobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(children: [
                for (final h in [('col_source', 3), ('col_data', 2), ('col_freq', 2), ('col_updated', 2), ('col_quality', 3), ('col_conf', 2), ('col_state', 2)])
                  Expanded(flex: h.$2, child: Text(context.tr(h.$1).toUpperCase(), style: TS.label(p))),
              ]),
            ),
          for (var i = 0; i < src.length; i++)
            Reveal(
              delay: i * 60,
              child: _SourceRow(src[i], confCol[src[i].confidence], _refresh),
            ),
        ]),
      ),
      gap16,
      GlassCard(
        accent: p.green,
        onTap: () => showTrust(context, 'price_arabica', repo.series('arabica').last.v, context.tr('kpi_price'), '\$/lb'),
        child: Row(children: [
          Icon(Icons.fingerprint_rounded, color: p.green, size: 30),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('traceability_title'), style: TS.h3(p)),
            const SizedBox(height: 3),
            Text(context.tr('traceability_sub'), style: TS.bodyS(p)),
          ])),
          Icon(Icons.chevron_right_rounded, color: p.muted),
        ]),
      ),
    ]);
  }
}

class _SourceRow extends StatelessWidget {
  final dynamic s;
  final Color conf;
  final double refresh;
  const _SourceRow(this.s, this.conf, this.refresh);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final mobile = context.isMobile;
    final stateChip = s.active ? Chip2(context.tr('state_active'), p.green, icon: Icons.circle) : Chip2(context.tr('state_paused'), p.warn, icon: Icons.pause_circle_rounded);
    final updated = refresh < 1 ? context.tr('refreshing_short') : context.tr('ago', [s.updated]);
    final quality = Row(children: [
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: s.quality / 100),
          duration: context.dur(1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7, borderRadius: BorderRadius.circular(4), color: s.quality > 85 ? p.green : (s.quality > 75 ? p.gold : p.warn), backgroundColor: p.border),
        ),
      ),
      const SizedBox(width: 8),
      Text(Fmt.pct(s.quality, 0), style: TS.h3(p).copyWith(fontSize: 12.5)),
    ]);
    final confText = Chip2(context.tr(['conf_low', 'conf_med', 'conf_high'][s.confidence]), conf);
    if (mobile) {
      return Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(context.tr(s.nameKey), style: TS.h3(p))), stateChip]),
          const SizedBox(height: 4),
          Text('${context.tr(s.dataKey)} · ${context.tr(s.freqKey)} · $updated', style: TS.bodyS(p)),
          Text('${context.tr('sp_planned')} : ${context.tr('sp_${s.id}')} — ${context.tr('sp_status')}', style: TS.bodyS(p).copyWith(fontSize: 11, color: p.gold)),
          const SizedBox(height: 8),
          quality,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: confText),
        ]),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border.withValues(alpha: .6)))),
      child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(s.nameKey), style: TS.h3(p)), const SizedBox(height: 2), Text('${context.tr('sp_planned')} : ${context.tr('sp_${s.id}')}', style: TS.bodyS(p).copyWith(fontSize: 10.5)), Text(context.tr('sp_status'), style: TS.bodyS(p).copyWith(fontSize: 10.5, color: p.gold, fontWeight: FontWeight.w700))])),
        Expanded(flex: 2, child: Text(context.tr(s.dataKey), style: TS.bodyS(p).copyWith(fontSize: 13))),
        Expanded(flex: 2, child: Text(context.tr(s.freqKey), style: TS.bodyS(p).copyWith(fontSize: 13))),
        Expanded(flex: 2, child: Text(updated, style: TS.bodyS(p).copyWith(fontSize: 13))),
        Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(right: 18), child: quality)),
        Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: confText)),
        Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: stateChip)),
      ]),
    );
  }
}
