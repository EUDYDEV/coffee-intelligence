import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/alerts_data.dart';
import '../../data/repository.dart';
import '../../animations/flows.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../shell/nav.dart';

class DecisionPage extends StatelessWidget {
  const DecisionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final arab = repo.series('arabica');
    final spark = arab.sublist(arab.length - 12).map((e) => e.v).toList();
    final prod = repo.africaProduction();
    final risks = repo.risks();
    final climate = repo.countries(africaOnly: true).fold(0.0, (a, c) => a + c.climateRisk) / 6;
    final fc = repo.forecast('price');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('decision_title', 'decision_sub'),
      const _ArrivalIntro(),
      Reveal(child: const _PulseCard()),
      gap24,
      SectionLabel(context.tr('key_indicators')),
      Grid(columns: context.cols(desktop: 3, tablet: 2, mobile: 1), children: [
        Reveal(delay: 100, child: KpiCard(labelKey: 'kpi_price', metric: 'price_arabica', value: arab.last.v, decimals: 2, unit: '\$/lb', trend: (arab.last.v / arab[arab.length - 2].v - 1) * 100, icon: Icons.show_chart_rounded, spark: spark)),
        Reveal(delay: 160, child: KpiCard(labelKey: 'kpi_prod', metric: 'production', value: prod, unit: 'kt', trend: 3.4, icon: Icons.spa_rounded, spark: repo.africaProdHistory())),
        Reveal(delay: 220, child: KpiCard(labelKey: 'kpi_income', metric: 'income', value: repo.africaIncome(), unit: '\$', trend: -2.1, icon: Icons.payments_rounded, spark: const [1210, 1190, 1240, 1180, 1160, 1150, 1170, 1130])),
        Reveal(delay: 280, child: KpiCard(labelKey: 'kpi_exports', metric: 'exports', value: repo.africaExports(), unit: 'kt', trend: -4.8, icon: Icons.directions_boat_rounded, spark: const [980, 1010, 990, 1040, 1000, 940, 910, 893])),
        Reveal(delay: 340, child: KpiCard(labelKey: 'kpi_climate', metric: 'climate', value: climate, unit: '/100', trend: 6.2, invertTrend: true, icon: Icons.cloud_rounded, spark: const [52, 54, 53, 58, 61, 63, 64, 66])),
        Reveal(delay: 400, child: KpiCard(labelKey: 'kpi_forecast', metric: 'price_arabica', value: fc.forecast.last.v, decimals: 2, unit: '\$/lb', trend: (fc.forecast.last.v / arab.last.v - 1) * 100, icon: Icons.query_stats_rounded, spark: [...spark.sublist(6), ...fc.forecast.map((e) => e.v)])),
      ]),
      gap24,
      TwoCol(
        flexL: 5,
        flexR: 4,
        left: Reveal(delay: 200, child: const _WatchToday()),
        right: Reveal(
          delay: 300,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('risk_radar')),
              Center(
                child: RadarW(
                  size: context.isMobile ? 280 : 320,
                  sweep: true,
                  axes: [for (final k in risks.keys) context.tr('risk_$k')],
                  series: [
                    RadarSeries('now', [for (final v in risks.values) v.last], p.alert),
                    RadarSeries('prev', [for (final v in risks.values) v[v.length - 3]], p.gold),
                  ],
                ),
              ),
              Center(child: Wrap(children: [LegendDot(p.alert, context.tr('radar_now')), LegendDot(p.gold, context.tr('radar_prev'))])),
            ]),
          ),
        ),
      ),
      gap24,
      TwoCol(
        flexL: 3,
        flexR: 2,
        left: Reveal(
          delay: 300,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('price_evolution')),
              LineChartW(
                height: 250,
                dates: arab.map((e) => e.t).toList(),
                series: [ChartSeries('Arabica', arab.map((e) => e.v).toList(), p.accent), ChartSeries('Robusta', repo.series('robusta').map((e) => e.v).toList(), p.green, fill: false)],
                yFmt: (v) => Fmt.usd(v),
              ),
            ]),
          ),
        ),
        right: Reveal(delay: 400, child: const _LatestAlerts()),
      ),
    ]);
  }
}

class _PulseCard extends StatefulWidget {
  const _PulseCard();
  @override
  State<_PulseCard> createState() => _PulseCardState();
}

class _PulseCardState extends State<_PulseCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  bool _init = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      if (!context.calm) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = <(String, String, double, int)>[
      ('pulse_market', 'pulse_market_v', 3.1, 1),
      ('pulse_production', 'pulse_production_v', 3.4, 0),
      ('pulse_climate', 'pulse_climate_v', 6.2, 2),
      ('pulse_income', 'pulse_income_v', -2.1, 1),
      ('pulse_risk', 'pulse_risk_v', 8.0, 2),
      ('pulse_trend', 'pulse_trend_v', 1.8, 0),
    ];
    final orb = SizedBox(
      width: 210,
      height: 210,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _PulsePainter(_c.value, p),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('COFFEE PULSE', style: TextStyle(fontSize: 9.5, letterSpacing: 2, color: CI.cream.withValues(alpha: .8), fontWeight: FontWeight.w700)),
              AnimatedCounter(72, style: const TextStyle(fontFamily: TS.display, fontSize: 56, fontWeight: FontWeight.w800, color: CI.cream, height: 1.1)),
              Text(context.tr('pulse_state'), style: const TextStyle(color: CI.gold, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
    final list = Column(children: [
      for (final it in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: [p.green, p.gold, p.alert][it.$4 == 0 ? 0 : (it.$4 == 1 ? 1 : 2)])),
            const SizedBox(width: 10),
            Expanded(child: Text(context.tr(it.$1), style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 12.5))),
            Text(context.tr(it.$2), style: const TextStyle(color: CI.cream, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
    ]);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.forest, CI.espressoDeep]),
        boxShadow: [BoxShadow(color: CI.forest.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: context.isMobile
          ? Column(children: [orb, const SizedBox(height: 14), list])
          : Row(children: [
              orb,
              const SizedBox(width: 36),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('pulse_title'), style: const TextStyle(fontFamily: TS.display, color: CI.cream, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(context.tr('pulse_sub'), style: TextStyle(color: CI.cream.withValues(alpha: .65), fontSize: 13.5)),
                const SizedBox(height: 14),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: list),
              ])),
            ]),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double t;
  final Pal p;
  _PulsePainter(this.t, this.p);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final base = s.width / 2 - 24;
    for (var i = 0; i < 3; i++) {
      final f = (t + i / 3) % 1;
      canvas.drawCircle(c, base * (.8 + .4 * f), Paint()..color = CI.gold.withValues(alpha: .35 * (1 - f))..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    final beat = math.pow(math.sin(t * math.pi * 2).abs(), 6).toDouble();
    canvas.drawCircle(c, base * (.92 + .05 * beat), Paint()..shader = RadialGradient(colors: [CI.leaf.withValues(alpha: .9), CI.forest]).createShader(Rect.fromCircle(center: c, radius: base)));
    canvas.drawCircle(c, base * (.92 + .05 * beat), Paint()..color = CI.gold..style = PaintingStyle.stroke..strokeWidth = 2.2);
    // ECG-like line behind text
    final path = Path();
    for (var x = 0.0; x <= s.width; x += 3) {
      final u = (x / s.width + t) % 1;
      final spike = u > .46 && u < .5 ? -((u - .46) / .04) : (u >= .5 && u < .54 ? ((u - .5) / .04) * 1.2 - 1 : 0.0);
      final y = c.dy + base * .62 + spike * 16;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: base * .9)));
    canvas.drawPath(path, Paint()..color = CI.gold.withValues(alpha: .55)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PulsePainter o) => true;
}

class _WatchToday extends StatelessWidget {
  const _WatchToday();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const icons = {'price': Icons.warning_amber_rounded, 'weather': Icons.thunderstorm_rounded, 'exports': Icons.inventory_2_rounded, 'production': Icons.trending_up_rounded};
    const targets = {'price': 'market', 'weather': 'forecast', 'exports': 'anomalies', 'production': 'production'};
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('watch_today')),
        for (var i = 0; i < watchToday.length; i++)
          Reveal(
            delay: 250 + i * 120,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => context.app.goto(navIndex(targets[watchToday[i][0]]!)),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: p.sev(watchToday[i][2] as int).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: p.sev(watchToday[i][2] as int), width: 4))),
                    child: Row(children: [
                      Icon(icons[watchToday[i][0]], color: p.sev(watchToday[i][2] as int)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.tr('${watchToday[i][1]}_t'), style: TS.h3(p)),
                          const SizedBox(height: 2),
                          Text(context.tr('${watchToday[i][1]}_d'), style: TS.bodyS(p)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.muted),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _LatestAlerts extends StatelessWidget {
  const _LatestAlerts();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final al = repo.alerts().take(4).toList();
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('latest_alerts'), trailing: GestureDetector(onTap: () => context.app.goto(navIndex('alerts')), child: Text(context.tr('see_all'), style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 12)))),
        for (final a in al)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 5), width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: p.sev(a.severity))),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr(a.titleKey), style: TS.h3(p).copyWith(fontSize: 13.5))),
              Text(context.tr('ago', [a.ago]), style: TS.bodyS(p).copyWith(fontSize: 11)),
            ]),
          ),
      ]),
    );
  }
}

bool _introSeen = false;

/// Data from every source converges, then collapses into the decision center (played once per session).
class _ArrivalIntro extends StatefulWidget {
  const _ArrivalIntro();
  @override
  State<_ArrivalIntro> createState() => _ArrivalIntroState();
}

class _ArrivalIntroState extends State<_ArrivalIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
  late bool _show = !_introSeen;
  @override
  void initState() {
    super.initState();
    _introSeen = true;
    if (_show) {
      _c.forward().then((_) {
        if (mounted) setState(() => _show = false);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedSize(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      child: !_show || context.calm
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GlassCard(
                accent: p.gold,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => Column(children: [
                    DataConvergence(progress: (_c.value / .8).clamp(0.0, 1.0), height: 330),
                    Opacity(
                      opacity: ((_c.value - .85) / .15).clamp(0.0, 1.0),
                      child: Text(context.tr('nav_decision').toUpperCase(), style: TextStyle(fontFamily: TS.display, fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.w800, color: p.gold)),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}
