import 'dart:async';
import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/format.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/palette.dart';
import '../data/repository.dart';
import '../models/models.dart';

/// Premium card: layered surface, hairline border, soft glow on hover.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? accent;
  final bool selected;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent,
    this.selected = false,
  });
  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final a = widget.accent ?? p.accent;
    final lit = _hover || widget.selected;
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: context.dur(220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, lit && widget.onTap != null ? -2 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.surface, Color.lerp(p.surface, p.bg2, p.dark ? .35 : .5)!],
            ),
            border: Border.all(color: lit ? a.withValues(alpha: .7) : p.border),
            boxShadow: [
              BoxShadow(
                  color: (lit ? a : Colors.black).withValues(alpha: lit ? .18 : (p.dark ? .25 : .06)),
                  blurRadius: lit ? 26 : 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fade + rise entrance, staggered by [delay] ms.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delay;
  const Reveal({super.key, required this.child, this.delay = 0});
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _t;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.duration = context.dur(650);
    if (context.calm) {
      _c.value = 1;
    } else {
      _t = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 26), child: child),
        );
      },
      child: widget.child,
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final double value;
  final int decimals;
  final String prefix, suffix;
  final TextStyle style;
  final String Function(double)? formatter;
  const AnimatedCounter(this.value,
      {super.key, this.decimals = 0, this.prefix = '', this.suffix = '', required this.style, this.formatter});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: context.dur(1800),
      curve: Curves.easeOutExpo,
      builder: (_, v, __) =>
          Text('$prefix${formatter != null ? formatter!(v) : Fmt.num(v, decimals)}$suffix', style: style),
    );
  }
}

class TrendBadge extends StatelessWidget {
  final double pct;
  final bool invert; // when true, up is bad
  const TrendBadge(this.pct, {super.key, this.invert = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final up = pct >= 0;
    final good = invert ? !up : up;
    final c = good ? p.green : p.alert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded, size: 12, color: c),
        const SizedBox(width: 3),
        Text(Fmt.pct(pct.abs(), 1), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

class Chip2 extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Chip2(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: .35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
        ]),
      );
}

class SevChip extends StatelessWidget {
  final int sev;
  const SevChip(this.sev, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final key = ['sev_critical', 'sev_important', 'sev_watch'][sev];
    return Chip2(context.tr(key), p.sev(sev), icon: Icons.circle);
  }
}

class DemoTag extends StatelessWidget {
  const DemoTag({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(color: p.gold.withValues(alpha: .7)),
          borderRadius: BorderRadius.circular(6),
          color: p.gold.withValues(alpha: .1)),
      child: Text(context.tr('demo_data'),
          style: TextStyle(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: p.gold)),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String titleKey, subKey;
  final Widget? trailing;
  const PageHeader(this.titleKey, this.subKey, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(
            child: Text(context.tr(titleKey),
                style: TS.h1(p).copyWith(fontSize: context.isMobile ? 26 : 34))),
        const SizedBox(width: 12),
        const DemoTag(),
      ]),
      const SizedBox(height: 6),
      Text(context.tr(subKey), style: TS.bodyS(p).copyWith(fontSize: 14)),
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: context.isMobile || trailing == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              title,
              if (trailing != null) ...[const SizedBox(height: 12), trailing!]
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: title),
              trailing!,
            ]),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 18, height: 2, color: p.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(text.toUpperCase(), style: TS.label(p))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Segmented selector with a sliding highlight.
class Segmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const Segmented(
      {super.key, required this.values, required this.selected, required this.label, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: p.surface2, borderRadius: BorderRadius.circular(30), border: Border.all(color: p.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final v in values)
          GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: context.dur(250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: v == selected ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(30)),
              child: Text(label(v),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: v == selected ? Colors.white : p.muted)),
            ),
          ),
      ]),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  const PrimaryButton(this.text, {super.key, this.icon, this.onTap, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            gradient: outlined
                ? null
                : LinearGradient(colors: [p.accent, Color.lerp(p.accent, CI.espresso, .35)!]),
            borderRadius: BorderRadius.circular(30),
            border: outlined ? Border.all(color: p.gold) : null,
            boxShadow: outlined
                ? null
                : [BoxShadow(color: p.accent.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 17, color: outlined ? p.gold : Colors.white), const SizedBox(width: 8)],
            Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: outlined ? p.gold : Colors.white)),
          ]),
        ),
      ),
    );
  }
}

/// Responsive grid of equally sized children (no fixed aspect ratio).
class Grid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;
  const Grid({super.key, required this.columns, required this.children, this.gap = 16});
  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]]
      ]);
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: gap),
              Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
            ]
          ]),
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// KPI tile. Tapping opens "Where does this number come from?".
class KpiCard extends StatelessWidget {
  final String labelKey, metric, unit;
  final double value;
  final int decimals;
  final double? trend;
  final bool invertTrend;
  final IconData icon;
  final List<double>? spark;
  final String Function(double)? formatter;
  const KpiCard({
    super.key,
    required this.labelKey,
    required this.metric,
    required this.value,
    required this.icon,
    this.unit = '',
    this.decimals = 0,
    this.trend,
    this.invertTrend = false,
    this.spark,
    this.formatter,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final money = unit.startsWith(r'$');
    final shownValue = money ? Fmt.conv(value) : value;
    final shownUnit = Fmt.unit(unit);
    final shownDec = money ? Fmt.decFor(decimals) : decimals;
    return GlassCard(
      onTap: () => showTrust(context, metric, value, context.tr(labelKey), unit),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: p.accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: p.accent)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(labelKey).toUpperCase(), style: TS.label(p), maxLines: 2)),
          Icon(Icons.info_outline_rounded, size: 14, color: p.muted.withValues(alpha: .6)),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCounter(shownValue,
                  decimals: shownDec, formatter: formatter, suffix: shownUnit.isEmpty ? '' : ' $shownUnit', style: TS.big(p, size: 29)),
            ),
          ),
          const SizedBox(width: 8),
          if (trend != null) TrendBadge(trend!, invert: invertTrend),
        ]),
        if (spark != null) ...[
          const SizedBox(height: 12),
          SizedBox(height: 32, child: Sparkline(spark!, color: p.accent)),
        ],
      ]),
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const Sparkline(this.values, {super.key, required this.color});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: context.dur(1400),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(painter: _SparkPainter(values, color, t), size: Size.infinite),
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  final double t;
  _SparkPainter(this.v, this.color, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    if (v.length < 2) return;
    final mn = v.reduce((a, b) => a < b ? a : b), mx = v.reduce((a, b) => a > b ? a : b);
    final r = (mx - mn) == 0 ? 1 : mx - mn;
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = s.width * i / (v.length - 1);
      final y = s.height - (v[i] - mn) / r * (s.height - 4) - 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final m = path.computeMetrics().first;
    final part = m.extractPath(0, m.length * t);
    final fill = Path.from(part)
      ..lineTo(s.width * t, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            color.withValues(alpha: .28),
            color.withValues(alpha: 0)
          ]).createShader(Offset.zero & s));
    canvas.drawPath(
        part,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t || o.v != v;
}

/// "Where does this number come from?" — lineage dialog.
void showTrust(BuildContext context, String metric, double value, String label, String unit) {
  final prov = repo.provenance(metric, value);
  final p = context.pal;
  final dialog = _TrustBody(prov: prov, label: label, unit: unit);
  if (context.isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => AppScope2(parent: context, child: SafeArea(child: dialog)),
    );
  } else {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: p.border)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: AppScope2(parent: context, child: dialog)),
      ),
    );
  }
}

/// Re-exposes the app scope inside dialogs/sheets (they live in a different route subtree).
class AppScope2 extends StatelessWidget {
  final BuildContext parent;
  final Widget child;
  const AppScope2({super.key, required this.parent, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _TrustBody extends StatelessWidget {
  final Provenance prov;
  final String label, unit;
  const _TrustBody({required this.prov, required this.label, required this.unit});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final conf = {'conf_high': p.green, 'conf_med': p.gold, 'conf_low': p.alert}[prov.confidenceKey]!;
    String v(double x) => prov.unit.startsWith(r'$') ? '${Fmt.num(Fmt.conv(x), Fmt.decFor(x.abs() < 20 ? 2 : 0))} ${Fmt.unit(prov.unit)}' : '${Fmt.num(x, x.abs() < 20 ? 2 : 0)} ${prov.unit}';
    Widget row(String k, String val, {Color? c}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(context.tr(k), style: TS.bodyS(p))),
            Text(val, style: TS.h3(p).copyWith(color: c)),
          ]),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.travel_explore_rounded, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('trust_title'), style: TS.h2(p))),
          const DemoTag(),
        ]),
        const SizedBox(height: 4),
        Text(label, style: TS.bodyS(p).copyWith(fontSize: 14)),
        const SizedBox(height: 14),
        row('trust_source', context.tr(prov.sourceKey)),
        row('trust_updated', context.tr('ago', [prov.updatedAgo])),
        row('trust_quality', Fmt.pct(prov.quality, 0)),
        row('trust_confidence', context.tr(prov.confidenceKey), c: conf),
        const Divider(height: 28),
        Text(context.tr('trust_lineage').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 10),
        _Step(Icons.download_rounded, context.tr('trust_received', [prov.received]), v(prov.rawValue), p.muted),
        for (final s in prov.processing) _Step(Icons.tune_rounded, context.tr(s), null, p.accent),
        _Step(Icons.check_circle_rounded, context.tr('trust_final'), v(prov.finalValue), p.green, last: true),
        const SizedBox(height: 14),
        Text(context.tr('trust_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? value;
  final Color color;
  final bool last;
  const _Step(this.icon, this.text, this.value, this.color, {this.last = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 26,
          child: Column(children: [
            Icon(icon, size: 18, color: color),
            if (!last) Expanded(child: Container(width: 1.5, color: p.border)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: p.text))),
            if (value != null) Text(value!, style: TS.h3(p)),
          ]),
        )),
      ]),
    );
  }
}
