import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/account_data.dart';
import '../../widgets/common.dart';
import 'account_widgets.dart';

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Visitor account + subscription (front-end demo: local storage, simulated payment).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _subscribe(BuildContext context) async {
    await showDialog<void>(context: context, builder: (_) => const _SubscribeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final me = app.me;
    final wide = context.w >= 1000;

    final plansBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionLabel(context.tr('acc_plans')),
      PlanPicker(
        currentPlan: me?.hasActivePlan == true ? me!.plan : 'free',
        onSelect: (id, cycle) {
          if (me == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('pw_signin_first'))));
          } else {
            _subscribe(context);
          }
        },
      ),
      const SizedBox(height: 14),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('acc_one_off_title'), style: TS.h3(p)),
          const SizedBox(height: 6),
          Text(context.tr('acc_one_off_d'), style: TS.bodyS(p)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip2('PNG · ${Fmt.usd(itemPriceUsd('png'), 2)}', p.accent),
            Chip2('CSV · ${Fmt.usd(itemPriceUsd('csv'), 2)}', p.accent),
            Chip2('PDF · ${Fmt.usd(itemPriceUsd('pdf'), 2)}', p.accent),
            Chip2('${context.tr('pw_report')} · ${Fmt.usd(itemPriceUsd('report'), 2)}', p.gold),
          ]),
        ]),
      ),
    ]);

    if (me == null) {
      // only reachable by the demo administrator (visitors sign in at the entrance)
      final note = GlassCard(
        accent: p.gold,
        child: Row(children: [
          Icon(Icons.admin_panel_settings_rounded, color: p.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(context.tr(app.admin ? 'acc_admin_note' : 'acc_welcome_d'), style: TS.bodyS(p).copyWith(color: p.text))),
        ]),
      );
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeader('acc_title', 'acc_sub', exportId: ''),
        note,
        if (!app.admin) ...[const SizedBox(height: 16), GlassCard(child: AuthPanel(onAuthed: () {}))],
        const SizedBox(height: 22),
        plansBlock,
      ]);
    }

    final plan = planById(me.plan);
    final active = me.hasActivePlan;
    final profile = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 26, backgroundColor: p.accent.withValues(alpha: .18), child: Text(me.fullName.isEmpty ? '?' : me.fullName[0].toUpperCase(), style: TS.h2(p).copyWith(color: p.accent))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(me.fullName, style: TS.h2(p)), Text('@${me.username}', style: TS.bodyS(p))])),
          Chip2(context.tr(me.verified ? 'acc_verified' : 'acc_unverified'), me.verified ? p.green : p.warn, icon: Icons.verified_rounded),
        ]),
        const Divider(height: 26),
        _kv(context, Icons.mail_outline_rounded, context.tr('acc_email'), me.email),
        _kv(context, Icons.public_rounded, context.tr('acc_country'), '${context.tr('mc_${me.country}')}${me.city.isEmpty ? '' : ' · ${me.city}'}'),
        if (me.address.isNotEmpty) _kv(context, Icons.home_outlined, context.tr('acc_address'), me.address),
        _kv(context, Icons.cake_outlined, context.tr('acc_birth'), _date(me.birth)),
        _kv(context, Icons.person_outline_rounded, context.tr('acc_gender'), context.tr('gender_${me.gender}')),
        _kv(context, Icons.event_available_rounded, context.tr('acc_since'), _date(me.created)),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: PrimaryButton(context.tr('acc_logout'), icon: Icons.logout_rounded, outlined: true, onTap: app.logoutVisitor)),
      ]),
    );
    final status = GlassCard(
      accent: active ? p.green : p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(active ? Icons.workspace_premium_rounded : Icons.lock_rounded, color: active ? p.green : p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(active ? plan.nameKey : 'plan_free'), style: TS.h2(p))),
          Chip2(context.tr(active ? 'acc_active' : 'acc_inactive'), active ? p.green : p.warn),
        ]),
        const SizedBox(height: 8),
        Text(active ? context.tr('acc_valid_until', [_date(me.planUntil!)]) : context.tr('acc_no_plan_d'), style: TS.bodyS(p)),
        const SizedBox(height: 12),
        PrimaryButton(context.tr(active ? 'plan_change' : 'plan_subscribe_now'), icon: Icons.workspace_premium_rounded, onTap: () => _subscribe(context)),
      ]),
    );
    final history = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('acc_history')),
        if (me.purchases.isEmpty) Text(context.tr('acc_no_history'), style: TS.bodyS(p)),
        for (final x in me.purchases)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(x.kind == 'plan' ? Icons.workspace_premium_rounded : Icons.download_done_rounded, size: 18, color: p.accent),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(purchaseLabel(context, x), style: TS.h3(p).copyWith(fontSize: 13.5)), Text('${_date(x.date)} · ${context.tr('pm_${x.method}')} · ${context.tr('pay_simulated')}', style: TS.bodyS(p).copyWith(fontSize: 11))])),
              Text(Fmt.usd(x.amountUsd, 2), style: TS.h3(p)),
            ]),
          ),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('acc_title', 'acc_sub', exportId: ''),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: profile),
          const SizedBox(width: 20),
          Expanded(flex: 6, child: Column(children: [status, const SizedBox(height: 16), history])),
        ])
      else ...[profile, const SizedBox(height: 16), status, const SizedBox(height: 16), history],
      const SizedBox(height: 24),
      plansBlock,
    ]);
  }

  Widget _kv(BuildContext context, IconData i, String k, String v) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, size: 16, color: p.muted),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: Text(k, style: TS.bodyS(p))),
        Expanded(child: Text(v, style: TS.bodyS(p).copyWith(color: p.text, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

/// Choose a plan, then pay (simulated).
class _SubscribeDialog extends StatefulWidget {
  const _SubscribeDialog();
  @override
  State<_SubscribeDialog> createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends State<_SubscribeDialog> {
  String? _plan, _cycle;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final mobile = context.isMobile;
    final def = _plan == null ? null : planById(_plan!);
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 24, vertical: mobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 14 : 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (def != null) IconButton(onPressed: () => setState(() => _plan = null), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(child: Text(context.tr(def == null ? 'acc_plans' : 'pw_payment'), style: TS.h1(p).copyWith(fontSize: mobile ? 20 : 24))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: def == null
                    ? PlanPicker(currentPlan: app.me?.plan, onSelect: (id, c) => setState(() {
                          _plan = id;
                          _cycle = c;
                        }))
                    : PayPanel(
                        summary: '${context.tr(def.nameKey)} · ${context.tr(_cycle == 'year' ? 'cyc_year' : 'cyc_month')}',
                        amountUsd: _cycle == 'year' ? def.yearUsd : def.monthUsd,
                        onPaid: (m) {
                          final msg = ScaffoldMessenger.of(context);
                          final done = context.tr('acc_subscribed');
                          app.subscribe(def.id, _cycle!, m);
                          Navigator.pop(context);
                          msg.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(done)));
                        },
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
