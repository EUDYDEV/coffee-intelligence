import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/export/download.dart';
import '../../core/export/export_data.dart';
import '../../core/export/pdf_export.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/admin2_data.dart';
import '../../data/repository.dart';
import '../../data/role_data.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../../widgets/org_logo.dart';

const _reports = [
  ('market', Icons.candlestick_chart_rounded),
  ('production', Icons.spa_rounded),
  ('quality', Icons.coffee_rounded),
  ('sustain', Icons.eco_rounded),
  ('risks', Icons.shield_rounded),
  ('chain', Icons.account_tree_rounded),
  ('africa', Icons.public_rounded),
  ('monthly', Icons.calendar_month_rounded),
];

String _stamp() {
  final n = DateTime.now();
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

/// Report center: generate (real PDF/CSV, locally), preview and schedule (e-mail delivery is simulated).
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  String? _id;
  bool _init = false;
  // schedule form
  String _sReport = 'market';
  String _sFreq = 'weekly';
  String _sUser = 'u6';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _c.duration = context.calm ? const Duration(milliseconds: 600) : const Duration(milliseconds: 5200);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _generate(String id) {
    setState(() => _id = id);
    context.app.addLog('log_report', id);
    _c.forward(from: 0);
  }

  Future<void> _download(String id, String kind) async {
    final doc = reportDoc(id, context.tr);
    final base = 'oiac_report_${id}_${_stamp()}';
    final msg = ScaffoldMessenger.of(context);
    final ok = context.tr('export_done');
    try {
      if (kind == 'pdf') {
        final Uint8List b = await docToPdf(doc, footer: context.tr('pdf_footer'), generated: context.tr('pdf_generated', [_stamp()]), org: context.tr('org_name'));
        await saveFile('$base.pdf', b, 'application/pdf');
      } else {
        await saveFile('$base.csv', docToCsv(doc), 'text/csv');
      }
      msg.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('$ok · ${kind.toUpperCase()}')));
    } catch (e) {
      msg.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('${context.tr('export_fail')} ($e)')));
    }
  }

  String _next(String freq) {
    final n = DateTime.now();
    final d = freq == 'daily' ? n.add(const Duration(days: 1)) : (freq == 'weekly' ? n.add(Duration(days: 8 - n.weekday)) : DateTime(n.year, n.month + 1, 1));
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} 07:00';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final cards = Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 1), gap: 14, children: [
      for (var i = 0; i < _reports.length; i++)
        Reveal(
          delay: i * 60,
          child: GlassCard(
            selected: _id == _reports[i].$1,
            onTap: () => _generate(_reports[i].$1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: p.accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Icon(_reports[i].$2, color: p.accent)),
                const Spacer(),
                Chip2('PDF · CSV', p.muted),
              ]),
              const SizedBox(height: 14),
              Text(context.tr('rep_${_reports[i].$1}'), style: TS.h2(p).copyWith(fontSize: 17)),
              const SizedBox(height: 4),
              Text(context.tr('rep_${_reports[i].$1}_d'), style: TS.bodyS(p)),
              const SizedBox(height: 14),
              Row(children: [Icon(Icons.auto_awesome_rounded, size: 15, color: p.gold), const SizedBox(width: 6), Text(context.tr('generate'), style: TextStyle(color: p.gold, fontWeight: FontWeight.w700, fontSize: 12.5))]),
            ]),
          ),
        ),
    ]);

    final sched = app.schedules;
    final scheduleCard = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('sch_title'), trailing: Chip2('${sched.where((s) => s.enabled).length} ${context.tr('sch_active')}', p.green)),
        Text(context.tr('sch_sub'), style: TS.bodyS(p)),
        const SizedBox(height: 12),
        if (sched.isEmpty) Text(context.tr('sch_none'), style: TS.bodyS(p)),
        for (final s in sched)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
            child: Row(children: [
              Icon(s.enabled ? Icons.schedule_send_rounded : Icons.pause_circle_outline_rounded, color: s.enabled ? p.green : p.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr('rep_${s.reportId}'), style: TS.h3(p).copyWith(fontSize: 13.5)),
                  Text('${context.tr('freq_${s.freq}')} · ${s.recipientName} (${context.tr(roleById(s.recipientRole).nameKey)})', style: TS.bodyS(p).copyWith(fontSize: 12)),
                  if (s.enabled) Text('${context.tr('sch_next')} : ${_next(s.freq)}', style: TS.bodyS(p).copyWith(fontSize: 11)),
                ]),
              ),
              IconButton(
                tooltip: context.tr('sch_send_now'),
                onPressed: () {
                  app.addLog('log_email', s.reportId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('sch_sent', [s.recipientName]))));
                },
                icon: Icon(Icons.send_rounded, color: p.accent, size: 20),
              ),
              Switch(value: s.enabled, onChanged: (v) {
                s.enabled = v;
                app.touch();
              }),
              IconButton(onPressed: () {
                app.schedules.remove(s);
                app.touch();
              }, icon: Icon(Icons.delete_outline_rounded, color: p.muted, size: 20)),
            ]),
          ),
        const Divider(height: 28),
        Text(context.tr('sch_new').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<String>(
              initialValue: _sReport,
              isExpanded: true,
              decoration: InputDecoration(isDense: true, labelText: context.tr('sch_report'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: [for (final r in _reports) DropdownMenuItem(value: r.$1, child: Text(context.tr('rep_${r.$1}'), overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _sReport = v ?? _sReport),
            ),
          ),
          Segmented<String>(values: const ['daily', 'weekly', 'monthly'], selected: _sFreq, label: (v) => context.tr('freq_$v'), onChanged: (v) => setState(() => _sFreq = v)),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: _sUser,
              isExpanded: true,
              decoration: InputDecoration(isDense: true, labelText: context.tr('sch_recipient'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: [for (final u in app.users) DropdownMenuItem(value: u.id, child: Text('${u.name} · ${context.tr(roleById(u.role).nameKey)}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _sUser = v ?? _sUser),
            ),
          ),
          PrimaryButton(context.tr('sch_add'), icon: Icons.add_alarm_rounded, onTap: () {
            final u = app.users.firstWhere((x) => x.id == _sUser);
            app.schedules.add(ReportSchedule('s${DateTime.now().millisecondsSinceEpoch}', _sReport, _sFreq, u.role, u.name, true));
            app.addLog('log_schedule', _sReport);
            app.touch();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('sch_added'))));
          }),
        ]),
        const SizedBox(height: 10),
        Text(context.tr('sch_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('reports_title', 'reports_sub'),
      cards,
      if (_id != null) ...[
        gap24,
        AnimatedBuilder(animation: _c, builder: (_, __) => _Generation(id: _id!, t: _c.value, onDownload: (k) => _download(_id!, k))),
      ],
      gap24,
      scheduleCard,
    ]);
  }
}

class _Generation extends StatelessWidget {
  final String id;
  final double t;
  final void Function(String kind) onDownload;
  const _Generation({required this.id, required this.t, required this.onDownload});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const stages = ['gen_prepare', 'gen_analyze', 'gen_generate', 'gen_ready'];
    final idx = (t * 4).floor().clamp(0, 3);
    final done = t >= 1;
    return GlassCard(
      accent: done ? p.green : p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('rep_$id')),
        Row(children: [
          for (var i = 0; i < stages.length; i++) ...[
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: context.dur(300),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < idx || done ? p.green : (i == idx ? p.gold : p.surface2), border: Border.all(color: i <= idx || done ? Colors.transparent : p.border)),
                  child: Icon(i < idx || done ? Icons.check_rounded : [Icons.cloud_download_rounded, Icons.analytics_rounded, Icons.edit_document, Icons.task_alt_rounded][i], size: 19, color: i <= idx || done ? Colors.white : p.muted),
                ),
                const SizedBox(height: 6),
                Text(context.tr(stages[i]), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500, color: i <= idx || done ? p.text : p.muted)),
              ]),
            ),
            if (i < stages.length - 1)
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: LinearProgressIndicator(value: ((t * 4 - i)).clamp(0.0, 1.0), minHeight: 3, color: p.green, backgroundColor: p.border))),
          ],
        ]),
        if (done) ...[
          const SizedBox(height: 20),
          _Preview(id: id, onDownload: onDownload),
        ],
      ]),
    );
  }
}

class _Preview extends StatelessWidget {
  final String id;
  final void Function(String kind) onDownload;
  const _Preview({required this.id, required this.onDownload});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final af = repo.countries(africaOnly: true);
    final paper = p.dark ? const Color(0xFF3A2A20) : const Color(0xFFFFFEFA);
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 16 : 28),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: p.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const OrgLogo(height: 34, framed: false),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('org_name').toUpperCase(), style: TS.label(p), overflow: TextOverflow.ellipsis)),
          const DemoTag(),
        ]),
        const SizedBox(height: 14),
        Text(context.tr('rep_$id'), style: TS.h1(p).copyWith(fontSize: 26)),
        Text('${context.tr('rep_period')} · ${context.tr('rep_generated')}', style: TS.bodyS(p)),
        const Divider(height: 28),
        Text(context.tr('rep_summary').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 6),
        Text(context.tr('rep_${id}_sum', [Fmt.usd(3.1)]), style: TextStyle(color: p.text, fontSize: 14, height: 1.55)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _K(context.tr('kpi_price'), Fmt.usd(repo.series('arabica').last.v), p)),
          Expanded(child: _K(context.tr('kpi_prod'), '${Fmt.num(repo.africaProduction(), 0)} kt', p)),
          Expanded(child: _K(context.tr('kpi_income'), Fmt.usd(repo.africaIncome(), 0), p)),
        ]),
        const SizedBox(height: 14),
        BarChartW(height: 170, sourceId: 'production', unit: 'kt', legend: [(p.accent, context.tr('kpi_prod'))], fmt: (v) => Fmt.num(v, 0), items: [for (final c in af) BarItem(c.id, c.prodKt, p.accent)]),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          PrimaryButton(context.tr('download_pdf'), icon: Icons.picture_as_pdf_rounded, onTap: () => onDownload('pdf')),
          PrimaryButton('CSV', icon: Icons.table_chart_rounded, outlined: true, onTap: () => onDownload('csv')),
          PrimaryButton(context.tr('share'), icon: Icons.mail_outline_rounded, outlined: true, onTap: () {
            context.app.addLog('log_email', id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('sch_sent', [context.app.adminUser]))));
          }),
        ]),
      ]),
    );
  }
}

class _K extends StatelessWidget {
  final String l, v;
  final Pal p;
  const _K(this.l, this.v, this.p);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.toUpperCase(), style: TS.label(p), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(v, style: TS.big(p, size: 20)),
      ]);
}
