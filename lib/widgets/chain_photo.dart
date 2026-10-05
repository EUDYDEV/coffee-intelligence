import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../core/theme/app_theme.dart';

/// Real photograph of a supply-chain step, with a unified warm cinematic grade,
/// slow push-in (Ken Burns) and a cross-fade when the step changes.
class ChainPhoto extends StatelessWidget {
  final String id;
  final double? height;
  final bool caption;
  const ChainPhoto(this.id, {super.key, this.height, this.caption = true});

  static Widget _img(String id, {double zoom = 1}) => Transform.scale(
      scale: zoom,
      child: Image.asset('assets/supply_chain/$id.webp', fit: BoxFit.cover, width: double.infinity, height: double.infinity, filterQuality: FilterQuality.medium, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF2B1B14))));

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: AnimatedSwitcher(
          duration: context.dur(700),
          child: KeyedSubtree(
            key: ValueKey(id),
            child: Stack(fit: StackFit.expand, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.08),
                duration: context.dur(14000),
                curve: Curves.easeOut,
                builder: (_, z, __) => _img(id, zoom: z),
              ),
              // unified grade: warm tint + vignette
              DecoratedBox(decoration: BoxDecoration(color: const Color(0xFF8A5A2B).withValues(alpha: .16), backgroundBlendMode: BlendMode.softLight)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(radius: 1.1, colors: [Colors.transparent, Colors.black.withValues(alpha: .5)], stops: const [.55, 1]),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: .75), Colors.transparent]),
                ),
              ),
              if (caption)
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(context.tr('chain_$id').toUpperCase(), style: TextStyle(color: p.gold, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.tr('chain_photo_$id'), style: const TextStyle(fontFamily: TS.display, color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.15)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
