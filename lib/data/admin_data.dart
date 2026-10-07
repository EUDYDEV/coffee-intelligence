import '../core/format.dart';
import '../data/demo/market_data.dart';
import '../data/demo/sustainability_data.dart';
import '../data/repository.dart';

/// Front-end only admin data (demo). Everything lives in memory; a real version would call an API.
class DataSet {
  final String id, nameKey, descKey, sourceId, license;
  final List<String> formats;
  final List<String> columns; // translation keys
  bool forSale;
  double priceUsd;
  DataSet(this.id, this.nameKey, this.descKey, this.sourceId, this.columns, this.priceUsd,
      {this.forSale = true, this.license = 'lic_commercial', this.formats = const ['CSV', 'API']});
}

class FieldDef {
  final String key; // translation key
  final String type; // text | number | money | country | port
  const FieldDef(this.key, this.type);
}

class ManualEntry {
  final String dataset;
  final List<String> values; // stored in column order (money stored as USD)
  final DateTime ts;
  ManualEntry(this.dataset, this.values) : ts = DateTime.now();
}

class Order {
  final String buyer, datasetId;
  final double usd;
  final DateTime ts;
  Order(this.buyer, this.datasetId, this.usd, this.ts);
}

class LogEntry {
  final DateTime ts;
  final String actionKey, detail;
  LogEntry(this.actionKey, this.detail) : ts = DateTime.now();
}

List<DataSet> buildDatasets() => [
      DataSet('prices', 'dset_prices', 'dset_prices_d', 'markets', ['col_month', 'col_arabica', 'col_robusta'], 1800),
      DataSet('production', 'dset_production', 'dset_production_d', 'production', ['col_country', 'col_season', 'col_kt'], 1400),
      DataSet('costs', 'dset_costs', 'dset_costs_d', 'survey', ['col_country', 'col_farmgate', 'col_cost', 'col_margin', 'col_income'], 1200),
      DataSet('coops', 'dset_coops', 'dset_coops_d', 'coops', ['col_coop', 'col_country', 'col_tonnes', 'col_port'], 900),
      DataSet('ports', 'dset_ports', 'dset_ports_d', 'ports', ['col_port', 'col_country', 'col_transport'], 600),
      DataSet('sustain', 'dset_sustain', 'dset_sustain_d', 'certs', ['col_country', 'col_cert', 'col_forest', 'col_social', 'col_env', 'col_index'], 1500),
      DataSet('climate', 'dset_climate', 'dset_climate_d', 'weather', ['col_month', 'col_rain', 'col_delay'], 700, forSale: false),
      DataSet('chain', 'dset_chain', 'dset_chain_d', 'ports', ['col_step', 'col_kt', 'col_days', 'col_risk'], 800),
      DataSet('forecast', 'dset_forecast', 'dset_forecast_d', 'markets', ['col_month', 'col_predicted', 'col_low', 'col_high'], 2200, license: 'lic_premium'),
      DataSet('anomalies', 'dset_anomalies', 'dset_anomalies_d', 'markets', ['col_anomaly', 'col_severity', 'col_country', 'col_value'], 500, forSale: false),
    ];

/// Datasets that accept manual entry, with their input fields (same order as the columns).
const manualFields = <String, List<FieldDef>>{
  'prices': [FieldDef('col_month', 'text'), FieldDef('col_arabica', 'money'), FieldDef('col_robusta', 'money')],
  'production': [FieldDef('col_country', 'country'), FieldDef('col_season', 'text'), FieldDef('col_kt', 'number')],
  'costs': [FieldDef('col_country', 'country'), FieldDef('col_farmgate', 'money'), FieldDef('col_cost', 'money'), FieldDef('col_margin', 'money'), FieldDef('col_income', 'money')],
  'coops': [FieldDef('col_coop', 'text'), FieldDef('col_country', 'country'), FieldDef('col_tonnes', 'number'), FieldDef('col_port', 'port')],
};

const _mon = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
String _ym(DateTime d) => '${d.year}-${_mon[d.month - 1]}';
String _m(double usd, [int d = 2]) => Fmt.money(usd, d);

/// Demo rows of a dataset (strings ready to display, money in the current currency).
List<List<String>> datasetRows(String id, String Function(String) t) {
  switch (id) {
    case 'prices':
      final a = repo.series('arabica'), r = repo.series('robusta');
      return [for (var i = 0; i < a.length; i++) [_ym(a[i].t), _m(a[i].v), _m(r[i].v)]];
    case 'production':
      final seasons = repo.seasonLabels();
      return [
        for (final c in repo.countries())
          for (var i = 0; i < 8; i++) [t(c.nameKey), seasons[i], Fmt.num(c.prodHistory[i], 0)]
      ];
    case 'costs':
      return [for (final c in repo.countries(africaOnly: true)) [t(c.nameKey), _m(c.farmgateKg), _m(c.costKg), _m(c.margin), _m(c.incomeYr, 0)]];
    case 'coops':
      return [for (final k in repo.coops()) [k.name, t(repo.country(k.country).nameKey), Fmt.num(k.volumeT, 0), k.portId ?? '-']];
    case 'ports':
      final tc = repo.transportCosts();
      return [for (final p in repo.ports()) [p.name, t(repo.country(p.country).nameKey), _m(tc[p.id]!, 0)]];
    case 'sustain':
      return [
        for (final c in repo.countries(africaOnly: true))
          () {
            final b = sustainFor(c);
            return [t(c.nameKey), Fmt.num(c.certPct, 0), Fmt.num(b.forest, 0), Fmt.num(b.social, 0), Fmt.num(b.environment, 0), Fmt.num(b.overall, 0)];
          }()
      ];
    case 'climate':
      final rain = rainCivSeries, delay = delayTzaSeries;
      return [for (var i = 0; i < rain.length; i++) [_ym(rain[i].t), Fmt.num(rain[i].v, 0), Fmt.num(delay[i].v, 1)]];
    case 'chain':
      return [for (final s in repo.chain()) [t(s.nameKey), Fmt.num(s.volumeKt, 0), Fmt.num(s.delayDays, 0), Fmt.num(s.risk, 0)]];
    case 'forecast':
      final f = repo.forecast('price');
      return [for (var i = 0; i < f.forecast.length; i++) [_ym(f.forecast[i].t), _m(f.forecast[i].v), _m(f.lower[i]), _m(f.upper[i])]];
    case 'anomalies':
      return [
        for (final a in repo.anomalies())
          [t(a.titleKey), t(['sev_critical', 'sev_important', 'sev_watch'][a.severity]), t(repo.country(a.country).nameKey), Fmt.num(a.value, a.value < 10 ? 2 : 0)]
      ];
  }
  return const [];
}

/// Manual entries stored in USD for monetary fields; this converts them for display.
List<String> manualRowDisplay(ManualEntry e) {
  final defs = manualFields[e.dataset]!;
  return [
    for (var i = 0; i < defs.length; i++)
      if (defs[i].type == 'money') (double.tryParse(e.values[i]) == null ? e.values[i] : _m(double.parse(e.values[i]), 2)) else e.values[i]
  ];
}

const buyers = ['Café Import SA', 'Ministère de l\'Agriculture', 'Torréfaction Atlas', 'Banque Agricole du Golfe', 'Université de Cocody', 'AgriTrade Logistics', 'Fondation Café Durable'];
