import 'dart:math' as math;
import '../../models/models.dart';

// DEMO DATA — fictional figures inspired by realistic orders of magnitude.
final demoCountries = <Country>[
  Country(
    id: 'ETH', flag: '🇪🇹', african: true, lon: 39.5, lat: 8.0, prodKt: 470, yieldKgHa: 780,
    areaKha: 600, producersK: 1200, coops: 420, costKg: 1.55, farmgateKg: 2.05, incomeYr: 1450,
    sustain: 64, certPct: 28, climateRisk: 58, deforestRisk: 42, exportsKt: 330, arabicaShare: 1.0,
    differential: 38, prodHistory: [410, 425, 440, 430, 455, 448, 462, 470],
    regions: [Region('Sidama', 0, -2.4, .28), Region('Jimma', -3.2, -.8, .30), Region('Harar', 3.2, 1.5, .17), Region('Guji', .8, -3.6, .25)],
  ),
  Country(
    id: 'KEN', flag: '🇰🇪', african: true, lon: 37.8, lat: 0.3, prodKt: 45, yieldKgHa: 620,
    areaKha: 75, producersK: 700, coops: 330, costKg: 2.60, farmgateKg: 3.40, incomeYr: 1900,
    sustain: 71, certPct: 42, climateRisk: 66, deforestRisk: 25, exportsKt: 40, arabicaShare: 1.0,
    differential: 62, prodHistory: [48, 46, 44, 47, 41, 43, 44, 45],
    regions: [Region('Nyeri', -.2, .6, .35), Region('Kisii', -3.0, -.4, .20), Region('Embu', .4, -.5, .30), Region('Mt Elgon', -2.8, 1.0, .15)],
  ),
  Country(
    id: 'UGA', flag: '🇺🇬', african: true, lon: 32.4, lat: 1.4, prodKt: 380, yieldKgHa: 650,
    areaKha: 560, producersK: 1700, coops: 280, costKg: 1.35, farmgateKg: 1.75, incomeYr: 980,
    sustain: 58, certPct: 22, climateRisk: 61, deforestRisk: 48, exportsKt: 360, arabicaShare: .22,
    differential: -18, prodHistory: [330, 345, 360, 350, 372, 365, 375, 380],
    regions: [Region('Mt Elgon', 2.0, .0, .30), Region('Rwenzori', -2.2, -1.0, .20), Region('Central', .3, -.7, .40), Region('West Nile', -.4, 1.5, .10)],
  ),
  Country(
    id: 'RWA', flag: '🇷🇼', african: true, lon: 29.9, lat: -2.0, prodKt: 22, yieldKgHa: 900,
    areaKha: 24, producersK: 400, coops: 190, costKg: 2.20, farmgateKg: 2.90, incomeYr: 1150,
    sustain: 74, certPct: 52, climateRisk: 49, deforestRisk: 18, exportsKt: 20, arabicaShare: .95,
    differential: 55, prodHistory: [20, 21, 19, 22, 23, 21, 22, 22],
    regions: [Region('Nyamasheke', -.6, -.5, .35), Region('Huye', .2, -.5, .25), Region('Rutsiro', -.3, .4, .40)],
  ),
  Country(
    id: 'TZA', flag: '🇹🇿', african: true, lon: 35.0, lat: -6.3, prodKt: 65, yieldKgHa: 500,
    areaKha: 130, producersK: 450, coops: 210, costKg: 1.80, farmgateKg: 2.35, incomeYr: 1050,
    sustain: 60, certPct: 31, climateRisk: 63, deforestRisk: 39, exportsKt: 58, arabicaShare: .7,
    differential: 10, prodHistory: [55, 60, 58, 62, 57, 64, 63, 65],
    regions: [Region('Kilimanjaro', 2.3, 3.0, .30), Region('Mbeya', -1.6, -2.6, .35), Region('Ruvuma', .5, -4.4, .35)],
  ),
  Country(
    id: 'CIV', flag: '🇨🇮', african: true, lon: -5.5, lat: 7.5, prodKt: 95, yieldKgHa: 420,
    areaKha: 225, producersK: 130, coops: 95, costKg: 1.15, farmgateKg: 1.30, incomeYr: 720,
    sustain: 52, certPct: 17, climateRisk: 70, deforestRisk: 65, exportsKt: 85, arabicaShare: 0,
    differential: -35, prodHistory: [90, 86, 94, 92, 88, 93, 91, 95],
    regions: [Region('Man', -2.0, -.1, .40), Region('Daloa', -.9, -.6, .35), Region('Abengourou', 2.0, -.8, .25)],
  ),
  Country(
    id: 'BRA', flag: '🇧🇷', african: false, lon: -48, lat: -14, prodKt: 3500, yieldKgHa: 1700,
    areaKha: 2100, producersK: 300, coops: 450, costKg: 2.10, farmgateKg: 3.10, incomeYr: 9800,
    sustain: 69, certPct: 38, climateRisk: 55, deforestRisk: 45, exportsKt: 2800, arabicaShare: .75,
    differential: -12, prodHistory: [3100, 3300, 3000, 3600, 3400, 3200, 3450, 3500],
  ),
  Country(
    id: 'COL', flag: '🇨🇴', african: false, lon: -74, lat: 4.5, prodKt: 750, yieldKgHa: 1100,
    areaKha: 680, producersK: 540, coops: 200, costKg: 2.90, farmgateKg: 3.60, incomeYr: 3400,
    sustain: 72, certPct: 55, climateRisk: 52, deforestRisk: 28, exportsKt: 700, arabicaShare: 1,
    differential: 70, prodHistory: [690, 710, 720, 700, 735, 740, 745, 750],
  ),
  Country(
    id: 'VNM', flag: '🇻🇳', african: false, lon: 108, lat: 14, prodKt: 1800, yieldKgHa: 2700,
    areaKha: 660, producersK: 600, coops: 120, costKg: 1.40, farmgateKg: 1.90, incomeYr: 3100,
    sustain: 55, certPct: 25, climateRisk: 58, deforestRisk: 35, exportsKt: 1650, arabicaShare: .05,
    differential: -30, prodHistory: [1700, 1750, 1650, 1820, 1780, 1740, 1790, 1800],
  ),
  Country(
    id: 'HND', flag: '🇭🇳', african: false, lon: -86.5, lat: 14.8, prodKt: 380, yieldKgHa: 800,
    areaKha: 475, producersK: 120, coops: 160, costKg: 2.40, farmgateKg: 3.00, incomeYr: 2300,
    sustain: 62, certPct: 35, climateRisk: 64, deforestRisk: 40, exportsKt: 340, arabicaShare: 1,
    differential: 20, prodHistory: [350, 360, 340, 375, 365, 370, 372, 380],
  ),
  Country(
    id: 'IDN', flag: '🇮🇩', african: false, lon: 113, lat: -2, prodKt: 700, yieldKgHa: 800,
    areaKha: 880, producersK: 1300, coops: 260, costKg: 1.50, farmgateKg: 2.00, incomeYr: 1500,
    sustain: 57, certPct: 20, climateRisk: 60, deforestRisk: 50, exportsKt: 380, arabicaShare: .2,
    differential: -15, prodHistory: [660, 680, 670, 700, 690, 685, 695, 700],
  ),
  // Other member countries of the organisation (25 in total) — DEMO values, smaller producers.
  ..._members,
];

const demoPorts = <Port>[
  Port('DJI', 'Djibouti', 'ETH', 43.15, 11.6),
  Port('MBA', 'Mombasa', 'KEN', 39.67, -4.05),
  Port('DAR', 'Dar es Salaam', 'TZA', 39.28, -6.82),
  Port('ABJ', 'Abidjan', 'CIV', -4.02, 5.3),
  Port('SPY', 'San Pedro', 'CIV', -6.6, 4.75),
  Port('DLA', 'Douala', 'CMR', 9.7, 4.05),
  Port('CKY', 'Conakry', 'GIN', -13.7, 9.5),
  Port('LFW', 'Lomé', 'TGO', 1.28, 6.13),
  Port('TMM', 'Toamasina', 'MDG', 49.4, -18.15),
];

const demoCoops = <Coop>[
  Coop('c1', 'Oromia Union', 'ETH', 36.8, 7.6, 4200, 'DJI'),
  Coop('c2', 'Sidama Union', 'ETH', 38.5, 6.9, 3100, 'DJI'),
  Coop('c3', 'Yirgacheffe Union', 'ETH', 38.2, 6.1, 2600, 'DJI'),
  Coop('c4', 'Thika Growers', 'KEN', 37.1, -1.0, 900, 'MBA'),
  Coop('c5', 'Nyeri Farmers', 'KEN', 36.95, -0.4, 1100, 'MBA'),
  Coop('c6', 'Kisii Coop', 'KEN', 34.8, -0.7, 600, 'MBA'),
  Coop('c7', 'Mt Elgon Coop', 'UGA', 34.4, 1.1, 2100, 'MBA'),
  Coop('c8', 'Rwenzori Hub', 'UGA', 30.2, 0.2, 1500, 'MBA'),
  Coop('c9', 'Kampala Hub', 'UGA', 32.6, 0.3, 3000, 'MBA'),
  Coop('c10', 'Huye Coop', 'RWA', 29.7, -2.6, 500, 'DAR'),
  Coop('c11', 'Nyamasheke Coop', 'RWA', 29.1, -2.3, 450, 'DAR'),
  Coop('c12', 'KNCU', 'TZA', 37.3, -3.3, 1300, 'DAR'),
  Coop('c13', 'Mbeya Coop', 'TZA', 33.5, -8.9, 900, 'DAR'),
  Coop('c14', 'Ruvuma Coop', 'TZA', 35.6, -10.7, 800, 'DAR'),
  Coop('c15', 'Man Coop', 'CIV', -7.5, 7.4, 1100, 'SPY'),
  Coop('c16', 'Daloa Coop', 'CIV', -6.4, 6.9, 1300, 'ABJ'),
  Coop('c17', 'Abengourou Coop', 'CIV', -3.5, 6.7, 800, 'ABJ'),
  Coop('c18', 'UCCAO', 'CMR', 10.4, 5.5, 2200, 'DLA'),
  Coop('c19', 'Kivu Coop', 'COD', 29.2, -2.3, 900, 'MBA'),
  Coop('c20', 'Ngozi Coop', 'BDI', 29.8, -2.9, 700, 'DAR'),
  Coop('c21', 'Nzérékoré Union', 'GIN', -8.8, 7.75, 1400, 'CKY'),
  Coop('c22', 'Kpalimé Coop', 'TGO', .63, 6.9, 600, 'LFW'),
  Coop('c23', 'Atsinanana Coop', 'MDG', 48.9, -18.3, 1100, 'TMM'),
];

Country countryById(String id) => demoCountries.firstWhere((c) => c.id == id);


double _hh(String k) {
  var h = 17;
  for (final c in k.codeUnits) {
    h = (h * 41 + c) % 100019;
  }
  return h / 100019;
}

double _r(double v, int d) => double.parse(v.toStringAsFixed(d));

/// Builds a member-country record from a few anchors; the other figures are derived (DEMO).
Country _member(String id, String flag, double lon, double lat, double prodKt, double yieldKgHa, double arabica, double certPct, double climate, double deforest, List<Region> regions) {
  final area = prodKt * 1000 / yieldKgHa;
  final producers = math.max(.4, area / 1.1);
  final cost = 1.1 + arabica * 1.1 + (_hh('${id}c') - .5) * .3;
  final farmgate = cost * (1.12 + _hh('${id}f') * .2);
  final income = 450 + (farmgate - cost) * 900 + arabica * 350 + _hh('${id}i') * 150;
  final sustain = (36 + certPct * .7 + (100 - deforest) * .15 + (_hh('${id}s') - .5) * 6).clamp(30.0, 80.0);
  final dec = prodKt < 5 ? 2 : 1;
  final hist = [for (var i = 0; i < 7; i++) _r(prodKt * (.86 + i * .02) * (1 + (_hh('$id$i') - .5) * .06), dec), prodKt];
  return Country(
    id: id,
    flag: flag,
    african: true,
    lon: lon,
    lat: lat,
    prodKt: prodKt,
    yieldKgHa: yieldKgHa,
    areaKha: _r(area, 1),
    producersK: _r(producers, 1),
    coops: math.max(2, (producers * .35).round()).toDouble(),
    costKg: _r(cost, 2),
    farmgateKg: _r(farmgate, 2),
    incomeYr: (income / 10).round() * 10.0,
    sustain: _r(sustain, 0),
    certPct: certPct,
    climateRisk: climate,
    deforestRisk: deforest,
    exportsKt: _r(prodKt * .82, dec),
    arabicaShare: arabica,
    differential: (arabica * 45 - (1 - arabica) * 28 + (_hh('${id}d') - .5) * 14).roundToDouble(),
    prodHistory: hist,
    regions: regions,
  );
}

final _members = <Country>[
  _member('CMR', '🇨🇲', 12.4, 5.7, 32, 330, .2, 14, 62, 55, const [Region('Ouest', -2.0, 0, .55), Region('Littoral', -2.6, -1.4, .30), Region('Est', 2.0, -1.5, .15)]),
  _member('COD', '🇨🇩', 23.6, -2.9, 28, 300, .35, 12, 66, 62, const [Region('Kivu', 5.2, .6, .50), Region('Tshopo', 1.8, 3.3, .30), Region('Équateur', -4.0, 2.9, .20)]),
  _member('MDG', '🇲🇬', 46.9, -19.0, 38, 320, .08, 9, 68, 62, const [Region('Atsinanana', 2.1, 1.0, .45), Region('Vatovavy', 1.0, -2.5, .35), Region('Sava', 3.0, 5.0, .20)]),
  _member('GIN', '🇬🇳', -10.9, 10.4, 30, 350, 0, 6, 64, 60, const [Region('Guinée forestière', 1.8, -2.6, .75), Region('Kindia', -1.9, -.3, .25)]),
  _member('BDI', '🇧🇮', 29.9, -3.4, 14, 560, .97, 34, 55, 30, const [Region('Kayanza', -.2, .5, .45), Region('Ngozi', .3, .5, .30), Region('Gitega', 0, 0, .25)]),
  _member('TGO', '🇹🇬', .9, 8.6, 10, 330, 0, 18, 62, 50, const [Region('Plateaux', 0, -1.4, .75), Region('Centrale', .2, .4, .25)]),
  _member('CAF', '🇨🇫', 20.9, 6.6, 5, 260, 0, 3, 63, 52, const [Region('Lobaye', -3.0, -3.0, .60), Region('Ombella-M’Poko', -2.4, -1.8, .40)]),
  _member('AGO', '🇦🇴', 17.9, -11.2, 4.5, 300, .15, 6, 60, 50, const [Region('Kwanza Sul', -3.5, .3, .60), Region('Uíge', -2.7, 3.6, .40)]),
  _member('SLE', '🇸🇱', -11.8, 8.5, 3, 280, 0, 5, 63, 60, const [Region('Kailahun', 1.2, -.4, .60), Region('Kenema', .6, -.7, .40)]),
  _member('NGA', '🇳🇬', 8.7, 9.1, 2.4, 300, .25, 5, 61, 52, const [Region('Taraba', 2.4, -1.1, .50), Region('Plateau', .2, .5, .30), Region('Kogi', -2.0, -1.5, .20)]),
  _member('MWI', '🇲🇼', 34.3, -13.3, 1.6, 600, 1, 30, 58, 40, const [Region('Mzuzu', -.3, 1.8, .60), Region('Thyolo', 1.0, -2.7, .40)]),
  _member('GHA', '🇬🇭', -1.0, 7.9, 1.5, 300, 0, 10, 65, 58, const [Region('Volta', 1.3, -1.3, .50), Region('Ashanti', -.6, -1.2, .30), Region('Bono', -1.4, 0, .20)]),
  _member('COG', '🇨🇬', 15.2, -.7, 1.2, 250, 0, 3, 60, 55, const [Region('Sangha', 1.0, 1.8, .60), Region('Cuvette', .6, .4, .40)]),
  _member('ZMB', '🇿🇲', 27.8, -13.1, .7, 900, 1, 26, 57, 28, const [Region('Muchinga', 3.3, 1.5, .60), Region('Northern', 3.0, 3.2, .40)]),
  _member('BEN', '🇧🇯', 2.3, 9.5, .6, 280, 0, 4, 64, 45, const [Region('Zou', 0, -2.3, .60), Region('Collines', 0, -1.0, .40)]),
  _member('LBR', '🇱🇷', -9.4, 6.4, .6, 260, 0, 4, 62, 66, const [Region('Lofa', -.5, 1.6, .50), Region('Nimba', .8, .6, .50)]),
  _member('ZWE', '🇿🇼', 29.9, -19.0, .6, 700, 1, 24, 61, 25, const [Region('Manicaland', 2.6, .2, .80), Region('Mashonaland', 1.2, 1.8, .20)]),
  _member('GAB', '🇬🇦', 11.6, -.8, .3, 240, 0, 3, 58, 40, const [Region('Woleu-Ntem', 0, 2.4, .70), Region('Ogooué-Ivindo', 1.3, 1.2, .30)]),
  _member('GNQ', '🇬🇶', 10.3, 1.6, .2, 230, 0, 2, 59, 45, const [Region('Bioko', -1.5, 2.0, .40), Region('Río Muni', .2, 0, .60)]),
];
