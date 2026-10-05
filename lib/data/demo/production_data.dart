import '../../models/models.dart';
import 'countries_data.dart';

List<Country> africanCountries() => demoCountries.where((c) => c.african).toList();

double africaProductionKt() => africanCountries().fold(0.0, (a, c) => a + c.prodKt);
double africaExportsKt() => africanCountries().fold(0.0, (a, c) => a + c.exportsKt);
double africaProducersK() => africanCountries().fold(0.0, (a, c) => a + c.producersK);
double africaAreaKha() => africanCountries().fold(0.0, (a, c) => a + c.areaKha);
double africaAvgYield() =>
    africaProductionKt() / africaAreaKha() * 1000; // kg per ha

/// Africa total production per season (8 seasons) in kt.
List<double> africaProdHistory() {
  final af = africanCountries();
  return [for (var i = 0; i < 8; i++) af.fold(0.0, (a, c) => a + c.prodHistory[i])];
}

/// Weighted-average household income of the African basket.
double africaAvgIncome() {
  final af = africanCountries();
  final w = af.fold(0.0, (a, c) => a + c.producersK);
  return af.fold(0.0, (a, c) => a + c.incomeYr * c.producersK) / w;
}

/// Seasons labels for the 8-season history.
List<String> seasonLabels() => [for (var i = 0; i < 8; i++) '${2019 + i}/${(20 + i) % 100}'];
