import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/theme/palette.dart';
import '../models/models.dart';

const chainIcons = <String, IconData>{
  'producer': Icons.agriculture_rounded,
  'coop': Icons.groups_rounded,
  'collect': Icons.local_shipping_rounded,
  'process': Icons.factory_rounded,
  'export': Icons.inventory_2_rounded,
  'port': Icons.anchor_rounded,
  'transport': Icons.directions_boat_rounded,
  'buyer': Icons.handshake_rounded,
  'roaster': Icons.local_cafe_rounded,
};

/// Looping clock helper.
mixin LoopClock<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController clock = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  bool clockStarted = false;
  void startClock(bool calm) {
    if (clockStarted) return;
    clockStarted = true;
    if (!calm) clock.repeat();
  }
}

/// Producer → roaster journey with coffee beans travelling between clickable steps.
class ChainFlow extends StatefulWidget {
  final List<ChainStep> steps;
  final String? selected;
  final ValueChanged<String>? onSelect;
  final double? progress; // 0..1 build progress (scroll driven); null = auto
  final bool compact;
  const ChainFlow({super.key, required this.steps, this.selected, this.onSelect, this.progress, this.compact = false});
  @override
  State<ChainFlow> createState() => _ChainFlowState();
}

class _ChainFlowState extends State<ChainFlow> with TickerProviderStateMixin, LoopClock {
  late final AnimationController _build = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    startClock(context.calm);
    if (widget.progress == null && !_build.isAnimating && _build.value == 0) {
      _build.duration = context.dur(2600);
      _build.forward();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    _build.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final vertical = context.isMobile && !widget.compact;
    final n = widget.steps.length;
    final nodeD = widget.compact ? 46.0 : 58.0;
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = vertical ? n * 84.0 : (widget.compact ? 110.0 : 150.0);
      List<Offset> pos;
      if (vertical) {
        pos = [for (var i = 0; i < n; i++) Offset(38, 42 + i * 84.0)];
      } else {
        final step = (w - 90) / (n - 1);
        pos = [for (var i = 0; i < n; i++) Offset(45 + i * step, widget.compact ? 40 : 56)];
      }
      return AnimatedBuilder(
        animation: Listenable.merge([clock, _build]),
        builder: (_, __) {
          final b = widget.progress ?? Curves.easeInOut.transform(_build.value);
          return SizedBox(
            height: h,
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(painter: _ChainPainter(pos, b, clock.value, p, widget.steps)),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: vertical ? pos[i].dx - nodeD / 2 : pos[i].dx - 45,
                  top: vertical ? pos[i].dy - nodeD / 2 : pos[i].dy - nodeD / 2,
                  width: vertical ? w - 10 : 90,
                  child: _node(context, widget.steps[i], i, b, nodeD, vertical),
                ),
            ]),
          );
        },
      );
    });
  }

  Widget _node(BuildContext context, ChainStep s, int i, double b, double d, bool vertical) {
    final p = context.pal;
    final n = widget.steps.length;
    final k = ((b * (n + 1) - i) / 1.2).clamp(0.0, 1.0);
    final sel = widget.selected == s.id;
    final col = [p.green, p.gold, p.alert][s.status];
    final circle = Transform.scale(
      scale: Curves.easeOutBack.transform(k),
      child: Opacity(
        opacity: k,
        child: GestureDetector(
          onTap: () => widget.onSelect?.call(s.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                  sel ? p.gold : p.accent,
                  Color.lerp(sel ? p.gold : p.accent, CI.espressoDeep, .5)!
                ]),
                border: Border.all(color: col, width: sel ? 3.5 : 2.4),
                image: null,
                boxShadow: [BoxShadow(color: (sel ? p.gold : p.accent).withValues(alpha: .4), blurRadius: sel ? 20 : 10)],
              ),
              child: ClipOval(child: Image.asset('assets/supply_chain/${s.id}.webp', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(chainIcons[s.id], color: Colors.white, size: d * .45))),
            ),
          ),
        ),
      ),
    );
    final label = Opacity(
      opacity: k,
      child: Text(context.tr(s.nameKey),
          textAlign: vertical ? TextAlign.left : TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: widget.compact ? 10 : 11.5, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? p.text : p.muted)),
    );
    if (vertical) {
      return Row(children: [
        circle,
        const SizedBox(width: 14),
        Expanded(child: label),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [circle, const SizedBox(height: 8), label]);
  }
}

class _ChainPainter extends CustomPainter {
  final List<Offset> pos;
  final double b, t;
  final Pal p;
  final List<ChainStep> steps;
  _ChainPainter(this.pos, this.b, this.t, this.p, this.steps);
  @override
  void paint(Canvas canvas, Size s) {
    final n = pos.length;
    for (var i = 0; i < n - 1; i++) {
      final k = ((b * (n + 1) - i - .6) / 1.0).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final a = pos[i], c = pos[i + 1];
      final line = Paint()..color = p.border..strokeWidth = 3..strokeCap = StrokeCap.round;
      final e = Offset.lerp(a, c, k)!;
      canvas.drawLine(a, e, line);
      canvas.drawLine(a, e, Paint()..color = p.accent.withValues(alpha: .35)..strokeWidth = 1.2);
      if (k >= 1) {
        for (var j = 0; j < 3; j++) {
          final f = (t * 2 + j / 3 + i * .17) % 1;
          final o = Offset.lerp(a, c, f)!;
          _bean(canvas, o, 5.2, p);
        }
      }
    }
  }

  void _bean(Canvas c, Offset o, double r, Pal p) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(.6);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 2.1), Paint()..color = p.dark ? CI.latte : CI.espresso);
    c.drawLine(Offset(0, -r), Offset(0, r), Paint()..color = (p.dark ? CI.espressoDeep : CI.latte)..strokeWidth = 1);
    c.restore();
  }

  @override
  bool shouldRepaint(_ChainPainter o) => true;
}

// ---------------------------------------------------------------------------

const _srcIcons = <(String, IconData)>[
  ('ds_markets', Icons.show_chart_rounded),
  ('ds_weather', Icons.cloud_rounded),
  ('ds_production', Icons.spa_rounded),
  ('ds_coops', Icons.groups_rounded),
  ('ds_ports', Icons.anchor_rounded),
  ('ds_sustain', Icons.eco_rounded),
  ('ds_certs', Icons.verified_rounded),
];

/// Data sources send streams to the data centre, which receives, checks, cleans,
/// analyses and turns them into indicators.
class DataConvergence extends StatefulWidget {
  final double? progress;
  final double height;
  const DataConvergence({super.key, this.progress, this.height = 380});
  @override
  State<DataConvergence> createState() => _DataConvergenceState();
}

class _DataConvergenceState extends State<DataConvergence> with TickerProviderStateMixin, LoopClock {
  late final AnimationController _auto = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  bool _go = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    startClock(context.calm);
    if (!_go && widget.progress == null) {
      _go = true;
      if (context.calm) {
        _auto.value = 1;
      } else {
        _auto.repeat();
      }
    }
  }

  @override
  void dispose() {
    clock.dispose();
    _auto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(builder: (_, c) {
      return AnimatedBuilder(
        animation: Listenable.merge([clock, _auto]),
        builder: (_, __) {
          var pr = widget.progress ?? _auto.value;
          final w = c.maxWidth, h = widget.height;
          final centre = Offset(w / 2, h * .42);
          final rad = math.min(w * .42, h * .36);
          final pts = [
            for (var i = 0; i < _srcIcons.length; i++)
              centre + Offset(math.cos(-math.pi / 2 + i * 2 * math.pi / _srcIcons.length), math.sin(-math.pi / 2 + i * 2 * math.pi / _srcIcons.length)) * rad
          ];
          final stepsK = ['pipe_received', 'pipe_checked', 'pipe_cleaned', 'pipe_analyzed', 'pipe_indicators'];
          final flowK = (pr / .4).clamp(0.0, 1.0);
          return SizedBox(
            height: h,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _ConvPainter(pts, centre, flowK, clock.value, p))),
              for (var i = 0; i < pts.length; i++)
                Positioned(
                  left: pts[i].dx - 38,
                  top: pts[i].dy - 24,
                  width: 76,
                  child: Opacity(
                    opacity: Curves.easeOut.transform(((flowK * 8 - i) / 1.2).clamp(0.0, 1.0)),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.gold), boxShadow: [BoxShadow(color: p.gold.withValues(alpha: .3), blurRadius: 10)]),
                        child: Icon(_srcIcons[i].$2, size: 17, color: p.accent),
                      ),
                      const SizedBox(height: 3),
                      Text(context.tr(_srcIcons[i].$1), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: p.muted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              Positioned(
                left: centre.dx - 44,
                top: centre.dy - 44,
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [p.accent, CI.espressoDeep]),
                      boxShadow: [BoxShadow(color: p.gold.withValues(alpha: .25 + .25 * flowK * (.5 + .5 * math.sin(clock.value * 6.28 * 2))), blurRadius: 30, spreadRadius: 4)]),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(context.tr('data_center'), textAlign: TextAlign.center, style: const TextStyle(color: CI.cream, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .6)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                  for (var i = 0; i < stepsK.length; i++)
                    Builder(builder: (_) {
                      final k = ((pr - .45 - i * .1) / .1).clamp(0.0, 1.0);
                      final done = k >= 1;
                      return Opacity(
                        opacity: .35 + .65 * (pr > .42 ? 1 : 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: done ? p.green.withValues(alpha: .16) : p.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: done ? p.green : p.border)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                                width: 13,
                                height: 13,
                                child: done
                                    ? Icon(Icons.check_circle_rounded, size: 13, color: p.green)
                                    : (k > 0 ? CircularProgressIndicator(value: k, strokeWidth: 2, color: p.gold) : Icon(Icons.circle_outlined, size: 13, color: p.muted))),
                            const SizedBox(width: 6),
                            Text(context.tr(stepsK[i]), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: done ? p.green : p.muted)),
                          ]),
                        ),
                      );
                    }),
                ]),
              ),
            ]),
          );
        },
      );
    });
  }
}

class _ConvPainter extends CustomPainter {
  final List<Offset> pts;
  final Offset c;
  final double k, t;
  final Pal p;
  _ConvPainter(this.pts, this.c, this.k, this.t, this.p);
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < pts.length; i++) {
      final kk = ((k * 8 - i) / 1.4).clamp(0.0, 1.0);
      if (kk <= 0) continue;
      final a = pts[i];
      final mid = Offset.lerp(a, c, .5)! + Offset((a.dy - c.dy) * .18, -(a.dx - c.dx) * .18);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, c.dx, c.dy);
      final m = path.computeMetrics().first;
      canvas.drawPath(m.extractPath(0, m.length * kk), Paint()..color = p.gold.withValues(alpha: .35)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      if (kk >= 1) {
        for (var j = 0; j < 4; j++) {
          final f = (t * 3 + j / 4 + i * .13) % 1;
          final o = m.getTangentForOffset(m.length * f)!.position;
          canvas.drawCircle(o, 3, Paint()..color = p.accent.withValues(alpha: .9));
          canvas.drawCircle(o, 6, Paint()..color = p.gold.withValues(alpha: .18));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConvPainter o) => true;
}
