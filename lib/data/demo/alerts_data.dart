import '../../models/models.dart';

const demoAnomalies = <Anomaly>[
  Anomaly('an1', 'an1_t', 'an1_d', 'an1_c', 'UGA', 0, 'arabica', 27, 2.43, 3.01),
  Anomaly('an2', 'an2_t', 'an2_d', 'an2_c', 'CIV', 0, 'rain_civ', 21, 28, 94),
  Anomaly('an3', 'an3_t', 'an3_d', 'an3_c', 'KEN', 1, 'exports_ken', 20, 2.1, 3.8),
  Anomaly('an4', 'an4_t', 'an4_d', 'an4_c', 'UGA', 1, 'yield_uga', 16, 790, 645),
  Anomaly('an5', 'an5_t', 'an5_d', 'an5_c', 'ETH', 2, 'prod_eth', 22, 49, 40),
  Anomaly('an6', 'an6_t', 'an6_d', 'an6_c', 'TZA', 2, 'delay_tza', 18, 11, 6),
];

const demoAlerts = <AlertItem>[
  AlertItem('al1', 'price', 0, 'al1_t', 'al1_d', '12 min'),
  AlertItem('al2', 'weather', 0, 'al2_t', 'al2_d', '38 min'),
  AlertItem('al3', 'production', 2, 'al3_t', 'al3_d', '2 h'),
  AlertItem('al4', 'transport', 1, 'al4_t', 'al4_d', '3 h'),
  AlertItem('al5', 'market', 1, 'al5_t', 'al5_d', '5 h'),
  AlertItem('al6', 'sustainability', 2, 'al6_t', 'al6_d', '1 j'),
  AlertItem('al7', 'keyword', 2, 'al7_t', 'al7_d', '1 j'),
  AlertItem('al8', 'weather', 1, 'al8_t', 'al8_d', '2 j'),
];

/// "À surveiller aujourd'hui" items: icon code, text key, severity.
const watchToday = <List<Object>>[
  ['price', 'w1', 0],
  ['weather', 'w2', 0],
  ['exports', 'w3', 1],
  ['production', 'w4', 2],
];

/// Risk radar axes, 0..100 (higher = riskier). Evolves with demo "ticks".
const riskAxes = <String, List<double>>{
  'price': [62, 58, 66, 71, 74],
  'weather': [55, 63, 70, 68, 72],
  'production': [38, 40, 36, 33, 31],
  'transport': [47, 52, 50, 58, 55],
  'sustainability': [44, 43, 42, 41, 40],
  'market': [50, 52, 57, 55, 60],
};
