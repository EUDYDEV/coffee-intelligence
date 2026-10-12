import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/role_data.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../../widgets/secret_tap.dart';
import 'account_widgets.dart';

/// Entrance of the platform. Two kinds of users:
/// - public users register (or sign in) and use the public space;
/// - partner organisations sign in to their private spaces (cooperative / farmer, exporter, roaster, NGO, national board).
/// Front-end demo: accounts are stored on this device / browser, credentials are not checked.
class VisitorGate extends StatefulWidget {
  const VisitorGate({super.key});
  @override
  State<VisitorGate> createState() => _VisitorGateState();
}

class _VisitorGateState extends State<VisitorGate> {
  late String _tab = context.app.gatePartnerTab ? 'partner' : 'public';

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
        bullet(Icons.person_rounded, 'gate_b2'),
        bullet(Icons.handshake_rounded, 'gate_b5'),
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
                Segmented<String>(
                  values: const ['public', 'partner'],
                  selected: _tab,
                  label: (v) => context.tr(v == 'public' ? 'gate_tab_public' : 'gate_tab_partner'),
                  onChanged: (v) => setState(() => _tab = v),
                ),
                const SizedBox(height: 16),
                if (_tab == 'public') ...[
                  Text(context.tr('gate_card_title'), style: TS.h2(p)),
                  const SizedBox(height: 4),
                  Text(context.tr('gate_card_sub'), style: TS.bodyS(p)),
                  const SizedBox(height: 16),
                  AuthPanel(onAuthed: app.enterAfterAuth),
                ] else
                  const PartnerLoginPanel(),
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

/// Partner sign-in (cooperatives / farmers, exporters, roasters, NGOs, national board). Demo: always accepted.
class PartnerLoginPanel extends StatefulWidget {
  const PartnerLoginPanel({super.key});
  @override
  State<PartnerLoginPanel> createState() => _PartnerLoginPanelState();
}

class _PartnerLoginPanelState extends State<PartnerLoginPanel> {
  final _org = TextEditingController(), _id = TextEditingController(), _pw = TextEditingController();

  @override
  void dispose() {
    _org.dispose();
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.tr('partner_title'), style: TS.h2(p)),
      const SizedBox(height: 4),
      Text(context.tr('partner_sub'), style: TS.bodyS(p)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final r in partnerRoles) Chip2(context.tr(r.nameKey), r.color, icon: r.icon)]),
      const SizedBox(height: 16),
      TextField(controller: _org, textCapitalization: TextCapitalization.words, decoration: _dec(context.tr('partner_org'), Icons.apartment_rounded)),
      const SizedBox(height: 12),
      TextField(controller: _id, decoration: _dec(context.tr('partner_id'), Icons.badge_outlined)),
      const SizedBox(height: 12),
      TextField(controller: _pw, obscureText: true, onSubmitted: (_) => app.loginPartner(_org.text, _id.text), decoration: _dec(context.tr('acc_password'), Icons.lock_outline_rounded)),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: PrimaryButton(context.tr('partner_btn'), icon: Icons.handshake_rounded, onTap: () => app.loginPartner(_org.text, _id.text))),
      const SizedBox(height: 12),
      const DemoNotice('partner_demo_note'),
    ]);
  }
}
