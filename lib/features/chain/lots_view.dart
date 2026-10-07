import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/countries_data.dart';
import '../../data/demo/quality_data.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

const _stepIcons = [
  Icons.landscape_rounded,
  Icons.groups_rounded,
  Icons.person_rounded,
  Icons.water_rounded,
  Icons.warehouse_rounded,
  Icons.inventory_2_rounded,
  Icons.anchor_rounded,
  Icons.directions_boat_rounded,
  Icons.handshake_rounded,
  Icons.local_cafe_rounded,
];

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Lot-level traceability: origin → cooperative → producer → processing → warehouse → exporter → port → ship → buyer → roaster.
class LotsView extends StatefulWidget {
  const LotsView({super.key});
  @override
  State<LotsView> createState() => _LotsViewState();
}

class _LotsViewState extends State<LotsView> {
  int _step = -1;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final lots = demoLots.where((l) => _q.isEmpty || l.id.toLowerCase().contains(_q.toLowerCase())).toList();
    final selId = app.selectedLot.isEmpty || !demoLots.any((l) => l.id == app.selectedLot) ? demoLots.first.id : app.selectedLot;
    final lot = lotById(selId);
    final coop = demoCoops.firstWhere((c) => c.id == lot.coopId);
    final country = countryById(coop.country);
    final q = qualityFor(lot.id);
    final cur = _step < 0 ? (lot.progress - 1).clamp(0, 9) : _step;
    final stepCol = [p.green, p.gold, p.muted];

    final list = GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        TextField(onChanged: (v) => setState(() => _q = v), decoration: InputDecoration(isDense: true, hintText: context.tr('lot_search'), prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 8),
        for (final l in lots)
          GestureDetector(
            onTap: () => setState(() {
              app.setChainTab('lots', lot: l.id);
              _step = -1;
            }),
            child: AnimatedContainer(
              duration: context.dur(200),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: l.id == lot.id ? p.accent.withValues(alpha: .14) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: l.id == lot.id ? p.accent : p.border)),
              child: Row(children: [
                Icon(Icons.qr_code_2_rounded, size: 20, color: l.id == lot.id ? p.accent : p.muted),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.id, style: TS.h3(p).copyWith(fontSize: 13)), Text(demoCoops.firstWhere((c) => c.id == l.coopId).name, style: TS.bodyS(p).copyWith(fontSize: 11.5))])),
                Chip2(context.tr(l.statusKey), l.progress >= 10 ? p.green : p.gold),
              ]),
            ),
          ),
      ]),
    );

    final header = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: p.accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.qr_code_2_rounded, color: p.accent, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${context.tr('lot_word')} ${lot.id}', style: TS.h2(p)), Text('${coop.name} · ${country.flag} ${context.tr(country.nameKey)}', style: TS.bodyS(p))])),
          Chip2(context.tr(lot.statusKey), lot.progress >= 10 ? p.green : p.gold, icon: Icons.circle),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 26, runSpacing: 12, children: [
          _kv(context, context.tr('lot_volume'), '${Fmt.num(lot.bags, 0)} ${context.tr('dd_bags')} (${Fmt.num(lot.bags * 60 / 1000, 1)} t)'),
          _kv(context, context.tr('lot_harvest'), _date(lot.harvest)),
          _kv(context, context.tr('ql_score'), '${Fmt.num(q.score, 1)} · ${context.tr(q.grade)}'),
          _kv(context, context.tr('ql_process'), context.tr(q.process)),
          _kv(context, context.tr('ql_altitude'), '${q.altitude} m'),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final c in lot.certs) Chip2(context.tr(c), p.green, icon: Icons.verified_rounded)]),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          key: ValueKey(lot.id),
          tween: Tween(begin: 0, end: lot.progress / 10),
          duration: context.dur(1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: v, minHeight: 10, color: p.green, backgroundColor: p.border)),
            const SizedBox(height: 4),
            Text(context.tr('lot_progress', [lot.progress, 10]), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
          ]),
        ),
      ]),
    );

    final timeline = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('lot_timeline')),
        for (var i = 0; i < lotSteps.length; i++)
          Builder(builder: (_) {
            final st = i < lot.progress - 1 ? 0 : (i == lot.progress - 1 ? 1 : 2); // done / current / pending
            final col = stepCol[st];
            final sel = cur == i;
            final date = lot.harvest.add(Duration(days: lotSteps[i].$3));
            return Reveal(
              delay: i * 60,
              child: GestureDetector(
                onTap: () => setState(() => _step = i),
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 40,
                      child: Column(children: [
                        Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: st == 2 ? p.surface2 : col, border: Border.all(color: col, width: 2)), child: Icon(st == 0 ? Icons.check_rounded : _stepIcons[i], size: 16, color: st == 2 ? p.muted : Colors.white)),
                        if (i < lotSteps.length - 1) Expanded(child: Container(width: 2, color: st == 0 ? p.green : p.border)),
                      ]),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: sel ? p.accent.withValues(alpha: .1) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? p.accent : Colors.transparent)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(context.tr(lotSteps[i].$1), style: TS.h3(p).copyWith(color: st == 2 ? p.muted : p.text))),
                            if (st != 2) Text(_date(date), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
                            const SizedBox(width: 8),
                            Chip2(context.tr(['lot_done', 'lot_current', 'lot_pending'][st]), col),
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [Icon(Icons.place_rounded, size: 13, color: p.muted), const SizedBox(width: 4), Expanded(child: Text(context.tr(lotSteps[i].$2), style: TS.bodyS(p).copyWith(fontSize: 12)))]),
                          if (sel) ...[
                            const SizedBox(height: 8),
                            Text(context.tr('${lotSteps[i].$1}_d'), style: TextStyle(color: p.text, fontSize: 12.5, height: 1.4)),
                            const SizedBox(height: 6),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              Chip2('${context.tr('lot_doc')} ${lot.id}-D${i + 1}', p.muted, icon: Icons.description_rounded),
                              Chip2('${context.tr('lot_qty')} ${Fmt.num(lot.bags * 60 / 1000 * (1 - i * .004), 1)} t', p.accent),
                              if (st != 2) Chip2(context.tr('lot_verified'), p.green, icon: Icons.verified_rounded),
                            ]),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        Text(context.tr('lot_sim_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      ]),
    );

    return TwoCol(flexL: 3, flexR: 7, stretch: false, left: list, right: Column(children: [header, gap16, timeline]));
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(k.toUpperCase(), style: TS.label(p)), const SizedBox(height: 3), Text(v, style: TS.h3(p))]);
  }
}
