import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// Start of each of the 13 chapters of the plant story (progress 0..1).
const plantStageStarts = <double>[0, .05, .12, .25, .34, .42, .48, .58, .68, .74, .80, .86, .94];

int plantStage(double p) {
  var s = 0;
  for (var i = 0; i < plantStageStarts.length; i++) {
    if (p >= plantStageStarts[i]) s = i;
  }
  return s;
}

double _e(double p, double a, double b) {
  final t = ((p - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Organic coffee plant drawn procedurally; scroll progress [p] builds it from
/// seed to roasted bean to data network. [t] is a free-running ambient clock (0..1).
class CoffeePlantPainter extends CustomPainter {
  final double p, t;
  final bool dark, light; // light = reduced detail on phones
  CoffeePlantPainter({required this.p, required this.t, required this.dark, this.light = false});

  late double w, h, m, cx, y0, hFull;

  static const leafDark = Color(0xFF2E5B38);
  static const leafLight = Color(0xFF6D9B66);
  static const soilTop = Color(0xFF5B3A28);
  static const soilBot = Color(0xFF2B1B14);

  @override
  void paint(Canvas canvas, Size s) {
    w = s.width;
    h = s.height;
    final portrait = h > w * 1.2;
    m = portrait ? math.min(w * 1.25, h * .7) : math.min(w, h * .98);
    cx = w / 2;
    y0 = h * (portrait ? .64 : .74);
    hFull = portrait ? h * .4 : m * .56;
    final plantA = 1 - _e(p, .64, .74);
    canvas.save();
    if (plantA > 0) {
      _soil(canvas, plantA);
      _roots(canvas, plantA);
      _seed(canvas, plantA);
      _plant(canvas, plantA);
    }
    canvas.restore();
    if (p > .62) _hero(canvas);
  }

  // ---- soil ---------------------------------------------------------------
  void _soil(Canvas canvas, double a) {
    final rect = Rect.fromCenter(center: Offset(cx, y0 + m * .1), width: math.min(m, w * 1.02), height: m * .3);
    canvas.drawOval(
        rect,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [soilTop, soilBot])
              .createShader(rect)
          ..color = Colors.white.withValues(alpha: a));
    canvas.drawOval(rect.deflate(1), Paint()..color = Colors.black.withValues(alpha: .0));
    // grains of soil
    final r = math.Random(4);
    final dot = Paint()..color = const Color(0xFF8A6244).withValues(alpha: .55 * a);
    for (var i = 0; i < (light ? 40 : 90); i++) {
      final ang = r.nextDouble() * 6.28, rr = math.sqrt(r.nextDouble());
      final o = rect.center + Offset(math.cos(ang) * rect.width / 2 * rr * .96, math.sin(ang) * rect.height / 2 * rr * .94);
      canvas.drawCircle(o, 1 + r.nextDouble() * 1.6, dot);
    }
  }

  // ---- seed ---------------------------------------------------------------
  void _seed(Canvas canvas, double a) {
    final s = _e(p, 0, .05) * (1 - _e(p, .1, .2) * .6);
    if (s <= 0) return;
    final c = Offset(cx, y0 + m * .075);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-.5);
    final r = m * .022 * s;
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.5);
    canvas.drawOval(rect, Paint()..color = const Color(0xFF8D9A62).withValues(alpha: a));
    canvas.drawPath(
        Path()
          ..moveTo(-r, 0)
          ..quadraticBezierTo(0, r * .35, r, 0),
        Paint()..color = const Color(0xFF3B2A1C).withValues(alpha: a)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.restore();
    // soft glow when it wakes up
    final g = _e(p, .02, .06) * (1 - _e(p, .08, .14));
    if (g > 0) {
      canvas.drawCircle(c, m * .09 * g, Paint()..color = CI.gold.withValues(alpha: .3 * g));
    }
  }

  // ---- roots --------------------------------------------------------------
  void _roots(Canvas canvas, double a) {
    final g = _e(p, .05, .17);
    if (g <= 0) return;
    final base = Offset(cx, y0 + m * .075);
    final paint = Paint()
      ..color = const Color(0xFFD9BE96).withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void root(Offset a0, Offset c1, Offset c2, Offset e, double wd, double start, double end) {
      final k = _e(g, start, end);
      if (k <= 0) return;
      final path = Path()
        ..moveTo(a0.dx, a0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
      final mt = path.computeMetrics().first;
      paint.strokeWidth = wd;
      canvas.drawPath(mt.extractPath(0, mt.length * k), paint);
    }

    root(base, base + Offset(-m * .01, m * .06), base + Offset(m * .02, m * .1), base + Offset(m * .005, m * .15), 3.2, 0, 1);
    final laterals = [
      [-.06, .06, .0, .09, -.11, .1, 0.15, .8],
      [.06, .07, .0, .1, .12, .12, 0.25, .9],
      [-.05, .11, .0, .12, -.1, .15, 0.4, 1.0],
      [.05, .12, .0, .13, .1, .15, 0.5, 1.0],
      [-.02, .15, -.01, .16, -.05, .19, 0.6, 1.0],
    ];
    for (final l in laterals) {
      final st = base + Offset(0.002 * m, l[1] * m * .7);
      root(st, st + Offset(l[0] * m * .6, m * .01), st + Offset(l[4] * m * .6, m * .01), st + Offset(l[4] * m, l[5] * m * .45), 1.8, l[6], l[7]);
    }
  }

  // ---- plant body ---------------------------------------------------------
  Offset _stem(double f, double sway) {
    return Offset(cx + m * .02 * math.sin(f * 2.4) + sway * f * f, y0 - hFull * f);
  }

  void _plant(Canvas canvas, double alpha) {
    final g = _e(p, .12, .46);
    if (g <= 0) return;
    final sway = math.sin(t * 2 * math.pi) * m * .008;
    final leafBoost = _e(p, .25, .40);

    // stem
    final sp = Path()..moveTo(cx, y0);
    for (var i = 1; i <= 24; i++) {
      final o = _stem(i / 24 * g, sway);
      sp.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
        sp,
        Paint()
          ..color = const Color(0xFF6B5A3A).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = m * .014 * (1 - g * .35) + 2
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        sp,
        Paint()
          ..color = const Color(0xFF8DA06A).withValues(alpha: .55 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = m * .005 + 1
          ..strokeCap = StrokeCap.round);

    final fl = _e(p, .42, .49) * (1 - _e(p, .54, .60));
    final ch = _e(p, .48, .60);
    final ripen = _e(p, .58, .70);

    const fr = [.26, .40, .54, .68, .82];
    for (var k = 0; k < fr.length; k++) {
      for (final side in [-1, 1]) {
        final bg = _e(g, fr[k], fr[k] + .22);
        if (bg <= 0) continue;
        final a0 = _stem(fr[k], sway);
        final len = m * (.30 - .038 * k) * (side == 1 ? 1.0 : .94);
        final droop = math.sin(t * 2 * math.pi + k + side) * m * .004;
        final end = a0 + Offset(side * len, -len * .04 + len * .1 + droop);
        final ctrl = a0 + Offset(side * len * .5, -len * .26 + droop);
        final path = Path()
          ..moveTo(a0.dx, a0.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
        final mt = path.computeMetrics().first;
        canvas.drawPath(
            mt.extractPath(0, mt.length * bg),
            Paint()
              ..color = const Color(0xFF6B5A3A).withValues(alpha: alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = m * .007 + .8
              ..strokeCap = StrokeCap.round);
        final nodes = light ? [.5, .92] : [.33, .62, .92];
        for (var n = 0; n < nodes.length; n++) {
          final ft = nodes[n];
          if (bg < ft) continue;
          final tan = mt.getTangentForOffset(mt.length * ft);
          if (tan == null) continue;
          final grow = _e(bg, ft, ft + .25) * (.55 + .45 * leafBoost);
          final lenL = m * (.082 - .006 * k) * grow;
          final ang = tan.angle;
          _leaf(canvas, tan.position, ang - 1.15, lenL, lenL * .36, alpha);
          _leaf(canvas, tan.position, ang + 1.15, lenL * .92, lenL * .34, alpha);
          if (n == nodes.length - 1) _leaf(canvas, tan.position, ang, lenL * 1.05, lenL * .38, alpha);
          // flowers and cherries hang below the node
          final below = tan.position + Offset(0, m * .012);
          if (fl > 0) _flower(canvas, below + Offset(m * .008, m * .004), m * .016 * fl, alpha * fl);
          if (ch > 0) _cherries(canvas, below, ch, ripen, alpha, k + n + side);
        }
      }
    }
    // top leaves
    final top = _stem(g, sway);
    final tl = m * .075 * _e(g, .35, .6) * (.55 + .45 * leafBoost);
    if (tl > 0) {
      _leaf(canvas, top, -math.pi / 2 - .7, tl, tl * .38, alpha);
      _leaf(canvas, top, -math.pi / 2 + .7, tl, tl * .38, alpha);
      _leaf(canvas, top, -math.pi / 2, tl * 1.1, tl * .4, alpha);
    }
  }

  void _leaf(Canvas c, Offset base, double ang, double len, double wid, double alpha) {
    if (len < 1) return;
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(ang);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * .4, -wid, len, 0)
      ..quadraticBezierTo(len * .4, wid, 0, 0);
    c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(colors: [
            Color.lerp(leafDark, Colors.black, dark ? 0 : .0)!.withValues(alpha: alpha),
            leafLight.withValues(alpha: alpha)
          ]).createShader(Rect.fromLTWH(0, -wid, len, wid * 2)));
    c.drawLine(Offset.zero, Offset(len * .92, 0), Paint()..color = Colors.white.withValues(alpha: .25 * alpha)..strokeWidth = .9);
    c.restore();
  }

  void _flower(Canvas c, Offset o, double r, double alpha) {
    if (r < 1) return;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 + t * .4;
      c.drawOval(Rect.fromCenter(center: o + Offset(math.cos(a), math.sin(a)) * r * .8, width: r * 1.1, height: r * .7),
          Paint()..color = const Color(0xFFFFFAF0).withValues(alpha: alpha));
    }
    c.drawCircle(o, r * .32, Paint()..color = CI.gold.withValues(alpha: alpha));
  }

  void _cherries(Canvas c, Offset o, double grow, double ripen, double alpha, int seed) {
    final n = 2 + seed % 2;
    for (var i = 0; i < n; i++) {
      final off = Offset((i - (n - 1) / 2) * m * .019, m * (.012 + .008 * ((i + seed) % 2)));
      final r = m * .0155 * grow;
      final pos = o + off + Offset(math.sin(t * 6.28 + i + seed) * .8, 0);
      c.drawLine(o, pos - Offset(0, r * .6), Paint()..color = const Color(0xFF55703F).withValues(alpha: alpha)..strokeWidth = 1.1);
      _cherry(c, pos, r, ripen, alpha);
    }
  }

  static Color cherryColor(double ripen) => ripen < .5
      ? Color.lerp(const Color(0xFF6E9B4D), const Color(0xFFE2A03A), ripen * 2)!
      : Color.lerp(const Color(0xFFE2A03A), const Color(0xFFB02E2B), (ripen - .5) * 2)!;

  void _cherry(Canvas c, Offset o, double r, double ripen, double alpha) {
    if (r < .8) return;
    final col = cherryColor(ripen).withValues(alpha: alpha);
    c.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-.4, -.4), colors: [
            Color.lerp(col, Colors.white, .35)!.withValues(alpha: alpha),
            col,
            Color.lerp(col, Colors.black, .35)!.withValues(alpha: alpha)
          ], stops: const [0, .5, 1])
              .createShader(Rect.fromCircle(center: o, radius: r)));
    c.drawCircle(o + Offset(0, r * .85), r * .2, Paint()..color = Colors.black.withValues(alpha: .35 * alpha));
  }

  // ---- hero: cherry → bean → roast → data ---------------------------------
  void _hero(Canvas canvas) {
    final hc = Offset(cx, h * .47);
    final R = m * .17;
    final enter = _e(p, .62, .72);
    final open = _e(p, .72, .79);
    final bean = _e(p, .76, .81);
    final proc = _e(p, .80, .87);
    final roast = _e(p, .86, .95);
    final data = _e(p, .94, 1.0);

    // halo
    final halo = _e(p, .62, .70);
    canvas.drawCircle(
        hc,
        R * (2.2 + .15 * math.sin(t * 6.28)),
        Paint()
          ..shader = RadialGradient(colors: [
            Color.lerp(CI.gold, const Color(0xFFE8803A), roast)!.withValues(alpha: .28 * halo),
            Color.lerp(CI.gold, const Color(0xFFE8803A), roast)!.withValues(alpha: 0)
          ]).createShader(Rect.fromCircle(center: hc, radius: R * 2.4)));

    // cherry (skin halves) – exists from enter until open completes
    if (bean < 1) {
      final skinA = 1 - _e(p, .76, .8);
      final cr = R * enter * (1 + .04 * math.sin(t * 12.56));
      final gap = open * R * .9;
      if (open < .02) {
        _cherry(canvas, hc, cr, 1, enter);
      } else {
        // pulp
        canvas.drawOval(Rect.fromCenter(center: hc, width: cr * 1.5 + gap, height: cr * 1.9),
            Paint()..color = const Color(0xFFE9B7A0).withValues(alpha: skinA));
        // two halves of skin
        for (final side in [-1, 1]) {
          canvas.save();
          canvas.translate(hc.dx + side * gap * .9, hc.dy + open * R * .15);
          canvas.rotate(side * open * .5);
          final path = Path()
            ..moveTo(0, -cr)
            ..cubicTo(side * cr * 1.15, -cr * .9, side * cr * 1.15, cr * .9, 0, cr)
            ..cubicTo(side * cr * .25, cr * .4, side * cr * .25, -cr * .4, 0, -cr);
          canvas.drawPath(path, Paint()..color = cherryColor(1).withValues(alpha: skinA));
          canvas.restore();
        }
        // two beans inside
        final b = open;
        for (final side in [-1, 1]) {
          _bean(canvas, hc + Offset(side * R * .26 * b, 0), R * .55 * b, const Color(0xFF9AAA6C).withValues(alpha: skinA + (1 - skinA) * .0), side * .08, 1);
        }
      }
    }

    // single hero bean
    if (bean > 0) {
      final single = _e(p, .77, .82);
      final col = _beanColor(proc, roast);
      final puff = 1 + .07 * math.sin(roast * math.pi) + .03 * math.sin(t * 6.28 * 3) * roast * (1 - data);
      final scale = R * 1.15 * single * puff * (1 - .18 * data);
      final rot = -.5 + proc * .3 + data * .2;
      // washing / drying
      if (proc > 0 && proc < 1) {
        for (var i = 0; i < 3; i++) {
          final f = ((t * 3 + i / 3) % 1);
          canvas.drawCircle(hc, scale * (1.0 + f * .8), Paint()..color = const Color(0xFFBFD9D2).withValues(alpha: .5 * (1 - f) * math.sin(proc * math.pi))..style = PaintingStyle.stroke..strokeWidth = 2);
        }
        for (var i = 0; i < 8; i++) {
          final f = ((t * 2 + i * .13) % 1);
          final x = hc.dx + (i - 3.5) * R * .22, y = hc.dy - R * 1.4 + f * R * 2.2;
          canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = const Color(0xFFB4D6E0).withValues(alpha: .7 * math.sin(proc * math.pi) * (1 - f)));
        }
      }
      // roast heat
      if (roast > 0 && data < 1) {
        canvas.drawCircle(hc, scale * 1.5, Paint()..color = const Color(0xFFE8803A).withValues(alpha: .18 * roast * (1 - data)));
        for (var i = 0; i < 9; i++) {
          final f = ((t * 1.5 + i * .11) % 1);
          final dx = math.sin(f * 7 + i) * R * .16;
          canvas.drawCircle(hc + Offset((i - 4) * R * .18 + dx, -scale * .9 - f * R * 1.3), 4 + f * 9,
              Paint()..color = Colors.white.withValues(alpha: .16 * (1 - f) * roast * (1 - data)));
        }
      }
      _bean(canvas, hc, scale, col.withValues(alpha: 1 - data * .55), rot, 1, crack: roast > .35 ? (roast - .35) / .65 : 0, glow: roast * (1 - data));
    }

    if (data > 0) _dataNetwork(canvas, hc, R, data);
  }

  Color _beanColor(double proc, double roast) {
    var c = Color.lerp(const Color(0xFF8FA06A), const Color(0xFFC1B68A), proc)!;
    if (roast < .3) return Color.lerp(c, const Color(0xFFB88B4A), roast / .3)!;
    if (roast < .65) return Color.lerp(const Color(0xFFB88B4A), const Color(0xFF7A4A28), (roast - .3) / .35)!;
    return Color.lerp(const Color(0xFF7A4A28), const Color(0xFF2E1A12), (roast - .65) / .35)!;
  }

  void _bean(Canvas c, Offset o, double r, Color col, double rot, double a, {double crack = 0, double glow = 0}) {
    if (r < 1) return;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 2.0);
    c.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-.35, -.4), radius: 1.0, colors: [
            Color.lerp(col, Colors.white, .28)!.withValues(alpha: col.a),
            col,
            Color.lerp(col, Colors.black, .45)!.withValues(alpha: col.a)
          ], stops: const [0, .55, 1])
              .createShader(rect));
    // central groove
    final groove = Path()
      ..moveTo(0, -r * .96)
      ..cubicTo(r * .28, -r * .45, -r * .3, r * .35, 0, r * .96);
    c.drawPath(groove, Paint()..color = Colors.black.withValues(alpha: .55 * col.a)..style = PaintingStyle.stroke..strokeWidth = r * .07..strokeCap = StrokeCap.round);
    if (crack > 0) {
      c.drawPath(groove, Paint()..color = const Color(0xFFFFB35A).withValues(alpha: .7 * crack * col.a)..style = PaintingStyle.stroke..strokeWidth = r * .025);
    }
    if (glow > 0) {
      c.drawOval(rect.inflate(2), Paint()..color = const Color(0xFFE8803A).withValues(alpha: .35 * glow)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    c.restore();
  }

  void _dataNetwork(Canvas c, Offset hc, double R, double e) {
    const n = 16;
    final rot = t * 2 * math.pi * .25;
    final ring = Paint()
      ..color = CI.gold.withValues(alpha: .5 * e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var k = 1; k <= 3; k++) {
      final rr = R * (1.1 + k * .55) * e;
      for (var d = 0.0; d < 6.28; d += .25) {
        c.drawArc(Rect.fromCircle(center: hc, radius: rr), d + rot * (k.isEven ? -1 : 1), .12, false, ring);
      }
    }
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final ring = 1 + (i % 3);
      final a = i * 2 * math.pi / n + rot * (ring.isEven ? -1 : 1);
      pts.add(hc + Offset(math.cos(a), math.sin(a)) * R * (1.1 + ring * .55) * e);
    }
    for (var i = 0; i < n; i++) {
      c.drawLine(hc, pts[i], Paint()..color = (dark ? CI.cream : CI.gold).withValues(alpha: .22 * e)..strokeWidth = 1);
      if (i % 3 == 0) c.drawLine(pts[i], pts[(i + 3) % n], Paint()..color = CI.gold.withValues(alpha: .25 * e)..strokeWidth = 1);
      // pulses travelling toward the centre
      final f = (t * 2 + i / n) % 1;
      c.drawCircle(Offset.lerp(pts[i], hc, f)!, 2.6, Paint()..color = CI.gold.withValues(alpha: e * (1 - f)));
      final big = i % 4 == 0;
      c.drawCircle(pts[i], (big ? 6 : 3.6) * e, Paint()..color = (big ? CI.leaf : CI.gold).withValues(alpha: e));
      c.drawCircle(pts[i], (big ? 6 : 3.6) * e, Paint()..color = Colors.white.withValues(alpha: .7 * e)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    // mini bars inside bean ("the bean is data now")
    final bars = [.4, .7, .5, .9, .65];
    for (var i = 0; i < bars.length; i++) {
      final bx = hc.dx + (i - 2) * R * .16;
      final bh = R * .7 * bars[i] * e * (.85 + .15 * math.sin(t * 6.28 + i));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx - R * .05, hc.dy + R * .35 - bh, R * .1, bh), const Radius.circular(3)),
          Paint()..color = CI.cream.withValues(alpha: .9 * e));
    }
  }

  @override
  bool shouldRepaint(CoffeePlantPainter o) => o.p != p || o.t != t || o.dark != dark;
}
