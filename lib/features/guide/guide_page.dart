import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../data/role_data.dart';
import '../../widgets/common.dart';

/// "How do I use this?" — a self-service guide so a new visitor can learn the platform without anyone's help.
class _Task {
  final String id, pageId;
  final IconData icon;
  final String? prodTab, chainTab;
  const _Task(this.id, this.icon, this.pageId, {this.prodTab, this.chainTab});
}

const _tasks = <_Task>[
  _Task('market', Icons.candlestick_chart_rounded, 'market'),
  _Task('compare', Icons.compare_arrows_rounded, 'compare'),
  _Task('quality', Icons.coffee_rounded, 'production', prodTab: 'quality'),
  _Task('lots', Icons.qr_code_2_rounded, 'chain', chainTab: 'lots'),
  _Task('risks', Icons.query_stats_rounded, 'forecast'),
  _Task('alerts', Icons.notifications_active_rounded, 'alerts'),
  _Task('sim', Icons.tune_rounded, 'simulator'),
  _Task('reports', Icons.description_rounded, 'reports'),
  _Task('export', Icons.ios_share_rounded, 'decision'),
  _Task('account', Icons.workspace_premium_rounded, 'account'),
  _Task('sources', Icons.hub_rounded, 'sources'),
  _Task('reference', Icons.menu_book_rounded, 'reference'),
];

const _quick = <(IconData, String)>[
  (Icons.groups_rounded, 'gq_1'),
  (Icons.translate_rounded, 'gq_2'),
  (Icons.menu_rounded, 'gq_3'),
  (Icons.touch_app_rounded, 'gq_4'),
  (Icons.ios_share_rounded, 'gq_5'),
];

const _legend = <(IconData, String)>[
  (Icons.science_rounded, 'gl_1'),
  (Icons.trending_up_rounded, 'gl_2'),
  (Icons.circle, 'gl_3'),
  (Icons.lock_rounded, 'gl_4'),
  (Icons.open_in_full_rounded, 'gl_5'),
  (Icons.open_with_rounded, 'gl_6'),
];

const _checks = ['gc_profile', 'gc_currency', 'gc_detail', 'gc_alert', 'gc_report', 'gc_account'];

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  void _open(_Task t) {
    final app = context.app;
    final i = AppState.pageIds.indexOf(t.pageId);
    if (i < 0) return;
    if (t.prodTab != null) app.setProductionTab(t.prodTab!);
    if (t.chainTab != null) app.setChainTab(t.chainTab!);
    app.goto(i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final wide = context.w >= 1000;
    final done = app.guideDone.length;

    Widget title(String k, [String? d]) => Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr(k)),
            if (d != null) Text(context.tr(d), style: TS.bodyS(p)),
          ]),
        );

    final hero = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_rounded, color: p.gold, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text(context.tr('guide_hello'), style: TS.h2(p))),
        ]),
        const SizedBox(height: 8),
        Text(context.tr('guide_hello_d'), style: TS.bodyS(p).copyWith(color: p.text)),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          PrimaryButton(context.tr('guide_tour'), icon: Icons.slideshow_rounded, onTap: () => app.setPresentation(true)),
          PrimaryButton(context.tr('guide_go_decision'), icon: Icons.space_dashboard_rounded, outlined: true, onTap: () => app.goto(0)),
        ]),
      ]),
    );

    final progress = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr('guide_progress'), style: TS.h3(p))),
          Text('$done / ${_checks.length}', style: TS.h3(p).copyWith(color: p.accent)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: done / _checks.length, minHeight: 8, backgroundColor: p.surface2, color: p.green)),
        const SizedBox(height: 6),
        for (final c in _checks)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: app.guideDone.contains(c),
            onChanged: (v) => app.toggleGuide(c, v ?? false),
            title: Text(context.tr(c), style: TS.bodyS(p).copyWith(color: p.text)),
          ),
        if (done == _checks.length) Chip2(context.tr('guide_all_done'), p.green, icon: Icons.emoji_events_rounded),
      ]),
    );

    final quick = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _quick.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 16, backgroundColor: p.accent, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Icon(_quick[i].$1, color: p.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('${_quick[i].$2}_t'), style: TS.h3(p)), const SizedBox(height: 2), Text(context.tr('${_quick[i].$2}_d'), style: TS.bodyS(p).copyWith(color: p.text))])),
            ]),
          ),
        ),
    ]);

    final tasks = Column(children: [
      for (final t in _tasks)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                leading: Icon(t.icon, color: p.accent),
                title: Text(context.tr('gt_${t.id}_t'), style: TS.h3(p)),
                subtitle: Text(context.tr('gt_${t.id}_s'), style: TS.bodyS(p).copyWith(fontSize: 12)),
                children: [
                  for (var i = 1; i <= 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$i.', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(context.tr('gt_${t.id}_$i'), style: TS.bodyS(p).copyWith(color: p.text))),
                      ]),
                    ),
                  const SizedBox(height: 6),
                  PrimaryButton(context.tr('guide_open_page'), icon: Icons.arrow_forward_rounded, outlined: true, onTap: () => _open(t)),
                ],
              ),
            ),
          ),
        ),
    ]);

    final legend = GlassCard(
      child: Column(children: [
        for (final l in _legend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(l.$1, size: 20, color: l.$2 == 'gl_3' ? p.warn : p.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(context.tr(l.$2), style: TS.bodyS(p).copyWith(color: p.text))),
            ]),
          ),
      ]),
    );

    final profiles = Wrap(spacing: 12, runSpacing: 12, children: [
      for (final r in publicRoles)
        SizedBox(
          width: wide ? 330 : double.infinity,
          child: GlassCard(
            accent: r.color,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(r.icon, color: r.color), const SizedBox(width: 10), Expanded(child: Text(context.tr(r.nameKey), style: TS.h3(p)))]),
              const SizedBox(height: 6),
              Text(context.tr(r.descKey), style: TS.bodyS(p)),
            ]),
          ),
        ),
    ]);

    final billing = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final k in const ['gb_1', 'gb_2', 'gb_3'])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.check_circle_rounded, size: 18, color: p.green),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr(k), style: TS.bodyS(p).copyWith(color: p.text))),
            ]),
          ),
        const SizedBox(height: 4),
        PrimaryButton(context.tr('guide_see_plans'), icon: Icons.workspace_premium_rounded, onTap: () => app.goto(AppState.pageIds.indexOf('account'))),
      ]),
    );

    final faq = Column(children: [
      for (var i = 1; i <= 8; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(context.tr('gf_${i}_q'), style: TS.h3(p).copyWith(fontSize: 14)),
                children: [Text(context.tr('gf_${i}_a'), style: TS.bodyS(p).copyWith(color: p.text))],
              ),
            ),
          ),
        ),
    ]);

    final glossary = GlassCard(
      child: Column(children: [
        for (var i = 1; i <= 8; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: wide ? 150 : 96, child: Text(context.tr('gg_${i}_t'), style: TS.h3(p).copyWith(fontSize: 13.5, color: p.accent))),
              Expanded(child: Text(context.tr('gg_${i}_d'), style: TS.bodyS(p).copyWith(color: p.text))),
            ]),
          ),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('guide_title', 'guide_sub', exportId: ''),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: hero), const SizedBox(width: 16), Expanded(flex: 4, child: progress)])
      else ...[hero, const SizedBox(height: 14), progress],
      title('guide_quick', 'guide_quick_d'),
      quick,
      title('guide_tasks', 'guide_tasks_d'),
      tasks,
      title('guide_legend', 'guide_legend_d'),
      legend,
      title('guide_profiles', 'guide_profiles_d'),
      profiles,
      title('guide_billing', 'guide_billing_d'),
      billing,
      title('guide_faq'),
      faq,
      title('guide_glossary'),
      glossary,
    ]);
  }
}
