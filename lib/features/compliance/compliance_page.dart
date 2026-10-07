import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../shell/nav.dart';

/// Status of a requirement of the Terms of Reference in this front-end demo.
/// complete  = working screen with demo data
/// simulated = visible and interactive, but the engine/back end behind it is simulated
/// partial   = only some of the requirement is covered
/// out       = production deliverable, outside the scope of the demo
enum St { complete, simulated, partial, out }

class _Req {
  final String section, req, fn, page;
  final St st;
  final String? tab;
  final int? admin;
  const _Req(this.section, this.req, this.fn, this.page, this.st, {this.tab, this.admin});
}

const _reqs = <_Req>[
  // 3. Specific objectives
  _Req('tor_s3', 'req_market', 'fn_market', 'market', St.complete),
  _Req('tor_s3', 'req_esg', 'fn_esg', 'sustain', St.complete),
  _Req('tor_s3', 'req_governance', 'fn_governance', 'sustain', St.complete),
  _Req('tor_s3', 'req_supply_map', 'fn_supply_map', 'chain', St.complete),
  _Req('tor_s3', 'req_cert_path', 'fn_cert_path', 'certs', St.complete),
  _Req('tor_s3', 'req_benchmark', 'fn_benchmark', 'compare', St.complete),
  _Req('tor_s3', 'req_forecast', 'fn_forecast', 'forecast', St.complete),
  // 4. Dashboards
  _Req('tor_s4', 'req_dash_market', 'fn_dash_market', 'market', St.complete),
  _Req('tor_s4', 'req_dash_sustain', 'fn_dash_sustain', 'sustain', St.complete),
  _Req('tor_s4', 'req_dash_trace', 'fn_dash_trace', 'chain', St.complete, tab: 'lots'),
  _Req('tor_s4', 'req_dash_quality', 'fn_dash_quality', 'production', St.complete, tab: 'quality'),
  _Req('tor_s4', 'req_weather', 'fn_weather', 'production', St.complete, tab: 'climate'),
  _Req('tor_s4', 'req_roles', 'fn_roles', 'decision', St.complete),
  _Req('tor_s4', 'req_security', 'fn_security', 'decision', St.simulated, admin: 5),
  _Req('tor_s4', 'req_etl', 'fn_etl', 'sources', St.simulated, admin: 7),
  _Req('tor_s4', 'req_warehouse', 'fn_warehouse', 'sources', St.simulated, admin: 1),
  _Req('tor_s4', 'req_user_input', 'fn_user_input', 'sources', St.complete, admin: 3),
  // 5. Features
  _Req('tor_s5', 'req_interactive', 'fn_interactive', 'production', St.complete),
  _Req('tor_s5', 'req_drag_drop', 'fn_drag_drop', 'decision', St.complete),
  _Req('tor_s5', 'req_custom_charts', 'fn_custom_charts', 'production', St.complete),
  _Req('tor_s5', 'req_reporting', 'fn_reporting', 'reports', St.complete),
  _Req('tor_s5', 'req_mobile', 'fn_mobile', 'decision', St.complete),
  _Req('tor_s5', 'req_lang', 'fn_lang', 'settings', St.complete),
  _Req('tor_s5', 'req_lang_more', 'fn_lang_more', 'settings', St.partial),
  _Req('tor_s5', 'req_alerts', 'fn_alerts', 'alerts', St.complete),
  _Req('tor_s5', 'req_export', 'fn_export', 'market', St.complete),
  // 6. Users
  _Req('tor_s6', 'req_u_coop', 'fn_u_coop', 'decision', St.complete),
  _Req('tor_s6', 'req_u_exporter', 'fn_u_exporter', 'decision', St.complete),
  _Req('tor_s6', 'req_u_board', 'fn_u_board', 'decision', St.complete),
  _Req('tor_s6', 'req_u_roaster', 'fn_u_roaster', 'decision', St.complete),
  _Req('tor_s6', 'req_u_ngo', 'fn_u_ngo', 'decision', St.complete),
  // 11. Risks
  _Req('tor_s11', 'req_trust', 'fn_trust', 'sources', St.complete),
  _Req('tor_s11', 'req_quality_admin', 'fn_quality_admin', 'sources', St.complete, admin: 8),
  _Req('tor_s11', 'req_adoption', 'fn_adoption', 'decision', St.partial),
];

/// Production deliverables: not part of a front-end demo.
const _deliverables = <_Req>[
  _Req('tor_b', 'req_cloud', 'fn_cloud', 'compliance', St.out),
  _Req('tor_b', 'req_b_warehouse', 'fn_b_warehouse', 'compliance', St.out),
  _Req('tor_b', 'req_b_etl', 'fn_b_etl', 'compliance', St.out),
  _Req('tor_b', 'req_b_security', 'fn_b_security', 'compliance', St.out),
  _Req('tor_b', 'req_docs', 'fn_docs', 'compliance', St.out),
  _Req('tor_b', 'req_b_training', 'fn_b_training', 'compliance', St.out),
  _Req('tor_b', 'req_b_uat', 'fn_b_uat', 'compliance', St.out),
  _Req('tor_b', 'req_b_sustain', 'fn_b_sustain', 'compliance', St.out),
];

class CompliancePage extends StatefulWidget {
  const CompliancePage({super.key});
  @override
  State<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends State<CompliancePage> {
  St? _filter;

  void _open(BuildContext context, _Req r) {
    final app = context.app;
    if (r.admin != null) {
      if (!app.admin) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('comp_admin_hint'))));
      } else {
        app.setRole('admin');
        app.gotoAdmin(r.admin!);
      }
      return;
    }
    if (r.page == 'compliance') return;
    if (r.page == 'production' && r.tab != null) app.setProductionTab(r.tab!);
    if (r.page == 'chain' && r.tab != null) app.setChainTab(r.tab!);
    app.goto(navIndex(r.page));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final col = {St.complete: p.green, St.simulated: p.accent, St.partial: p.warn, St.out: p.muted};
    final label = {St.complete: '✅ ${context.tr('st_complete')}', St.simulated: '🔷 ${context.tr('st_simulated')}', St.partial: '🟡 ${context.tr('st_partial')}', St.out: '⚪ ${context.tr('st_out')}'};
    int n(St s) => _reqs.where((r) => r.st == s).length;
    final covered = n(St.complete) + n(St.simulated);
    final shown = _reqs.where((r) => _filter == null || r.st == _filter).toList();
    String? lastSection;

    Widget row(_Req r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            accent: col[r.st],
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: context.isMobile ? double.infinity : 300, child: Text(context.tr(r.req), style: TS.h3(p).copyWith(fontSize: 13.5))),
                SizedBox(width: context.isMobile ? double.infinity : 360, child: Text(context.tr(r.fn), style: TS.bodyS(p).copyWith(fontSize: 12.5, color: p.text))),
                if (r.page != 'compliance') Chip2(r.admin != null ? context.tr('comp_screen_admin') : context.tr(navItems[navIndex(r.page)].labelKey), p.accent, icon: Icons.desktop_windows_rounded),
                Chip2(label[r.st]!, col[r.st]!),
                if (r.page != 'compliance') TextButton.icon(onPressed: () => _open(context, r), icon: const Icon(Icons.open_in_new_rounded, size: 16), label: Text(context.tr('comp_see'))),
              ]),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('comp_title', 'comp_sub'),
      GlassCard(
        accent: p.green,
        child: Wrap(spacing: 28, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(context.tr('comp_visible_cov').toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 4),
            AnimatedCounter(covered / _reqs.length * 100, suffix: ' %', style: TS.big(p, size: 38).copyWith(color: p.green)),
            Text(context.tr('comp_visible_cov_d', [covered, _reqs.length]), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
          ]),
          SizedBox(width: context.isMobile ? double.infinity : 460, child: Text(context.tr('comp_note'), style: TS.bodyS(p))),
        ]),
      ),
      gap16,
      Grid(columns: context.cols(desktop: 5, tablet: 3, mobile: 2), gap: 12, children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('comp_total').toUpperCase(), style: TS.label(p)), const SizedBox(height: 6), AnimatedCounter(_reqs.length.toDouble(), style: TS.big(p, size: 30))])),
        for (final s in [St.complete, St.simulated, St.partial])
          GlassCard(
            accent: col[s],
            selected: _filter == s,
            onTap: () => setState(() => _filter = _filter == s ? null : s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label[s]!.toUpperCase(), style: TS.label(p), maxLines: 2), const SizedBox(height: 6), AnimatedCounter(n(s).toDouble(), style: TS.big(p, size: 30).copyWith(color: col[s]))]),
          ),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label[St.out]!.toUpperCase(), style: TS.label(p), maxLines: 2), const SizedBox(height: 6), AnimatedCounter(_deliverables.length.toDouble(), style: TS.big(p, size: 30).copyWith(color: p.muted))])),
      ]),
      gap24,
      SectionLabel(context.tr('comp_part_a')),
      Text(context.tr('comp_part_a_d'), style: TS.bodyS(p)),
      const SizedBox(height: 10),
      for (final r in shown) ...[
        if (r.section != lastSection) Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(context.tr(lastSection = r.section), style: TS.h3(p).copyWith(color: p.gold))),
        row(r),
      ],
      gap24,
      SectionLabel(context.tr('comp_part_b')),
      Text(context.tr('comp_part_b_d'), style: TS.bodyS(p)),
      const SizedBox(height: 10),
      for (final r in _deliverables) row(r),
    ]);
  }
}
