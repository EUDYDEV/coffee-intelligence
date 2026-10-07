import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/cert_weather_data.dart';
import '../../data/demo/countries_data.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

/// "Climate & Production": weather history, forecast and its estimated impact on output.
class ClimateView extends StatefulWidget {
  const ClimateView({super.key});
  @override
  State<ClimateView> createState() => _ClimateViewState();
}

class _ClimateViewState extends State<ClimateView> {
  String _country = '';
  int _months = 24;
  bool _imperial = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final af = repo.countries(africaOnly: true);
    if (_country.isEmpty) _country = af.any((c) => c.id == app.myCountry) ? app.myCountry : 'ETH';
    final all = weatherFor(_country);
    final hist = all.where((w) => !w.forecast).toList();
    final fc = all.where((w) => w.forecast).toList();
    final shown = hist.sublist(hist.length - _months.clamp(6, hist.length));
    final impact = climateImpact(_country);
    final last = hist.last;
    final prevYear = hist[hist.length - 13];

    double rainU(double mm) => _imperial ? mm / 25.4 : mm;
    double tempU(double c) => _imperial ? c * 9 / 5 + 32 : c;
    final rainUnit = _imperial ? 'in' : 'mm', tempUnit = _imperial ? '°F' : '°C';
    String r1(double v) => Fmt.num(v, _imperial ? 2 : 0);

    final dates = [...shown.map((e) => e.t), ...fc.map((e) => e.t)];
    final nObs = shown.length;

    final selector = Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final c in af)
        ChoiceChip(label: Text('${c.flag} ${context.tr(c.nameKey)}'), selected: c.id == _country, showCheckmark: false, selectedColor: p.accent.withValues(alpha: .28), onSelected: (_) => setState(() => _country = c.id)),
      Segmented<int>(values: const [12, 24], selected: _months, label: (v) => '$v ${context.tr('m')}', onChanged: (v) => setState(() => _months = v)),
      Segmented<bool>(values: const [false, true], selected: _imperial, label: (v) => v ? 'in / °F' : 'mm / °C', onChanged: (v) => setState(() => _imperial = v)),
    ]);

    final kpis = Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 2), gap: 12, children: [
      _Kpi(context.tr('wx_temp'), '${Fmt.num(tempU(last.temp), 1)} $tempUnit', last.temp - prevYear.temp, Icons.thermostat_rounded, p.warn, '+/-', true),
      _Kpi(context.tr('wx_rain'), '${r1(rainU(last.rain))} $rainUnit', (last.rain / last.normalRain - 1) * 100, Icons.water_drop_rounded, const Color(0xFF4F7F93), '%', false),
      _Kpi(context.tr('wx_humidity'), '${Fmt.num(last.humidity, 0)} %', last.humidity - prevYear.humidity, Icons.cloud_rounded, p.green, '+/-', false),
      _Kpi(context.tr('wx_drought'), '${Fmt.num(last.drought, 0)}/100', last.drought - prevYear.drought, Icons.wb_sunny_rounded, p.alert, '+/-', true),
    ]);

    final chain = GlassCard(
      accent: impact.productionDelta < -3 ? p.alert : p.green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('wx_impact_title')),
        Text(context.tr('wx_impact_sub', [context.tr('c_$_country')]), style: TS.bodyS(p)),
        const SizedBox(height: 14),
        _ImpactChain(
          key: ValueKey(_country),
          steps: [
            (Icons.water_drop_rounded, '${context.tr('wx_rain')} ${impact.rainDelta < 0 ? '↓' : '↑'} ${Fmt.num(impact.rainDelta.abs(), 0)} %', impact.rainDelta < 0),
            (Icons.local_fire_department_rounded, '${context.tr('wx_water_risk')} ${impact.droughtDelta > 0 ? '↑' : '↓'}', impact.droughtDelta > 0),
            (Icons.spa_rounded, '${context.tr('wx_prod_est')} ${impact.productionDelta < 0 ? '↓' : '↑'} ${Fmt.num(impact.productionDelta.abs(), 0)} %', impact.productionDelta < 0),
          ],
        ),
        const SizedBox(height: 12),
        Text(context.tr('wx_impact_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
      ]),
    );

    // rainfall chart: observed (history), normal (whole span), forecast (dashed, starts at last observed)
    final rainObs = [for (final w in shown) rainU(w.rain)];
    final rainNormal = [for (final w in [...shown, ...fc]) rainU(w.normalRain)];
    final rainFc = [rainU(shown.last.rain), for (final w in fc) rainU(w.rain)];
    final tempObs = [for (final w in shown) tempU(w.temp)];
    final tempFc = [tempU(shown.last.temp), for (final w in fc) tempU(w.temp)];

    final anomalies = hist.where((w) => w.rain < w.normalRain * .75).toList().reversed.take(4).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      selector,
      gap16,
      kpis,
      gap24,
      TwoCol(
        flexL: 5,
        flexR: 5,
        left: chain,
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('wx_forecast_6')),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final w in fc)
                Container(
                  width: 98,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${w.t.month}/${w.t.year % 100}', style: TS.label(p)),
                    const SizedBox(height: 6),
                    Icon(w.rain < w.normalRain * .85 ? Icons.wb_cloudy_rounded : Icons.water_drop_rounded, color: w.rain < w.normalRain * .85 ? p.warn : const Color(0xFF4F7F93), size: 20),
                    const SizedBox(height: 4),
                    Text('${r1(rainU(w.rain))} $rainUnit', style: TS.h3(p).copyWith(fontSize: 13)),
                    Text('${Fmt.num(tempU(w.temp), 0)}$tempUnit', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),
            SectionLabel(context.tr('wx_anomalies')),
            if (anomalies.isEmpty) Text(context.tr('wx_none'), style: TS.bodyS(p)),
            for (final w in anomalies)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: p.warn),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${w.t.month}/${w.t.year} · ${context.tr('wx_rain_deficit', [Fmt.num((1 - w.rain / w.normalRain) * 100, 0)])}', style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13))),
                ]),
              ),
          ]),
        ),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('wx_rain_chart')),
          LineChartW(
            height: 280,
            sourceId: 'weather',
            unit: rainUnit,
            dates: dates,
            forecastFrom: nObs - 1,
            yFmt: (v) => Fmt.num(v, _imperial ? 1 : 0),
            series: [
              ChartSeries(context.tr('wx_observed'), rainObs, const Color(0xFF4F7F93)),
              ChartSeries(context.tr('wx_normal'), rainNormal, p.muted, dashed: true, fill: false),
              ChartSeries(context.tr('wx_forecast'), rainFc, p.gold, dashed: true, fill: false, start: nObs - 1),
            ],
          ),
        ]),
      ),
      gap24,
      TwoCol(
        left: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('wx_temp_chart')),
            LineChartW(
              height: 240,
              sourceId: 'weather',
              unit: tempUnit,
              dates: dates,
              forecastFrom: nObs - 1,
              yFmt: (v) => Fmt.num(v, 0),
              series: [ChartSeries(context.tr('wx_observed'), tempObs, p.warn), ChartSeries(context.tr('wx_forecast'), tempFc, p.gold, dashed: true, fill: false, start: nObs - 1)],
            ),
          ]),
        ),
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('wx_humidity_chart')),
            LineChartW(
              height: 240,
              sourceId: 'weather',
              unit: '% · /100',
              dates: shown.map((e) => e.t).toList(),
              yFmt: (v) => Fmt.num(v, 0),
              series: [ChartSeries(context.tr('wx_humidity'), [for (final w in shown) w.humidity], p.green, fill: false), ChartSeries(context.tr('wx_drought'), [for (final w in shown) w.drought], p.alert, fill: false)],
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Kpi extends StatelessWidget {
  final String label, value, unitDelta;
  final double delta;
  final IconData icon;
  final Color color;
  final bool upIsBad;
  const _Kpi(this.label, this.value, this.delta, this.icon, this.color, this.unitDelta, this.upIsBad);
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isPct = unitDelta == '%';
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 10), Expanded(child: Text(label.toUpperCase(), style: TS.label(p)))]),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TS.big(p, size: 26))),
        const SizedBox(height: 8),
        Row(children: [
          if (isPct) TrendBadge(delta, invert: false) else TrendBadge(delta, invert: upIsBad),
          const SizedBox(width: 8),
          Flexible(child: Text(context.tr(isPct ? 'wx_vs_normal' : 'wx_vs_last_year'), style: TS.bodyS(p).copyWith(fontSize: 11))),
        ]),
      ]),
    );
  }
}

/// Animated cause → effect chain (rain → water risk → production).
class _ImpactChain extends StatefulWidget {
  final List<(IconData, String, bool)> steps; // icon, text, isBad
  const _ImpactChain({super.key, required this.steps});
  @override
  State<_ImpactChain> createState() => _ImpactChainState();
}

class _ImpactChainState extends State<_ImpactChain> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _init = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _c.duration = context.dur(2400);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Column(children: [
        for (var i = 0; i < widget.steps.length; i++) ...[
          Builder(builder: (_) {
            final k = ((_c.value * widget.steps.length - i)).clamp(0.0, 1.0);
            final s = widget.steps[i];
            final col = s.$3 ? p.alert : p.green;
            return Opacity(
              opacity: k,
              child: Transform.translate(
                offset: Offset(0, (1 - k) * 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: col.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border.all(color: col.withValues(alpha: .5))),
                  child: Row(children: [Icon(s.$1, color: col), const SizedBox(width: 12), Expanded(child: Text(s.$2, style: TS.h3(p).copyWith(fontSize: 15)))]),
                ),
              ),
            );
          }),
          if (i < widget.steps.length - 1)
            Opacity(opacity: ((_c.value * widget.steps.length - i - .5)).clamp(0.0, 1.0), child: Icon(Icons.south_rounded, color: p.muted, size: 22)),
        ],
      ]),
    );
  }
}
