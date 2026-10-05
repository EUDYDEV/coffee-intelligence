import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  int _months = 36;
  bool _arab = true, _rob = true;
  int? _selOrigin;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final ind = repo.marketIndicators();
    final a = repo.series('arabica'), r = repo.series('robusta');
    final n = _months;
    final aa = a.sublist(a.length - n), rr = r.sublist(r.length - n);
    final series = <ChartSeries>[
      if (_arab) ChartSeries('Arabica', aa.map((e) => e.v).toList(), p.accent),
      if (_rob) ChartSeries('Robusta', rr.map((e) => e.v).toList(), p.green, fill: !_arab),
    ];
    if (series.isEmpty) series.add(ChartSeries('Arabica', aa.map((e) => e.v).toList(), p.accent));
    final origins = [...repo.countries()]..sort((x, y) => y.differential.compareTo(x.differential));
    double base(c) => (c.arabicaShare >= .5 ? a.last.v : r.last.v) + c.differential / 100;
    final ports = repo.transportCosts();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('market_title', 'market_sub',
          trailing: Segmented<int>(values: const [6, 12, 36], selected: _months, label: (v) => v == 36 ? '3 ${context.tr('y')}' : (v == 12 ? '1 ${context.tr('y')}' : '6 ${context.tr('m')}'), onChanged: (v) => setState(() => _months = v))),
      Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 1), children: [
        for (var i = 0; i < ind.length; i++)
          Reveal(delay: i * 80, child: _IndCard(ind[i], i)),
      ]),
      gap24,
      Reveal(
        delay: 200,
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('price_history'), trailing: Wrap(spacing: 6, children: [
              FilterChip(label: const Text('Arabica'), selected: _arab, onSelected: (v) => setState(() => _arab = v), selectedColor: p.accent.withValues(alpha: .25), showCheckmark: false),
              FilterChip(label: const Text('Robusta'), selected: _rob, onSelected: (v) => setState(() => _rob = v), selectedColor: p.green.withValues(alpha: .25), showCheckmark: false),
            ])),
            LineChartW(height: context.isMobile ? 240 : 330, dates: aa.map((e) => e.t).toList(), series: series, yFmt: (v) => Fmt.usd(v), highlight: _months == 36 && _arab ? 27 : null),
            if (_months == 36 && _arab)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [Icon(Icons.circle, size: 10, color: p.alert), const SizedBox(width: 6), Expanded(child: Text(context.tr('market_anomaly_note'), style: TS.bodyS(p)))]),
              ),
          ]),
        ),
      ),
      gap24,
      TwoCol(
        left: Reveal(
          delay: 300,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('origin_prices')),
              BarChartW(
                height: 260,
                selected: _selOrigin,
                onTap: (i) => setState(() => _selOrigin = i),
                fmt: (v) => Fmt.money(v, 2),
                items: [for (final c in origins) BarItem('${c.flag} ${c.id}', base(c), c.african ? p.accent : p.muted)],
              ),
              if (_selOrigin != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${context.tr(origins[_selOrigin!].nameKey)} · ${context.tr('differential')}: ${origins[_selOrigin!].differential >= 0 ? '+' : '-'}${Fmt.usd(origins[_selOrigin!].differential.abs() / 100)}/lb', style: TS.h3(p)),
                ),
            ]),
          ),
        ),
        right: Reveal(
          delay: 400,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('differentials')),
              for (final c in origins.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(width: 120, child: Text('${c.flag} ${context.tr(c.nameKey)}', style: TextStyle(color: p.text, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: c.differential),
                        duration: context.dur(1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => SizedBox(
                          height: 14,
                          child: CustomPaint(painter: _DiffBar(v, p.accent, p.alert, p.border)),
                        ),
                      ),
                    ),
                    SizedBox(width: 50, child: Text('${c.differential >= 0 ? '+' : '-'}${Fmt.money(c.differential.abs() / 100)}', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: c.differential >= 0 ? p.green : p.alert, fontSize: 12.5))),
                  ]),
                ),
            ]),
          ),
        ),
      ),
      gap24,
      Reveal(
        delay: 500,
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('transport_costs')),
            BarChartW(height: 200, fmt: (v) => Fmt.usd(v, 0), items: [
              for (final pt in repo.ports()) BarItem(pt.name, ports[pt.id]!, p.green),
            ]),
            Text(context.tr('transport_note'), style: TS.bodyS(p)),
          ]),
        ),
      ),
    ]);
  }
}

class _IndCard extends StatelessWidget {
  final dynamic ind;
  final int i;
  const _IndCard(this.ind, this.i);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isPct = ind.unit == '%';
    final metric = i == 1 ? 'price_robusta' : 'price_arabica';
    return GlassCard(
      onTap: () => showTrust(context, metric, ind.value, context.tr('ind_${ind.key}'), ind.unit),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('ind_${ind.key}').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 10),
        AnimatedCounter(isPct ? ind.value : Fmt.conv(ind.value), decimals: isPct ? 1 : Fmt.decFor(2), suffix: isPct ? ' %' : ' ${Fmt.unit(r'$/lb')}', style: TS.big(p, size: 28)),
        const SizedBox(height: 12),
        Row(children: [
          _mini(context, context.tr('daily'), ind.day),
          _mini(context, context.tr('monthly'), ind.month),
          _mini(context, context.tr('yearly'), ind.year),
        ]),
      ]),
    );
  }

  Widget _mini(BuildContext context, String l, double v) {
    final p = context.pal;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: TS.bodyS(p).copyWith(fontSize: 10.5)),
        const SizedBox(height: 3),
        Text(Fmt.pct(v, 1, true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: v >= 0 ? p.green : p.alert)),
      ]),
    );
  }
}

class _DiffBar extends CustomPainter {
  final double v;
  final Color pos, neg, track;
  _DiffBar(this.v, this.pos, this.neg, this.track);
  @override
  void paint(Canvas canvas, Size s) {
    final mid = s.width * .35;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 3, s.width, s.height - 6), const Radius.circular(6)), Paint()..color = track.withValues(alpha: .5));
    final w = (v.abs() / 80) * (v >= 0 ? s.width - mid : mid);
    final rect = v >= 0 ? Rect.fromLTWH(mid, 3, w, s.height - 6) : Rect.fromLTWH(mid - w, 3, w, s.height - 6);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = v >= 0 ? pos : neg);
    canvas.drawLine(Offset(mid, 0), Offset(mid, s.height), Paint()..color = track..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_DiffBar o) => o.v != v;
}
