import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/format.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/palette.dart';

class ChartSeries {
  final String name;
  final List<double> values;
  final Color color;
  final bool dashed, fill;
  final int start; // index of the first value on the x axis
  const ChartSeries(this.name, this.values, this.color, {this.dashed = false, this.fill = true, this.start = 0});
}

/// Animated line chart: the line draws itself, supports a forecast band,
/// highlighted point, zoom window (for anomalies) and a hover crosshair.
class LineChartW extends StatefulWidget {
  final List<ChartSeries> series;
  final List<DateTime> dates;
  final double height;
  final int? highlight;
  final (int, int)? window; // visible index range
  final List<double>? lower, upper; // band, aligned to the *end* of dates
  final int? forecastFrom; // index where forecast starts (draws a divider)
  final String Function(double) yFmt;
  final Color? highlightColor;
  const LineChartW({
    super.key,
    required this.series,
    required this.dates,
    this.height = 260,
    this.highlight,
    this.window,
    this.lower,
    this.upper,
    this.forecastFrom,
    this.yFmt = _def,
    this.highlightColor,
  });
  static String _def(double v) => Fmt.num(v, v.abs() < 10 ? 2 : 0);
  @override
  State<LineChartW> createState() => _LineChartWState();
}

class _LineChartWState extends State<LineChartW> with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this);
  late final AnimationController _zoom = AnimationController(vsync: this);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  (double, double) _from = (0, 1), _to = (0, 1);
  int? _hover;
  bool _init = false;

  (double, double) _target() {
    final n = widget.dates.length;
    final w = widget.window;
    return w == null ? (0, (n - 1).toDouble()) : (w.$1.toDouble(), w.$2.toDouble());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _from = _to = _target();
    _draw.duration = context.dur(1800);
    _zoom.duration = context.dur(900);
    _draw.forward();
    if (!context.calm) _pulse.repeat();
  }

  @override
  void didUpdateWidget(LineChartW old) {
    super.didUpdateWidget(old);
    if (old.window != widget.window || old.dates.length != widget.dates.length) {
      final cur = _cur();
      _from = cur;
      _to = _target();
      _zoom.forward(from: 0);
    }
    if (old.series.length != widget.series.length || old.series.first.values != widget.series.first.values) {
      _draw.forward(from: 0);
    }
  }

  (double, double) _cur() {
    final t = Curves.easeInOutCubic.transform(_zoom.value);
    return (_from.$1 + (_to.$1 - _from.$1) * t, _from.$2 + (_to.$2 - _from.$2) * t);
  }

  @override
  void dispose() {
    _draw.dispose();
    _zoom.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _hoverAt(double dx, double w) {
    final win = _cur();
    const left = 46.0, right = 12.0;
    final f = ((dx - left) / (w - left - right)).clamp(0.0, 1.0);
    final i = (win.$1 + f * (win.$2 - win.$1)).round().clamp(0, widget.dates.length - 1);
    if (i != _hover) setState(() => _hover = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (_, c) {
        return MouseRegion(
          onHover: (e) => _hoverAt(e.localPosition.dx, c.maxWidth),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            onTapDown: (d) => _hoverAt(d.localPosition.dx, c.maxWidth),
            onHorizontalDragUpdate: (d) => _hoverAt(d.localPosition.dx, c.maxWidth),
            child: AnimatedBuilder(
              animation: Listenable.merge([_draw, _zoom, _pulse]),
              builder: (_, __) => CustomPaint(
                size: Size(c.maxWidth, widget.height),
                painter: _LinePainter(
                  w: widget,
                  p: p,
                  draw: Curves.easeOutCubic.transform(_draw.value),
                  win: _cur(),
                  hover: _hover,
                  pulse: _pulse.value,
                  lang: context.app.lang,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LinePainter extends CustomPainter {
  final LineChartW w;
  final Pal p;
  final double draw, pulse;
  final (double, double) win;
  final int? hover;
  final String lang;
  _LinePainter({required this.w, required this.p, required this.draw, required this.win, required this.hover, required this.pulse, required this.lang});

  static const left = 46.0, right = 12.0, top = 14.0, bottom = 28.0;

  @override
  void paint(Canvas canvas, Size s) {
    final n = w.dates.length;
    if (n < 2) return;
    final cw = s.width - left - right, ch = s.height - top - bottom;
    final i0 = win.$1.floor().clamp(0, n - 1), i1 = win.$2.ceil().clamp(0, n - 1);
    var mn = double.infinity, mx = -double.infinity;
    void see(double v) {
      mn = math.min(mn, v);
      mx = math.max(mx, v);
    }

    for (final se in w.series) {
      for (var i = math.max(i0, se.start); i <= i1 && i - se.start < se.values.length; i++) {
        see(se.values[i - se.start]);
      }
    }
    if (w.lower != null) {
      final off = n - w.lower!.length;
      for (var i = math.max(i0, off); i <= i1; i++) {
        see(w.lower![i - off]);
        see(w.upper![i - off]);
      }
    }
    final pad = (mx - mn) * .12 + .0001;
    mn -= pad;
    mx += pad;
    double xOf(double i) => left + (i - win.$1) / (win.$2 - win.$1) * cw;
    double yOf(double v) => top + (1 - (v - mn) / (mx - mn)) * ch;

    // grid + y labels
    final grid = Paint()
      ..color = p.border.withValues(alpha: .7)
      ..strokeWidth = 1;
    for (var g = 0; g <= 4; g++) {
      final y = top + ch * g / 4;
      canvas.drawLine(Offset(left, y), Offset(s.width - right, y), grid);
      _text(canvas, w.yFmt(mx - (mx - mn) * g / 4), Offset(left - 6, y), p.muted, 10, align: TextAlign.right);
    }
    // x labels
    final step = math.max(1, ((win.$2 - win.$1) / 5).round());
    for (var i = i0; i <= i1; i += step) {
      final d = w.dates[i];
      _text(canvas, '${_mon(d.month, lang)} ${d.year % 100}', Offset(xOf(i.toDouble()), s.height - 14), p.muted, 10, align: TextAlign.center);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(left - 2, 0, cw + 4, s.height));

    // forecast divider
    if (w.forecastFrom != null) {
      final x = xOf(w.forecastFrom!.toDouble());
      canvas.drawRect(Rect.fromLTRB(x, top, s.width - right, top + ch), Paint()..color = p.gold.withValues(alpha: .06));
      canvas.drawLine(Offset(x, top), Offset(x, top + ch), Paint()..color = p.gold.withValues(alpha: .6)..strokeWidth = 1);
    }

    // uncertainty band
    if (w.lower != null) {
      final off = n - w.lower!.length;
      final path = Path();
      final shown = (w.lower!.length * draw).ceil();
      if (shown > 1) {
        for (var k = 0; k < shown; k++) {
          final x = xOf((off + k).toDouble());
          k == 0 ? path.moveTo(x, yOf(w.upper![k])) : path.lineTo(x, yOf(w.upper![k]));
        }
        for (var k = shown - 1; k >= 0; k--) {
          path.lineTo(xOf((off + k).toDouble()), yOf(w.lower![k]));
        }
        path.close();
        canvas.drawPath(path, Paint()..color = p.gold.withValues(alpha: .22));
      }
    }

    for (final se in w.series) {
      final m = se.values.length;
      final path = Path();
      for (var i = 0; i < m; i++) {
        final pt = Offset(xOf((i + se.start).toDouble()), yOf(se.values[i]));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      final metric = path.computeMetrics().first;
      final len = metric.length * draw;
      if (se.fill && !se.dashed) {
        final part = metric.extractPath(0, len);
        final fill = Path.from(part);
        final end = metric.getTangentForOffset(len)?.position ?? Offset(left, top);
        fill
          ..lineTo(end.dx, top + ch)
          ..lineTo(xOf(se.start.toDouble()), top + ch)
          ..close();
        canvas.drawPath(
            fill,
            Paint()
              ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                se.color.withValues(alpha: .26),
                se.color.withValues(alpha: 0)
              ]).createShader(Rect.fromLTWH(left, top, cw, ch)));
      }
      final paint = Paint()
        ..color = se.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (se.dashed) {
        var d = 0.0;
        while (d < len) {
          canvas.drawPath(metric.extractPath(d, math.min(d + 7, len)), paint);
          d += 12;
        }
      } else {
        canvas.drawPath(metric.extractPath(0, len), paint);
      }
      // leading dot
      final tip = metric.getTangentForOffset(len)?.position;
      if (tip != null && draw < 1) {
        canvas.drawCircle(tip, 4.5, Paint()..color = se.color);
        canvas.drawCircle(tip, 9, Paint()..color = se.color.withValues(alpha: .2));
      }
    }

    // highlighted anomaly
    if (w.highlight != null && draw > .95) {
      final i = w.highlight!;
      final se = w.series.first;
      if (i - se.start >= 0 && i - se.start < se.values.length) {
        final c = Offset(xOf(i.toDouble()), yOf(se.values[i - se.start]));
        final col = w.highlightColor ?? p.alert;
        canvas.drawLine(Offset(c.dx, top), Offset(c.dx, top + ch), Paint()..color = col.withValues(alpha: .35)..strokeWidth = 1);
        canvas.drawCircle(c, 10 + 14 * pulse, Paint()..color = col.withValues(alpha: .25 * (1 - pulse)));
        canvas.drawCircle(c, 6, Paint()..color = col);
        canvas.drawCircle(c, 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    // hover
    if (hover != null) {
      final i = hover!;
      final x = xOf(i.toDouble());
      canvas.drawLine(Offset(x, top), Offset(x, top + ch), Paint()..color = p.muted.withValues(alpha: .5)..strokeWidth = 1);
      final lines = <String>['${_mon(w.dates[i].month, lang)} ${w.dates[i].year}'];
      for (final se in w.series) {
        final j = i - se.start;
        if (j >= 0 && j < se.values.length) {
          canvas.drawCircle(Offset(x, yOf(se.values[j])), 4.5, Paint()..color = se.color);
          lines.add('${se.name}: ${w.yFmt(se.values[j])}');
        }
      }
      _tooltip(canvas, s, Offset(x, top + 6), lines);
    }
    canvas.restore();
  }

  void _tooltip(Canvas canvas, Size s, Offset at, List<String> lines) {
    final tps = [
      for (var i = 0; i < lines.length; i++)
        TextPainter(
            text: TextSpan(text: lines[i], style: TextStyle(fontSize: 11, color: CI.cream, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400)),
            textDirection: TextDirection.ltr)
          ..layout()
    ];
    final wd = tps.map((t) => t.width).reduce(math.max) + 18;
    final ht = tps.fold<double>(0, (a, t) => a + t.height + 2) + 12;
    var x = at.dx + 12;
    if (x + wd > s.width) x = at.dx - wd - 12;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, at.dy, wd, ht), const Radius.circular(8));
    canvas.drawRRect(r, Paint()..color = CI.espressoDeep.withValues(alpha: .94));
    var y = at.dy + 6;
    for (final t in tps) {
      t.paint(canvas, Offset(x + 9, y));
      y += t.height + 2;
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => true;
}

String _mon(int m, String lang) {
  const fr = ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return (lang == 'fr' ? fr : en)[(m - 1) % 12];
}

void _text(Canvas c, String t, Offset at, Color col, double size,
    {TextAlign align = TextAlign.left, FontWeight? weight, double maxW = 200}) {
  final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, color: col, fontWeight: weight, fontFamily: TS.body)),
      textDirection: TextDirection.ltr,
      textAlign: align)
    ..layout(maxWidth: maxW);
  final dx = align == TextAlign.right ? -tp.width : (align == TextAlign.center ? -tp.width / 2 : 0.0);
  tp.paint(c, Offset(at.dx + dx, at.dy - tp.height / 2));
}

// ---------------------------------------------------------------------------

class BarItem {
  final String label;
  final double value; // bar spans from -> value
  final double from;
  final Color color;
  final String? valueLabel;
  const BarItem(this.label, this.value, this.color, {this.from = 0, this.valueLabel});
}

/// Bars that rise from the baseline one after another. Also draws waterfalls (via `from`).
class BarChartW extends StatefulWidget {
  final List<BarItem> items;
  final double height;
  final int? selected;
  final ValueChanged<int>? onTap;
  final String Function(double) fmt;
  final bool showValues;
  const BarChartW({
    super.key,
    required this.items,
    this.height = 240,
    this.selected,
    this.onTap,
    this.fmt = _f,
    this.showValues = true,
  });
  static String _f(double v) => Fmt.num(v, v.abs() < 10 ? 1 : 0);
  @override
  State<BarChartW> createState() => _BarChartWState();
}

class _BarChartWState extends State<BarChartW> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _init = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _c.duration = context.dur(1500);
    _c.forward();
  }

  @override
  void didUpdateWidget(BarChartW o) {
    super.didUpdateWidget(o);
    if (o.items.length != widget.items.length || o.items.first.value != widget.items.first.value) _c.forward(from: .25);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (_, c) {
        return GestureDetector(
          onTapDown: (d) {
            if (widget.onTap == null) return;
            const l = 8.0;
            final slot = (c.maxWidth - 2 * l) / widget.items.length;
            final i = ((d.localPosition.dx - l) / slot).floor();
            if (i >= 0 && i < widget.items.length) widget.onTap!(i);
          },
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
                size: Size(c.maxWidth, widget.height),
                painter: _BarPainter(widget, p, _c.value)),
          ),
        );
      }),
    );
  }
}

class _BarPainter extends CustomPainter {
  final BarChartW w;
  final Pal p;
  final double t;
  _BarPainter(this.w, this.p, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final n = w.items.length;
    if (n == 0) return;
    const l = 8.0, top = 22.0, bottom = 34.0;
    final ch = s.height - top - bottom;
    var mx = 0.0, mn = 0.0;
    for (final b in w.items) {
      mx = math.max(mx, math.max(b.value, b.from));
      mn = math.min(mn, math.min(b.value, b.from));
    }
    final range = (mx - mn) == 0 ? 1.0 : (mx - mn) * 1.08;
    double yOf(double v) => top + (1 - (v - mn) / range) * ch;
    final slot = (s.width - 2 * l) / n;
    final bw = math.min(slot * .62, 56.0);
    canvas.drawLine(Offset(l, yOf(0)), Offset(s.width - l, yOf(0)), Paint()..color = p.border..strokeWidth = 1.2);
    for (var i = 0; i < n; i++) {
      final b = w.items[i];
      final delay = i / (n * 1.6);
      final k = Curves.easeOutBack.transform(((t - delay) / (1 - delay * .9)).clamp(0.0, 1.0));
      final cx = l + slot * (i + .5);
      final from = b.from, to = b.from + (b.value - b.from) * k;
      final rect = Rect.fromLTRB(cx - bw / 2, math.min(yOf(from), yOf(to)), cx + bw / 2, math.max(yOf(from), yOf(to)));
      final sel = w.selected == i;
      final rr = RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(7), topRight: const Radius.circular(7));
      canvas.drawRRect(
          rr,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
              b.color,
              Color.lerp(b.color, CI.espresso, .35)!
            ]).createShader(rect.inflate(1)));
      if (sel) canvas.drawRRect(rr.inflate(2), Paint()..color = p.gold..style = PaintingStyle.stroke..strokeWidth = 2);
      if (w.showValues && k > .6) {
        _text(canvas, b.valueLabel ?? w.fmt(b.value), Offset(cx, rect.top - 9), p.text, 11, align: TextAlign.center, weight: FontWeight.w700);
      }
      _text(canvas, b.label, Offset(cx, s.height - 16), sel ? p.text : p.muted, 10.5,
          align: TextAlign.center, maxW: slot + 6, weight: sel ? FontWeight.w700 : null);
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.t != t || o.w.selected != w.selected || o.w.items != w.items;
}

// ---------------------------------------------------------------------------

class RadarSeries {
  final String name;
  final List<double> values;
  final Color color;
  const RadarSeries(this.name, this.values, this.color);
}

class RadarW extends StatelessWidget {
  final List<String> axes;
  final List<RadarSeries> series;
  final double size;
  final bool sweep;
  const RadarW({super.key, required this.axes, required this.series, this.size = 300, this.sweep = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Loop(
      loop: sweep && !context.calm,
      ms: 4200,
      builder: (t) => TweenAnimationBuilder<double>(
        key: ValueKey(series.map((e) => e.values.join(',')).join('|')),
        tween: Tween(begin: 0, end: 1),
        duration: context.dur(1300),
        curve: Curves.easeOutCubic,
        builder: (_, g, __) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _RadarPainter(axes, series, p, g, t, sweep)),
        ),
      ),
    );
  }
}

class _Loop extends StatefulWidget {
  final bool loop;
  final int ms;
  final Widget Function(double) builder;
  const _Loop({required this.loop, required this.ms, required this.builder});
  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms));
  @override
  void initState() {
    super.initState();
    if (widget.loop) _c.repeat();
  }

  @override
  void didUpdateWidget(_Loop o) {
    super.didUpdateWidget(o);
    if (widget.loop && !_c.isAnimating) _c.repeat();
    if (!widget.loop) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => widget.builder(_c.value));
}

class _RadarPainter extends CustomPainter {
  final List<String> axes;
  final List<RadarSeries> series;
  final Pal p;
  final double g, t;
  final bool sweep;
  _RadarPainter(this.axes, this.series, this.p, this.g, this.t, this.sweep);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 34;
    final n = axes.length;
    Offset pt(int i, double f) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final o = pt(i, ring / 4);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = p.border..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, pt(i, 1), Paint()..color = p.border..strokeWidth = 1);
      _text(canvas, axes[i], pt(i, 1.2), p.muted, 11, align: TextAlign.center, maxW: 80);
    }
    if (sweep) {
      final a = t * 2 * math.pi - math.pi / 2;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          a - 1.0,
          1.0,
          true,
          Paint()
            ..shader = SweepGradient(
                    startAngle: a - 1.0,
                    endAngle: a,
                    colors: [p.green.withValues(alpha: 0), p.green.withValues(alpha: .35)],
                    transform: GradientRotation(0))
                .createShader(Rect.fromCircle(center: c, radius: r)));
    }
    for (final se in series) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final o = pt(i, (se.values[i] / 100) * g);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = se.color.withValues(alpha: .2));
      canvas.drawPath(path, Paint()..color = se.color..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeJoin = StrokeJoin.round);
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(pt(i, (se.values[i] / 100) * g), 3.5, Paint()..color = se.color);
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => true;
}

// ---------------------------------------------------------------------------

/// Ring gauge with animated sweep and counter.
class RingGauge extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final Color? color;
  final String? caption;
  final bool pulse;
  const RingGauge(this.value, {super.key, this.size = 150, this.color, this.caption, this.pulse = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final col = color ?? p.green;
    return _Loop(
      loop: pulse && !context.calm,
      ms: 2400,
      builder: (t) => TweenAnimationBuilder<double>(
        key: ValueKey(value.round()),
        tween: Tween(begin: 0, end: value),
        duration: context.dur(1600),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v, col, p, t, pulse),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(Fmt.num(v, 0), style: TS.big(p, size: size * .3)),
                if (caption != null) Text(caption!, style: TS.label(p)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color col;
  final Pal p;
  final double t;
  final bool pulse;
  _RingPainter(this.v, this.col, this.p, this.t, this.pulse);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);
    if (pulse) {
      canvas.drawCircle(c, r + 4 + 6 * math.sin(t * 2 * math.pi), Paint()..color = col.withValues(alpha: .08));
    }
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()..color = p.border..style = PaintingStyle.stroke..strokeWidth = 9);
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * v / 100,
        false,
        Paint()
          ..shader = SweepGradient(colors: [col.withValues(alpha: .5), col], startAngle: 0, endAngle: 2 * math.pi, transform: const GradientRotation(-math.pi / 2)).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter o) => true;
}

/// Horizontal comparison rows: one animated bar per entity.
class CompareRow extends StatelessWidget {
  final String label;
  final List<(String, double, Color)> entries; // name, value, color
  final String Function(double) fmt;
  final bool lowerIsBetter;
  const CompareRow({super.key, required this.label, required this.entries, required this.fmt, this.lowerIsBetter = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final mx = entries.map((e) => e.$2).reduce(math.max);
    final best = lowerIsBetter ? entries.map((e) => e.$2).reduce(math.min) : mx;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 8),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 74, child: Text(e.$1, style: TextStyle(fontSize: 12, color: p.text), overflow: TextOverflow.ellipsis)),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: mx == 0 ? 0 : e.$2 / mx),
                    duration: context.dur(1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, f, __) => Stack(children: [
                      Container(height: 14, decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(7))),
                      Container(
                        height: 14,
                        width: c.maxWidth * f,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [e.$3.withValues(alpha: .7), e.$3]),
                            borderRadius: BorderRadius.circular(7)),
                      ),
                    ]),
                  ),
                ),
              ),
              SizedBox(
                  width: 74,
                  child: Text(fmt(e.$2),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: e.$2 == best ? FontWeight.w800 : FontWeight.w500, color: e.$2 == best ? p.green : p.text))),
            ]),
          ),
      ]),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const LegendDot(this.color, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TS.bodyS(context.pal).copyWith(fontSize: 12)),
        const SizedBox(width: 14),
      ]);
}
