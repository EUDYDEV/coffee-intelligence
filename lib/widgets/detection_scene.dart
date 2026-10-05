import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/theme/palette.dart';

/// "The system has just discovered something": scan → detection → signals → impact.
class DetectionScene extends StatefulWidget {
  final String title;
  final int severity;
  final List<(String, int)> signals; // label key, direction: -1 down, 0 stable, 1 up
  final String impactKey;
  const DetectionScene({super.key, required this.title, required this.severity, required this.signals, required this.impactKey});
  @override
  State<DetectionScene> createState() => _DetectionSceneState();
}

class _DetectionSceneState extends State<DetectionScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _init = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _c.duration = context.dur(4800);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _w(double a, double b) => ((_c.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final col = p.sev(widget.severity);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final scan = _w(0, .3), found = _w(.3, .4), impact = _w(.82, 1);
        final scanning = _c.value < .3;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.dark ? const Color(0xFF1B100B) : CI.espressoDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Color.lerp(p.gold.withValues(alpha: .3), col, found)!),
            boxShadow: [BoxShadow(color: col.withValues(alpha: .25 * found), blurRadius: 24)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(
                width: 22,
                height: 22,
                child: scanning ? CircularProgressIndicator(strokeWidth: 2.4, color: p.gold) : Icon(Icons.radar_rounded, color: col, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(scanning ? context.tr('det_scanning') : context.tr('det_found').toUpperCase(),
                    style: TextStyle(color: scanning ? CI.cream.withValues(alpha: .7) : col, fontWeight: FontWeight.w800, letterSpacing: 1.6, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: scanning ? scan : 1, minHeight: 3, color: scanning ? p.gold : col, backgroundColor: Colors.white12),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < widget.signals.length; i++)
                Builder(builder: (_) {
                  final k = _w(.42 + i * .1, .5 + i * .1);
                  final s = widget.signals[i];
                  final c2 = s.$2 == 0 ? p.green : (s.$2 < 0 ? p.alert : p.warn);
                  return Opacity(
                    opacity: k,
                    child: Transform.translate(
                      offset: Offset(0, (1 - k) * 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: c2.withValues(alpha: .16), borderRadius: BorderRadius.circular(12), border: Border.all(color: c2.withValues(alpha: .6))),
                        child: Text(context.tr(s.$1), style: const TextStyle(color: CI.cream, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }),
            ]),
            const SizedBox(height: 14),
            Opacity(
              opacity: impact,
              child: Row(children: [
                Text(context.tr('det_impact').toUpperCase(), style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(value: impact * [.9, .6, .3][widget.severity], minHeight: 8, color: col, backgroundColor: Colors.white12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(context.tr(widget.impactKey), style: TextStyle(color: col, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
