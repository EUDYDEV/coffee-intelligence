import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/format.dart';
import '../core/theme/app_theme.dart';
import '../data/demo/countries_data.dart';
import '../data/demo/quality_data.dart';
import '../data/repository.dart';
import '../features/shell/nav.dart';
import 'charts.dart';
import 'common.dart';

/// Drill-down explorer: Africa → country → region → cooperative → producer → lot.
class DrillDown extends StatefulWidget {
  const DrillDown({super.key});
  @override
  State<DrillDown> createState() => _DrillDownState();
}

class _Node {
  final String key, label;
  final double tonnes, quality, income;
  const _Node(this.key, this.label, this.tonnes, this.quality, this.income);
}

class _DrillDownState extends State<DrillDown> {
  final List<String> _path = [];
  String _metric = 'prod'; // prod | quality | income
  String _unit = 'kt'; // kt | t | bags

  static const _levels = ['dd_africa', 'dd_country', 'dd_region', 'dd_coop', 'dd_producer', 'dd_lot'];

  List<_Node> _children(BuildContext c) {
    final af = repo.countries(africaOnly: true);
    switch (_path.length) {
      case 0:
        return [for (final k in af) _Node(k.id, '${k.flag} ${c.tr(k.nameKey)}', k.prodKt * 1000, qualityFor(k.id).score, k.incomeYr)];
      case 1:
        final k = countryById(_path[0]);
        return [for (final r in k.regions) _Node(r.name, r.name, k.prodKt * 1000 * r.share, qualityFor('${k.id}:${r.name}').score, k.incomeYr * (.9 + r.share))];
      case 2:
        return [
          for (final co in demoCoops.where((x) => x.country == _path[0] && coopProfile(x).region == _path[1]))
            _Node(co.id, co.name, co.volumeT, qualityFor(co.id).score, coopProfile(co).incomeYr)
        ];
      case 3:
        return [for (final pr in producersOf(_path[2])) _Node(pr.id, pr.name, pr.kg / 1000, qualityFor(_path[2]).score, pr.incomeYr)];
      case 4:
        return [for (final l in demoLots.where((x) => x.coopId == _path[2])) _Node(l.id, l.id, l.bags * 60 / 1000, qualityFor(l.id).score, 0)];
    }
    return [];
  }

  double _val(_Node n) {
    switch (_metric) {
      case 'quality':
        return n.quality;
      case 'income':
        return Fmt.conv(n.income);
      default:
        return _unit == 'kt' ? n.tonnes / 1000 : (_unit == 't' ? n.tonnes : n.tonnes * 1000 / 60);
    }
  }

  String _fmt(double v) => _metric == 'quality' ? Fmt.num(v, 1) : Fmt.compact(v);

  String _unitLabel() => _metric == 'quality' ? '/100' : (_metric == 'income' ? '${Fmt.sym}/${context.tr('y')}' : (_unit == 'bags' ? context.tr('dd_bags') : _unit));

  String _crumb(int i) {
    final k = _path[i];
    if (i == 0) return context.tr('c_$k');
    if (i == 2) return demoCoops.firstWhere((c) => c.id == k).name;
    return k;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final nodes = _children(context);
    final leaf = _path.length >= 5;
    final lotId = leaf ? _path[4] : '';
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('dd_title')),
        Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Segmented<String>(values: const ['prod', 'quality', 'income'], selected: _metric, label: (v) => context.tr('dd_m_$v'), onChanged: (v) => setState(() => _metric = v)),
          if (_metric == 'prod') Segmented<String>(values: const ['kt', 't', 'bags'], selected: _unit, label: (v) => v == 'bags' ? context.tr('dd_bags') : v, onChanged: (v) => setState(() => _unit = v)),
        ]),
        const SizedBox(height: 10),
        // breadcrumb
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          GestureDetector(onTap: () => setState(_path.clear), child: Chip2(context.tr('africa'), _path.isEmpty ? p.accent : p.muted, icon: Icons.public_rounded)),
          for (var i = 0; i < _path.length; i++) ...[
            Icon(Icons.chevron_right_rounded, size: 18, color: p.muted),
            GestureDetector(onTap: () => setState(() => _path.removeRange(i + 1, _path.length)), child: Chip2(_crumb(i), i == _path.length - 1 ? p.accent : p.muted)),
          ],
        ]),
        const SizedBox(height: 4),
        Text('${context.tr('dd_level')} : ${context.tr(_levels[_path.length.clamp(0, 5)])}', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
        const SizedBox(height: 8),
        if (leaf)
          _LotCard(lotId: lotId)
        else if (nodes.isEmpty)
          Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(context.tr('dd_empty'), style: TS.bodyS(p))))
        else
          BarChartW(
            key: ValueKey('${_path.join('/')}$_metric$_unit'),
            height: 250,
            sourceId: _metric == 'income' ? 'survey' : (_metric == 'quality' ? 'coops' : 'production'),
            unit: _unitLabel(),
            legend: [(p.accent, context.tr(_levels[_path.length + 1 > 5 ? 5 : _path.length + 1]))],
            fmt: _fmt,
            onTap: (i) => setState(() => _path.add(nodes[i].key)),
            items: [for (final n in nodes) BarItem(n.label.length > 12 ? '${n.label.substring(0, 11)}…' : n.label, _val(n), p.accent)],
          ),
        if (!leaf && nodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.touch_app_rounded, size: 15, color: p.gold),
              const SizedBox(width: 6),
              Expanded(child: Text(context.tr('dd_hint'), style: TS.bodyS(p).copyWith(fontSize: 11.5))),
              if (_path.isNotEmpty) TextButton.icon(onPressed: () => setState(_path.removeLast), icon: const Icon(Icons.arrow_back_rounded, size: 16), label: Text(context.tr('dd_up'))),
            ]),
          ),
        if (leaf)
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 10, children: [
              TextButton.icon(onPressed: () => setState(_path.removeLast), icon: const Icon(Icons.arrow_back_rounded, size: 16), label: Text(context.tr('dd_up'))),
              PrimaryButton(context.tr('dd_open_trace'), icon: Icons.route_rounded, onTap: () {
                app.setChainTab('lots', lot: lotId);
                app.goto(navIndex('chain'));
              }),
            ]),
          ),
      ]),
    );
  }
}

class _LotCard extends StatelessWidget {
  final String lotId;
  const _LotCard({required this.lotId});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final l = lotById(lotId);
    final q = qualityFor(lotId);
    final coop = demoCoops.firstWhere((c) => c.id == l.coopId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Wrap(spacing: 24, runSpacing: 10, children: [
        _kv(context, 'LOT', l.id),
        _kv(context, context.tr('lot_coop'), coop.name),
        _kv(context, context.tr('lot_volume'), '${Fmt.num(l.bags, 0)} ${context.tr('dd_bags')}'),
        _kv(context, context.tr('ql_score'), Fmt.num(q.score, 1)),
        _kv(context, context.tr('lot_status'), context.tr(l.statusKey)),
      ]),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(k.toUpperCase(), style: TS.label(p)), const SizedBox(height: 3), Text(v, style: TS.h3(p))]);
  }
}
