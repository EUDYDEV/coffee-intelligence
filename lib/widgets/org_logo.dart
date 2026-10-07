import 'package:flutter/material.dart';
import '../core/ctx.dart';

/// Official IACO / OIAC logo. The lock-up follows the app language (EN → IACO, FR → OIAC);
/// [emblem] shows the round mark alone. Shown on a white plate so it stays readable on dark themes.
class OrgLogo extends StatelessWidget {
  final double height;
  final bool emblem;
  final bool framed;
  const OrgLogo({super.key, this.height = 44, this.emblem = false, this.framed = true});

  @override
  Widget build(BuildContext context) {
    final lang = context.app.lang;
    final asset = emblem ? 'assets/logo/emblem.png' : (lang == 'fr' ? 'assets/logo/logo_fr.png' : 'assets/logo/logo_en.png');
    final img = AnimatedSwitcher(
      duration: context.dur(300),
      child: Image.asset(asset, key: ValueKey(asset), height: height, fit: BoxFit.contain, filterQuality: FilterQuality.high),
    );
    if (!framed) return img;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: height * .22, vertical: height * .14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(height * .3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 10)]),
      child: img,
    );
  }
}
