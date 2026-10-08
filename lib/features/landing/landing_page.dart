import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../animations/coffee_plant_painter.dart';
import '../../animations/flows.dart';
import '../../animations/scroll_sequence.dart';
import '../../core/theme/app_theme.dart' show buildTheme;
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../widgets/chain_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../../widgets/secret_tap.dart';
import '../shell/top_controls.dart';

double _e(double p, double a, double b) {
  final t = ((p - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Alpha window: fades in over [a, a+f], out over [b-f, b].
double _win(double g, double a, double b, {double f = .02, bool holdEnd = false}) {
  final i = _e(g, a, a + f);
  final o = holdEnd ? 1.0 : 1 - _e(g, b - f, b);
  return math.min(i, o);
}

/// Scroll-driven story: seed → plant → cherry → bean → roast → data → indicators → decision.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  final ScrollController _sc = ScrollController();
  late final AnimationController _amb = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  bool _init = false;
  SequenceManifest? _seq; // cinematic frames, when delivered in assets/sequence/
  static const screens = 11.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      if (!context.calm) _amb.repeat();
      SequenceManifest.load(mobile: context.isMobile).then((m) {
        if (mounted && m != null) setState(() => _seq = m);
      });
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    _amb.dispose();
    super.dispose();
  }

  double get _g {
    if (_sc.positions.length != 1 || !_sc.position.hasContentDimensions) return 0;
    final mx = _sc.position.maxScrollExtent;
    return mx <= 0 ? 0 : (_sc.offset / mx).clamp(0.0, 1.0);
  }

  void _scrollTo(double g) {
    if (!_sc.hasClients) return;
    _sc.animateTo(_sc.position.maxScrollExtent * g, duration: const Duration(milliseconds: 900), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    // Footage is portrait: shown on phones only; larger screens keep the drawn plant animation.
    final seq = context.isMobile ? _seq : null;
    Widget page(BuildContext context) => _page(context, h, seq);
    return Theme(data: seq == null ? Theme.of(context) : buildTheme(Brightness.dark), child: Builder(builder: page));
  }

  Widget _page(BuildContext context, double h, SequenceManifest? seq) {
    final p = context.pal;
    return Material(
      type: MaterialType.transparency,
      child: Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.dark ? [const Color(0xFF120A07), const Color(0xFF2A1810)] : [CI.offWhite, CI.cream])),
      child: Stack(children: [
        // scroll driver (invisible content, real scroll physics)
        Positioned.fill(
          child: SingleChildScrollView(controller: _sc, child: SizedBox(height: h * screens, width: double.infinity)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_sc, _amb]),
              builder: (_, __) => _Stage(g: _g, t: _amb.value, seq: seq),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(bottom: false, child: _TopBar(onEnter: () => context.app.enter()))),
        // final call-to-action layer (interactive) fades in with progress
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _sc,
            builder: (_, __) {
              final a = _e(_g, .955, .985);
              return IgnorePointer(
                ignoring: a < .5,
                child: Opacity(opacity: a, child: _FinalCta(onEnter: () => context.app.enter())),
              );
            },
          ),
        ),
        // scroll hint + chapter rail
        Positioned(
          right: context.isMobile ? 8 : 22,
          top: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _sc,
            builder: (_, __) => _Rail(g: _g, onJump: _scrollTo),
          ),
        ),
      ]),
    ));
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onEnter;
  const _TopBar({required this.onEnter});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.isMobile ? 14 : 28, vertical: 12),
      child: Row(children: [
        SecretTap(onTriple: context.app.openLogin, child: OrgLogo(height: context.isMobile ? 32 : 46, emblem: context.isMobile)),
        const SizedBox(width: 12),
        if (!context.isMobile)
          Text(context.tr('org_name').toUpperCase(), style: TextStyle(fontFamily: TS.display, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: p.text, fontSize: 14)),
        const Spacer(),
        const LangToggle(),
        const SizedBox(width: 8),
        const CurrencyPicker(compact: true),
        const SizedBox(width: 8),
        const ThemeToggle(),
        const SizedBox(width: 8),
        if (!context.isMobile) PrimaryButton(context.tr('enter_platform'), icon: Icons.arrow_forward_rounded, onTap: onEnter),
        if (context.isMobile)
          IconButton(onPressed: onEnter, icon: Icon(Icons.arrow_forward_rounded, color: p.accent)),
      ]),
    );
  }
}

class _Rail extends StatelessWidget {
  final double g;
  final ValueChanged<double> onJump;
  const _Rail({required this.g, required this.onJump});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final marks = <double>[0, .1, .2, .3, .4, .5, .6, .7, .8, .9, 1.0];
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final m in marks)
          GestureDetector(
            onTap: () => onJump(m),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 7,
                height: (g - m).abs() < .05 ? 22 : 7,
                decoration: BoxDecoration(color: g >= m - .001 ? p.gold : p.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _FinalCta extends StatelessWidget {
  final VoidCallback onEnter;
  const _FinalCta({required this.onEnter});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.isMobile ? 40 : 56),
        child: Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
          PrimaryButton(context.tr('enter_platform'), icon: Icons.dashboard_rounded, onTap: onEnter),
          PrimaryButton(context.tr('presentation_mode'), icon: Icons.slideshow_rounded, outlined: true, onTap: () => context.app.setPresentation(true)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Stage extends StatelessWidget {
  final double g, t;
  final SequenceManifest? seq;
  const _Stage({required this.g, required this.t, this.seq});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final size = MediaQuery.sizeOf(context);
    final mobile = context.isMobile;
    final plantProg = (g / .5).clamp(0.0, 1.0);
    final plantAlpha = 1 - _e(g, .5, .535);
    var stage = plantStage(plantProg);
    final ch = seq?.chapters ?? const <double>[];
    if (ch.length == 13) {
      stage = 0;
      for (var i = 0; i < 13; i++) {
        if (plantProg >= ch[i]) stage = i;
      }
    }

    return Stack(children: [
      // soft light
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(0, .1), radius: .9, colors: [
            p.gold.withValues(alpha: p.dark ? .10 : .16),
            Colors.transparent
          ])),
        ),
      ),
      // cinematic footage (scroll = camera) replaces the vector plant when available
      if (seq != null && plantAlpha > 0)
        Positioned.fill(child: Opacity(opacity: plantAlpha, child: ScrollSequence(manifest: seq!, progress: plantProg, ambient: t))),
      // vector fallback
      if (seq == null && plantAlpha > 0)
        Positioned.fill(
          top: mobile ? 40 : 20,
          child: Opacity(
            opacity: plantAlpha,
            child: CustomPaint(painter: CoffeePlantPainter(p: plantProg, t: t, dark: p.dark, light: mobile)),
          ),
        ),
      // final: data network fades in behind the closing title
      if (g > .93)
        Positioned.fill(
          top: 20,
          child: Opacity(
            opacity: _e(g, .935, .965) * .55,
            child: CustomPaint(painter: CoffeePlantPainter(p: 1, t: t, dark: p.dark, light: mobile)),
          ),
        ),
      // hero title (start)
      Positioned(
        top: size.height * (mobile ? .13 : .14),
        left: 0,
        right: 0,
        child: Opacity(
          opacity: 1 - _e(g, .01, .05),
          child: Transform.translate(
            offset: Offset(0, -_e(g, 0, .05) * 40),
            child: Column(children: [
              Text(context.tr('org_acronym'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: TS.display, fontSize: mobile ? 64 : 110, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: mobile ? 6 : 12, color: p.text)),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 24 : 0),
                child: Text(context.tr('org_full').toUpperCase(), textAlign: TextAlign.center, style: TS.label(p).copyWith(fontSize: mobile ? 11 : 14, letterSpacing: 3, color: p.gold)),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 28 : 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(context.tr('hero_sub'), textAlign: TextAlign.center, style: TS.bodyS(p).copyWith(fontSize: mobile ? 14 : 17, height: 1.5)),
                ),
              ),
            ]),
          ),
        ),
      ),
      // scroll hint
      Positioned(
        bottom: 28,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: 1 - _e(g, .005, .03),
          child: Column(children: [
            Text(context.tr('scroll_hint').toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 6),
            Transform.translate(offset: Offset(0, math.sin(t * 6.28 * 2) * 5), child: Icon(Icons.keyboard_arrow_down_rounded, color: p.gold, size: 30)),
          ]),
        ),
      ),
      // plant chapter caption
      if (g > .02 && g < .52) _Caption(index: stage + 1, total: 13, titleKey: 'stage_${stage + 1}_t', descKey: 'stage_${stage + 1}_d', onVideo: seq != null, alpha: _e(g, .02, .05) * plantAlpha),
      // scenes
      _scene(context, .50, .64, 'scene_chain', _chain(context)),
      _scene(context, .64, .78, 'scene_data', _data(context)),
      _scene(context, .78, .89, 'scene_kpi', _kpis(context)),
      _scene(context, .89, .955, 'scene_decide', _decide(context)),
      // final title
      Positioned.fill(
        child: Opacity(
          opacity: _e(g, .95, .975),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, -size.height * .08),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(context.tr('final_kicker').toUpperCase(), style: TS.label(p).copyWith(color: p.gold, letterSpacing: 3)),
                const SizedBox(height: 14),
                Text(context.tr('final_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: TS.display, fontSize: mobile ? 38 : 72, fontWeight: FontWeight.w800, height: 1.02, color: p.text, shadows: [Shadow(color: p.gold.withValues(alpha: .5), blurRadius: 30)])),
                const SizedBox(height: 18),
                Text('${context.tr('chain_producer')} → ${context.tr('final_data')} → ${context.tr('final_decision')}', style: TS.bodyS(p).copyWith(fontSize: 15)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _scene(BuildContext context, double a, double b, String key, Widget child) {
    final alpha = _win(g, a, b, f: .025, holdEnd: false);
    if (alpha <= 0) return const SizedBox();
    final p = context.pal;
    final mobile = context.isMobile;
    return Positioned.fill(
      child: Opacity(
        opacity: alpha,
        child: Transform.translate(
          offset: Offset(0, (1 - alpha) * 30),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(mobile ? 18 : 60, 70, mobile ? 30 : 80, 30),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(context.tr('${key}_t'), textAlign: TextAlign.center, style: TS.h1(p).copyWith(fontSize: mobile ? 26 : 40)),
                const SizedBox(height: 8),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Text(context.tr('${key}_d'), textAlign: TextAlign.center, style: TS.bodyS(p).copyWith(fontSize: mobile ? 13 : 15.5))),
                SizedBox(height: mobile ? 22 : 38),
                Flexible(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: child)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chain(BuildContext context) {
    final steps = repo.chain();
    final k = _e(g, .515, .625);
    final idx = (k * steps.length).floor().clamp(0, steps.length - 1);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Flexible(child: ChainPhoto(steps[idx].id, height: context.isMobile ? 190 : 300)),
      const SizedBox(height: 16),
      ChainFlow(steps: steps, selected: steps[idx].id, progress: 1, compact: true),
    ]);
  }

  Widget _data(BuildContext context) =>
      DataConvergence(progress: _e(g, .655, .765), height: context.isMobile ? 420 : 400);

  Widget _kpis(BuildContext context) {
    final p = context.pal;
    final k = _e(g, .785, .85);
    final items = [
      ('kpi_prod', repo.africaProduction(), 0, 'kt', Icons.spa_rounded),
      ('kpi_price', repo.series('arabica').last.v, 2, '\$/lb', Icons.show_chart_rounded),
      ('kpi_income', repo.africaIncome(), 0, '\$', Icons.payments_rounded),
      ('kpi_exports', repo.africaExports(), 0, 'kt', Icons.directions_boat_rounded),
    ];
    final vals = repo.series('arabica').map((e) => e.v).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Grid(columns: context.isMobile ? 2 : 4, gap: 12, children: [
        for (var i = 0; i < items.length; i++)
          Opacity(
            opacity: _e(k, i * .12, i * .12 + .4),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(items[i].$5, color: p.accent, size: 18),
                const SizedBox(height: 8),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${Fmt.num((items[i].$4.startsWith(r'$') ? Fmt.conv(items[i].$2) : items[i].$2) * Curves.easeOutExpo.transform(_e(k, i * .1, 1)), items[i].$4.startsWith(r'$') ? Fmt.decFor(items[i].$3) : items[i].$3)} ${Fmt.unit(items[i].$4)}', style: TS.big(p, size: 26))),
                const SizedBox(height: 4),
                Text(context.tr(items[i].$1).toUpperCase(), style: TS.label(p), maxLines: 2),
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 16),
      Opacity(
        opacity: _e(g, .83, .86),
        child: GlassCard(
          child: SizedBox(height: context.isMobile ? 90 : 120, width: double.infinity, child: CustomPaint(painter: _BigLine(vals, _e(g, .835, .885), p.accent, p.gold))),
        ),
      ),
    ]);
  }

  Widget _decide(BuildContext context) {
    final p = context.pal;
    final cards = [
      (Icons.radar_rounded, 'decide_1'),
      (Icons.science_rounded, 'decide_2'),
      (Icons.verified_rounded, 'decide_3'),
    ];
    return Grid(columns: context.isMobile ? 1 : 3, gap: 12, children: [
      for (var i = 0; i < cards.length; i++)
        Opacity(
          opacity: _e(g, .895 + i * .01, .91 + i * .012),
          child: GlassCard(
            accent: p.green,
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: p.green.withValues(alpha: .15), shape: BoxShape.circle), child: Icon(cards[i].$1, color: p.green)),
              const SizedBox(width: 12),
              Expanded(child: Text(context.tr(cards[i].$2), style: TS.h3(p))),
            ]),
          ),
        ),
    ]);
  }
}

class _Caption extends StatelessWidget {
  final int index, total;
  final String titleKey, descKey;
  final double alpha;
  final bool onVideo; // white text with a shadow over the footage
  const _Caption({required this.index, required this.total, required this.titleKey, required this.descKey, required this.alpha, this.onVideo = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final mobile = context.isMobile;
    final num = index.toString().padLeft(2, '0');
    final body = Column(crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('$num / $total', style: TextStyle(fontFamily: TS.display, fontSize: mobile ? 14 : 18, color: p.gold, letterSpacing: 3, fontWeight: FontWeight.w700, shadows: onVideo ? const [Shadow(color: Color(0xCC000000), blurRadius: 14), Shadow(color: Color(0x99000000), blurRadius: 3)] : null)),
      const SizedBox(height: 6),
      AnimatedSwitcher(
        duration: context.dur(350),
        child: Column(
          key: ValueKey(titleKey),
          crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(context.tr(titleKey), textAlign: mobile ? TextAlign.center : TextAlign.left, style: TS.h1(p).copyWith(fontSize: mobile ? 26 : 44, color: onVideo ? Colors.white : null, shadows: onVideo ? const [Shadow(color: Color(0xCC000000), blurRadius: 14), Shadow(color: Color(0x99000000), blurRadius: 3)] : null)),
            const SizedBox(height: 8),
            ConstrainedBox(
                constraints: BoxConstraints(maxWidth: mobile ? 320 : 380),
                child: Text(context.tr(descKey), textAlign: mobile ? TextAlign.center : TextAlign.left, style: TS.bodyS(p).copyWith(fontSize: mobile ? 13 : 15, height: 1.5, color: onVideo ? Colors.white.withValues(alpha: .92) : null, shadows: onVideo ? const [Shadow(color: Color(0xCC000000), blurRadius: 14), Shadow(color: Color(0x99000000), blurRadius: 3)] : null))),
          ],
        ),
      ),
    ]);
    return Positioned(
      left: mobile ? 0 : 64,
      right: mobile ? 0 : null,
      top: mobile ? null : 150,
      bottom: mobile ? 36 : null,
      child: Opacity(opacity: alpha, child: body),
    );
  }
}

class _BigLine extends CustomPainter {
  final List<double> v;
  final double t;
  final Color c1, c2;
  _BigLine(this.v, this.t, this.c1, this.c2);
  @override
  void paint(Canvas canvas, Size s) {
    final mn = v.reduce(math.min), mx = v.reduce(math.max);
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = s.width * i / (v.length - 1);
      final y = s.height - (v[i] - mn) / (mx - mn) * (s.height - 10) - 5;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final m = path.computeMetrics().first;
    final part = m.extractPath(0, m.length * t);
    final tip = m.getTangentForOffset(m.length * t)?.position ?? Offset.zero;
    final fill = Path.from(part)
      ..lineTo(tip.dx, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c1.withValues(alpha: .3), c1.withValues(alpha: 0)]).createShader(Offset.zero & s));
    canvas.drawPath(part, Paint()..color = c1..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    if (t > 0 && t < 1) {
      canvas.drawCircle(tip, 6, Paint()..color = c2);
      canvas.drawCircle(tip, 12, Paint()..color = c2.withValues(alpha: .25));
    }
  }

  @override
  bool shouldRepaint(_BigLine o) => o.t != t;
}
