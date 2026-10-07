import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/cert_weather_data.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

const _schemeIcons = {
  'fairtrade': Icons.handshake_rounded,
  'rainforest': Icons.forest_rounded,
  'utz': Icons.verified_user_rounded,
  'organic': Icons.eco_rounded,
  'c4': Icons.public_rounded,
};

const _journeyIcons = [Icons.agriculture_rounded, Icons.groups_rounded, Icons.fact_check_rounded, Icons.workspace_premium_rounded, Icons.factory_rounded, Icons.inventory_2_rounded, Icons.handshake_rounded];

class CertsPage extends StatefulWidget {
  const CertsPage({super.key});
  @override
  State<CertsPage> createState() => _CertsPageState();
}

class _CertsPageState extends State<CertsPage> {
  String? _scheme;
  String? _country;
  int? _status;
  int _step = 2;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final af = repo.countries(africaOnly: true);
    final statusColors = [p.green, p.warn, p.alert, p.muted];
    final all = demoCerts;
    final rows = all.where((c) => (_scheme == null || c.scheme == _scheme) && (_country == null || c.country == _country) && (_status == null || c.status == _status)).toList()
      ..sort((a, b) => a.expires.compareTo(b.expires));
    final expiring = all.where((c) => c.status == 1).length;
    final expired = all.where((c) => c.status == 2).length;
    final chartScheme = _scheme ?? 'fairtrade';
    final step = certJourney[_step];

    Widget schemeCard(String s) {
      final recs = all.where((c) => c.scheme == s).toList();
      final cov = recs.fold(0.0, (a, c) => a + c.coverage) / recs.length;
      final prod = recs.fold(0.0, (a, c) => a + c.producers);
      final vol = recs.fold(0.0, (a, c) => a + c.volumeKt);
      return GlassCard(
        selected: _scheme == s,
        onTap: () => setState(() => _scheme = _scheme == s ? null : s),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(_schemeIcons[s], color: p.accent), const SizedBox(width: 8), Expanded(child: Text(context.tr('cert_$s'), style: TS.h3(p)))]),
          const SizedBox(height: 10),
          AnimatedCounter(cov, decimals: 1, suffix: ' %', style: TS.big(p, size: 26)),
          Text(context.tr('cert_coverage'), style: TS.bodyS(p).copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          Text('${Fmt.compact(prod)} ${context.tr('cert_producers').toLowerCase()}', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
          Text('${Fmt.num(vol, 0)} kt ${context.tr('cert_volume').toLowerCase()}', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var st = 0; st < 3; st++)
              if (recs.any((c) => c.status == st)) Chip2('${recs.where((c) => c.status == st).length}', statusColors[st]),
          ]),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('certs_title', 'certs_sub'),
      if (expiring + expired > 0)
        Reveal(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.warn.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: p.warn, width: 4))),
            child: Row(children: [
              Icon(Icons.event_busy_rounded, color: p.warn),
              const SizedBox(width: 12),
              Expanded(child: Text(context.tr('cert_alert_text', [expiring, expired]), style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13.5))),
              TextButton(onPressed: () => setState(() => _status = 1), child: Text(context.tr('cert_see_expiring'))),
            ]),
          ),
        ),
      Grid(columns: context.cols(desktop: 5, tablet: 3, mobile: 2), gap: 12, children: [for (var i = 0; i < certSchemes.length; i++) Reveal(delay: i * 70, child: schemeCard(certSchemes[i]))]),
      gap24,
      TwoCol(
        flexL: 5,
        flexR: 4,
        left: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cert_coverage_by_country', [context.tr('cert_$chartScheme')])),
            BarChartW(
              height: 240,
              sourceId: 'certs',
              unit: '%',
              legend: [(p.green, context.tr('cert_coverage'))],
              fmt: (v) => Fmt.num(v, 1),
              selected: _country == null ? null : af.indexWhere((x) => x.id == _country),
              onTap: (i) => setState(() => _country = _country == af[i].id ? null : af[i].id),
              items: [for (final c in af) BarItem(c.id, all.firstWhere((r) => r.scheme == chartScheme && r.country == c.id).coverage, p.green)],
            ),
          ]),
        ),
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('cert_status_summary')),
            for (var st = 0; st < 4; st++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _status = _status == st ? null : st),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColors[st])),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.tr(['cert_st_valid', 'cert_st_expiring', 'cert_st_expired', 'cert_st_pending'][st]), style: TextStyle(color: p.text, fontWeight: _status == st ? FontWeight.w800 : FontWeight.w500))),
                    Text('${all.where((c) => c.status == st).length}', style: TS.h3(p)),
                  ]),
                ),
              ),
            const Divider(height: 24),
            Text(context.tr('cert_filters').toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ChoiceChip(label: Text(context.tr('cat_all')), selected: _country == null, onSelected: (_) => setState(() => _country = null), showCheckmark: false),
              for (final c in af) ChoiceChip(label: Text(c.id), selected: _country == c.id, onSelected: (_) => setState(() => _country = _country == c.id ? null : c.id), showCheckmark: false),
            ]),
          ]),
        ),
      ),
      gap24,
      GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(6, 6, 6, 0), child: SectionLabel(context.tr('certs_register'), trailing: Chip2('${rows.length}', p.accent))),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: context.w - 90),
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 44,
                columnSpacing: 22,
                headingTextStyle: TS.label(p),
                columns: [for (final k in ['col_country', 'cert_scheme', 'cert_body', 'cert_status', 'cert_issued', 'cert_expires', 'cert_coverage', 'cert_producers', 'cert_volume']) DataColumn(label: Text(context.tr(k).toUpperCase()))],
                rows: [
                  for (final c in rows.take(30))
                    DataRow(cells: [
                      DataCell(Text(context.tr('c_${c.country}'), style: TextStyle(color: p.text))),
                      DataCell(Text(context.tr('cert_${c.scheme}'), style: TextStyle(color: p.text, fontWeight: FontWeight.w600))),
                      DataCell(Text(c.body, style: TextStyle(color: p.muted, fontSize: 12.5))),
                      DataCell(Chip2(context.tr(['cert_st_valid', 'cert_st_expiring', 'cert_st_expired', 'cert_st_pending'][c.status]), statusColors[c.status])),
                      DataCell(Text('${c.issued.year}-${c.issued.month.toString().padLeft(2, '0')}', style: TextStyle(color: p.text))),
                      DataCell(Text('${c.expires.year}-${c.expires.month.toString().padLeft(2, '0')}', style: TextStyle(color: c.status >= 1 && c.status <= 2 ? statusColors[c.status] : p.text, fontWeight: FontWeight.w600))),
                      DataCell(Text('${Fmt.num(c.coverage, 1)} %', style: TextStyle(color: p.text))),
                      DataCell(Text(Fmt.num(c.producers, 0), style: TextStyle(color: p.text))),
                      DataCell(Text('${Fmt.num(c.volumeKt, 1)} kt', style: TextStyle(color: p.text))),
                    ]),
                ],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 4), child: Text(context.tr('chart_source', [context.tr('s_certs'), context.tr('ago', ['34 j']), '88']), style: TS.bodyS(p).copyWith(fontSize: 11))),
        ]),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('cj_title')),
          Text(context.tr('cj_sub'), style: TS.bodyS(p)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, c) {
            final vertical = c.maxWidth < 700;
            final nodes = [
              for (var i = 0; i < certJourney.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _step = i),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: context.dur(250),
                      padding: const EdgeInsets.all(12),
                      width: vertical ? double.infinity : null,
                      decoration: BoxDecoration(
                        color: _step == i ? p.accent.withValues(alpha: .16) : p.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _step == i ? p.accent : p.border, width: _step == i ? 2 : 1),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_journeyIcons[i], color: _step == i ? p.accent : p.muted),
                        const SizedBox(height: 6),
                        Text(context.tr(certJourney[i].key), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.text)),
                      ]),
                    ),
                  ),
                ),
            ];
            if (vertical) {
              return Column(children: [for (var i = 0; i < nodes.length; i++) ...[nodes[i], if (i < nodes.length - 1) Icon(Icons.south_rounded, color: p.muted)]]);
            }
            return Row(children: [for (var i = 0; i < nodes.length; i++) ...[Expanded(child: nodes[i]), if (i < nodes.length - 1) Icon(Icons.arrow_forward_rounded, color: p.muted, size: 18)]]);
          }),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: context.dur(250),
            child: Container(
              key: ValueKey(_step),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
              child: Wrap(spacing: 28, runSpacing: 12, children: [
                _kv(context, context.tr('cj_step'), context.tr(step.key)),
                _kv(context, context.tr('cj_duration'), '${Fmt.num(step.days, 0)} ${context.tr('days')}'),
                _kv(context, context.tr('cj_pass'), '${Fmt.num(step.passRate, 0)} %'),
                _kv(context, context.tr('cj_items'), Fmt.num(step.items.toDouble(), 0)),
                SizedBox(width: 320, child: Text(context.tr('${step.key}_d'), style: TS.bodyS(p).copyWith(fontSize: 13))),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Text(context.tr('cj_funnel').toUpperCase(), style: TS.label(p)),
          const SizedBox(height: 6),
          BarChartW(
            height: 170,
            unit: context.tr('cj_items'),
            legend: [(p.accent, context.tr('cj_items'))],
            fmt: (v) => Fmt.compact(v),
            selected: _step,
            onTap: (i) => setState(() => _step = i),
            items: [for (final j in certJourney) BarItem(context.tr(j.key).split(' ').first, j.items.toDouble(), p.accent)],
          ),
        ]),
      ),
    ]);
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(k.toUpperCase(), style: TS.label(p)), const SizedBox(height: 3), Text(v, style: TS.h3(p))]);
  }
}
