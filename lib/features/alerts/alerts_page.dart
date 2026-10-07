import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import 'rules_panel.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String _cat = 'all';
  String _metric = 'arabica';
  String _op = 'above';
  double _thr = 3.5;
  final TextEditingController _kw = TextEditingController(text: 'frost');

  static const _cats = ['all', 'price', 'weather', 'production', 'transport', 'market', 'sustainability', 'keyword'];
  static const _catIcons = {
    'price': Icons.attach_money_rounded,
    'weather': Icons.thunderstorm_rounded,
    'production': Icons.spa_rounded,
    'transport': Icons.local_shipping_rounded,
    'market': Icons.candlestick_chart_rounded,
    'sustainability': Icons.eco_rounded,
    'keyword': Icons.label_important_rounded,
  };
  static const _metrics = {'arabica': (1.5, 5.0, '\$/lb'), 'robusta': (1.0, 4.0, '\$/lb'), 'rain': (0.0, 100.0, '/100'), 'exports': (500.0, 1500.0, 'kt')};

  @override
  void dispose() {
    _kw.dispose();
    super.dispose();
  }

  double _current(String m) => switch (m) {
        'arabica' => repo.series('arabica').last.v,
        'robusta' => repo.series('robusta').last.v,
        'rain' => 66.0,
        _ => repo.africaExports(),
      };

  void _toast(String text, IconData icon) {
    final p = context.pal;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CI.espressoDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.gold)),
      content: Row(children: [Icon(icon, color: CI.gold), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(color: CI.cream)))]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final alerts = repo.alerts().where((a) => _cat == 'all' || a.category == _cat).toList();
    final m = _metrics[_metric]!;
    final isKw = _metric == 'keyword';

    final create = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('create_alert')),
        Text(context.tr('alert_notify_me', [Fmt.usd(3.5)]), style: TS.bodyS(p)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _metric,
          decoration: InputDecoration(labelText: context.tr('metric'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: [
            for (final k in [..._metrics.keys, 'keyword']) DropdownMenuItem(value: k, child: Text(context.tr('am_$k'))),
          ],
          onChanged: (v) => setState(() {
            _metric = v!;
            if (_metrics.containsKey(v)) _thr = v == 'arabica' ? 3.5 : (v == 'robusta' ? 2.8 : (v == 'rain' ? 75 : 950));
          }),
        ),
        const SizedBox(height: 12),
        if (isKw)
          TextField(controller: _kw, decoration: InputDecoration(labelText: context.tr('keyword'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))
        else ...[
          Segmented<String>(values: const ['above', 'below'], selected: _op, label: (v) => context.tr('op_$v'), onChanged: (v) => setState(() => _op = v)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Slider(value: _thr.clamp(m.$1, m.$2), min: m.$1, max: m.$2, onChanged: (v) => setState(() => _thr = v))),
            SizedBox(width: 90, child: Text(_metric == 'arabica' || _metric == 'robusta' ? '${Fmt.money(_thr)} ${Fmt.unit(m.$3)}' : '${Fmt.num(_thr, 0)} ${m.$3}', style: TS.h3(p), textAlign: TextAlign.right)),
          ]),
        ],
        const SizedBox(height: 10),
        PrimaryButton(context.tr('create_alert'), icon: Icons.add_alert_rounded, onTap: () {
          app.addAlert(UserAlert(isKw ? 'kw:${_kw.text}' : _metric, _op, isKw ? 0 : _thr));
          _toast(context.tr('alert_created'), Icons.notifications_active_rounded);
        }),
        if (app.userAlerts.isNotEmpty) ...[
          const Divider(height: 30),
          SectionLabel(context.tr('my_alerts')),
          for (final u in app.userAlerts)
            Reveal(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UserAlertTile(u: u, current: u.metric.startsWith('kw:') ? 0 : _current(u.metric), onFire: () => _toast(u.metric.startsWith('kw:') ? context.tr('kw_triggered', [u.metric.substring(3)]) : context.tr('alert_triggered', [context.tr('am_${u.metric}')]), Icons.notifications_rounded), onDelete: () => app.removeAlert(u)),
              ),
            ),
        ],
      ]),
    );

    final feed = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in _cats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: c == 'all' ? null : Icon(_catIcons[c], size: 16, color: _cat == c ? Colors.white : p.muted),
                label: Text(context.tr('cat_$c')),
                selected: _cat == c,
                showCheckmark: false,
                selectedColor: p.accent,
                labelStyle: TextStyle(color: _cat == c ? Colors.white : p.text, fontWeight: FontWeight.w600, fontSize: 12.5),
                onSelected: (_) => setState(() => _cat = c),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      AnimatedSwitcher(
        duration: context.dur(300),
        child: Column(
          key: ValueKey(_cat),
          children: [
            for (var i = 0; i < alerts.length; i++)
              Reveal(
                delay: i * 70,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    accent: p.sev(alerts[i].severity),
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(shape: BoxShape.circle, color: p.sev(alerts[i].severity).withValues(alpha: .14)), child: Icon(_catIcons[alerts[i].category], size: 18, color: p.sev(alerts[i].severity))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(context.tr(alerts[i].titleKey), style: TS.h3(p))), Text(context.tr('ago', [alerts[i].ago]), style: TS.bodyS(p).copyWith(fontSize: 11))]),
                          const SizedBox(height: 3),
                          Text(context.tr(alerts[i].textKey), style: TS.bodyS(p)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: [SevChip(alerts[i].severity), Chip2(context.tr('cat_${alerts[i].category}'), p.muted)]),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('alerts_title', 'alerts_sub'),
      TwoCol(flexL: 6, flexR: 4, stretch: false, left: feed, right: create),
      gap24,
      const RulesPanel(),
    ]);
  }
}

class _UserAlertTile extends StatelessWidget {
  final UserAlert u;
  final double current;
  final VoidCallback onFire, onDelete;
  const _UserAlertTile({required this.u, required this.current, required this.onFire, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final kw = u.metric.startsWith('kw:');
    final reached = !kw && (u.op == 'above' ? current >= u.threshold : current <= u.threshold);
    final gap = kw ? 0 : (u.threshold / current - 1) * 100;
    final text = kw
        ? '${context.tr('am_keyword')}: "${u.metric.substring(3)}"'
        : '${context.tr('am_${u.metric}')} ${context.tr('op_${u.op}')} ${u.metric == 'arabica' || u.metric == 'robusta' ? Fmt.money(u.threshold) : Fmt.num(u.threshold, 0)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: reached ? p.alert : p.border)),
      child: Row(children: [
        Icon(kw ? Icons.label_important_rounded : Icons.notifications_active_rounded, color: reached ? p.alert : p.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: TS.h3(p).copyWith(fontSize: 13)),
            Text(kw ? context.tr('watching_news') : (reached ? context.tr('threshold_reached') : context.tr('gap_to_threshold', [Fmt.pct(gap.abs().toDouble(), 1)])), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
          ]),
        ),
        IconButton(tooltip: context.tr('simulate_trigger'), onPressed: onFire, icon: Icon(Icons.play_arrow_rounded, color: p.green)),
        IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline_rounded, color: p.muted)),
      ]),
    );
  }
}
