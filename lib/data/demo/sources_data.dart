import '../../models/models.dart';

const demoSources = <DataSource>[
  DataSource('markets', 's_markets', 'd_prices', 'f_30min', '24 min', true, 98, 2),
  DataSource('weather', 's_weather', 'd_climate', 'f_1h', '41 min', true, 94, 2),
  DataSource('production', 's_production', 'd_production', 'f_monthly', '6 j', true, 91, 2),
  DataSource('coops', 's_coops', 'd_producers', 'f_variable', '3 j', true, 83, 1),
  DataSource('certs', 's_certs', 'd_sustain', 'f_quarterly', '34 j', true, 88, 2),
  DataSource('ports', 's_ports', 'd_logistics', 'f_daily', '5 h', true, 90, 2),
  DataSource('satellite', 's_satellite', 'd_vegetation', 'f_weekly', '2 j', true, 86, 1),
  DataSource('customs', 's_customs', 'd_exports', 'f_monthly', '12 j', true, 79, 1),
  DataSource('news', 's_news', 'd_keywords', 'f_15min', '9 min', true, 72, 0),
  DataSource('survey', 's_survey', 'd_income', 'f_yearly', '112 j', false, 68, 0),
];

/// Lineage for each important indicator ("Where does this number come from?").
Provenance provenanceFor(String metric, double finalValue) {
  switch (metric) {
    case 'price_arabica':
    case 'price_robusta':
      return Provenance('s_markets', '24 min', 98, 'conf_high', finalValue * 1.004, finalValue, '\$/lb',
          ['p_check', 'p_clean', 'p_fx', 'p_validate'], '10:42');
    case 'production':
      return Provenance('s_production', '6 j', 91, 'conf_high', finalValue * .97, finalValue, 'kt',
          ['p_check', 'p_merge', 'p_clean', 'p_aggregate'], '08:15');
    case 'income':
      return Provenance('s_survey', '112 j', 68, 'conf_low', finalValue * 1.09, finalValue, '\$',
          ['p_check', 'p_clean', 'p_infl', 'p_aggregate'], '09:30');
    case 'sustain':
      return Provenance('s_certs', '34 j', 88, 'conf_high', finalValue * 1.03, finalValue, '/100',
          ['p_check', 'p_score', 'p_aggregate'], '07:50');
    case 'exports':
      return Provenance('s_customs', '12 j', 79, 'conf_med', finalValue * .94, finalValue, 'kt',
          ['p_check', 'p_clean', 'p_gap', 'p_aggregate'], '11:05');
    case 'climate':
      return Provenance('s_weather', '41 min', 94, 'conf_high', finalValue * 1.06, finalValue, '/100',
          ['p_check', 'p_clean', 'p_score', 'p_validate'], '10:25');
    default:
      return Provenance('s_markets', '24 min', 95, 'conf_high', finalValue, finalValue, '',
          ['p_check', 'p_clean', 'p_validate'], '10:40');
  }
}
