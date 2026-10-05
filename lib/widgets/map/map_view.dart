import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import 'africa_geo.dart';

const mapLayerKeys = ['production', 'coops', 'climate', 'exports', 'cert', 'deforest'];

/// Interactive, animated map of Africa drawn with a CustomPainter.
/// Builds itself in stages: continent → countries → regions → producers → cooperatives → routes → ports.
class MapView extends StatefulWidget {
  final Set<String> layers;
  final String? selected;
  final String? focus; // country to zoom into
  final ValueChanged<String>? onSelect;
  final double height;
  final bool interactive;
  final bool build;
  final Map<String, double>? impact; // country id -> -1 (bad) .. +1 (good), what-if overlay
  const MapView({
    super.key,
    this.layers = const {'production', 'coops', 'exports'},
    this.selected,
    this.focus,
    this.onSelect,
    this.height = 520,
    this.interactive = true,
    this.build = true,
    this.impact,
  });
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  late final AnimationController _build = AnimationController(vsync: this);
  late final AnimationController _cam = AnimationController(vsync: this);
  final Map<String, double> _lv = {for (final k in mapLayerKeys) k: 0};
  double _cx = 16, _cy = 1, _zoom = 1;
  double _fx = 16, _fy = 1, _fz = 1, _tx = 16, _ty = 1, _tz = 1;
  Size _size = Size.zero;
  double _scaleStart = 1;
  bool _init = false;
  String? _hover;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _build.duration = context.dur(6500);
    _cam.duration = context.dur(1100);
    if (widget.build) {
      _build.forward();
    } else {
      _build.value = 1;
    }
    if (!context.calm) {
      _time.repeat();
      _time.addListener(_stepLayers);
    } else {
      for (final k in mapLayerKeys) {
        _lv[k] = widget.layers.contains(k) ? 1 : 0;
      }
    }
    _cam.addListener(() {
      final t = Curves.easeInOutCubic.transform(_cam.value);
      _cx = _fx + (_tx - _fx) * t;
      _cy = _fy + (_ty - _fy) * t;
      _zoom = _fz + (_tz - _fz) * t;
      if (context.calm) setState(() {});
    });
    _applyFocus(animate: false);
  }

  void _stepLayers() {
    for (final k in mapLayerKeys) {
      final target = widget.layers.contains(k) ? 1.0 : 0.0;
      _lv[k] = _lv[k]! + (target - _lv[k]!) * .12;
      if ((target - _lv[k]!).abs() < .005) _lv[k] = target;
    }
  }

  @override
  void didUpdateWidget(MapView o) {
    super.didUpdateWidget(o);
    if (o.focus != widget.focus) _applyFocus();
    if (context.calm) {
      for (final k in mapLayerKeys) {
        _lv[k] = widget.layers.contains(k) ? 1 : 0;
      }
    }
  }

  void _applyFocus({bool animate = true}) {
    _fx = _cx;
    _fy = _cy;
    _fz = _zoom;
    if (widget.focus == null) {
      _tx = 16;
      _ty = 1;
      _tz = 1;
    } else {
      final c = repo.country(widget.focus!);
      _tx = c.lon;
      _ty = c.lat;
      _tz = 3.4;
    }
    if (animate) {
      _cam.forward(from: 0);
    } else {
      _cx = _tx;
      _cy = _ty;
      _zoom = _tz;
    }
  }

  @override
  void dispose() {
    _time.dispose();
    _build.dispose();
    _cam.dispose();
    super.dispose();
  }

  double get _k => math.min(_size.width / 76, _size.height / 78);
  Offset _proj(double lon, double lat) => Offset(
      _size.width / 2 + (lon - _cx) * _k * _zoom, _size.height / 2 - (lat - _cy) * _k * _zoom);

  String? _hit(Offset pos) {
    String? best;
    var bd = 34.0;
    for (final c in repo.countries(africaOnly: true)) {
      final d = (_proj(c.lon, c.lat) - pos).distance;
      if (d < bd) {
        bd = d;
        best = c.id;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final names = {for (final c in repo.countries(africaOnly: true)) c.id: context.tr(c.nameKey)};
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(22),
          gradient: RadialGradient(
              center: const Alignment(.1, -.1),
              radius: 1.1,
              colors: p.dark
                  ? [const Color(0xFF2A1A12), const Color(0xFF120A07)]
                  : [const Color(0xFFFFF8EA), const Color(0xFFEBDDC2)]),
        ),
        child: LayoutBuilder(builder: (_, c) {
          _size = Size(c.maxWidth, c.maxHeight);
          return Listener(
            onPointerSignal: (e) {
              if (!widget.interactive) return;
              if (e is PointerScrollEvent) {
                setState(() => _zoom = (_zoom * (e.scrollDelta.dy < 0 ? 1.12 : .89)).clamp(1.0, 7.0));
              }
            },
            child: MouseRegion(
              cursor: _hover != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
              onHover: (e) {
                final h = _hit(e.localPosition);
                if (h != _hover) setState(() => _hover = h);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final h = _hit(d.localPosition);
                  if (h != null) widget.onSelect?.call(h);
                },
                onScaleStart: (d) => _scaleStart = _zoom,
                onScaleUpdate: (d) {
                  if (!widget.interactive) return;
                  setState(() {
                    _zoom = (_scaleStart * d.scale).clamp(1.0, 7.0);
                    _cx -= d.focalPointDelta.dx / (_k * _zoom);
                    _cy += d.focalPointDelta.dy / (_k * _zoom);
                  });
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_time, _build, _cam]),
                  builder: (_, __) => CustomPaint(
                    size: _size,
                    painter: _MapPainter(
                      p: p,
                      cx: _cx,
                      cy: _cy,
                      zoom: _zoom,
                      build: _build.value,
                      time: _time.value,
                      lv: Map.of(_lv),
                      selected: widget.selected,
                      hover: _hover,
                      names: names,
                      impact: widget.impact,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Pal p;
  final double cx, cy, zoom, build, time;
  final Map<String, double> lv;
  final String? selected, hover;
  final Map<String, String> names;
  final Map<String, double>? impact;
  _MapPainter({
    this.impact,
    required this.p,
    required this.cx,
    required this.cy,
    required this.zoom,
    required this.build,
    required this.time,
    required this.lv,
    required this.selected,
    required this.hover,
    required this.names,
  });

  late Size sz;
  double get k => math.min(sz.width / 76, sz.height / 78);
  Offset pr(double lon, double lat) => Offset(sz.width / 2 + (lon - cx) * k * zoom, sz.height / 2 - (lat - cy) * k * zoom);

  /// Local progress of a build stage between [a] and [b].
  double st(double a, double b) => ((build - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    sz = size;
    // lat/lon graticule
    final gp = Paint()..color = p.border.withValues(alpha: .45)..strokeWidth = .8;
    for (var lon = -20; lon <= 60; lon += 10) {
      canvas.drawLine(pr(lon.toDouble(), 45), pr(lon.toDouble(), -45), gp);
    }
    for (var lat = -40; lat <= 40; lat += 10) {
      canvas.drawLine(pr(-25, lat.toDouble()), pr(60, lat.toDouble()), gp);
    }

    _continent(canvas, africaOutline);
    _continent(canvas, madagascarOutline);

    final af = repo.countries(africaOnly: true);
    final cStage = st(.18, .38);

    // production zones
    final prodA = (lv['production'] ?? 0);
    if (prodA > 0) {
      for (final c in af) {
        final pc = pr(c.lon, c.lat);
        final r = (math.sqrt(c.prodKt) * 1.25 + 14) * zoom.clamp(1.0, 3.4) * .8 * cStage;
        canvas.drawCircle(
            pc,
            r * 1.6,
            Paint()
              ..shader = RadialGradient(colors: [
                p.accent.withValues(alpha: .38 * prodA),
                p.accent.withValues(alpha: 0)
              ]).createShader(Rect.fromCircle(center: pc, radius: r * 1.6)));
        // regions
        final rs = st(.38, .55);
        for (final rg in c.regions) {
          final o = pr(c.lon + rg.dLon, c.lat + rg.dLat);
          final rr = (math.sqrt(c.prodKt * rg.share) * 1.1 + 4) * zoom.clamp(1.0, 3.4) * .75 * rs;
          canvas.drawCircle(o, rr, Paint()..color = p.green.withValues(alpha: .28 * prodA));
          canvas.drawCircle(o, rr, Paint()..color = p.green.withValues(alpha: .6 * prodA)..style = PaintingStyle.stroke..strokeWidth = 1);
          if (zoom > 2.2 && rs > .9) {
            _label(canvas, rg.name, o + Offset(0, rr + 8), p.muted.withValues(alpha: prodA), 9.5);
          }
        }
        // producers (dots)
        final ps = st(.55, .7);
        final cnt = (c.producersK / 40).clamp(10, 40).toInt();
        for (var i = 0; i < (cnt * ps).floor(); i++) {
          final a = i * 2.399, d = math.sqrt(i + 1) * 3.4 * zoom.clamp(1.0, 3.0);
          canvas.drawCircle(pc + Offset(math.cos(a), math.sin(a)) * d, 1.7 * zoom.clamp(1.0, 2.0), Paint()..color = CI.gold.withValues(alpha: .85 * prodA));
        }
      }
    }

    // climate risk halos
    final clA = lv['climate'] ?? 0;
    if (clA > 0) {
      for (final c in af) {
        final pc = pr(c.lon, c.lat);
        final col = Color.lerp(p.green, p.alert, ((c.climateRisk - 45) / 30).clamp(0.0, 1.0))!;
        final pulse = (time * 3) % 1;
        final r = (22 + c.climateRisk * .35) * zoom.clamp(1.0, 3.0);
        canvas.drawCircle(pc, r, Paint()..color = col.withValues(alpha: .13 * clA));
        canvas.drawCircle(pc, r * (.6 + .6 * pulse), Paint()..color = col.withValues(alpha: .5 * (1 - pulse) * clA)..style = PaintingStyle.stroke..strokeWidth = 1.6);
      }
    }

    // what-if impact overlay
    if (impact != null) {
      for (final c in af) {
        final v = impact![c.id] ?? 0;
        final pc = pr(c.lon, c.lat);
        final col = v >= 0 ? p.green : p.alert;
        final r = (18 + v.abs() * 34) * zoom.clamp(1.0, 3.0) * cStage;
        final pulse = (time * 3) % 1;
        canvas.drawCircle(pc, r, Paint()..color = col.withValues(alpha: .22 + .25 * v.abs()));
        canvas.drawCircle(pc, r * (.7 + .5 * pulse), Paint()..color = col.withValues(alpha: .55 * (1 - pulse))..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    // deforestation
    final dfA = lv['deforest'] ?? 0;
    if (dfA > 0) {
      for (final c in af) {
        final pc = pr(c.lon, c.lat);
        final n = (c.deforestRisk / 4).round();
        for (var i = 0; i < n; i++) {
          final a = i * 2.17 + c.lon, d = (10 + (i * 7) % 26) * zoom.clamp(1.0, 3.0);
          canvas.drawCircle(pc + Offset(math.cos(a), math.sin(a)) * d, 2.4, Paint()..color = p.alert.withValues(alpha: .75 * dfA));
        }
      }
    }

    // coops
    final coA = lv['coops'] ?? 0;
    final cs = st(.7, .8);
    if (coA > 0 && cs > 0) {
      for (final c in repo.coops()) {
        final o = pr(c.lon, c.lat);
        final r = (3.2 + math.sqrt(c.volumeT) * .05) * cs * zoom.clamp(1.0, 2.4);
        canvas.drawCircle(o, r + 3, Paint()..color = p.dark ? CI.cream.withValues(alpha: .18 * coA) : CI.espresso.withValues(alpha: .12 * coA));
        canvas.drawCircle(o, r, Paint()..color = p.gold.withValues(alpha: coA));
        canvas.drawCircle(o, r, Paint()..color = CI.espressoDeep.withValues(alpha: coA)..style = PaintingStyle.stroke..strokeWidth = 1);
        if (zoom > 2.6) _label(canvas, c.name, o + Offset(0, r + 9), p.muted.withValues(alpha: coA), 9);
      }
    }

    // routes + ports
    final exA = lv['exports'] ?? 0;
    final rs2 = st(.8, .92), ps2 = st(.92, 1);
    if (exA > 0) {
      final ports = {for (final pt in repo.ports()) pt.id: pt};
      for (final c in repo.coops()) {
        final port = ports[c.portId];
        if (port == null || rs2 == 0) continue;
        final a = pr(c.lon, c.lat), b = pr(port.lon, port.lat);
        final mid = Offset.lerp(a, b, .5)! + Offset(0, -(a - b).distance * .18);
        final path = Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
        final m = path.computeMetrics().first;
        canvas.drawPath(m.extractPath(0, m.length * rs2), Paint()..color = p.accent.withValues(alpha: .35 * exA)..style = PaintingStyle.stroke..strokeWidth = 1.4);
        if (rs2 >= 1) {
          for (var i = 0; i < 3; i++) {
            final f = ((time * 4 + i / 3 + c.lon * .013) % 1);
            final pos = m.getTangentForOffset(m.length * f)!.position;
            canvas.drawCircle(pos, 2.6, Paint()..color = CI.espresso.withValues(alpha: exA));
            canvas.drawCircle(pos, 1.6, Paint()..color = p.gold.withValues(alpha: exA));
          }
        }
      }
      for (final pt in repo.ports()) {
        final o = pr(pt.lon, pt.lat);
        // sea lane
        final ex = portExit[pt.id]!;
        final e = pr(ex[0], ex[1]);
        if (ps2 > 0) {
          final dash = Paint()..color = p.green.withValues(alpha: .55 * exA * ps2)..strokeWidth = 1.4;
          final len = (e - o).distance;
          final dir = (e - o) / len;
          for (var d = 0.0; d < len * ps2; d += 9) {
            canvas.drawLine(o + dir * d, o + dir * math.min(d + 4.5, len), dash);
          }
          final sh = o + dir * (len * ((time * 3) % 1));
          canvas.drawCircle(sh, 3.4, Paint()..color = p.green.withValues(alpha: exA));
        }
        final sz2 = 6.5 * ps2 * zoom.clamp(1.0, 2.0);
        final r = Rect.fromCenter(center: o, width: sz2 * 1.8, height: sz2 * 1.8);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = p.green.withValues(alpha: exA));
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Colors.white.withValues(alpha: .9 * exA)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        if (ps2 > .8 && zoom > 1.8) _label(canvas, pt.name, o + const Offset(0, 16), p.text.withValues(alpha: .8 * exA), 10, bold: true);
      }
    }

    // certification rings
    final ceA = lv['cert'] ?? 0;
    if (ceA > 0) {
      for (final c in af) {
        final pc = pr(c.lon, c.lat);
        final r = 25.0 * zoom.clamp(1.0, 2.2);
        final rect = Rect.fromCircle(center: pc, radius: r);
        canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..color = p.border.withValues(alpha: ceA)..style = PaintingStyle.stroke..strokeWidth = 5);
        canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * c.certPct / 100, false, Paint()..color = p.green.withValues(alpha: ceA)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
      }
    }

    // country nodes (always visible)
    for (final c in af) {
      final pc = pr(c.lon, c.lat);
      final sel = selected == c.id, hov = hover == c.id;
      final a = cStage;
      if (a == 0) continue;
      if (sel) {
        final pulse = (time * 5) % 1;
        canvas.drawCircle(pc, 12 + 18 * pulse, Paint()..color = p.gold.withValues(alpha: .5 * (1 - pulse)));
      }
      final r = (sel ? 9.0 : (hov ? 8.0 : 6.5)) * a;
      canvas.drawCircle(pc, r + 3, Paint()..color = (p.dark ? CI.cream : CI.espressoDeep).withValues(alpha: .15 * a));
      canvas.drawCircle(pc, r, Paint()..color = sel ? p.gold : p.accent);
      canvas.drawCircle(pc, r, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      _label(canvas, names[c.id] ?? c.id, pc + Offset(0, -r - 11), p.text.withValues(alpha: a), sel ? 12.5 : 11.5, bold: true);
    }
  }

  void _continent(Canvas canvas, List<List<double>> pts) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = pr(pts[i][0], pts[i][1]);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    final s1 = st(0, .18);
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            (p.dark ? const Color(0xFF3A2519) : const Color(0xFFE6D2B0)).withValues(alpha: s1),
            (p.dark ? const Color(0xFF241610) : const Color(0xFFD7BD94)).withValues(alpha: s1)
          ]).createShader(Offset.zero & sz));
    final m = path.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * Curves.easeOut.transform(s1)),
        Paint()..color = p.gold..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round);
  }

  void _label(Canvas canvas, String t, Offset at, Color col, double size, {bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(fontFamily: TS.body, fontSize: size, color: col, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapPainter o) => true;
}
