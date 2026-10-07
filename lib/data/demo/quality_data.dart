import '../../models/models.dart';
import 'countries_data.dart';
import 'market_data.dart';

/// DEMO DATA — cup quality, coop profiles, geographic hierarchy, producers and lots.

class QualityProfile {
  final double score, acidity, body, sweetness, aroma, aftertaste, balance;
  final int defects, altitude;
  final String grade, variety, process, origin;
  final List<String> notes; // translation keys
  const QualityProfile(this.score, this.acidity, this.body, this.sweetness, this.aroma, this.aftertaste,
      this.balance, this.defects, this.altitude, this.grade, this.variety, this.process, this.origin, this.notes);
}

const _qBase = <String, (double, String, String, int, List<String>)>{
  'ETH': (86.0, 'Heirloom', 'proc_natural', 1900, ['qn_floral', 'qn_blueberry', 'qn_citrus']),
  'KEN': (85.5, 'SL28 / SL34', 'proc_washed', 1750, ['qn_blackcurrant', 'qn_citrus', 'qn_winey']),
  'RWA': (84.0, 'Red Bourbon', 'proc_washed', 1800, ['qn_caramel', 'qn_redfruit', 'qn_floral']),
  'UGA': (80.5, 'SL14 / Robusta', 'proc_natural', 1500, ['qn_chocolate', 'qn_nutty', 'qn_spice']),
  'TZA': (83.0, 'Bourbon / Kent', 'proc_washed', 1600, ['qn_citrus', 'qn_caramel', 'qn_redfruit']),
  'CIV': (78.5, 'Robusta (Conilon)', 'proc_natural', 450, ['qn_chocolate', 'qn_woody', 'qn_nutty']),
  'BRA': (82.0, 'Catuai / Mundo Novo', 'proc_natural', 1100, ['qn_chocolate', 'qn_nutty', 'qn_caramel']),
  'COL': (84.5, 'Caturra / Castillo', 'proc_washed', 1700, ['qn_caramel', 'qn_redfruit', 'qn_citrus']),
  'VNM': (76.0, 'Robusta', 'proc_natural', 600, ['qn_woody', 'qn_spice', 'qn_nutty']),
  'HND': (82.5, 'Catuai / Pacas', 'proc_honey', 1400, ['qn_caramel', 'qn_chocolate', 'qn_redfruit']),
  'IDN': (80.0, 'Typica / Ateng', 'proc_honey', 1300, ['qn_spice', 'qn_woody', 'qn_chocolate']),
};

String gradeFor(double s) => s >= 90 ? 'grade_outstanding' : (s >= 85 ? 'grade_excellent' : (s >= 80 ? 'grade_specialty' : (s >= 75 ? 'grade_premium' : 'grade_commercial')));

/// International reference and national/regional helpers.
const intlReferenceScore = 83.0;

double _h(String key) {
  var h = 7;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) % 100003;
  }
  return h / 100003;
}

QualityProfile qualityFor(String key) {
  // key: country id, "ETH:Sidama" (region), coop id "c1", or lot id
  var country = key;
  var spread = 0.0;
  if (key.contains(':')) {
    country = key.split(':').first;
    spread = (_h(key) - .5) * 3.0;
  } else if (!_qBase.containsKey(key)) {
    final coop = demoCoops.where((c) => c.id == key).firstOrNull;
    if (coop != null) {
      country = coop.country;
      spread = (_h(key) - .4) * 4.5;
    } else {
      final lot = demoLots.where((l) => l.id == key).firstOrNull;
      if (lot != null) {
        country = demoCoops.firstWhere((c) => c.id == lot.coopId).country;
        spread = (_h(key) - .4) * 3.5;
      } else {
        country = 'ETH';
      }
    }
  }
  final b = _qBase[country] ?? _qBase['ETH']!;
  final score = (b.$1 + spread).clamp(70.0, 92.0);
  double attr(double off, String salt) => ((score / 10 + off + (_h(key + salt) - .5) * 1.1)).clamp(5.5, 9.5);
  final isRob = country == 'CIV' || country == 'VNM';
  final acid = attr(isRob ? -.6 : .3, 'a'), body = attr(isRob ? .6 : .0, 'b'), sweet = attr(.0, 's');
  final aroma = attr(.1, 'r'), after = attr(-.1, 't'), bal = attr(-.05, 'l');
  final defects = (_h(key + 'd') * (isRob ? 4.5 : 2.6)).floor();
  final alt = (b.$4 + (_h(key + 'h') - .5) * 240).round();
  return QualityProfile(
    double.parse(score.toStringAsFixed(1)),
    double.parse(acid.toStringAsFixed(1)),
    double.parse(body.toStringAsFixed(1)),
    double.parse(sweet.toStringAsFixed(1)),
    double.parse(aroma.toStringAsFixed(1)),
    double.parse(after.toStringAsFixed(1)),
    double.parse(bal.toStringAsFixed(1)),
    defects,
    alt,
    gradeFor(score),
    b.$2,
    b.$3,
    country,
    b.$5,
  );
}

// ---------------------------------------------------------------------------
// Cooperative profiles (derived from the demo coop list)
// ---------------------------------------------------------------------------
class CoopProfile {
  final Coop coop;
  final String region;
  final double yieldKgHa, incomeYr, certPct, climateRisk, farmers, productionT, costKg, margin;
  const CoopProfile(this.coop, this.region, this.yieldKgHa, this.incomeYr, this.certPct, this.climateRisk,
      this.farmers, this.productionT, this.costKg, this.margin);
}

CoopProfile coopProfile(Coop c) {
  final k = countryById(c.country);
  final f = .85 + _h(c.id) * .4; // performance factor around 1
  final rIdx = demoCoops.where((x) => x.country == c.country).toList().indexWhere((x) => x.id == c.id);
  final region = k.regions.isEmpty ? '-' : k.regions[rIdx % k.regions.length].name;
  return CoopProfile(
    c,
    region,
    k.yieldKgHa * f,
    k.incomeYr * (.82 + _h(c.id + 'i') * .4),
    (k.certPct * (.6 + _h(c.id + 'c') * .9)).clamp(5, 95).toDouble(),
    (k.climateRisk + (_h(c.id + 'x') - .5) * 14).clamp(20, 95).toDouble(),
    (c.volumeT / 1.8 * (.8 + _h(c.id + 'f') * .5)).roundToDouble(),
    c.volumeT,
    k.costKg * (.9 + _h(c.id + 'k') * .25),
    k.margin * (.8 + _h(c.id + 'm') * .4),
  );
}

List<CoopProfile> coopProfiles() => [for (final c in demoCoops) coopProfile(c)];

/// Averages of a set of coop profiles (used as regional / national benchmarks).
class Bench {
  final double production, yield, quality, income, cert, climate, margin, cost;
  const Bench(this.production, this.yield, this.quality, this.income, this.cert, this.climate, this.margin, this.cost);
}

Bench benchOf(List<CoopProfile> ps) {
  if (ps.isEmpty) return const Bench(0, 0, 0, 0, 0, 0, 0, 0);
  double avg(double Function(CoopProfile) f) => ps.fold(0.0, (a, p) => a + f(p)) / ps.length;
  return Bench(avg((p) => p.productionT), avg((p) => p.yieldKgHa), avg((p) => qualityFor(p.coop.id).score), avg((p) => p.incomeYr),
      avg((p) => p.certPct), avg((p) => p.climateRisk), avg((p) => p.margin), avg((p) => p.costKg));
}

/// International reference (demo constants).
const intlBench = Bench(1500, 1250, 83.0, 2600, 42, 55, .95, 1.9);

// ---------------------------------------------------------------------------
// Producers & hierarchy
// ---------------------------------------------------------------------------
class Producer {
  final String id, name, coopId;
  final double areaHa, kg, yieldKgHa, incomeYr;
  const Producer(this.id, this.name, this.coopId, this.areaHa, this.kg, this.yieldKgHa, this.incomeYr);
}

const _first = ['Amadou', 'Fatou', 'Kofi', 'Aminata', 'Yao', 'Mariam', 'Abdoulaye', 'Esther', 'Samuel', 'Grace', 'Joseph', 'Alice', 'Moussa', 'Chantal', 'Daniel', 'Rose', 'Ibrahim', 'Nadia', 'Pierre', 'Hawa'];
const _last = ['Koné', 'Traoré', 'Mensah', 'Kamau', 'Okello', 'Mukamana', 'Bekele', 'Tesfaye', 'Mwangi', 'Nakato', 'Diallo', 'Mushi', 'Kouassi', 'Abebe', 'Otieno', 'Uwase', 'Tadesse', 'Njoroge', 'Bamba', 'Kigozi'];

List<Producer> producersOf(String coopId) {
  final c = demoCoops.firstWhere((x) => x.id == coopId);
  final p = coopProfile(c);
  return [
    for (var i = 0; i < 5; i++)
      () {
        final f = .6 + _h('$coopId$i') * .9;
        final area = double.parse((.8 + _h('$coopId$i' 'a') * 2.4).toStringAsFixed(1));
        final kg = (p.productionT * 1000 / p.farmers * f).roundToDouble();
        return Producer('$coopId-P${i + 1}', '${_first[((_h(coopId) * 1000).floor() + i * 3) % _first.length]} ${_last[((_h(coopId) * 1000).floor() + i * 7 + 2) % _last.length]}', coopId, area, kg, (kg / area).roundToDouble(), p.incomeYr * f);
      }()
  ];
}

// ---------------------------------------------------------------------------
// Lots (traceability)
// ---------------------------------------------------------------------------
class Lot {
  final String id, coopId, statusKey;
  final double bags, tonnes;
  final DateTime harvest;
  final int progress; // number of completed steps (0..10)
  final List<String> certs;
  const Lot(this.id, this.coopId, this.bags, this.tonnes, this.harvest, this.progress, this.certs, this.statusKey);
}

const lotSteps = <(String, String, int)>[
  // key, location key, days after harvest
  ('lot_origin', 'lot_loc_farm', 0),
  ('lot_coop', 'lot_loc_coop', 2),
  ('lot_producer', 'lot_loc_plot', 3),
  ('lot_station', 'lot_loc_station', 9),
  ('lot_warehouse', 'lot_loc_wh', 24),
  ('lot_exporter', 'lot_loc_exporter', 31),
  ('lot_port', 'lot_loc_port', 36),
  ('lot_ship', 'lot_loc_sea', 41),
  ('lot_buyer', 'lot_loc_buyer', 72),
  ('lot_roaster', 'lot_loc_roaster', 80),
];

const _iso2 = {'ETH': 'ET', 'KEN': 'KE', 'UGA': 'UG', 'RWA': 'RW', 'TZA': 'TZ', 'CIV': 'CI'};

final List<Lot> demoLots = [
  for (var i = 0; i < 12; i++)
    () {
      final c = demoCoops[(i * 3 + 1) % demoCoops.length];
      final prog = [10, 8, 7, 9, 5, 6, 4, 10, 3, 7, 2, 8][i];
      final certs = [
        ['cert_fairtrade', 'cert_organic'],
        ['cert_rainforest'],
        ['cert_fairtrade'],
        ['cert_rainforest', 'cert_utz'],
        ['cert_fairtrade', 'cert_rainforest'],
        ['cert_c4'],
      ][i % 6];
      return Lot(
        '${_iso2[c.country]}-2026-${(481 + i * 37).toString().padLeft(5, '0')}',
        c.id,
        (80 + _h('lot$i') * 220).roundToDouble(),
        0,
        DateTime(2026, 1 + (i % 5), 5 + i),
        prog,
        certs,
        prog >= 10 ? 'lot_st_delivered' : (prog >= 8 ? 'lot_st_sea' : (prog >= 5 ? 'lot_st_transit' : 'lot_st_local')),
      );
    }()
];

Lot lotById(String id) => demoLots.firstWhere((l) => l.id == id);

/// Aggregated yearly quality/price evolution used by trend charts.
List<double> qualityTrend(String key) {
  final base = qualityFor(key).score;
  final r = Lcg((_h(key) * 997).floor() + 3);
  return [for (var i = 0; i < 8; i++) double.parse((base - 2 + i * .3 + r.noise(.5)).clamp(70, 92).toStringAsFixed(1))];
}

double round1(double v) => (v * 10).round() / 10;
