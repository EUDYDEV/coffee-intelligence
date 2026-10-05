import '../../models/models.dart';

// DEMO DATA — fictional figures inspired by realistic orders of magnitude.
const demoCountries = <Country>[
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
];

const demoPorts = <Port>[
  Port('DJI', 'Djibouti', 'ETH', 43.15, 11.6),
  Port('MBA', 'Mombasa', 'KEN', 39.67, -4.05),
  Port('DAR', 'Dar es Salaam', 'TZA', 39.28, -6.82),
  Port('ABJ', 'Abidjan', 'CIV', -4.02, 5.3),
  Port('SPY', 'San Pedro', 'CIV', -6.6, 4.75),
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
];

Country countryById(String id) => demoCountries.firstWhere((c) => c.id == id);
