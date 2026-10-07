import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/admin2_data.dart';
import '../../widgets/common.dart';

const ruleMetrics = ['arabica', 'robusta', 'rain', 'climate', 'exports', 'delay'];

String ruleValueText(BuildContext c, String metric, double v) {
  switch (metric) {
    case 'arabica':
    case 'robusta':
      return '${Fmt.money(v, 2)} ${Fmt.unit(r'$/lb')}';
    case 'rain':
      return '${Fmt.num(v, 0)} % ${c.tr('rule_of_normal')}';
    case 'climate':
      return '${Fmt.num(v, 0)}/100';
    case 'exports':
      return '${Fmt.num(v, 0)} kt';
    default:
      return '${Fmt.num(v, 0)} ${c.tr('days')}';
  }
}

/// Visual alert rules: IF … AND … THEN create an alert. The rule engine is simulated.
class RulesPanel extends StatefulWidget {
  final bool admin;
  const RulesPanel({super.key, this.admin = false});
  @override
  State<RulesPanel> createState() => _RulesPanelState();
}

class _RulesPanelState extends State<RulesPanel> {
  String _m1 = 'robusta', _m2 = 'climate';
  String _o1 = 'lt', _o2 = 'gt';
  final _v1 = TextEditingController();
  final _v2 = TextEditingController();
  final _name = TextEditingController();
  bool _two = false;
  int _sev = 1;

  @override
  void dispose() {
    _v1.dispose();
    _v2.dispose();
    _name.dispose();
    super.dispose();
  }

  double? _parse(String metric, String text) {
    final n = double.tryParse(text.replaceAll(',', '.').replaceAll(' ', ''));
    if (n == null) return null;
    return (metric == 'arabica' || metric == 'robusta') ? n / Fmt.cur.perUsd : n;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;

    Widget condChip(RuleCond c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: p.accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(10), border: Border.all(color: p.accent.withValues(alpha: .4))),
          child: Text('${context.tr('rm_${c.metric}')} ${c.op == 'lt' ? '<' : '>'} ${ruleValueText(context, c.metric, c.value)}', style: TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 12.5)),
        );

    Widget kw(String t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(t, style: TextStyle(color: p.gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)));

    Widget builderRow(String metric, String op, TextEditingController ctl, void Function(String) setM, void Function(String) setO) => Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: metric,
              isExpanded: true,
              decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: [for (final m in ruleMetrics) DropdownMenuItem(value: m, child: Text(context.tr('rm_$m'), overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => setM(v ?? metric)),
            ),
          ),
          Segmented<String>(values: const ['lt', 'gt'], selected: op, label: (v) => v == 'lt' ? '<' : '>', onChanged: (v) => setState(() => setO(v))),
          SizedBox(
            width: 130,
            child: TextField(
              controller: ctl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(isDense: true, hintText: (metric == 'arabica' || metric == 'robusta') ? Fmt.money(2.5, 2) : '', suffixText: (metric == 'arabica' || metric == 'robusta') ? Fmt.sym : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]);

    return GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr(widget.admin ? 'rules_admin_title' : 'rules_title'), trailing: Chip2('${app.rules.where((r) => r.enabled).length} ${context.tr('sch_active')}', p.green)),
        Text(context.tr('rules_sub'), style: TS.bodyS(p)),
        const SizedBox(height: 12),
        for (final r in app.rules)
          Builder(builder: (_) {
            final met = ruleMet(r);
            final name = r.custom.isNotEmpty ? r.custom : context.tr(r.nameKey);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: r.enabled && met ? p.sev(r.severity) : p.border, width: r.enabled && met ? 1.6 : 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, style: TS.h3(p))),
                  SevChip(r.severity),
                  Switch(value: r.enabled, onChanged: (v) {
                    r.enabled = v;
                    app.touch();
                  }),
                ]),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: [
                  kw(context.tr('rule_if')),
                  for (var i = 0; i < r.conds.length; i++) ...[if (i > 0) kw(context.tr('rule_and')), condChip(r.conds[i])],
                  kw(context.tr('rule_then')),
                  Chip2('${context.tr('rule_create_alert')} « $name »', p.sev(r.severity), icon: Icons.notifications_active_rounded),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: met ? p.sev(r.severity) : p.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(met ? context.tr('rule_met_now') : context.tr('rule_not_met'), style: TS.bodyS(p).copyWith(fontSize: 12))),
                  TextButton.icon(
                    onPressed: () {
                      final msg = met ? context.tr('rule_test_met', [name]) : context.tr('rule_test_not', [name]);
                      if (met) app.addLog('log_rule', name);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(context.tr('rule_test')),
                  ),
                  IconButton(visualDensity: VisualDensity.compact, onPressed: () {
                    app.rules.remove(r);
                    app.touch();
                  }, icon: Icon(Icons.delete_outline_rounded, size: 19, color: p.muted)),
                ]),
              ]),
            );
          }),
        const Divider(height: 26),
        Text(context.tr('rule_new').toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 10),
        Row(children: [kw(context.tr('rule_if'))]),
        builderRow(_m1, _o1, _v1, (v) => _m1 = v, (v) => _o1 = v),
        const SizedBox(height: 8),
        Row(children: [
          Switch(value: _two, onChanged: (v) => setState(() => _two = v)),
          kw(context.tr('rule_and')),
        ]),
        if (_two) builderRow(_m2, _o2, _v2, (v) => _m2 = v, (v) => _o2 = v),
        const SizedBox(height: 10),
        Row(children: [kw(context.tr('rule_then'))]),
        Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 240, child: TextField(controller: _name, decoration: InputDecoration(isDense: true, labelText: context.tr('rule_alert_name'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
          Segmented<int>(values: const [0, 1, 2], selected: _sev, label: (v) => context.tr(['sev_critical', 'sev_important', 'sev_watch'][v]), onChanged: (v) => setState(() => _sev = v)),
          PrimaryButton(context.tr('rule_add'), icon: Icons.rule_rounded, onTap: () {
            final a = _parse(_m1, _v1.text);
            final b = _two ? _parse(_m2, _v2.text) : null;
            if (a == null || (_two && b == null)) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('adm_invalid'))));
              return;
            }
            app.rules.add(AlertRule('r${DateTime.now().millisecondsSinceEpoch}', 'rule_custom', _name.text.trim(), [RuleCond(_m1, _o1, a), if (_two) RuleCond(_m2, _o2, b!)], _sev, true));
            app.addLog('log_rule_add', _name.text.trim());
            _v1.clear();
            _v2.clear();
            _name.clear();
            app.touch();
          }),
        ]),
        const SizedBox(height: 8),
        Text(context.tr('rules_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      ]),
    );
  }
}
