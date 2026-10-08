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

/// Scroll-scrubbed player: cross-fades adjacent frames and covers the viewport (no stretching, no grading of the footage).
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
  final Set<int> _loaded = {}; // decoded frames (used to show the nearest ready frame while others load)
  int _center = 1;
  static const _behind = 2, _ahead = 8;

  ImageProvider _provider(int i, int width) => ResizeImage(AssetImage(widget.manifest.frame(i)), width: width, allowUpscaling: false);

  int get _width {
    final w = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return w.clamp(480, widget.manifest.lite ? 960 : 1600).round();
  }

  /// Closest frame that is already decoded (never leaves the screen empty during fast scrolls).
  int _ready(int i) {
    if (_loaded.isEmpty || _loaded.contains(i)) return i;
    for (var d = 1; d < widget.manifest.frames; d++) {
      if (_loaded.contains(i - d)) return i - d;
      if (_loaded.contains(i + d)) return i + d;
    }
    return i;
  }

  void _window(int center) {
    _center = center;
    final m = widget.manifest;
    final w = _width;
    for (var i = center - _behind; i <= center + _ahead; i++) {
      final k = i.clamp(1, m.frames);
      if (_requested.add(k)) {
        precacheImage(_provider(k, w), context).then((_) {
          if (!mounted) return;
          _loaded.add(k);
          if ((k - _center).abs() <= 2) setState(() {});
        }).catchError((_) {});
      }
    }
    // free frames far outside the window
    final far = _requested.where((k) => k < center - _behind - 6 || k > center + _ahead + 6).toList();
    for (final k in far) {
      PaintingBinding.instance.imageCache.evict(_provider(k, w));
      _requested.remove(k);
      _loaded.remove(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.manifest;
    final pos = widget.progress.clamp(0.0, 1.0) * (m.frames - 1) + 1;
    final a0 = pos.floor(), b0 = math.min(a0 + 1, m.frames);
    var t = pos - a0;
    _window(a0);
    final a = _ready(a0), b = _loaded.contains(b0) ? b0 : a;
    if (b == a) t = 0;
    final w = _width;
    Widget img(int i, double o) => Opacity(
          opacity: o,
          child: Image(image: _provider(i, w), fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium, errorBuilder: (_, __, ___) => const SizedBox()),
        );
    // Full-bleed: BoxFit.cover fills the screen without stretching the footage (only the edges are cropped).
    final footage = Stack(fit: StackFit.expand, children: [img(a, 1), if (t > .02 && b != a) img(b, t)]);
    return Stack(fit: StackFit.expand, children: [
      footage,
      // light scrims only where the header / captions sit, so the footage stays bright
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .22, .6, 1], colors: [Color(0x59000000), Color(0x00000000), Color(0x00000000), Color(0x73000000)]),
        ),
      ),
    ]);
  }
}
