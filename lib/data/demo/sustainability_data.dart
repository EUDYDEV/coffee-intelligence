import '../../models/models.dart';

/// Sustainability dimensions (0..100, higher is better) derived from the demo country record.
class SustainBreakdown {
  final double certification, livingIncome, yieldPractice, forest, emissions, coverage, social, environment;
  const SustainBreakdown(this.certification, this.livingIncome, this.yieldPractice, this.forest,
      this.emissions, this.coverage, this.social, this.environment);
  double get overall => (social + environment) / 2;
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
  return SustainBreakdown(cert, living, yieldP, forest, emis, cover, social, env);
}
