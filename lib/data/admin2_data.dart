import '../core/format.dart';
import 'repository.dart';

/// Front-end only demo data for the administration area (users, sources, flows, quality, KPIs, rules, schedules).

class AppUser {
  final String id, name, org, email;
  String role;
  int status; // 0 active, 1 invited, 2 suspended
  String lastSeen;
  AppUser(this.id, this.name, this.org, this.email, this.role, this.status, this.lastSeen);
}

List<AppUser> seedUsers() => [
      AppUser('u1', 'Aminata Koné', 'OIAC', 'a.kone@oiac.example', 'admin', 0, '2 min'),
      AppUser('u2', 'Yao Kouassi', 'Coop. Man', 'y.kouassi@coop-man.example', 'coop', 0, '1 h'),
      AppUser('u3', 'Grace Mukamana', 'Huye Coop', 'g.mukamana@huye.example', 'coop', 0, '3 h'),
      AppUser('u4', 'Samuel Mwangi', 'Kenya Coffee Exports', 's.mwangi@kce.example', 'exporter', 0, '5 h'),
      AppUser('u5', 'Fatou Traoré', 'AgriTrade Logistics', 'f.traore@agritrade.example', 'exporter', 1, '—'),
      AppUser('u6', 'Dr. Kofi Mensah', 'Conseil Café-Cacao (démo)', 'k.mensah@board.example', 'board', 0, '30 min'),
      AppUser('u7', 'Esther Bekele', 'Ethiopia Coffee Board (démo)', 'e.bekele@board.example', 'board', 0, '2 j'),
      AppUser('u8', 'Pierre Dubois', 'Torréfaction Atlas', 'p.dubois@atlas.example', 'roaster', 0, '1 j'),
      AppUser('u9', 'Nadia Hassan', 'Roasters United', 'n.hassan@roasters.example', 'roaster', 2, '40 j'),
      AppUser('u10', 'Joseph Okello', 'Fondation Café Durable', 'j.okello@fcd.example', 'ngo', 0, '4 h'),
      AppUser('u11', 'Alice Uwase', 'Donor Partners (démo)', 'a.uwase@donors.example', 'ngo', 0, '6 j'),
      AppUser('u12', 'Moussa Diallo', 'Coop. Daloa', 'm.diallo@coop-daloa.example', 'coop', 1, '—'),
    ];

/// Operational status of each data source (admin view).
class SourceOps {
  final String id;
  int status; // 0 active, 1 attention, 2 error, 3 suspended
  int errors;
  double rowsReceived, rowsValid, rowsRejected;
  String lastSync;
  SourceOps(this.id, this.status, this.errors, this.rowsReceived, this.rowsValid, this.rowsRejected, this.lastSync);
  double get validPct => rowsReceived == 0 ? 0 : rowsValid / rowsReceived * 100;
}

List<SourceOps> seedSourceOps() => [
      SourceOps('markets', 0, 0, 124800, 124350, 450, '24 min'),
      SourceOps('weather', 0, 2, 311200, 305900, 5300, '41 min'),
      SourceOps('production', 0, 1, 48200, 46980, 1220, '6 j'),
      SourceOps('coops', 1, 14, 21500, 19450, 2050, '3 j'),
      SourceOps('certs', 0, 0, 5600, 5588, 12, '34 j'),
      SourceOps('ports', 0, 3, 88400, 86020, 2380, '5 h'),
      SourceOps('satellite', 1, 7, 402000, 381900, 20100, '2 j'),
      SourceOps('customs', 2, 31, 36800, 29700, 7100, '12 j'),
      SourceOps('news', 0, 9, 15400, 14200, 1200, '9 min'),
      SourceOps('survey', 3, 0, 9300, 9100, 200, '112 j'),
    ];

/// Data-quality issues to review.
class QualityIssue {
  final String id, titleKey, datasetKey, country;
  final double value, expected;
  final String unit;
  int status; // 0 to check, 1 validated, 2 rejected, 3 corrected
  double? corrected;
  QualityIssue(this.id, this.titleKey, this.datasetKey, this.country, this.value, this.expected, this.unit, this.status);
}

List<QualityIssue> seedIssues() => [
      QualityIssue('q1', 'qi_yield_high', 'dset_production', 'UGA', 8950, 650, 'kg/ha', 0),
      QualityIssue('q2', 'qi_price_drop', 'dset_prices', 'KEN', 1.12, 3.05, r'$/lb', 0),
      QualityIssue('q3', 'qi_volume_zero', 'dset_coops', 'ETH', 0, 2600, 't', 0),
      QualityIssue('q4', 'qi_rain_neg', 'dset_climate', 'CIV', -14, 90, 'mm', 0),
      QualityIssue('q5', 'qi_dup', 'dset_coops', 'KEN', 900, 900, 't', 0),
      QualityIssue('q6', 'qi_income_low', 'dset_costs', 'TZA', 12, 1050, r'$', 0),
      QualityIssue('q7', 'qi_cert_over', 'dset_sustain', 'RWA', 138, 52, '%', 0),
      QualityIssue('q8', 'qi_delay_high', 'dset_chain', 'TZA', 210, 9, 'jours', 0),
    ];

class KpiDef {
  final String id, nameKey, defKey, unit, sourceId, freqKey;
  double threshold; // alert threshold
  final bool below; // alert when value is below the threshold
  final double Function() current;
  KpiDef(this.id, this.nameKey, this.defKey, this.unit, this.sourceId, this.freqKey, this.threshold, this.below, this.current);
  // status: 0 ok, 1 alert
  int get status => below ? (current() < threshold ? 1 : 0) : (current() > threshold ? 1 : 0);
}

List<KpiDef> seedKpis() => [
      KpiDef('income', 'kpi_def_income', 'kpi_def_income_d', r'$/yr', 'survey', 'f_yearly', 1500, true, () => repo.africaIncome()),
      KpiDef('arabica', 'kpi_price', 'kpi_def_arabica_d', r'$/lb', 'markets', 'f_30min', 3.5, false, () => repo.series('arabica').last.v),
      KpiDef('robusta', 'kpi_def_robusta', 'kpi_def_robusta_d', r'$/lb', 'markets', 'f_30min', 2.0, true, () => repo.series('robusta').last.v),
      KpiDef('production', 'kpi_prod', 'kpi_def_prod_d', 'kt', 'production', 'f_monthly', 1000, true, () => repo.africaProduction()),
      KpiDef('exports', 'kpi_exports', 'kpi_def_exports_d', 'kt', 'customs', 'f_monthly', 900, true, () => repo.africaExports()),
      KpiDef('yield', 'kpi_yield', 'kpi_def_yield_d', 'kg/ha', 'production', 'f_monthly', 600, true, () => 1066 / 1830 * 1000),
      KpiDef('climate', 'kpi_climate', 'kpi_def_climate_d', '/100', 'weather', 'f_1h', 65, false, () => repo.countries(africaOnly: true).fold(0.0, (a, c) => a + c.climateRisk) / 6),
      KpiDef('cert', 'kpi_def_cert', 'kpi_def_cert_d', '%', 'certs', 'f_quarterly', 25, true, () => repo.countries(africaOnly: true).fold(0.0, (a, c) => a + c.certPct) / 6),
      KpiDef('delay', 'kpi_def_delay', 'kpi_def_delay_d', 'jours', 'ports', 'f_daily', 75, false, () => repo.chain().fold(0.0, (a, s) => a + s.delayDays)),
      KpiDef('quality', 'kpi_def_quality', 'kpi_def_quality_d', '/100', 'coops', 'f_variable', 82, true, () => 83.4),
    ];

String kpiValueText(KpiDef k) {
  final v = k.current();
  if (k.unit.startsWith(r'$')) return '${Fmt.money(v, k.unit.contains('lb') ? 2 : 0)} ${Fmt.unit(k.unit)}';
  return '${Fmt.num(v, v < 20 ? 1 : 0)} ${k.unit}';
}

String kpiThresholdText(KpiDef k) {
  final v = k.threshold;
  final cmp = k.below ? '<' : '>';
  if (k.unit.startsWith(r'$')) return '$cmp ${Fmt.money(v, k.unit.contains('lb') ? 2 : 0)} ${Fmt.unit(k.unit)}';
  return '$cmp ${Fmt.num(v, v < 20 ? 1 : 0)} ${k.unit}';
}

/// Alert rule: IF cond1 [AND cond2] THEN create alert.
class RuleCond {
  String metric; // arabica, robusta, rain, climate, exports, delay
  String op; // lt | gt
  double value; // in base units (USD for prices)
  RuleCond(this.metric, this.op, this.value);
}

class AlertRule {
  final String id;
  String nameKey, custom; // custom name if user typed
  final List<RuleCond> conds;
  int severity;
  bool enabled;
  AlertRule(this.id, this.nameKey, this.custom, this.conds, this.severity, this.enabled);
}

double ruleMetricValue(String m) {
  switch (m) {
    case 'arabica':
      return repo.series('arabica').last.v;
    case 'robusta':
      return repo.series('robusta').last.v;
    case 'rain':
      return 82; // % of normal rainfall (demo)
    case 'climate':
      return repo.countries(africaOnly: true).fold(0.0, (a, c) => a + c.climateRisk) / 6;
    case 'exports':
      return repo.africaExports();
    case 'delay':
      return 11;
  }
  return 0;
}

bool ruleMet(AlertRule r) => r.conds.every((c) {
      final v = ruleMetricValue(c.metric);
      return c.op == 'lt' ? v < c.value : v > c.value;
    });

List<AlertRule> seedRules() => [
      AlertRule('r1', 'rule_critical_price', '', [RuleCond('robusta', 'lt', 2.5)], 0, true),
      AlertRule('r2', 'rule_prod_risk', '', [RuleCond('rain', 'lt', 90), RuleCond('climate', 'gt', 55)], 1, true),
      AlertRule('r3', 'rule_export_drop', '', [RuleCond('exports', 'lt', 900)], 1, true),
      AlertRule('r4', 'rule_port_delay', '', [RuleCond('delay', 'gt', 9)], 2, false),
    ];

/// Report schedule (email delivery is simulated).
class ReportSchedule {
  final String id;
  final String reportId;
  String freq; // daily | weekly | monthly
  String recipientRole;
  String recipientName;
  bool enabled;
  ReportSchedule(this.id, this.reportId, this.freq, this.recipientRole, this.recipientName, this.enabled);
}

List<ReportSchedule> seedSchedules() => [
      ReportSchedule('s1', 'market', 'weekly', 'exporter', 'Samuel Mwangi', true),
      ReportSchedule('s2', 'monthly', 'monthly', 'board', 'Dr. Kofi Mensah', true),
      ReportSchedule('s3', 'sustain', 'monthly', 'ngo', 'Joseph Okello', false),
    ];
