import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/countries_data.dart';
import '../../data/demo/quality_data.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

const _intlProfile = QualityProfile(83.0, 8.1, 7.9, 8.0, 8.2, 7.9, 8.0, 1, 1600, 'grade_specialty', 'Mixed', 'proc_washed', 'INT', []);

/// "Production & Quality" — quality scorecards by country, region, cooperative and lot.
class QualityView extends StatefulWidget {
  const QualityView({super.key});
  @override
  State<QualityView> createState() => _QualityViewState();
}

class _QualityViewState extends State<QualityView> {
  String _level = 'coop'; // country | region | coop | lot
  String _key = '';

  List<(String, String)> _entities(BuildContext c) {
    switch (_level) {
      case 'country':
        return [for (final k in demoCountries) (k.id, '${k.flag} ${c.tr(k.nameKey)}')];
      case 'region':
        return [for (final k in demoCountries.where((x) => x.african)) for (final r in k.regions) ('${k.id}:${r.name}', '${r.name} · ${c.tr(k.nameKey)}')];
      case 'lot':
        return [for (final l in demoLots) (l.id, l.id)];
      default:
        return [for (final k in demoCoops) (k.id, '${k.name} · ${k.country}')];
    }
  }

  String _countryOf(String key) {
    if (key.contains(':')) return key.split(':').first;
    final coop = demoCoops.where((x) => x.id == key).firstOrNull;
    if (coop != null) return coop.country;
    final lot = demoLots.where((l) => l.id == key).firstOrNull;
    if (lot != null) return demoCoops.firstWhere((x) => x.id == lot.coopId).country;
    return key;
  }

  String _regionOf(String key) {
    final coop = demoCoops.where((x) => x.id == key).firstOrNull ?? (demoLots.where((l) => l.id == key).firstOrNull != null ? demoCoops.firstWhere((x) => x.id == demoLots.firstWhere((l) => l.id == key).coopId) : null);
    if (coop == null) return '';
    return '${coop.country}:${coopProfile(coop).region}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final ents = _entities(context);
    if (_key.isEmpty || !ents.any((e) => e.$1 == _key)) {
      _key = _level == 'coop' && ents.any((e) => e.$1 == app.myCoop) ? app.myCoop : ents.first.$1;
    }
    final q = qualityFor(_key);
    final country = _countryOf(_key);
    final label = ents.firstWhere((e) => e.$1 == _key).$2;

    // comparators
    final comps = <(String, QualityProfile, Color)>[];
    if (_level == 'coop' || _level == 'lot') {
      final reg = _regionOf(_key);
      if (reg.isNotEmpty) comps.add((context.tr('cmp_region_avg'), qualityFor(reg), p.gold));
    }
    if (_level != 'country') comps.add((context.tr('cmp_national_avg'), qualityFor(country), p.green));
    comps.add((context.tr('cmp_intl_ref'), _intlProfile, p.muted));
    final attrs = <(String, double Function(QualityProfile))>[
      ('qa_acidity', (x) => x.acidity),
      ('qa_body', (x) => x.body),
      ('qa_sweetness', (x) => x.sweetness),
      ('qa_aroma', (x) => x.aroma),
      ('qa_aftertaste', (x) => x.aftertaste),
      ('qa_balance', (x) => x.balance),
    ];
    final ranking = [...demoCoops]..sort((a, b) => qualityFor(b.id).score.compareTo(qualityFor(a.id).score));
    final trend = qualityTrend(_key), trendNat = qualityTrend(country);

    final selector = Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Segmented<String>(values: const ['country', 'region', 'coop', 'lot'], selected: _level, label: (v) => context.tr('ql_$v'), onChanged: (v) => setState(() {
        _level = v;
        _key = '';
      })),
      SizedBox(
        width: context.isMobile ? double.infinity : 360,
        child: DropdownButtonFormField<String>(
          key: ValueKey('$_level$_key'),
          initialValue: _key,
          isExpanded: true,
          decoration: InputDecoration(isDense: true, labelText: context.tr('ql_select'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: [for (final e in ents) DropdownMenuItem(value: e.$1, child: Text(e.$2, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => _key = v ?? _key),
        ),
      ),
    ]);

    final card = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.espresso, CI.espressoDeep]), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .2), blurRadius: 22, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('ql_$_level').toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: TS.display, color: CI.cream, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          RingGauge(q.score, size: 120, color: CI.gold, textColor: CI.cream, caption: context.tr('ql_score')),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Chip2(context.tr(q.grade), CI.gold, icon: Icons.workspace_premium_rounded),
              const SizedBox(height: 10),
              _meta(context.tr('ql_variety'), q.variety),
              _meta(context.tr('ql_process'), context.tr(q.process)),
              _meta(context.tr('ql_altitude'), '${Fmt.num(q.altitude.toDouble(), 0)} m'),
              _meta(context.tr('ql_origin'), context.tr('c_$country')),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Text(context.tr('ql_notes').toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final n in q.notes) Chip2(context.tr(n), CI.latte)]),
      ]),
    );

    final bars = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('ql_attributes')),
        for (final a in attrs) _AttrBar(context.tr(a.$1), a.$2(q), p.green),
        _AttrBar(context.tr('ql_defects'), q.defects.toDouble(), p.alert, max: 10, inverse: true, valueText: '${q.defects}'),
        Text(context.tr('ql_scale_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      ]),
    );

    final compare = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('ql_compare')),
        Center(
          child: RadarW(
            size: context.isMobile ? 290 : 340,
            axes: [for (final a in attrs) context.tr(a.$1)],
            series: [
              RadarSeries(label, [for (final a in attrs) (a.$2(q) - 5) * 20], p.accent),
              for (final c in comps) RadarSeries(c.$1, [for (final a in attrs) (a.$2(c.$2) - 5) * 20], c.$3),
            ],
          ),
        ),
        Wrap(children: [LegendDot(p.accent, label), for (final c in comps) LegendDot(c.$3, c.$1)]),
        const SizedBox(height: 10),
        for (final c in comps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Expanded(child: Text('${context.tr('ql_score')} · $label ${context.tr('vs')} ${c.$1}', style: TS.bodyS(p).copyWith(fontSize: 12))),
              TrendBadge((q.score / c.$2.score - 1) * 100),
              const SizedBox(width: 6),
              Text('${Fmt.num(q.score - c.$2.score, 1)} pts', style: TS.h3(p).copyWith(fontSize: 12.5)),
            ]),
          ),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      selector,
      gap16,
      TwoCol(flexL: 4, flexR: 5, left: card, right: bars),
      gap24,
      TwoCol(
        flexL: 5,
        flexR: 5,
        left: compare,
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('ql_trend')),
            LineChartW(
              height: 260,
              sourceId: 'coops',
              unit: '/100',
              dates: [for (var i = 0; i < 8; i++) DateTime(2019 + i, 7, 1)],
              yFmt: (v) => Fmt.num(v, 1),
              series: [ChartSeries(label, trend, p.accent, fill: false), ChartSeries(context.tr('cmp_national_avg'), trendNat, p.green, fill: false, dashed: true)],
            ),
          ]),
        ),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('ql_ranking')),
          BarChartW(
            height: 260,
            sourceId: 'coops',
            unit: '/100',
            legend: [(p.accent, context.tr('ql_selected')), (p.green, context.tr('ql_coops'))],
            fmt: (v) => Fmt.num(v, 1),
            selected: ranking.indexWhere((x) => x.id == _key),
            onTap: (i) => setState(() {
              _level = 'coop';
              _key = ranking[i].id;
            }),
            items: [for (final c in ranking) BarItem(c.name.split(' ').first, qualityFor(c.id).score, c.id == _key ? p.accent : p.green)],
          ),
        ]),
      ),
    ]);
  }

  Widget _meta(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          SizedBox(width: 76, child: Text(k, style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(color: CI.cream, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
}

class _AttrBar extends StatelessWidget {
  final String label;
  final double v;
  final Color color;
  final double max;
  final bool inverse;
  final String? valueText;
  const _AttrBar(this.label, this.v, this.color, {this.max = 10, this.inverse = false, this.valueText});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 92, child: Text(label, style: TextStyle(color: p.text, fontSize: 12.5))),
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('$label$v'),
            tween: Tween(begin: 0, end: v / max),
            duration: context.dur(1000),
            curve: Curves.easeOutCubic,
            builder: (_, f, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: f.clamp(0.0, 1.0), minHeight: 12, color: inverse ? (v <= 2 ? p.green : (v <= 4 ? p.warn : p.alert)) : color, backgroundColor: p.border),
            ),
          ),
        ),
        SizedBox(width: 44, child: Text(valueText ?? Fmt.num(v, 1), textAlign: TextAlign.right, style: TS.h3(p).copyWith(fontSize: 13))),
      ]),
    );
  }
}
