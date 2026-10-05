import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../../widgets/map/map_view.dart';

class _Scenario {
  final String id;
  final double priceMul, cost, vol;
  const _Scenario(this.id, this.priceMul, this.cost, this.vol);
}

const _scenarios = [
  _Scenario('sc_base', 1, 0, 0),
  _Scenario('sc_up15', 1.15, 0, 0),
  _Scenario('sc_crash', 0.64, 0, 0),
  _Scenario('sc_inputs', 1, 20, 0),
  _Scenario('sc_climate', 1.12, 5, -18),
];

class _Result {
  final double income, margin, cost, farmgate, volume, producerDelta, coopDelta, exporterDelta, roasterDelta;
  final Map<String, double> marginBy, incomeDeltaBy, volumeBy;
  const _Result(this.income, this.margin, this.cost, this.farmgate, this.volume, this.producerDelta, this.coopDelta, this.exporterDelta, this.roasterDelta, this.marginBy, this.incomeDeltaBy, this.volumeBy);
}

_Result _simulate(double price, double costShock, double volShock) {
  final p0 = repo.series('arabica').last.v;
  final r = price / p0;
  final af = repo.countries(africaOnly: true);
  final marginBy = <String, double>{}, incomeBy = <String, double>{}, volBy = <String, double>{};
  var inc = 0.0, w = 0.0, vol = 0.0, vol0 = 0.0, mar = 0.0, cst = 0.0, fg = 0.0, inc0 = 0.0;
  for (final c in af) {
    final pass = c.arabicaShare >= .5 ? .92 : .8;
    final farmgate = c.farmgateKg * (1 + (r - 1) * pass);
    final cost = c.costKg * (1 + costShock / 100 + .2 * (r - 1));
    final margin = farmgate - cost;
    final income = c.incomeYr * (margin / c.margin);
    final v = c.exportsKt * (1 + .18 * (r - 1) - .25 * (costShock / 100).clamp(0.0, 1.0) + volShock / 100);
    marginBy[c.id] = margin;
    incomeBy[c.id] = (income / c.incomeYr - 1) * 100;
    volBy[c.id] = (v / c.exportsKt - 1) * 100;
    inc += income * c.producersK;
    inc0 += c.incomeYr * c.producersK;
    w += c.producersK;
    vol += v;
    vol0 += c.exportsKt;
    mar += margin * c.prodKt;
    cst += cost * c.prodKt;
    fg += farmgate * c.prodKt;
  }
  final tp = af.fold(0.0, (a, c) => a + c.prodKt);
  final volFactor = vol / vol0;
  return _Result(inc / w, mar / tp, cst / tp, fg / tp, vol, (inc / inc0 - 1) * 100, ((r * volFactor) - 1) * 100, (r - 1) * 40 - costShock * .15 + volShock * .3, (r - 1) * 55, marginBy, incomeBy, volBy);
}

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});
  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
  late double _price = repo.series('arabica').last.v;
  double _cost = 0, _vol = 0;
  String _sc = 'sc_base';

  void _apply(_Scenario s) {
    final p0 = repo.series('arabica').last.v;
    setState(() {
      _sc = s.id;
      _price = (p0 * s.priceMul).clamp(2.0, 4.0);
      _cost = s.cost;
      _vol = s.vol;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final p0 = repo.series('arabica').last.v;
    final base = _simulate(p0, 0, 0);
    final res = _simulate(_price, _cost, _vol);
    final af = repo.countries(africaOnly: true);
    final change = (_price / p0 - 1) * 100;
    final impact = {for (final c in af) c.id: (res.incomeDeltaBy[c.id]! / 30).clamp(-1.0, 1.0)};
    final distressed = af.where((c) => res.marginBy[c.id]! < .25).length;

    final slider = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr('if_title', [(change >= 0 ? '+' : '') + Fmt.num(change, 0)]), style: TS.h2(p))),
          const DemoTag(),
        ]),
        const SizedBox(height: 14),
        Text(context.tr('sim_price').toUpperCase(), style: TS.label(p)),
        Row(children: [
          Expanded(
            child: Slider(value: _price.clamp(2.0, 4.0), min: 2, max: 4, onChanged: (v) => setState(() {
              _price = v;
              _sc = '';
            })),
          ),
          SizedBox(width: 82, child: LiveNumber(_price, (v) => Fmt.usd(v), TS.big(p, size: 22))),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (final t in [2.0, 2.5, 3.0, 3.5, 4.0]) Text(Fmt.usd(t), style: TS.bodyS(p).copyWith(fontSize: 11))]),
        ),
        const SizedBox(height: 10),
        Text(context.tr('sim_cost').toUpperCase(), style: TS.label(p)),
        Row(children: [
          Expanded(child: Slider(value: _cost, min: -10, max: 30, onChanged: (v) => setState(() {
            _cost = v;
            _sc = '';
          }))),
          SizedBox(width: 82, child: Text(Fmt.pct(_cost, 0, true), textAlign: TextAlign.right, style: TS.h3(p))),
        ]),
        Text(context.tr('sim_vol').toUpperCase(), style: TS.label(p)),
        Row(children: [
          Expanded(child: Slider(value: _vol, min: -30, max: 10, onChanged: (v) => setState(() {
            _vol = v;
            _sc = '';
          }))),
          SizedBox(width: 82, child: Text(Fmt.pct(_vol, 0, true), textAlign: TextAlign.right, style: TS.h3(p))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in _scenarios)
            ChoiceChip(label: Text(context.tr(s.id, s.id == 'sc_crash' ? [Fmt.usd(2)] : const [])), selected: _sc == s.id, showCheckmark: false, selectedColor: p.accent, labelStyle: TextStyle(color: _sc == s.id ? Colors.white : p.text, fontWeight: FontWeight.w600, fontSize: 12.5), onSelected: (_) => _apply(s)),
        ]),
      ]),
    );

    Widget out(String k, double v, double b, String unit, int dec, {bool inv = false}) {
      final d = b == 0 ? 0.0 : (v / b - 1) * 100;
      final money = unit.startsWith(r'$');
      final sv = money ? Fmt.conv(v) : v;
      final sdec = money ? Fmt.decFor(dec) : dec;
      return GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(k).toUpperCase(), style: TS.label(p)),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: LiveNumber(sv, (x) => '${Fmt.num(x, sdec)} ${Fmt.unit(unit)}', TS.big(p, size: 26))),
          const SizedBox(height: 8),
          TrendBadge(d, invert: inv),
        ]),
      );
    }

    final outputs = Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 2), gap: 12, children: [
      out('kpi_income', res.income, base.income, '\$', 0),
      out('margin', res.margin, base.margin, '\$/kg', 2),
      out('prod_cost', res.cost, base.cost, '\$/kg', 2, inv: true),
      out('kpi_exports', res.volume, base.volume, 'kt', 0),
    ]);

    final actors = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('impact_actors')),
        _ActorRow(Icons.agriculture_rounded, context.tr('chain_producer'), res.producerDelta),
        _ActorRow(Icons.groups_rounded, context.tr('chain_coop'), res.coopDelta),
        _ActorRow(Icons.inventory_2_rounded, context.tr('chain_export'), res.exporterDelta),
        _ActorRow(Icons.local_cafe_rounded, context.tr('chain_roaster'), res.roasterDelta, invert: true),
      ]),
    );

    final zones = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('impact_zones'), trailing: Chip2(context.tr('n_pressure', [distressed]), distressed == 0 ? p.green : p.alert)),
        for (final c in af)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(width: 108, child: Text('${c.flag} ${context.tr(c.nameKey)}', overflow: TextOverflow.ellipsis, style: TextStyle(color: p.text, fontSize: 12.5, fontWeight: FontWeight.w600))),
              Expanded(child: _MarginBar(res.marginBy[c.id]!, base.marginBy[c.id]!, p)),
              SizedBox(width: 74, child: Text('${Fmt.money(res.marginBy[c.id]!, 2)} ${Fmt.unit(r'$/kg')}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: res.marginBy[c.id]! < .25 ? p.alert : p.text))),
            ]),
          ),
        const SizedBox(height: 6),
        Text(context.tr('margin_bar_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('simulator_title', 'simulator_sub'),
      slider,
      gap16,
      outputs,
      gap24,
      TwoCol(
        flexL: 5,
        flexR: 4,
        left: Column(children: [zones, gap16, actors]),
        right: MapView(height: context.isMobile ? 380 : 560, layers: const {'production'}, impact: impact, build: false, selected: null, interactive: true),
      ),
    ]);
  }
}

class LiveNumber extends StatelessWidget {
  final double value;
  final String Function(double) fmt;
  final TextStyle style;
  const LiveNumber(this.value, this.fmt, this.style, {super.key});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: context.dur(450),
        curve: Curves.easeOut,
        builder: (_, v, __) => Text(fmt(v), style: style),
      );
}

class _ActorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double delta;
  final bool invert;
  const _ActorRow(this.icon, this.label, this.delta, {this.invert = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final good = invert ? delta <= 0 : delta >= 0;
    final col = good ? p.green : p.alert;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: p.muted, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 96, child: Text(label, style: TS.h3(p).copyWith(fontSize: 13))),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: (delta / 40).clamp(-1.0, 1.0)),
            duration: context.dur(500),
            curve: Curves.easeOut,
            builder: (_, v, __) => SizedBox(height: 12, child: CustomPaint(painter: _CenterBar(v, col, p.border))),
          ),
        ),
        SizedBox(width: 60, child: LiveNumber(delta, (x) => Fmt.pct(x, 0, true), TextStyle(fontWeight: FontWeight.w800, color: col, fontSize: 13))),
      ]),
    );
  }
}

class _CenterBar extends CustomPainter {
  final double v;
  final Color c, track;
  _CenterBar(this.v, this.c, this.track);
  @override
  void paint(Canvas canvas, Size s) {
    final mid = s.width / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, s.width, s.height - 4), const Radius.circular(6)), Paint()..color = track.withValues(alpha: .5));
    final w = v.abs() * mid;
    final r = v >= 0 ? Rect.fromLTWH(mid, 2, w, s.height - 4) : Rect.fromLTWH(mid - w, 2, w, s.height - 4);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = c);
    canvas.drawLine(Offset(mid, 0), Offset(mid, s.height), Paint()..color = track..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_CenterBar o) => o.v != v || o.c != c;
}

class _MarginBar extends StatelessWidget {
  final double margin, base;
  final Pal p;
  const _MarginBar(this.margin, this.base, this.p);
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: margin),
      duration: context.dur(450),
      curve: Curves.easeOut,
      builder: (_, v, __) => SizedBox(height: 14, child: CustomPaint(painter: _MPainter(v, base, p))),
    );
  }
}

class _MPainter extends CustomPainter {
  final double v, base;
  final Pal p;
  _MPainter(this.v, this.base, this.p);
  @override
  void paint(Canvas canvas, Size s) {
    const mx = 2.2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, s.width, s.height - 4), const Radius.circular(6)), Paint()..color = p.border.withValues(alpha: .5));
    final w = (v.clamp(0, mx) / mx) * s.width;
    final col = v < .25 ? p.alert : (v < .6 ? p.warn : p.green);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, w, s.height - 4), const Radius.circular(6)), Paint()..color = col);
    final bx = (base / mx) * s.width;
    canvas.drawLine(Offset(bx, 0), Offset(bx, s.height), Paint()..color = p.text.withValues(alpha: .6)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_MPainter o) => true;
}
