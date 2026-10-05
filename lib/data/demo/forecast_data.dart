import 'dart:math' as math;
import '../../models/models.dart';
import 'market_data.dart';

SeriesPoint _pt(int monthsAhead, double v) =>
    SeriesPoint(DateTime(demoNow.year, demoNow.month + monthsAhead, 1), v);

ForecastSeries _build(String id, List<SeriesPoint> hist, double endForecast, double lowW, double upW,
    {double season = 0}) {
  final last = hist.last.v;
  final fc = <SeriesPoint>[], lo = <double>[], up = <double>[];
  for (var k = 1; k <= 12; k++) {
    final c = last + (endForecast - last) * k / 12 + season * math.sin(k * .5);
    fc.add(_pt(k, c));
    lo.add(c - lowW * k / 12 - lowW * .15);
    up.add(c + upW * k / 12 + upW * .15);
  }
  return ForecastSeries(id, hist, fc, lo, up);
}

List<SeriesPoint> _tail(List<SeriesPoint> s, int n) => s.sublist(s.length - n);

final Map<String, ForecastSeries> demoForecasts = {
  'price': _build('price', _tail(arabicaSeries, 24), 3.40, .26, .31, season: .03),
  'production': _build('production', _monthlyAfrica(), 52.5, 4.2, 3.4, season: .6),
  'yield': _build('yield', _monthlyYield(), 705, 38, 30, season: 4),
  'climate': _build('climate', _monthlyClimate(), 71, 8, 10, season: 2),
};

List<SeriesPoint> _monthlyAfrica() {
  final r = Lcg(31);
  return [
    for (var i = 0; i < 24; i++)
      SeriesPoint(monthsAgo(23 - i), 42 + .22 * i + 3 * math.sin(i * .52) + r.noise(.7))
  ];
}

List<SeriesPoint> _monthlyYield() {
  final r = Lcg(37);
  return [
    for (var i = 0; i < 24; i++)
      SeriesPoint(monthsAgo(23 - i), 640 + 1.8 * i + 12 * math.sin(i * .5) + r.noise(4))
  ];
}

List<SeriesPoint> _monthlyClimate() {
  final r = Lcg(41);
  return [
    for (var i = 0; i < 24; i++)
      SeriesPoint(monthsAgo(23 - i), 52 + .5 * i + 6 * math.sin(i * .6) + r.noise(1.5))
  ];
}
