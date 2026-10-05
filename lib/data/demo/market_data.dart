import 'dart:math' as math;
import '../../models/models.dart';

/// Deterministic pseudo-random generator (identical on every platform).
class Lcg {
  int _s;
  Lcg(this._s) {
    for (var i = 0; i < 8; i++) {
      next();
    }
  }
  double next() {
    _s = (_s * 48271) % 2147483647; // Park–Miller, safe within 2^53 on web
    return _s / 2147483647;
  }

  double noise(double amp) => (next() - .5) * 2 * amp;
}

final DateTime demoNow = DateTime(2026, 10, 1);

DateTime monthsAgo(int n) => DateTime(demoNow.year, demoNow.month - n, 1);

List<SeriesPoint> _monthly(int n, double Function(int i, Lcg r) f, {int seed = 1}) {
  final r = Lcg(seed);
  return [for (var i = 0; i < n; i++) SeriesPoint(monthsAgo(n - 1 - i), f(i, r))];
}

List<SeriesPoint> _rescale(List<SeriesPoint> s, double last) {
  final k = last / s.last.v;
  return [for (final p in s) SeriesPoint(p.t, p.v * k)];
}

/// Arabica benchmark, USD/lb, 36 months. Contains a sudden drop at index 27.
final List<SeriesPoint> arabicaSeries = _rescale(
    _monthly(36, (i, r) {
      var v = 2.35 + 0.0215 * i + 0.16 * math.sin(i * .55) + r.noise(.05);
      if (i == 27) v *= .80;
      return v;
    }, seed: 7),
    3.12);

final List<SeriesPoint> robustaSeries = _rescale(
    _monthly(36, (i, r) => 1.85 + 0.014 * i + 0.12 * math.sin(i * .45 + 1) + r.noise(.04), seed: 11), 2.38);

/// Last 30 days, daily arabica.
List<SeriesPoint> dailyArabica() {
  final r = Lcg(21);
  final base = arabicaSeries.last.v;
  return [
    for (var i = 0; i < 30; i++)
      SeriesPoint(demoNow.add(Duration(days: i - 29)),
          base * (0.97 + 0.03 * math.sin(i * .5) + r.noise(.012) + i * .0009))
  ];
}

/// Kenya monthly exports (kt) with a sudden drop (anomaly).
final List<SeriesPoint> exportsKenSeries = _monthly(24, (i, r) {
  var v = 3.6 + .8 * math.sin(i * .52) + r.noise(.15);
  if (i == 20) v *= .55;
  return v;
}, seed: 5);

final List<SeriesPoint> yieldUgaSeries = _monthly(24, (i, r) {
  var v = 640 + 25 * math.sin(i * .5) + r.noise(8);
  if (i == 16) v += 150;
  return v;
}, seed: 9);

final List<SeriesPoint> prodEthSeries = _monthly(24, (i, r) {
  var v = 36 + 4 * math.sin(i * .55) + i * .15 + r.noise(.8);
  if (i == 22) v += 9;
  return v;
}, seed: 13);

final List<SeriesPoint> rainCivSeries = _monthly(24, (i, r) {
  var v = 100 + 35 * math.sin(i * .52) + r.noise(5);
  if (i == 21) v = 28;
  return v;
}, seed: 17);

final List<SeriesPoint> delayTzaSeries = _monthly(24, (i, r) {
  var v = 6 + 1.2 * math.sin(i * .6) + r.noise(.4);
  if (i == 18) v += 5;
  return v;
}, seed: 23);

List<SeriesPoint> seriesById(String id) {
  switch (id) {
    case 'arabica':
      return arabicaSeries;
    case 'robusta':
      return robustaSeries;
    case 'exports_ken':
      return exportsKenSeries;
    case 'yield_uga':
      return yieldUgaSeries;
    case 'prod_eth':
      return prodEthSeries;
    case 'rain_civ':
      return rainCivSeries;
    case 'delay_tza':
      return delayTzaSeries;
  }
  return arabicaSeries;
}

/// Market indicators.
class MarketIndicator {
  final String key;
  final double value, day, month, year;
  final String unit;
  const MarketIndicator(this.key, this.value, this.day, this.month, this.year, this.unit);
}

List<MarketIndicator> marketIndicators() {
  final a = arabicaSeries, r = robustaSeries;
  double ch(List<SeriesPoint> s, int n) => (s.last.v / s[s.length - 1 - n].v - 1) * 100;
  return [
    MarketIndicator('arabica', a.last.v, 0.8, ch(a, 1), ch(a, 12), '\$/lb'),
    MarketIndicator('robusta', r.last.v, -0.4, ch(r, 1), ch(r, 12), '\$/lb'),
    MarketIndicator('spread', a.last.v - r.last.v, 1.9, 3.4, 8.1, '\$/lb'),
    MarketIndicator('volatility', 24.6, 3.0, 11.0, 18.0, '%'),
  ];
}

/// Transport cost, USD per tonne, by corridor.
const transportCosts = <String, double>{
  'DJI': 118,
  'MBA': 142,
  'DAR': 156,
  'ABJ': 96,
  'SPY': 104,
};
