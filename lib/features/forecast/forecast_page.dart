import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});
  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  String _id = 'price';
  int _h = 12;

  static const _units = {'price': '\$/lb', 'production': 'kt', 'yield': 'kg/ha', 'climate': '/100'};
  static const _icons = {'price': Icons.show_chart_rounded, 'production': Icons.spa_rounded, 'yield': Icons.grass_rounded, 'climate': Icons.thunderstorm_rounded};

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = repo.forecast(_id);
    final dec = _id == 'price' ? 2 : (_id == 'climate' ? 0 : (_id == 'yield' ? 0 : 1));
    String fmt(double v) => _id == 'price' ? Fmt.usd(v) : Fmt.num(v, dec);
    final hist = f.history.map((e) => e.v).toList();
    final fc = [hist.last, ...f.forecast.map((e) => e.v)];
    final lo = [hist.last, ...f.lower];
    final up = [hist.last, ...f.upper];
    final shown = _h + 1;
    final dates = [...f.history.map((e) => e.t), ...f.forecast.take(_h).map((e) => e.t)];
    final k = _h - 1;
    final cur = hist.last;
    final target = f.forecast[k].v;
    final change = (target / cur - 1) * 100;
    final risky = _id == 'climate';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('forecast_title', 'forecast_sub',
          trailing: Segmented<int>(values: const [3, 6, 12], selected: _h, label: (v) => '$v ${context.tr('m')}', onChanged: (v) => setState(() => _h = v))),
      Reveal(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final id in _units.keys)
            ChoiceChip(
              avatar: Icon(_icons[id], size: 16, color: _id == id ? Colors.white : p.muted),
              label: Text(context.tr('fc_$id')),
              selected: _id == id,
              showCheckmark: false,
              selectedColor: p.accent,
              labelStyle: TextStyle(color: _id == id ? Colors.white : p.text, fontWeight: FontWeight.w600),
              onSelected: (_) => setState(() => _id = id),
            ),
        ]),
      ),
      gap16,
      TwoCol(
        flexL: 3,
        flexR: 7,
        left: AnimatedSwitcher(
          duration: context.dur(350),
          child: Container(
            key: ValueKey('$_id$_h'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.espresso, CI.espressoDeep]), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .2), blurRadius: 24, offset: const Offset(0, 10))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('fc_predicted', [context.tr('fc_$_id')]).toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              AnimatedCounter(target, decimals: _id == 'price' ? 2 : dec, formatter: _id == 'price' ? (v) => Fmt.usd(v) : null, suffix: _id == 'price' ? '' : ' ${_units[_id]}', style: const TextStyle(fontFamily: TS.display, color: CI.cream, fontSize: 44, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TrendBadge(change, invert: risky),
              const SizedBox(height: 18),
              Text(context.tr('fc_range').toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${fmt(f.lower[k])} – ${fmt(f.upper[k])}', style: const TextStyle(color: CI.gold, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _RangeBar(lo: f.lower[k], hi: f.upper[k], v: target, cur: cur),
              const SizedBox(height: 16),
              Text(context.tr('fc_conf', [Fmt.num(_h <= 3 ? 86 : (_h <= 6 ? 78 : 68), 0)]), style: TextStyle(color: CI.cream.withValues(alpha: .75), fontSize: 12.5)),
              const SizedBox(height: 6),
              Text(context.tr('fc_disclaimer'), style: TextStyle(color: CI.cream.withValues(alpha: .5), fontSize: 11)),
            ]),
          ),
        ),
        right: Reveal(
          delay: 100,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('fc_chart'), trailing: Wrap(children: [LegendDot(p.accent, context.tr('fc_history')), LegendDot(p.gold, context.tr('fc_forecast'))])),
              LineChartW(
                key: ValueKey('$_id$_h'),
                height: context.isMobile ? 280 : 380,
                dates: dates,
                yFmt: fmt,
                forecastFrom: hist.length - 1,
                series: [
                  ChartSeries(context.tr('fc_history'), hist, p.accent),
                  ChartSeries(context.tr('fc_forecast'), fc.sublist(0, shown), p.gold, dashed: true, fill: false, start: hist.length - 1),
                ],
                lower: lo.sublist(0, shown),
                upper: up.sublist(0, shown),
              ),
            ]),
          ),
        ),
      ),
      gap24,
      Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 1), gap: 12, children: [
        for (final id in _units.keys)
          Reveal(
            child: GlassCard(
              onTap: () => setState(() => _id = id),
              selected: id == _id,
              child: Builder(builder: (_) {
                final s = repo.forecast(id);
                final ch = (s.forecast.last.v / s.history.last.v - 1) * 100;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(_icons[id], size: 18, color: p.accent), const SizedBox(width: 8), Expanded(child: Text(context.tr('fc_$id'), style: TS.h3(p)))]),
                  const SizedBox(height: 10),
                  Row(children: [TrendBadge(ch, invert: id == 'climate'), const SizedBox(width: 8), Text(context.tr('fc_in12'), style: TS.bodyS(p).copyWith(fontSize: 11.5))]),
                  const SizedBox(height: 8),
                  SizedBox(height: 34, child: Sparkline([...s.history.map((e) => e.v).skip(12), ...s.forecast.map((e) => e.v)], color: p.gold)),
                ]);
              }),
            ),
          ),
      ]),
    ]);
  }
}

class _RangeBar extends StatelessWidget {
  final double lo, hi, v, cur;
  const _RangeBar({required this.lo, required this.hi, required this.v, required this.cur});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: context.dur(1200),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(painter: _RangePainter(lo, hi, v, cur, t), size: Size.infinite),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  final double lo, hi, v, cur, t;
  _RangePainter(this.lo, this.hi, this.v, this.cur, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final mn = [lo, cur].reduce((a, b) => a < b ? a : b), mx = [hi, cur].reduce((a, b) => a > b ? a : b);
    final pad = (mx - mn) * .15;
    double x(double val) => (val - mn + pad) / (mx - mn + 2 * pad) * s.width;
    final y = s.height / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 3, s.width, 6), const Radius.circular(3)), Paint()..color = Colors.white12);
    final cx = x(v);
    final a = cx + (x(lo) - cx) * t, b = cx + (x(hi) - cx) * t;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a, y - 7, b, y + 7), const Radius.circular(7)), Paint()..color = CI.gold.withValues(alpha: .35));
    canvas.drawCircle(Offset(cx, y), 7, Paint()..color = CI.gold);
    canvas.drawCircle(Offset(x(cur), y), 4, Paint()..color = CI.cream);
  }

  @override
  bool shouldRepaint(_RangePainter o) => o.t != t || o.v != v || o.lo != lo;
}
