/// Domain models. The UI only talks to these types, so the demo data layer can
/// later be swapped for a real API without touching widgets.

class Country {
  final String id, flag;
  final bool african;
  final double lon, lat;
  final double prodKt; // production, thousand tonnes
  final double yieldKgHa, areaKha, producersK, coops;
  final double costKg, farmgateKg; // USD per kg (green equivalent)
  final double incomeYr; // average producer net coffee income, USD / year
  final double sustain, certPct, climateRisk, deforestRisk, exportsKt;
  final double arabicaShare; // 0..1
  final double differential; // origin differential, USD cents/lb vs benchmark
  final List<double> prodHistory; // last 8 seasons (kt)
  final List<Region> regions;
  const Country({
    required this.id,
    required this.flag,
    required this.african,
    required this.lon,
    required this.lat,
    required this.prodKt,
    required this.yieldKgHa,
    required this.areaKha,
    required this.producersK,
    required this.coops,
    required this.costKg,
    required this.farmgateKg,
    required this.incomeYr,
    required this.sustain,
    required this.certPct,
    required this.climateRisk,
    required this.deforestRisk,
    required this.exportsKt,
    required this.arabicaShare,
    required this.differential,
    required this.prodHistory,
    this.regions = const [],
  });
  String get nameKey => 'c_$id';
  double get margin => farmgateKg - costKg;
}

class Region {
  final String name;
  final double dLon, dLat, share; // offset from the country centre, share of production
  const Region(this.name, this.dLon, this.dLat, this.share);
}

class Port {
  final String id, name, country;
  final double lon, lat;
  const Port(this.id, this.name, this.country, this.lon, this.lat);
}

class Coop {
  final String id, name, country;
  final double lon, lat, volumeT;
  final String? portId;
  const Coop(this.id, this.name, this.country, this.lon, this.lat, this.volumeT, this.portId);
}

class SeriesPoint {
  final DateTime t;
  final double v;
  const SeriesPoint(this.t, this.v);
}

class Anomaly {
  final String id, titleKey, descKey, causeKey, country;
  final int severity; // 0 critical, 1 important, 2 watch
  final String series; // which series the point belongs to
  final int index; // index in that series
  final double value, expected;
  const Anomaly(this.id, this.titleKey, this.descKey, this.causeKey, this.country, this.severity,
      this.series, this.index, this.value, this.expected);
}

class AlertItem {
  final String id, titleKey, textKey, category;
  final int severity;
  final String ago;
  const AlertItem(this.id, this.category, this.severity, this.titleKey, this.textKey, this.ago);
}

class UserAlert {
  final String metric, op;
  final double threshold;
  final DateTime created;
  UserAlert(this.metric, this.op, this.threshold) : created = DateTime.now();
}

class DataSource {
  final String id, nameKey, dataKey, freqKey, updated;
  final bool active;
  final double quality;
  final int confidence; // 0 low, 1 medium, 2 high
  const DataSource(this.id, this.nameKey, this.dataKey, this.freqKey, this.updated, this.active,
      this.quality, this.confidence);
}

class ChainStep {
  final String id;
  final double volumeKt;
  final double delayDays;
  final int status; // 0 ok, 1 attention, 2 risk
  final List<String> actors;
  final String location;
  final double risk; // 0..100
  const ChainStep(this.id, this.volumeKt, this.delayDays, this.status, this.actors, this.location, this.risk);
  String get nameKey => 'chain_$id';
}

class ForecastSeries {
  final String id;
  final List<SeriesPoint> history;
  final List<SeriesPoint> forecast;
  final List<double> lower, upper;
  const ForecastSeries(this.id, this.history, this.forecast, this.lower, this.upper);
}

class Provenance {
  final String sourceKey, updatedAgo, confidenceKey;
  final double quality, rawValue, finalValue;
  final String unit;
  final List<String> processing;
  final String received;
  const Provenance(this.sourceKey, this.updatedAgo, this.quality, this.confidenceKey, this.rawValue,
      this.finalValue, this.unit, this.processing, this.received);
}
