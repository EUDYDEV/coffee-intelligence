import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../widgets/org_logo.dart';
import '../../widgets/secret_tap.dart';
import 'account_widgets.dart';

/// Entry of the platform: the visitor identifies / registers once, then chooses a profile.
/// Front-end demo: the account is stored on this device / browser only.
class VisitorGate extends StatelessWidget {
  const VisitorGate({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final wide = context.w >= 1000;

    Widget bullet(IconData i, String k) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, color: CI.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr(k), style: TextStyle(color: CI.cream.withValues(alpha: .9), fontSize: 14, height: 1.4))),
          ]),
        );

    final brand = Column(crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
      SecretTap(onTriple: app.openLogin, child: OrgLogo(height: wide ? 70 : 54)),
      const SizedBox(height: 22),
      Text(context.tr('gate_title'), textAlign: wide ? TextAlign.left : TextAlign.center, style: TextStyle(fontFamily: TS.display, color: CI.cream, fontSize: wide ? 34 : 26, fontWeight: FontWeight.w700, height: 1.15)),
      const SizedBox(height: 10),
      Text(context.tr('gate_sub'), textAlign: wide ? TextAlign.left : TextAlign.center, style: TextStyle(color: CI.cream.withValues(alpha: .75), fontSize: 14.5, height: 1.45)),
      if (wide) ...[
        const SizedBox(height: 26),
        bullet(Icons.public_rounded, 'gate_b1'),
        bullet(Icons.insights_rounded, 'gate_b2'),
        bullet(Icons.workspace_premium_rounded, 'gate_b3'),
        bullet(Icons.school_rounded, 'gate_b4'),
      ],
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: app.openLanding,
        icon: const Icon(Icons.arrow_back_rounded, color: CI.gold, size: 18),
        label: Text(context.tr('gate_back'), style: const TextStyle(color: CI.gold)),
      ),
    ]);

    final card = Material(
      color: p.surface,
      elevation: 12,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
      padding: EdgeInsets.all(context.isMobile ? 16 : 26),
      child: !app.accountsReady
          ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('gate_card_title'), style: TS.h2(p)),
              const SizedBox(height: 4),
              Text(context.tr('gate_card_sub'), style: TS.bodyS(p)),
              const SizedBox(height: 16),
              AuthPanel(onAuthed: app.enterAfterAuth),
            ]),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.espressoDeep, CI.forest])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.isMobile ? 12 : 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 4, child: Padding(padding: const EdgeInsets.only(top: 30, right: 40), child: brand)),
                        Expanded(flex: 6, child: card),
                      ])
                    : Column(children: [brand, const SizedBox(height: 16), card]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
