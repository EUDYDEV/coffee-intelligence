import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../shell/top_controls.dart';
import 'admin_pages.dart';

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
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1360), child: _nav[app.adminPage].build())),
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
        const Spacer(),
        if (!mobile) ...[const LangToggle(), const SizedBox(width: 8), const CurrencyPicker(compact: true), const SizedBox(width: 8), const ThemeToggle(), const SizedBox(width: 12)],
        if (mobile) ...[const LangToggle(), const SizedBox(width: 6), const CurrencyPicker(compact: true), const SizedBox(width: 4)],
        mobile
            ? IconButton(tooltip: context.tr('adm_view_public'), onPressed: () => app.setAdminView(false), icon: Icon(Icons.public_rounded, color: p.accent))
            : PrimaryButton(context.tr('adm_view_public'), icon: Icons.public_rounded, outlined: true, onTap: () => app.setAdminView(false)),
        if (mobile) IconButton(tooltip: context.tr('adm_logout'), onPressed: app.logout, icon: Icon(Icons.logout_rounded, color: p.muted)),
      ]),
    );
  }

  Widget _side(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final wide = context.isDesktop;
    return Container(
      width: wide ? 252 : 76,
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
                      padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 0, vertical: 12),
                      decoration: BoxDecoration(
                        color: app.adminPage == i ? CI.gold.withValues(alpha: .16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: app.adminPage == i ? CI.gold : Colors.transparent, width: 3)),
                      ),
                      child: Row(mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
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
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (var i = 0; i < _nav.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => app.gotoAdmin(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_nav[i].icon, color: app.adminPage == i ? p.accent : p.muted),
                    const SizedBox(height: 2),
                    Text(context.tr(_nav[i].labelKey), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: app.adminPage == i ? FontWeight.w700 : FontWeight.w500, color: app.adminPage == i ? p.accent : p.muted)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Small helper so the shell can show the signed-in name without importing app state statics.
class AppStateAdmin {
  static const user = 'admin';
}
