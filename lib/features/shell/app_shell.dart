import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../assistant/assistant_panel.dart';
import '../admin/admin_shell.dart';
import '../admin/login_page.dart';
import '../../widgets/secret_tap.dart';
import '../landing/landing_page.dart';
import '../../data/role_data.dart';
import 'nav.dart';
import 'role_widgets.dart';
import 'top_controls.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _assist = false;
  int _stopOverride = 0;
  Timer? _auto;

  /// Current tour stop, derived from the visible page so the bar never goes out of sync.
  int get _stop {
    final i = presentationStops.indexWhere((e) => navIndex(e.$1) == context.app.page);
    return i >= 0 ? i : _stopOverride;
  }

  void _goStop(int i) {
    final s = (i % presentationStops.length + presentationStops.length) % presentationStops.length;
    setState(() => _stopOverride = s);
    context.app.goto(navIndex(presentationStops[s].$1));
  }

  void _syncAuto() {
    final on = context.app.presentation && context.app.autoPlay;
    if (on && _auto == null) {
      _auto = Timer.periodic(const Duration(seconds: 14), (_) {
        if (mounted) _goStop(_stop + 1);
      });
    } else if (!on) {
      _auto?.cancel();
      _auto = null;
    }
  }

  bool _warmed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    // Progressive loading: warm the supply-chain photos shortly after startup.
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      for (final s in repo.chain()) {
        precacheImage(AssetImage('assets/supply_chain/${s.id}.webp'), context).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAuto();
    });
    if (app.showLogin) return const AdminLogin();
    if (app.showRoleChooser) return const RoleChooserScreen();
    if (app.admin && app.adminView) return const AdminShell();
    if (app.showLanding) {
      return AnimatedSwitcher(duration: context.dur(500), child: const LandingPage(key: ValueKey('landing')));
    }
    final content = AnimatedSwitcher(
      duration: context.dur(420),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) => FadeTransition(
          opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .02), end: Offset.zero).animate(a), child: c)),
      child: _PageHost(key: ValueKey(app.page), index: app.page),
    );

    Widget body;
    if (context.isMobile) {
      body = Column(children: [
        _MobileTop(onMenu: () => _openMore(context)),
        Expanded(child: content),
        _BottomNav(onMore: () => _openMore(context)),
      ]);
    } else {
      body = Row(children: [
        _Sidebar(extended: context.isDesktop),
        Expanded(
          child: Column(children: [
            _DesktopTop(onAssist: () => setState(() => _assist = !_assist)),
            Expanded(child: content),
          ]),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.bg, p.bg2])))),
        SafeArea(bottom: false, child: body),
        if (app.admin && !app.adminView)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => app.setAdminView(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: CI.alert, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 10)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 16), const SizedBox(width: 6), Text(context.tr('adm_back_admin'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]),
                ),
              ),
            ),
          ),
        if (app.presentation)
          Positioned(
            left: 0,
            right: 0,
            bottom: context.isMobile ? 66 : 14,
            child: Center(child: _PresentationBar(stop: _stop, onGo: _goStop)),
          ),
        // assistant FAB + panel
        Positioned(
          right: 18,
          bottom: context.isMobile ? (app.presentation ? 130 : 76) : (app.presentation ? 90 : 20),
          child: AnimatedScale(
            duration: context.dur(250),
            scale: _assist ? 0 : 1,
            child: FloatingActionButton.extended(
              heroTag: 'assist',
              backgroundColor: p.accent,
              foregroundColor: Colors.white,
              onPressed: () => setState(() => _assist = true),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: context.isMobile ? const SizedBox() : Text(context.tr('assistant_name')),
            ),
          ),
        ),
        if (_assist)
          Positioned(
            right: context.isMobile ? 0 : 18,
            left: context.isMobile ? 0 : null,
            bottom: context.isMobile ? 0 : 18,
            top: context.isMobile ? 70 : 80,
            child: AssistantPanel(onClose: () => setState(() => _assist = false)),
          ),
      ]),
    );
  }

  void _openMore(BuildContext context) {
    final p = context.pal;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 10, runSpacing: 8, children: [RoleSwitcher(), CurrencyPicker()])),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < navItems.length; i++)
                SizedBox(
                  width: (MediaQuery.sizeOf(c).width - 36 - 20) / 3,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(c);
                      context.app.goto(i);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      decoration: BoxDecoration(
                          color: context.app.page == i ? p.accent.withValues(alpha: .15) : p.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.app.page == i ? p.accent : p.border)),
                      child: Column(children: [
                        Icon(context.app.isRestricted(navItems[i].id) ? Icons.lock_rounded : navItems[i].icon, color: context.app.isRestricted(navItems[i].id) ? p.muted : p.accent),
                        const SizedBox(height: 6),
                        Text(context.tr(navItems[i].labelKey), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: p.text, fontWeight: FontWeight.w600), maxLines: 2),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: PrimaryButton(context.tr('presentation_mode'), icon: Icons.slideshow_rounded, outlined: true, onTap: () {
                Navigator.pop(c);
                context.app.setPresentation(true);
                _goStop(0);
              })),
              const SizedBox(width: 10),
              PrimaryButton(context.tr('intro'), icon: Icons.local_florist_rounded, onTap: () {
                Navigator.pop(c);
                context.app.openLanding();
              }),
            ]),
          ])),
        ),
      ),
    );
  }
}

class _PageHost extends StatefulWidget {
  final int index;
  const _PageHost({super.key, required this.index});
  @override
  State<_PageHost> createState() => _PageHostState();
}

class _PageHostState extends State<_PageHost> {
  final GlobalKey _boundary = GlobalKey(); // own key: old and new hosts coexist during the page transition
  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    context.app.exportKey = _boundary;
    final nav = navItems[index];
    final locked = context.app.isRestricted(nav.id);
    final pad = context.isMobile ? 16.0 : (context.isTablet ? 24.0 : 32.0);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, context.isMobile ? 10 : 6, pad, 120),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1360), child: locked ? RestrictedPage(pageNameKey: nav.labelKey) : RepaintBoundary(key: _boundary, child: nav.build())),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool extended;
  const _Sidebar({required this.extended});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return AnimatedContainer(
      duration: context.dur(300),
      width: extended ? 252 : 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.dark ? [const Color(0xFF1E120D), const Color(0xFF120A07)] : [CI.espresso, CI.espressoDeep]),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 24)],
      ),
      child: SafeArea(
        child: Column(children: [
          SecretTap(
            onTriple: app.openLogin,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: extended
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const OrgLogo(height: 84),
                      const SizedBox(height: 10),
                      Text(context.tr('org_name').toUpperCase(), style: TextStyle(fontFamily: TS.display, color: CI.gold, fontWeight: FontWeight.w800, letterSpacing: 1.8, fontSize: 11.5)),
                    ])
                  : const Center(child: OrgLogo(height: 40, emblem: true)),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: RoleSwitcher(dark: true, compact: !extended)),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
              if (extended) Padding(padding: const EdgeInsets.fromLTRB(6, 2, 6, 6), child: Text(context.tr('nav_for_you').toUpperCase(), style: TextStyle(fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: CI.gold.withValues(alpha: .8)))),
              for (final i in primaryIndices(app.roleDef.primary)) _NavTile(i: i, extended: extended),
              GestureDetector(
                onTap: app.toggleNav,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 0, vertical: 10),
                  child: Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                    Icon(app.navExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: CI.cream.withValues(alpha: .6)),
                    if (extended) ...[const SizedBox(width: 8), Text(context.tr('nav_all_pages'), style: TextStyle(fontSize: 12, color: CI.cream.withValues(alpha: .6), fontWeight: FontWeight.w600))],
                  ]),
                ),
              ),
              if (app.navExpanded)
                for (var i = 0; i < navItems.length - 1; i++)
                  if (!app.roleDef.primary.contains(navItems[i].id)) _NavTile(i: i, extended: extended),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              if (extended)
                Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const LangToggle(), const ThemeToggle()]), const SizedBox(height: 8), const Align(alignment: Alignment.centerLeft, child: CurrencyPicker())])
              else ...[const FittedBox(fit: BoxFit.scaleDown, child: LangToggle()), const SizedBox(height: 8), const ThemeToggle(), const SizedBox(height: 8), const FittedBox(fit: BoxFit.scaleDown, child: CurrencyPicker(compact: true))],
              const SizedBox(height: 10),
              _NavTile(i: navItems.length - 1, extended: extended),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final int i;
  final bool extended;
  const _NavTile({required this.i, required this.extended});
  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final n = navItems[widget.i];
    final sel = app.page == widget.i;
    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => app.goto(widget.i),
        child: AnimatedContainer(
          duration: context.dur(200),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: widget.extended ? 14 : 0, vertical: widget.extended ? 11 : 8),
          decoration: BoxDecoration(
            color: sel ? CI.gold.withValues(alpha: .16) : (_h ? Colors.white.withValues(alpha: .06) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: sel ? CI.gold : Colors.transparent, width: 3)),
          ),
          child: !widget.extended
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(n.icon, size: 20, color: sel ? CI.gold : CI.cream.withValues(alpha: app.isRestricted(n.id) ? .35 : .7)),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(context.tr(n.labelKey), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, height: 1.1, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? CI.cream : CI.cream.withValues(alpha: .65))),
                  ),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Icon(n.icon, size: 20, color: sel ? CI.gold : CI.cream.withValues(alpha: app.isRestricted(n.id) ? .35 : .7)),
            if (widget.extended) ...[
              const SizedBox(width: 12),
              Expanded(child: Text(context.tr(n.labelKey), style: TextStyle(fontSize: 13.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? CI.cream : CI.cream.withValues(alpha: app.isRestricted(n.id) ? .4 : .75)))),
              if (app.isRestricted(n.id)) Icon(Icons.lock_rounded, size: 14, color: CI.cream.withValues(alpha: .4)),
            ],
          ]),
        ),
      ),
    );
    return widget.extended ? tile : Tooltip(message: context.tr(n.labelKey), child: tile);
  }
}

class _DesktopTop extends StatelessWidget {
  final VoidCallback onAssist;
  const _DesktopTop({required this.onAssist});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 4),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: p.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.green, blurRadius: 8)])),
        const SizedBox(width: 8),
        Expanded(child: Text(context.tr('live_demo'), maxLines: 2, overflow: TextOverflow.ellipsis, style: TS.label(p))),
        const SizedBox(width: 12),
        if (context.w > 1000) Text('${context.tr('role_profile')} : ', style: TS.bodyS(p)),
        if (context.w > 1000) Text(context.tr(app.roleDef.nameKey), style: TS.h3(p).copyWith(color: app.roleDef.color)),
        const SizedBox(width: 14),
        if (context.w > 1000)
          PrimaryButton(app.presentation ? context.tr('exit_presentation') : context.tr('presentation_mode'),
              icon: app.presentation ? Icons.close_rounded : Icons.slideshow_rounded, outlined: true, onTap: () {
            app.setPresentation(!app.presentation);
          })
        else
          IconButton(
              tooltip: context.tr('presentation_mode'),
              onPressed: () => app.setPresentation(!app.presentation),
              icon: Icon(app.presentation ? Icons.close_rounded : Icons.slideshow_rounded, color: p.gold)),
        const SizedBox(width: 10),
        PrimaryButton(context.tr('assistant_name'), icon: Icons.auto_awesome_rounded, onTap: onAssist),
      ]),
    );
  }
}

class _MobileTop extends StatelessWidget {
  final VoidCallback onMenu;
  const _MobileTop({required this.onMenu});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(children: [
        SecretTap(onTriple: context.app.openLogin, child: const OrgLogo(height: 30, emblem: true)),
        const SizedBox(width: 8),
        Expanded(child: Text(context.tr('final_kicker'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: TS.display, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.8, color: p.text))),
        const RoleSwitcher(compact: true),
        const SizedBox(width: 6),
        const LangToggle(),
        const SizedBox(width: 6),
        const ThemeToggle(),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final VoidCallback onMore;
  const _BottomNav({required this.onMore});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final main = primaryIndices(app.roleDef.primary).take(4).toList();
    Widget item(IconData icon, String label, bool sel, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: context.dur(250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: sel ? p.accent.withValues(alpha: .18) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, size: 22, color: sel ? p.accent : p.muted),
                ),
                const SizedBox(height: 2),
                Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, height: 1.1, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? p.accent : p.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (final i in main) item(navItems[i].icon, context.tr(i == 0 ? 'nav_decision_short' : navItems[i].labelKey), app.page == i, () => app.goto(i)),
          item(Icons.apps_rounded, context.tr('more'), !main.contains(app.page), onMore),
        ]),
      ),
    );
  }
}

class _PresentationBar extends StatelessWidget {
  final int stop;
  final ValueChanged<int> onGo;
  const _PresentationBar({required this.stop, required this.onGo});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final mobile = context.isMobile;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 18, vertical: 10),
      decoration: BoxDecoration(
        color: CI.espressoDeep.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: CI.gold.withValues(alpha: .6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => onGo(stop - 1), icon: const Icon(Icons.chevron_left_rounded, color: CI.cream)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${stop + 1} / ${presentationStops.length}  ·  ${context.tr(presentationStops[stop].$2)}', style: const TextStyle(color: CI.cream, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < presentationStops.length; i++)
              GestureDetector(
                onTap: () => onGo(i),
                child: AnimatedContainer(
                  duration: context.dur(250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == stop ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i <= stop ? CI.gold : Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
              ),
          ]),
        ]),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => onGo(stop + 1), icon: const Icon(Icons.chevron_right_rounded, color: CI.cream)),
        if (!mobile)
          IconButton(
              tooltip: context.tr('autoplay'),
              visualDensity: VisualDensity.compact,
              onPressed: () => app.setAutoPlay(!app.autoPlay),
              icon: Icon(app.autoPlay ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: p.gold)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => app.setPresentation(false), icon: const Icon(Icons.close_rounded, color: CI.cream)),
      ]),
    );
  }
}
