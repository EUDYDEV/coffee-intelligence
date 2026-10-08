import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/admin2_data.dart';
import '../../data/repository.dart';
import '../../data/role_data.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../alerts/rules_panel.dart';
import '../shell/nav.dart';

String _ago(int mins) => mins < 60 ? '$mins min' : '${(mins / 60).round()} h';

// ===========================================================================
// Users
// ===========================================================================
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final statusCol = [p.green, p.gold, p.muted];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_users_title', 'adm_users_sub', trailing: PrimaryButton(context.tr('adm_user_add'), icon: Icons.person_add_alt_1_rounded, onTap: () => _addDialog(context))),
      Grid(columns: context.cols(desktop: 4, tablet: 4, mobile: 2), gap: 12, children: [
        KpiCard(labelKey: 'adm_users_total', metric: 'default', value: app.users.length.toDouble(), icon: Icons.groups_rounded),
        KpiCard(labelKey: 'adm_users_active', metric: 'default', value: app.users.where((u) => u.status == 0).length.toDouble(), icon: Icons.verified_user_rounded),
        KpiCard(labelKey: 'adm_users_invited', metric: 'default', value: app.users.where((u) => u.status == 1).length.toDouble(), icon: Icons.mail_outline_rounded),
        KpiCard(labelKey: 'adm_users_suspended', metric: 'default', value: app.users.where((u) => u.status == 2).length.toDouble(), icon: Icons.block_rounded),
      ]),
      gap24,
      GlassCard(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: context.w - (context.isMobile ? 60 : 340)),
            child: DataTable(
              columnSpacing: 24,
              headingTextStyle: TS.label(p),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              columns: [for (final k in ['adm_u_name', 'adm_u_org', 'adm_u_role', 'adm_u_status', 'adm_u_last', 'adm_u_access', 'adm_u_actions']) DataColumn(label: Text(context.tr(k).toUpperCase()))],
              rows: [
                for (final u in app.users)
                  DataRow(cells: [
                    DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: TS.h3(p).copyWith(fontSize: 13.5)), Text(u.email, style: TS.bodyS(p).copyWith(fontSize: 11))])),
                    DataCell(Text(u.org, style: TextStyle(color: p.text, fontSize: 13))),
                    DataCell(DropdownButton<String>(
                      value: u.role,
                      underline: const SizedBox(),
                      items: [for (final r in roles) DropdownMenuItem(value: r.id, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(r.icon, size: 16, color: r.color), const SizedBox(width: 6), Text(context.tr(r.nameKey), style: const TextStyle(fontSize: 13))]))],
                      onChanged: (v) {
                        u.role = v ?? u.role;
                        app.addLog('log_role_change', u.name);
                        app.touch();
                      },
                    )),
                    DataCell(Chip2(context.tr(['adm_st_active', 'adm_st_invited', 'adm_st_suspended'][u.status]), statusCol[u.status], icon: Icons.circle)),
                    DataCell(Text(u.lastSeen == '—' ? '—' : context.tr('ago', [u.lastSeen]), style: TextStyle(color: p.muted, fontSize: 12.5))),
                    DataCell(Text(context.tr('adm_pages_n', [roleById(u.role).primary.length]), style: TextStyle(color: p.text, fontSize: 12.5))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: u.status == 2 ? context.tr('adm_u_activate') : context.tr('adm_u_suspend'),
                        icon: Icon(u.status == 2 ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded, color: p.accent),
                        onPressed: () {
                          u.status = u.status == 2 ? 0 : 2;
                          app.addLog(u.status == 2 ? 'log_user_suspend' : 'log_user_activate', u.name);
                          app.touch();
                        },
                      ),
                      IconButton(
                        tooltip: context.tr('adm_u_view_as'),
                        icon: Icon(Icons.visibility_rounded, color: p.gold),
                        onPressed: () {
                          app.setRole(u.role == 'admin' ? 'board' : u.role);
                        },
                      ),
                    ])),
                  ]),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  void _addDialog(BuildContext context) {
    final app = context.app;
    final name = TextEditingController(), org = TextEditingController();
    var role = 'coop';
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(context.tr('adm_user_add')),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: InputDecoration(labelText: context.tr('adm_u_name'))),
              TextField(controller: org, decoration: InputDecoration(labelText: context.tr('adm_u_org'))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                initialValue: role,
                decoration: InputDecoration(labelText: context.tr('adm_u_role')),
                items: [for (final r in roles) DropdownMenuItem(value: r.id, child: Text(context.tr(r.nameKey)))],
                onChanged: (v) => set(() => role = v ?? role),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                app.users.insert(0, AppUser('u${DateTime.now().millisecondsSinceEpoch}', name.text.trim(), org.text.trim().isEmpty ? '—' : org.text.trim(), '${name.text.trim().toLowerCase().replaceAll(' ', '.')}@demo.example', role, 1, '—'));
                app.addLog('log_user_add', name.text.trim());
                app.touch();
                Navigator.pop(c);
              },
              child: Text(context.tr('adm_user_invite')),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Roles & permissions
// ===========================================================================
class AdminRolesPage extends StatelessWidget {
  const AdminRolesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final pages = [for (final n in navItems) if (n.id != 'settings' && n.id != 'compliance') n];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('adm_roles_title', 'adm_roles_sub'),
      GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('adm_perm_matrix')),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              headingTextStyle: TS.label(p),
              columns: [
                DataColumn(label: Text(context.tr('adm_permission').toUpperCase())),
                for (final r in roles) DataColumn(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(r.icon, size: 15, color: r.color), const SizedBox(width: 5), Text(context.tr(r.nameKey).toUpperCase())])),
              ],
              rows: [
                for (final k in permissionKeys)
                  DataRow(cells: [
                    DataCell(Text(context.tr(k), style: TextStyle(color: p.text, fontWeight: FontWeight.w600))),
                    for (final r in roles)
                      DataCell(Checkbox(
                        value: app.perms[r.id]![k] ?? false,
                        activeColor: r.color,
                        onChanged: r.id == 'admin' ? null : (v) {
                          app.perms[r.id]![k] = v ?? false;
                          app.addLog('log_perm', '${r.id}:$k');
                          app.touch();
                        },
                      )),
                  ]),
              ],
            ),
          ),
          Text(context.tr('adm_perm_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
        ]),
      ),
      gap24,
      GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('adm_page_matrix')),
          Wrap(spacing: 14, children: [LegendDot(p.green, context.tr('adm_pg_primary')), LegendDot(p.muted, context.tr('adm_pg_secondary')), LegendDot(p.alert, context.tr('adm_pg_restricted'))]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              headingTextStyle: TS.label(p),
              columns: [
                DataColumn(label: Text(context.tr('adm_page').toUpperCase())),
                for (final r in roles) DataColumn(label: Icon(r.icon, size: 18, color: r.color)),
              ],
              rows: [
                for (final n in pages)
                  DataRow(cells: [
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [Icon(n.icon, size: 16, color: p.muted), const SizedBox(width: 8), Text(context.tr(n.labelKey), style: TextStyle(color: p.text))])),
                    for (final r in roles)
                      DataCell(r.restricted.contains(n.id)
                          ? Icon(Icons.lock_rounded, size: 17, color: p.alert)
                          : (r.primary.contains(n.id) ? Icon(Icons.check_circle_rounded, size: 18, color: p.green) : Icon(Icons.remove_circle_outline_rounded, size: 18, color: p.muted))),
                  ]),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ===========================================================================
// Data sources
// ===========================================================================
const _srcStatus = [Icons.circle, Icons.warning_rounded, Icons.error_rounded, Icons.pause_circle_filled_rounded];

class AdminSourcesPage extends StatefulWidget {
  const AdminSourcesPage({super.key});
  @override
  State<AdminSourcesPage> createState() => _AdminSourcesPageState();
}

class _AdminSourcesPageState extends State<AdminSourcesPage> {
  final Set<String> _syncing = {};

  void _sync(SourceOps o) {
    final app = context.app;
    setState(() => _syncing.add(o.id));
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      o.rowsReceived += 400 + o.id.length * 53;
      o.rowsValid += 380 + o.id.length * 50;
      o.rowsRejected += 20 + o.id.length * 3;
      o.lastSync = '0 min';
      if (o.status == 1) o.status = 0;
      app.addLog('log_sync', o.id);
      setState(() => _syncing.remove(o.id));
      app.touch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final cols = [p.green, p.warn, p.alert, p.muted];
    final src = repo.sources();
    final ops = app.sourceOps;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_src_title', 'adm_src_sub', trailing: PrimaryButton(context.tr('adm_sync_all'), icon: Icons.sync_rounded, onTap: () {
        for (final o in ops.where((o) => o.status != 3)) {
          _sync(o);
        }
      })),
      Wrap(spacing: 14, runSpacing: 8, children: [
        for (var i = 0; i < 4; i++) Chip2('${context.tr(['adm_ss_active', 'adm_ss_attention', 'adm_ss_error', 'adm_ss_suspended'][i])} · ${ops.where((o) => o.status == i).length}', cols[i], icon: _srcStatus[i]),
      ]),
      gap16,
      GlassCard(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: context.w - (context.isMobile ? 60 : 340)),
            child: DataTable(
              columnSpacing: 22,
              headingTextStyle: TS.label(p),
              dataRowMinHeight: 54,
              dataRowMaxHeight: 60,
              columns: [for (final k in ['col_source', 'col_data', 'adm_col_state', 'col_freq', 'adm_last_sync', 'col_quality', 'col_conf', 'adm_errors', 'adm_u_actions']) DataColumn(label: Text(context.tr(k).toUpperCase()))],
              rows: [
                for (final o in ops)
                  () {
                    final s = src.firstWhere((x) => x.id == o.id);
                    final busy = _syncing.contains(o.id);
                    return DataRow(cells: [
                      DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(s.nameKey), style: TS.h3(p).copyWith(fontSize: 13.5)), Text('${context.tr('sp_planned')} : ${context.tr('sp_${s.id}')}', style: TS.bodyS(p).copyWith(fontSize: 10.5))])),
                      DataCell(Text(context.tr(s.dataKey), style: TextStyle(color: p.text, fontSize: 13))),
                      DataCell(Chip2(context.tr(['adm_ss_active', 'adm_ss_attention', 'adm_ss_error', 'adm_ss_suspended'][o.status]), cols[o.status], icon: _srcStatus[o.status])),
                      DataCell(Text(context.tr(s.freqKey), style: TextStyle(color: p.text, fontSize: 13))),
                      DataCell(busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(o.lastSync == '0 min' ? context.tr('adm_just_now') : context.tr('ago', [o.lastSync]), style: TextStyle(color: p.muted, fontSize: 12.5))),
                      DataCell(SizedBox(width: 110, child: Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.quality / 100, minHeight: 7, color: s.quality > 85 ? p.green : p.gold, backgroundColor: p.border))), const SizedBox(width: 6), Text(Fmt.num(s.quality, 0), style: TS.h3(p).copyWith(fontSize: 12))]))),
                      DataCell(Chip2(context.tr(['conf_low', 'conf_med', 'conf_high'][s.confidence]), [p.alert, p.gold, p.green][s.confidence])),
                      DataCell(Text('${o.errors}', style: TextStyle(color: o.errors > 10 ? p.alert : p.text, fontWeight: FontWeight.w700))),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(tooltip: context.tr('adm_sync_now'), onPressed: o.status == 3 || busy ? null : () => _sync(o), icon: Icon(Icons.sync_rounded, color: p.accent)),
                        IconButton(
                          tooltip: o.status == 3 ? context.tr('adm_resume') : context.tr('adm_pause'),
                          onPressed: () {
                            o.status = o.status == 3 ? 0 : 3;
                            app.addLog(o.status == 3 ? 'log_src_pause' : 'log_src_resume', o.id);
                            app.touch();
                          },
                          icon: Icon(o.status == 3 ? Icons.play_circle_rounded : Icons.pause_circle_rounded, color: p.gold),
                        ),
                      ])),
                    ]);
                  }(),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(context.tr('adm_src_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
    ]);
  }
}

// ===========================================================================
// Data flows (pipeline)
// ===========================================================================
class AdminFlowsPage extends StatefulWidget {
  const AdminFlowsPage({super.key});
  @override
  State<AdminFlowsPage> createState() => _AdminFlowsPageState();
}

class _AdminFlowsPageState extends State<AdminFlowsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final src = repo.sources();
    final ops = app.sourceOps;
    final recv = ops.fold(0.0, (a, o) => a + o.rowsReceived), valid = ops.fold(0.0, (a, o) => a + o.rowsValid), rej = ops.fold(0.0, (a, o) => a + o.rowsRejected);
    const stages = ['flow_ingest', 'flow_validate', 'flow_transform', 'flow_available'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('adm_flows_title', 'adm_flows_sub'),
      Grid(columns: context.cols(desktop: 4, tablet: 4, mobile: 2), gap: 12, children: [
        KpiCard(labelKey: 'flow_received', metric: 'default', value: recv, icon: Icons.download_rounded),
        KpiCard(labelKey: 'flow_valid', metric: 'default', value: valid, icon: Icons.check_circle_rounded),
        KpiCard(labelKey: 'flow_rejected', metric: 'default', value: rej, icon: Icons.cancel_rounded),
        KpiCard(labelKey: 'flow_errors', metric: 'default', value: ops.fold(0.0, (a, o) => a + o.errors), icon: Icons.bug_report_rounded),
      ]),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('flow_pipeline')),
          for (final o in ops)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final s = src.firstWhere((x) => x.id == o.id);
                  final paused = o.status == 3;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(context.tr(s.nameKey), style: TS.h3(p))),
                      Text('${Fmt.compact(o.rowsReceived)} → ${Fmt.compact(o.rowsValid)} ✓ · ${Fmt.compact(o.rowsRejected)} ✗', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
                    ]),
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (_, c) {
                      final w = c.maxWidth;
                      return SizedBox(
                        height: 40,
                        child: Stack(children: [
                          Positioned(left: 0, right: 0, top: 18, child: Container(height: 3, color: p.border)),
                          for (var i = 0; i < stages.length; i++)
                            Positioned(
                              left: w * i / (stages.length - 1) - (i == stages.length - 1 ? 74 : (i == 0 ? 0 : 37)),
                              top: 0,
                              child: SizedBox(
                                width: 74,
                                child: Column(children: [
                                  Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: paused ? p.muted : (o.status == 2 && i == 1 ? p.alert : (o.status == 1 && i == 1 ? p.warn : p.green)))),
                                  Text(context.tr(stages[i]), style: TextStyle(fontSize: 9.5, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ]),
                              ),
                            ),
                          if (!paused)
                            for (var j = 0; j < 3; j++)
                              Positioned(
                                left: ((_c.value + j / 3) % 1) * (w - 10),
                                top: 14,
                                child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: p.gold.withValues(alpha: .9), boxShadow: [BoxShadow(color: p.gold, blurRadius: 6)])),
                              ),
                        ]),
                      );
                    }),
                  ]);
                },
              ),
            ),
          Text(context.tr('flow_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
        ]),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('flow_valid_pct')),
          BarChartW(
            height: 240,
            unit: '%',
            legend: [(p.green, context.tr('flow_valid'))],
            fmt: (v) => Fmt.num(v, 1),
            items: [for (final o in ops) BarItem(context.tr(src.firstWhere((x) => x.id == o.id).nameKey).split(' ').first, o.validPct, o.validPct > 95 ? p.green : (o.validPct > 85 ? p.warn : p.alert))],
          ),
          Text(context.tr('adm_src_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
        ]),
      ),
    ]);
  }
}

// ===========================================================================
// Data quality
// ===========================================================================
class AdminQualityPage extends StatefulWidget {
  const AdminQualityPage({super.key});
  @override
  State<AdminQualityPage> createState() => _AdminQualityPageState();
}

class _AdminQualityPageState extends State<AdminQualityPage> {
  int? _filter;

  Future<void> _correct(QualityIssue q) async {
    final ctl = TextEditingController(text: Fmt.num(q.expected, q.expected < 10 ? 2 : 0));
    final app = context.app;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('adm_q_correct')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${context.tr(q.titleKey)} (${q.country})'),
          const SizedBox(height: 8),
          Text('${context.tr('observed')}: ${Fmt.num(q.value, q.value < 10 ? 2 : 0)} ${q.unit}'),
          TextField(controller: ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${context.tr('adm_q_new_value')} (${q.unit})')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('adm_save')))],
      ),
    );
    if (ok == true) {
      q.corrected = double.tryParse(ctl.text.replaceAll(',', '.').replaceAll(' ', '')) ?? q.expected;
      q.status = 3;
      app.addLog('log_q_correct', q.id);
      app.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final ops = app.sourceOps;
    final analysed = ops.fold(0.0, (a, o) => a + o.rowsReceived) + 186000;
    final pending = app.issues.where((i) => i.status == 0).length;
    final rejectedIssues = app.issues.where((i) => i.status == 2).length;
    final rejected = ops.fold(0.0, (a, o) => a + o.rowsRejected) + rejectedIssues * 1200;
    final toCheck = 9000.0 + pending * 3560;
    final valid = analysed - rejected - toCheck;
    final shown = app.issues.where((i) => _filter == null || i.status == _filter).toList();
    final stCol = [p.warn, p.green, p.alert, p.accent];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('adm_q_title', 'adm_q_sub'),
      Grid(columns: context.cols(desktop: 4, tablet: 4, mobile: 2), gap: 12, children: [
        KpiCard(labelKey: 'adm_q_analysed', metric: 'default', value: analysed, icon: Icons.analytics_rounded),
        KpiCard(labelKey: 'adm_q_valid', metric: 'default', value: valid, icon: Icons.check_circle_rounded),
        KpiCard(labelKey: 'adm_q_tocheck', metric: 'default', value: toCheck, icon: Icons.rule_rounded),
        KpiCard(labelKey: 'adm_q_rejected', metric: 'default', value: rejected, icon: Icons.cancel_rounded),
      ]),
      gap16,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('adm_q_split')),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: Row(children: [
                Expanded(flex: (valid / analysed * 1000).round(), child: Container(color: p.green)),
                Expanded(flex: (toCheck / analysed * 1000).round().clamp(1, 1000), child: Container(color: p.warn)),
                Expanded(flex: (rejected / analysed * 1000).round().clamp(1, 1000), child: Container(color: p.alert)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(children: [LegendDot(p.green, '${context.tr('adm_q_valid')} ${Fmt.pct(valid / analysed * 100, 1)}'), LegendDot(p.warn, '${context.tr('adm_q_tocheck')} ${Fmt.pct(toCheck / analysed * 100, 1)}'), LegendDot(p.alert, '${context.tr('adm_q_rejected')} ${Fmt.pct(rejected / analysed * 100, 1)}')]),
        ]),
      ),
      gap24,
      SectionLabel(context.tr('adm_q_list'), trailing: Wrap(spacing: 6, children: [
        ChoiceChip(label: Text(context.tr('cat_all')), selected: _filter == null, onSelected: (_) => setState(() => _filter = null), showCheckmark: false),
        for (var i = 0; i < 4; i++) ChoiceChip(label: Text(context.tr(['adm_qs_check', 'adm_qs_valid', 'adm_qs_rejected', 'adm_qs_corrected'][i])), selected: _filter == i, onSelected: (_) => setState(() => _filter = _filter == i ? null : i), showCheckmark: false),
      ])),
      for (final q in shown)
        Reveal(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              accent: stCol[q.status],
              child: Wrap(spacing: 18, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: context.isMobile ? double.infinity : 360,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.flag_rounded, color: stCol[q.status], size: 18), const SizedBox(width: 8), Expanded(child: Text(context.tr(q.titleKey), style: TS.h3(p)))]),
                    const SizedBox(height: 4),
                    Text('${context.tr(q.datasetKey)} · ${context.tr('c_${q.country}')}', style: TS.bodyS(p).copyWith(fontSize: 12)),
                  ]),
                ),
                _kv(context, context.tr('observed'), '${Fmt.num(q.value, q.value.abs() < 10 ? 2 : 0)} ${q.unit}'),
                _kv(context, context.tr('expected'), '${Fmt.num(q.expected, q.expected < 10 ? 2 : 0)} ${q.unit}'),
                Chip2(context.tr(['adm_qs_check', 'adm_qs_valid', 'adm_qs_rejected', 'adm_qs_corrected'][q.status]) + (q.corrected != null ? ' → ${Fmt.num(q.corrected!, q.corrected! < 10 ? 2 : 0)}' : ''), stCol[q.status]),
                if (q.status == 0)
                  Wrap(spacing: 8, children: [
                    FilledButton.tonalIcon(onPressed: () { q.status = 1; app.addLog('log_q_validate', q.id); app.touch(); }, icon: const Icon(Icons.check_rounded, size: 18), label: Text(context.tr('adm_q_validate'))),
                    OutlinedButton.icon(onPressed: () => _correct(q), icon: const Icon(Icons.edit_rounded, size: 18), label: Text(context.tr('adm_q_correct'))),
                    OutlinedButton.icon(onPressed: () { q.status = 2; app.addLog('log_q_reject', q.id); app.touch(); }, icon: Icon(Icons.close_rounded, size: 18, color: p.alert), label: Text(context.tr('adm_q_reject'), style: TextStyle(color: p.alert))),
                  ])
                else
                  TextButton(onPressed: () { q.status = 0; q.corrected = null; app.touch(); }, child: Text(context.tr('adm_q_reopen'))),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(k.toUpperCase(), style: TS.label(p)), const SizedBox(height: 3), Text(v, style: TS.h3(p))]);
  }
}

// ===========================================================================
// KPI manager
// ===========================================================================
class AdminKpiPage extends StatelessWidget {
  const AdminKpiPage({super.key});

  Future<void> _edit(BuildContext context, KpiDef k) async {
    final app = context.app;
    final money = k.unit.startsWith(r'$');
    final ctl = TextEditingController(text: money ? Fmt.money(k.threshold, k.unit.contains('lb') ? 2 : 0).replaceAll(' ', '').replaceAll(',', '') : Fmt.num(k.threshold, k.threshold < 20 ? 1 : 0).replaceAll(' ', '').replaceAll(',', ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr(k.nameKey)),
        content: TextField(controller: ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${context.tr('adm_kpi_threshold')} (${money ? Fmt.unit(k.unit) : k.unit})')),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('adm_save')))],
      ),
    );
    if (ok == true) {
      final v = double.tryParse(ctl.text.replaceAll(',', '.').replaceAll(' ', ''));
      if (v != null) {
        k.threshold = money ? v / Fmt.cur.perUsd : v;
        app.addLog('log_kpi', k.id);
        app.touch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final src = repo.sources();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('adm_kpi_title', 'adm_kpi_sub'),
      Wrap(spacing: 10, children: [
        Chip2('${app.kpis.where((k) => k.status == 0).length} OK', p.green, icon: Icons.check_circle_rounded),
        Chip2('${app.kpis.where((k) => k.status == 1).length} ${context.tr('adm_kpi_alert')}', p.alert, icon: Icons.notifications_active_rounded),
      ]),
      gap16,
      for (final k in app.kpis)
        Reveal(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              accent: k.status == 1 ? p.alert : p.green,
              child: Wrap(spacing: 22, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: context.isMobile ? double.infinity : 330,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(k.nameKey), style: TS.h3(p).copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(context.tr(k.defKey), style: TS.bodyS(p).copyWith(fontSize: 12)),
                  ]),
                ),
                _kv(context, context.tr('adm_kpi_unit'), k.unit.startsWith(r'$') ? Fmt.unit(k.unit) : k.unit),
                _kv(context, context.tr('trust_source'), context.tr(src.firstWhere((s) => s.id == k.sourceId).nameKey)),
                _kv(context, context.tr('col_freq'), context.tr(k.freqKey)),
                _kv(context, context.tr('adm_kpi_current'), kpiValueText(k)),
                _kv(context, context.tr('adm_kpi_threshold'), kpiThresholdText(k)),
                Chip2(k.status == 1 ? context.tr('adm_kpi_alert') : 'OK', k.status == 1 ? p.alert : p.green, icon: k.status == 1 ? Icons.warning_amber_rounded : Icons.check_circle_rounded),
                IconButton(tooltip: context.tr('adm_kpi_edit'), onPressed: () => _edit(context, k), icon: Icon(Icons.edit_rounded, color: p.accent)),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(k.toUpperCase(), style: TS.label(p)), const SizedBox(height: 3), Text(v, style: TS.h3(p).copyWith(fontSize: 13.5))]);
  }
}

// ===========================================================================
// Alert rules (global) + audit log
// ===========================================================================
class AdminRulesPage extends StatelessWidget {
  const AdminRulesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('adm_rules_title', 'adm_rules_sub'),
      const RulesPanel(admin: true),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('adm_activity')),
          if (app.log.isEmpty) Text(context.tr('adm_no_activity'), style: TS.bodyS(p)),
          for (final l in app.log.take(25))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text('${l.ts.hour.toString().padLeft(2, '0')}:${l.ts.minute.toString().padLeft(2, '0')}', style: TS.bodyS(p)),
                const SizedBox(width: 12),
                Expanded(child: Text('${context.tr(l.actionKey)}${l.detail.isEmpty ? '' : ' · ${l.detail}'}', style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
