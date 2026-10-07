import 'dart:math' as math;
import 'countries_data.dart';
import 'market_data.dart';

/// DEMO DATA — certifications and weather.

const certSchemes = ['fairtrade', 'rainforest', 'utz', 'organic', 'c4'];

class CertRecord {
  final String scheme, country, body;
  final int status; // 0 valid, 1 expiring, 2 expired, 3 pending
  final DateTime issued, expires;
  final double coverage; // % of producers covered
  final double producers; // number
  final double volumeKt;
  const CertRecord(this.scheme, this.country, this.body, this.status, this.issued, this.expires, this.coverage, this.producers, this.volumeKt);
}

const _bodies = {'fairtrade': 'FLOCERT', 'rainforest': 'Rainforest Alliance (RA)', 'utz': 'UTZ / RA legacy', 'organic': 'ECOCERT', 'c4': '4C Association'};

double _h(String k) {
  var h = 11;
  for (final c in k.codeUnits) {
    h = (h * 37 + c) % 99991;
  }
  return h / 99991;
}

final DateTime _today = DateTime(2026, 10, 1);

final List<CertRecord> demoCerts = [
  for (final c in demoCountries.where((x) => x.african))
    for (final s in certSchemes)
      () {
        final r = _h('${c.id}$s');
        final cov = (c.certPct * (.25 + r * .9)).clamp(2.0, 70.0).toDouble();
        final months = (r * 30).round() - 6; // expiry relative to today (months)
        final expires = DateTime(_today.year, _today.month + months, 1);
        final status = months < 0 ? 2 : (months <= 3 ? 1 : (r > .9 ? 3 : 0));
        return CertRecord(s, c.id, _bodies[s]!, status, DateTime(expires.year - 3, expires.month, 1), expires, double.parse(cov.toStringAsFixed(1)), (c.producersK * 1000 * cov / 100).roundToDouble(), double.parse((c.prodKt * cov / 100).toStringAsFixed(1)));
      }()
];

class CertStep {
  final String key;
  final double days, passRate;
  final int items;
  const CertStep(this.key, this.days, this.passRate, this.items);
}

const certJourney = <CertStep>[
  CertStep('cj_producer', 0, 100, 3200),
  CertStep('cj_coop', 14, 96, 3070),
  CertStep('cj_control', 45, 81, 2490),
  CertStep('cj_cert', 20, 94, 2340),
  CertStep('cj_process', 30, 98, 2290),
  CertStep('cj_export', 12, 99, 2260),
  CertStep('cj_buyer', 7, 100, 2250),
];

// ---------------------------------------------------------------------------
// Weather
// ---------------------------------------------------------------------------
class WeatherMonth {
  final DateTime t;
  final double temp, rain, normalRain, humidity, drought;
  final bool forecast;
  const WeatherMonth(this.t, this.temp, this.rain, this.normalRain, this.humidity, this.drought, this.forecast);
}

class _Climate {
  final double temp, rain, amp, phase;
  const _Climate(this.temp, this.rain, this.amp, this.phase);
}

const _clim = {
  'ETH': _Climate(19.5, 95, 70, 1.2),
  'KEN': _Climate(19.0, 85, 60, 1.0),
  'UGA': _Climate(21.5, 120, 55, .9),
  'RWA': _Climate(19.0, 110, 70, 1.0),
  'TZA': _Climate(21.0, 100, 80, 1.5),
  'CIV': _Climate(26.5, 120, 90, 1.6),
};

/// 24 months of history (+6 forecast months) of weather for a country.
List<WeatherMonth> weatherFor(String country) {
  final c = _clim[country] ?? _clim['ETH']!;
  final r = Lcg((_h(country) * 900).floor() + 5);
  final out = <WeatherMonth>[];
  for (var i = -23; i <= 6; i++) {
    final d = DateTime(demoNow.year, demoNow.month + i, 1);
    final m = d.month;
    final normal = c.rain + c.amp * math.sin((m - 1) / 12 * 2 * math.pi + c.phase);
    var rain = normal * (1 + r.noise(.12));
    // recent dry spell (anomaly) for the demo
    if (i >= -3 && i <= 0) rain *= country == 'CIV' ? .55 : .82;
    if (i > 0) rain = normal * (country == 'CIV' ? .78 : .88);
    final temp = c.temp + 2.2 * math.sin((m - 3) / 12 * 2 * math.pi) + r.noise(.4) + (i > -6 ? .5 : 0);
    final hum = (68 + (rain / (c.rain + c.amp)) * 18 + r.noise(2)).clamp(35, 95).toDouble();
    final drought = (50 - (rain / normal - 1) * 160 + r.noise(4)).clamp(5, 98).toDouble();
    out.add(WeatherMonth(d, temp, math.max(rain, 3), math.max(normal, 3), hum, drought, i > 0));
  }
  return out;
}

class ClimateImpact {
  final double rainDelta, droughtDelta, productionDelta;
  const ClimateImpact(this.rainDelta, this.droughtDelta, this.productionDelta);
}

/// Simple demo model linking recent rainfall anomaly to production.
ClimateImpact climateImpact(String country) {
  final w = weatherFor(country).where((e) => !e.forecast).toList();
  final last = w.sublist(w.length - 3);
  final rain = last.fold(0.0, (a, e) => a + e.rain), normal = last.fold(0.0, (a, e) => a + e.normalRain);
  final rd = (rain / normal - 1) * 100;
  final dd = last.last.drought - w[w.length - 12].drought;
  final pd = (rd * .38 - math.max(0.0, dd) * .05).clamp(-25.0, 8.0).toDouble();
  return ClimateImpact(rd, dd, pd);
}
