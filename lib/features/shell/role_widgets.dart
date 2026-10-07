import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/role_data.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';

/// Profile selector: simulates the 5 user groups (and the admin once signed in).
class RoleSwitcher extends StatelessWidget {
  final bool compact;
  final bool dark; // rendered on the dark sidebar
  const RoleSwitcher({super.key, this.compact = false, this.dark = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final r = app.roleDef;
    final list = app.admin ? roles : publicRoles;
    return PopupMenuButton<String>(
      tooltip: context.tr('role_switch'),
      color: p.surface,
      onSelected: (id) => app.setRole(id),
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(context.tr('role_view_as').toUpperCase(), style: TS.label(p))),
        for (final x in list)
          PopupMenuItem(
            value: x.id,
            child: Row(children: [
              Icon(x.icon, color: x.color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr(x.nameKey), style: TextStyle(fontWeight: x.id == r.id ? FontWeight.w800 : FontWeight.w500, color: p.text))),
              if (x.id == r.id) Icon(Icons.check_rounded, size: 18, color: p.green),
            ]),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: .08) : p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: r.color.withValues(alpha: .7))),
        child: Row(mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: r.color.withValues(alpha: .25), shape: BoxShape.circle), child: Icon(r.icon, size: 16, color: dark ? CI.cream : r.color)),
          if (!compact) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(context.tr('role_profile').toUpperCase(), style: TextStyle(fontSize: 8.5, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: dark ? CI.cream.withValues(alpha: .55) : p.muted)),
                Text(context.tr(r.nameKey), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: dark ? CI.cream : p.text)),
              ]),
            ),
            Icon(Icons.unfold_more_rounded, size: 18, color: dark ? CI.cream.withValues(alpha: .6) : p.muted),
          ],
        ]),
      ),
    );
  }
}

/// Sign-in → choose a role → matching workspace.
class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.espressoDeep, CI.forest])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const OrgLogo(height: 56),
                  const SizedBox(height: 22),
                  Text(context.tr('role_choose_title'), textAlign: TextAlign.center, style: const TextStyle(fontFamily: TS.display, color: CI.cream, fontSize: 30, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(context.tr('role_choose_sub', [app.adminUser]), textAlign: TextAlign.center, style: TextStyle(color: CI.cream.withValues(alpha: .7), fontSize: 14)),
                  const SizedBox(height: 22),
                  Grid(columns: context.cols(desktop: 3, tablet: 2, mobile: 1), gap: 12, children: [
                    for (final r in roles)
                      GestureDetector(
                        onTap: () => app.setRole(r.id),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: r.color.withValues(alpha: .7), width: 1.5)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: r.color.withValues(alpha: .18), shape: BoxShape.circle), child: Icon(r.icon, color: r.color)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(context.tr(r.nameKey), style: TS.h3(p).copyWith(fontSize: 15))),
                              ]),
                              const SizedBox(height: 10),
                              Text(context.tr(r.descKey), style: TS.bodyS(p)),
                              const SizedBox(height: 10),
                              Chip2(context.tr(r.id == 'admin' ? 'role_admin_space' : 'role_workspace'), r.color, icon: Icons.arrow_forward_rounded),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  Text(context.tr('role_sim_note'), textAlign: TextAlign.center, style: TextStyle(color: CI.cream.withValues(alpha: .6), fontSize: 11.5)),
                  TextButton(onPressed: app.logout, child: Text(context.tr('adm_logout'), style: const TextStyle(color: CI.gold))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the current profile has no access to a page (simulated permission).
class RestrictedPage extends StatelessWidget {
  final String pageNameKey;
  const RestrictedPage({super.key, required this.pageNameKey});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final r = app.roleDef;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassCard(
            accent: p.alert,
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: p.alert.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(Icons.lock_rounded, size: 34, color: p.alert)),
              const SizedBox(height: 16),
              Text(context.tr('restricted_title'), textAlign: TextAlign.center, style: TS.h2(p)),
              const SizedBox(height: 6),
              Text(context.tr('restricted_text', [context.tr(pageNameKey), context.tr(r.nameKey)]), textAlign: TextAlign.center, style: TS.bodyS(p).copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                PrimaryButton(context.tr('restricted_request'), icon: Icons.mail_outline_rounded, outlined: true, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('restricted_sent'))));
                }),
                PrimaryButton(context.tr('nav_decision'), icon: Icons.space_dashboard_rounded, onTap: () => app.goto(0)),
              ]),
              const SizedBox(height: 14),
              Text(context.tr('role_sim_note'), textAlign: TextAlign.center, style: TS.bodyS(p).copyWith(fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}
