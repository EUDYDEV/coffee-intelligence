import '../models/models.dart';
import 'demo/alerts_data.dart';
import 'demo/countries_data.dart';
import 'demo/forecast_data.dart';
import 'demo/market_data.dart';
import 'demo/production_data.dart' as prod;
import 'demo/sources_data.dart';
import 'demo/supply_chain_data.dart';

/// Single access point for the UI. Replace [DemoRepository] by an API-backed
/// implementation later: the interface stays the same, widgets are untouched.
abstract class CoffeeRepository {
  List<Country> countries({bool africaOnly = false});
  Country country(String id);
  List<Port> ports();
  List<Coop> coops();
  List<SeriesPoint> series(String id);
  List<SeriesPoint> dailyArabica();
  List<MarketIndicator> marketIndicators();
  Map<String, double> transportCosts();
  List<Anomaly> anomalies();
  List<AlertItem> alerts();
  List<ChainStep> chain();
  List<DataSource> sources();
  ForecastSeries forecast(String id);
  Provenance provenance(String metric, double value);
  double africaProduction();
  double africaExports();
  double africaIncome();
  List<double> africaProdHistory();
  List<String> seasonLabels();
  Map<String, List<double>> risks();
}

class DemoRepository implements CoffeeRepository {
  const DemoRepository();
  @override
  List<Country> countries({bool africaOnly = false}) =>
      africaOnly ? prod.africanCountries() : demoCountries;
  @override
  Country country(String id) => countryById(id);
  @override
  List<Port> ports() => demoPorts;
  @override
  List<Coop> coops() => demoCoops;
  @override
  List<SeriesPoint> series(String id) => seriesById(id);
  @override
  List<SeriesPoint> dailyArabica() => _daily;
  @override
  List<MarketIndicator> marketIndicators() => _ind;
  @override
  Map<String, double> transportCosts() => transportCosts_;
  @override
  List<Anomaly> anomalies() => demoAnomalies;
  @override
  List<AlertItem> alerts() => demoAlerts;
  @override
  List<ChainStep> chain() => demoChain;
  @override
  List<DataSource> sources() => demoSources;
  @override
  ForecastSeries forecast(String id) => demoForecasts[id]!;
  @override
  Provenance provenance(String metric, double value) => provenanceFor(metric, value);
  @override
  double africaProduction() => prod.africaProductionKt();
  @override
  double africaExports() => prod.africaExportsKt();
  @override
  double africaIncome() => prod.africaAvgIncome();
  @override
  List<double> africaProdHistory() => prod.africaProdHistory();
  @override
  List<String> seasonLabels() => prod.seasonLabels();
  @override
  Map<String, List<double>> risks() => riskAxes;
}

final _daily = dailyArabica();
final _ind = marketIndicators();
const transportCosts_ = transportCosts;

const CoffeeRepository repo = DemoRepository();
