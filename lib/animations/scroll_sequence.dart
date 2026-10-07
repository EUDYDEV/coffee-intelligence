import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Description of a frame sequence (assets/sequence/manifest.json).
/// Optional "lite" block = smaller frames used on phones (less memory, faster loading).
class SequenceManifest {
  final String pattern;
  final int frames;
  final double aspect;
  final List<double> chapters;
  final bool lite;
  const SequenceManifest(this.pattern, this.frames, this.aspect, this.chapters, this.lite);

  /// Returns null when no media has been delivered yet → the caller falls back to the vector scene.
  static Future<SequenceManifest?> load({bool mobile = false}) async {
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/sequence/manifest.json')) as Map<String, dynamic>;
      final l = mobile ? j['lite'] as Map<String, dynamic>? : null;
      return SequenceManifest(
        (l?['pattern'] ?? j['pattern']) as String,
        (l?['frames'] ?? j['frames']) as int,
        (j['aspect'] as num?)?.toDouble() ?? 16 / 9,
        [for (final c in (j['chapters'] as List? ?? const [])) (c as num).toDouble()],
        l != null,
      );
    } catch (_) {
      return null;
    }
  }

  String frame(int i) {
    final n = (i.clamp(1, frames)).toString().padLeft(4, '0');
    return pattern.replaceAll('%04d', n);
  }
}

/// Scroll-scrubbed cinematic player: cross-fades adjacent frames, covers the viewport,
/// adds a slow push-in, vignette and film grain for a filmic grade.
/// Memory: only a sliding window of frames is kept decoded (decoded at screen size, not full size).
class ScrollSequence extends StatefulWidget {
  final SequenceManifest manifest;
  final double progress; // 0..1
  final double ambient; // free-running clock 0..1 (grain / dust)
  const ScrollSequence({super.key, required this.manifest, required this.progress, required this.ambient});
  @override
  State<ScrollSequence> createState() => _ScrollSequenceState();
}

class _ScrollSequenceState extends State<ScrollSequence> {
  final Set<int> _requested = {};
  static const _behind = 2, _ahead = 8;

  ImageProvider _provider(int i, int width) => ResizeImage(AssetImage(widget.manifest.frame(i)), width: width, allowUpscaling: false);

  int get _width {
    final w = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return w.clamp(480, widget.manifest.lite ? 960 : 1600).round();
  }

  void _window(int center) {
    final m = widget.manifest;
    final w = _width;
    for (var i = center - _behind; i <= center + _ahead; i++) {
      final k = i.clamp(1, m.frames);
      if (_requested.add(k)) {
        precacheImage(_provider(k, w), context).catchError((_) {});
      }
    }
    // free frames far outside the window
    final far = _requested.where((k) => k < center - _behind - 6 || k > center + _ahead + 6).toList();
    for (final k in far) {
      PaintingBinding.instance.imageCache.evict(_provider(k, w));
      _requested.remove(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.manifest;
    final pos = widget.progress.clamp(0.0, 1.0) * (m.frames - 1) + 1;
    final a = pos.floor(), b = math.min(a + 1, m.frames);
    final t = pos - a;
    _window(a);
    final w = _width;
    Widget img(int i, double o) => Opacity(
          opacity: o,
          child: Image(image: _provider(i, w), fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium, errorBuilder: (_, __, ___) => const SizedBox()),
        );
    final push = 1.0 + .06 * widget.progress;
    return Stack(fit: StackFit.expand, children: [
      Transform.scale(scale: push, child: Stack(fit: StackFit.expand, children: [img(a, 1), if (t > .02 && b != a) img(b, t)])),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(radius: 1.05, colors: [Colors.transparent, Colors.black.withValues(alpha: .55)], stops: const [.55, 1]),
        ),
      ),
      CustomPaint(painter: _GrainPainter(widget.ambient)),
    ]);
  }
}

class _GrainPainter extends CustomPainter {
  final double t;
  _GrainPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random((t * 24).floor());
    final p = Paint();
    for (var i = 0; i < 160; i++) {
      p.color = Colors.white.withValues(alpha: .03 + r.nextDouble() * .05);
      canvas.drawCircle(Offset(r.nextDouble() * s.width, r.nextDouble() * s.height), .6 + r.nextDouble() * .8, p);
    }
    final d = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = (d.nextDouble() + t * (.05 + d.nextDouble() * .08)) % 1 * s.width;
      final y = (d.nextDouble() - t * (.04 + d.nextDouble() * .06)) % 1 * s.height;
      canvas.drawCircle(Offset(x, y), 2 + d.nextDouble() * 5, Paint()..color = const Color(0xFFFFE9B8).withValues(alpha: .05 + d.nextDouble() * .07));
    }
  }

  @override
  bool shouldRepaint(_GrainPainter o) => o.t != t;
}
