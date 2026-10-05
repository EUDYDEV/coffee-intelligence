import 'package:flutter/material.dart';
import '../alerts/alerts_page.dart';
import '../anomalies/anomalies_page.dart';
import '../chain/chain_page.dart';
import '../compare/compare_page.dart';
import '../decision/decision_page.dart';
import '../forecast/forecast_page.dart';
import '../map/map_page.dart';
import '../market/market_page.dart';
import '../production/production_page.dart';
import '../reports/reports_page.dart';
import '../revenue/revenue_page.dart';
import '../settings/settings_page.dart';
import '../simulator/simulator_page.dart';
import '../sources/sources_page.dart';
import '../sustainability/sustainability_page.dart';

class NavDef {
  final String id, labelKey;
  final IconData icon;
  final Widget Function() build;
  const NavDef(this.id, this.icon, this.labelKey, this.build);
}

final navItems = <NavDef>[
  NavDef('decision', Icons.space_dashboard_rounded, 'nav_decision', () => const DecisionPage()),
  NavDef('market', Icons.candlestick_chart_rounded, 'nav_market', () => const MarketPage()),
  NavDef('production', Icons.spa_rounded, 'nav_production', () => const ProductionPage()),
  NavDef('revenue', Icons.payments_rounded, 'nav_revenue', () => const RevenuePage()),
  NavDef('sustain', Icons.eco_rounded, 'nav_sustain', () => const SustainabilityPage()),
  NavDef('chain', Icons.account_tree_rounded, 'nav_chain', () => const ChainPage()),
  NavDef('map', Icons.public_rounded, 'nav_map', () => const MapPage()),
  NavDef('compare', Icons.compare_arrows_rounded, 'nav_compare', () => const ComparePage()),
  NavDef('forecast', Icons.query_stats_rounded, 'nav_forecast', () => const ForecastPage()),
  NavDef('anomalies', Icons.troubleshoot_rounded, 'nav_anomalies', () => const AnomaliesPage()),
  NavDef('alerts', Icons.notifications_active_rounded, 'nav_alerts', () => const AlertsPage()),
  NavDef('reports', Icons.description_rounded, 'nav_reports', () => const ReportsPage()),
  NavDef('sources', Icons.hub_rounded, 'nav_sources', () => const SourcesPage()),
  NavDef('simulator', Icons.tune_rounded, 'nav_simulator', () => const SimulatorPage()),
  NavDef('settings', Icons.settings_rounded, 'nav_settings', () => const SettingsPage()),
];

int navIndex(String id) => navItems.indexWhere((e) => e.id == id);

/// Guided tour used by the "presentation mode" (indices into [navItems]).
final presentationStops = <(String, String)>[
  ('decision', 'pres_decision'),
  ('map', 'pres_map'),
  ('chain', 'pres_chain'),
  ('market', 'pres_market'),
  ('forecast', 'pres_forecast'),
  ('anomalies', 'pres_risks'),
  ('simulator', 'pres_sim'),
  ('sources', 'pres_sources'),
];
