import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/detection_scene.dart';
import '../../widgets/layout.dart';
import '../../widgets/map/map_view.dart';

class AnomaliesPage extends StatefulWidget {
  const AnomaliesPage({super.key});
  @override
  State<AnomaliesPage> createState() => _AnomaliesPageState();
}

class _AnomaliesPageState extends State<AnomaliesPage> {
  String _sel = 'an1';
  bool _zoomed = false;
  final bool _showPanel = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _t?.cancel();
    _zoomed = false;
    _t = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _zoomed = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _unit(String series) => switch (series) {
        'arabica' => '\$/lb',
        'rain_civ' => 'mm',
        'exports_ken' => 'kt',
        'yield_uga' => 'kg/ha',
        'prod_eth' => 'kt',
        _ => context.tr('days'),
      };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final list = repo.anomalies();
    final a = list.firstWhere((x) => x.id == _sel);
    final s = repo.series(a.series);
    final c = repo.country(a.country);
    final obs = s[a.index].v;
    final prevV = s[a.index - 1].v, nextV = a.index + 1 < s.length ? s[a.index + 1].v : prevV;
    final exp = (prevV + nextV) / 2;
    final dev = (obs / exp - 1) * 100;
    final from = (a.index - 5).clamp(0, s.length - 1), to = (a.index + 4).clamp(0, s.length - 1);
    final count = [for (var i = 0; i < 3; i++) list.where((x) => x.severity == i).length];
    final col = p.sev(a.severity);
    final unit = _unit(a.series);

    final listW = Column(children: [
      for (var i = 0; i < list.length; i++)
        Reveal(
          delay: i * 70,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              selected: list[i].id == _sel,
              accent: p.sev(list[i].severity),
              padding: const EdgeInsets.all(14),
              onTap: () {
                setState(() => _sel = list[i].id);
                _schedule();
              },
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: p.sev(list[i].severity), boxShadow: [BoxShadow(color: p.sev(list[i].severity), blurRadius: 8)])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(list[i].titleKey), style: TS.h3(p)),
                    const SizedBox(height: 3),
                    Text('${repo.country(list[i].country).flag} ${context.tr(repo.country(list[i].country).nameKey)}', style: TS.bodyS(p)),
                  ]),
                ),
                SevChip(list[i].severity),
              ]),
            ),
          ),
        ),
    ]);

    final detail = AnimatedSwitcher(
      duration: context.dur(300),
      child: Column(
        key: ValueKey(_sel),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetectionScene(
            title: context.tr(a.titleKey),
            severity: a.severity,
            impactKey: ['impact_high', 'impact_medium', 'impact_low'][a.severity],
            signals: switch (a.series) {
              'arabica' => [('sg_price', -1), ('sg_prod_stable', 0), ('sg_exports', -1), ('sg_transport', 1)],
              'rain_civ' => [('sg_rain', -1), ('sg_prod_risk', -1), ('sg_price_up', 1)],
              'exports_ken' => [('sg_exports', -1), ('sg_prod_stable', 0), ('sg_transport', 1)],
              'yield_uga' => [('sg_yield', 1), ('sg_data_check', 1)],
              'prod_eth' => [('sg_prod_up', 1), ('sg_price', -1)],
              _ => [('sg_transport', 1), ('sg_exports', -1)],
            },
          ),
          gap16,
          GlassCard(
            accent: col,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(context.tr(a.titleKey), style: TS.h2(p))),
                SevChip(a.severity),
              ]),
              const SizedBox(height: 6),
              Text(context.tr(a.descKey), style: TS.bodyS(p).copyWith(fontSize: 14)),
              const SizedBox(height: 14),
              LineChartW(
                height: context.isMobile ? 230 : 290,
                dates: s.map((e) => e.t).toList(),
                series: [ChartSeries(context.tr('observed'), s.map((e) => e.v).toList(), p.accent)],
                highlight: a.index,
                highlightColor: col,
                window: _zoomed ? (from, to) : null,
                yFmt: (v) => a.series == 'arabica' ? Fmt.usd(v) : Fmt.num(v, v.abs() < 10 ? 2 : 0),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Mini(context.tr('observed'), a.series == 'arabica' ? '${Fmt.usd(obs)}/lb' : '${Fmt.num(obs, obs < 10 ? 2 : 0)} $unit', col)),
                Expanded(child: _Mini(context.tr('expected'), a.series == 'arabica' ? '${Fmt.usd(exp)}/lb' : '${Fmt.num(exp, exp < 10 ? 2 : 0)} $unit', p.muted)),
                Expanded(child: _Mini(context.tr('deviation'), Fmt.pct(dev, 0, true), col)),
              ]),
            ]),
          ),
          gap16,
          TwoCol(
            left: GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(context.tr('likely_cause')),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lightbulb_rounded, color: p.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.tr(a.causeKey), style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, height: 1.4))),
                ]),
                const SizedBox(height: 14),
                SectionLabel(context.tr('related_info')),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip2('${c.flag} ${context.tr(c.nameKey)}', p.accent),
                  Chip2(context.tr('detected_by'), p.green, icon: Icons.memory_rounded),
                  Chip2(context.tr('confidence_n', [Fmt.num(96 - a.severity * 6, 0)]), p.gold),
                ]),
              ]),
            ),
            right: _showPanel
                ? MapView(height: 250, layers: const {'production', 'climate'}, focus: _zoomed ? (c.african ? c.id : null) : null, selected: c.african ? c.id : null, interactive: false, build: false)
                : const SizedBox(),
          ),
        ],
      ),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('anomalies_title', 'anomalies_sub'),
      Reveal(
        child: Wrap(spacing: 10, runSpacing: 8, children: [
          for (var i = 0; i < 3; i++)
            Chip2('${context.tr(['sev_critical', 'sev_important', 'sev_watch'][i])} · ${count[i]}', p.sev(i), icon: Icons.circle),
          Chip2(context.tr('auto_detection'), p.green, icon: Icons.auto_graph_rounded),
        ]),
      ),
      gap16,
      TwoCol(flexL: 4, flexR: 7, stretch: false, left: listW, right: detail),
    ]);
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Mini(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TS.label(p)),
      const SizedBox(height: 3),
      Text(value, style: TS.big(p, size: 20).copyWith(color: color)),
    ]);
  }
}
