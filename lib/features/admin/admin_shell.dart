import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../shell/role_widgets.dart';
import '../shell/top_controls.dart';
import 'admin_pages.dart';
import 'admin_pages2.dart';

class _AdminNav {
  final IconData icon;
  final String labelKey;
  final Widget Function() build;
  const _AdminNav(this.icon, this.labelKey, this.build);
}

final _nav = <_AdminNav>[
  _AdminNav(Icons.insights_rounded, 'adm_nav_dash', () => const AdminDashboardPage()),
  _AdminNav(Icons.dataset_rounded, 'adm_nav_data', () => const AdminDataPage()),
  _AdminNav(Icons.sell_rounded, 'adm_nav_sales', () => const AdminSalesPage()),
  _AdminNav(Icons.edit_note_rounded, 'adm_nav_add', () => const AdminAddPage()),
  _AdminNav(Icons.manage_accounts_rounded, 'adm_nav_users', () => const AdminUsersPage()),
  _AdminNav(Icons.lock_person_rounded, 'adm_nav_roles', () => const AdminRolesPage()),
  _AdminNav(Icons.hub_rounded, 'adm_nav_sources', () => const AdminSourcesPage()),
  _AdminNav(Icons.swap_calls_rounded, 'adm_nav_flows', () => const AdminFlowsPage()),
  _AdminNav(Icons.rule_rounded, 'adm_nav_quality', () => const AdminQualityPage()),
  _AdminNav(Icons.speed_rounded, 'adm_nav_kpis', () => const AdminKpiPage()),
  _AdminNav(Icons.rule_folder_rounded, 'adm_nav_rules', () => const AdminRulesPage()),
];

/// Administrator area: a different dashboard from the public platform.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final mobile = context.isMobile;
    final content = AnimatedSwitcher(
      duration: context.dur(350),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: SingleChildScrollView(
        key: ValueKey('${app.adminPage}'),
        padding: EdgeInsets.fromLTRB(mobile ? 16 : 32, 12, mobile ? 16 : 32, 100),
        child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1360), child: _nav[app.adminPage].build())),
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.bg, p.bg2])),
        child: SafeArea(
          bottom: false,
          child: mobile
              ? Column(children: [
                  _top(context),
                  Expanded(child: content),
                  _bottom(context),
                ])
              : Row(children: [_side(context), Expanded(child: Column(children: [_top(context), Expanded(child: content)]))]),
        ),
      ),
    );
  }

  Widget _adminBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: CI.alert.withValues(alpha: .15), borderRadius: BorderRadius.circular(6), border: Border.all(color: CI.alert.withValues(alpha: .6))),
        child: Text(context.tr('adm_badge'), style: const TextStyle(color: CI.alert, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.6)),
      );

  Widget _top(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final mobile = context.isMobile;
    return Padding(
      padding: EdgeInsets.fromLTRB(mobile ? 12 : 32, 10, mobile ? 8 : 32, 4),
      child: Row(children: [
        if (mobile) ...[const OrgLogo(height: 30, emblem: true), const SizedBox(width: 8)],
        _adminBadge(context),
        const SizedBox(width: 10),
        if (!mobile) Text(context.tr('adm_signed_as', [app.adminUser]), style: TS.bodyS(p)),
        Expanded(child: Align(alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!mobile) ...[const RoleSwitcher(compact: true), const SizedBox(width: 8), const LangToggle(), const SizedBox(width: 8), const CurrencyPicker(compact: true), const SizedBox(width: 8), const ThemeToggle(), const SizedBox(width: 12)],
        if (mobile) ...[const LangToggle(), const SizedBox(width: 6), const CurrencyPicker(compact: true), const SizedBox(width: 4)],
        mobile
            ? IconButton(tooltip: context.tr('adm_view_public'), onPressed: () => app.setAdminView(false), icon: Icon(Icons.public_rounded, color: p.accent))
            : PrimaryButton(context.tr('adm_view_public'), icon: Icons.public_rounded, outlined: true, onTap: () => app.setAdminView(false)),
        if (mobile) IconButton(tooltip: context.tr('adm_logout'), onPressed: app.logout, icon: Icon(Icons.logout_rounded, color: p.muted)),
      ])))),
      ]),
    );
  }

  Widget _side(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final wide = context.isDesktop;
    return Container(
      width: wide ? 252 : 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A1612), Color(0xFF140B09)]),
        border: Border(right: BorderSide(color: CI.alert.withValues(alpha: .35))),
      ),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
            child: wide ? const Align(alignment: Alignment.centerLeft, child: OrgLogo(height: 70)) : const OrgLogo(height: 38, emblem: true),
          ),
          if (wide) Padding(padding: const EdgeInsets.only(left: 16, bottom: 14), child: Align(alignment: Alignment.centerLeft, child: _adminBadge(context))),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
              for (var i = 0; i < _nav.length; i++)
                GestureDetector(
                  onTap: () => app.gotoAdmin(i),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: context.dur(200),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 0, vertical: wide ? 12 : 8),
                      decoration: BoxDecoration(
                        color: app.adminPage == i ? CI.gold.withValues(alpha: .16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: app.adminPage == i ? CI.gold : Colors.transparent, width: 3)),
                      ),
                      child: !wide
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(_nav[i].icon, size: 20, color: app.adminPage == i ? CI.gold : CI.cream.withValues(alpha: .7)),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(context.tr(_nav[i].labelKey), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, height: 1.1, fontWeight: app.adminPage == i ? FontWeight.w700 : FontWeight.w500, color: app.adminPage == i ? CI.cream : CI.cream.withValues(alpha: .65))),
                              ),
                            ])
                          : Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        Icon(_nav[i].icon, size: 20, color: app.adminPage == i ? CI.gold : CI.cream.withValues(alpha: .7)),
                        if (wide) ...[const SizedBox(width: 12), Expanded(child: Text(context.tr(_nav[i].labelKey), style: TextStyle(fontSize: 13.5, fontWeight: app.adminPage == i ? FontWeight.w700 : FontWeight.w500, color: CI.cream.withValues(alpha: app.adminPage == i ? 1 : .75))))],
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: wide
                ? Column(children: [
                    Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: app.logout, icon: Icon(Icons.logout_rounded, color: CI.cream.withValues(alpha: .8), size: 18), label: Text(context.tr('adm_logout'), style: TextStyle(color: CI.cream.withValues(alpha: .8))))),
                  ])
                : IconButton(tooltip: context.tr('adm_logout'), onPressed: app.logout, icon: Icon(Icons.logout_rounded, color: p.muted)),
          ),
        ]),
      ),
    );
  }

  Widget _bottom(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    Widget item(IconData icon, String label, bool sel, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: sel ? p.accent : p.muted),
                const SizedBox(height: 2),
                Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.1, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? p.accent : p.muted)),
              ]),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (var i = 0; i < 4; i++) item(_nav[i].icon, context.tr(_nav[i].labelKey), app.adminPage == i, () => app.gotoAdmin(i)),
          item(Icons.apps_rounded, context.tr('more'), app.adminPage >= 4, () => _more(context)),
        ]),
      ),
    );
  }

  void _more(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < _nav.length; i++)
              SizedBox(
                width: (MediaQuery.sizeOf(c).width - 32 - 20) / 3,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(c);
                    app.gotoAdmin(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    decoration: BoxDecoration(color: app.adminPage == i ? p.accent.withValues(alpha: .15) : p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: app.adminPage == i ? p.accent : p.border)),
                    child: Column(children: [Icon(_nav[i].icon, color: p.accent), const SizedBox(height: 6), Text(context.tr(_nav[i].labelKey), textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, color: p.text, fontWeight: FontWeight.w600))]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Small helper so the shell can show the signed-in name without importing app state statics.
class AppStateAdmin {
  static const user = 'admin';
}
