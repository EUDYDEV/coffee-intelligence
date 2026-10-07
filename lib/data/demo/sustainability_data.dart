import '../../models/models.dart';

/// Governance indicators (the "G" of ESG) — DEMO values derived from the country record.
class GovBreakdown {
  final double transparency, coopGovernance, compliance, audit, traceability, grievance, controlFreq, auditCoverage;
  const GovBreakdown(this.transparency, this.coopGovernance, this.compliance, this.audit, this.traceability, this.grievance, this.controlFreq, this.auditCoverage);
  double get score => (transparency + coopGovernance + compliance + audit + traceability + grievance) / 6;
}

double _h(String k) {
  var h = 3;
  for (final c in k.codeUnits) {
    h = (h * 43 + c) % 99971;
  }
  return h / 99971;
}

GovBreakdown govFor(Country c) {
  double cl(double v) => v.clamp(15, 97).toDouble();
  final base = 38 + c.certPct * .55 + (c.incomeYr / 4000) * 12;
  return GovBreakdown(
    cl(base + (_h('${c.id}t') - .5) * 18),
    cl(base - 4 + (_h('${c.id}g') - .5) * 18),
    cl(base + 4 + (_h('${c.id}c') - .5) * 14),
    cl(base - 2 + (_h('${c.id}a') - .5) * 16),
    cl(base + 2 + (_h('${c.id}r') - .5) * 18),
    cl(base - 8 + (_h('${c.id}m') - .5) * 20),
    (1 + c.certPct / 14 + _h('${c.id}f') * 2).roundToDouble(), // controls per year
    cl(c.certPct * 1.3 + 20 + (_h('${c.id}v') - .5) * 12),
  );
}

/// ESG dimensions (0..100, higher is better) derived from the demo country record:
/// E = environment, S = social, G = governance.
class SustainBreakdown {
  final double certification, livingIncome, yieldPractice, forest, emissions, coverage, social, environment, governance;
  const SustainBreakdown(this.certification, this.livingIncome, this.yieldPractice, this.forest, this.emissions, this.coverage, this.social, this.environment, this.governance);
  double get overall => (social + environment + governance) / 3;
}

SustainBreakdown sustainFor(Country c) {
  double cl(double v) => v.clamp(5, 98).toDouble();
  final cert = cl(c.certPct * 1.5 + 18);
  final living = cl(c.incomeYr / 3500 * 100 + 25);
  final yieldP = cl(c.yieldKgHa / 1700 * 60 + 35);
  final forest = cl(100 - c.deforestRisk);
  final emis = cl(88 - c.areaKha / 40 - (c.climateRisk - 50) * .3);
  final cover = cl(c.certPct * 1.3 + 25);
  final social = (living * .5 + cert * .3 + cover * .2);
  final env = (forest * .5 + emis * .25 + yieldP * .25);
  return SustainBreakdown(cert, living, yieldP, forest, emis, cover, social, env, govFor(c).score);
}
