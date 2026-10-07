import 'countries_data.dart';

/// DEMO DATA — volumes are deliberately split into four distinct notions:
/// exported volume (flow over the year) ≠ available stock ≠ reserved stock ≠ volume in transit.
class StockRow {
  final String country;
  final double exportedKt; // exported over the last 12 months
  final double availableKt; // physically in warehouses, free to sell
  final double reservedKt; // in warehouses, already contracted
  final double transitKt; // on the road / at the port / at sea
  final double capacityFreeKt; // free warehouse capacity
  const StockRow(this.country, this.exportedKt, this.availableKt, this.reservedKt, this.transitKt, this.capacityFreeKt);
  double get totalKt => availableKt + reservedKt + transitKt;
}

double _h(String k) {
  var h = 5;
  for (final c in k.codeUnits) {
    h = (h * 41 + c) % 99989;
  }
  return h / 99989;
}

List<StockRow> stockRows() => [
      for (final c in demoCountries.where((x) => x.african))
        () {
          final avail = c.exportsKt * (.07 + _h('${c.id}a') * .06);
          final res = avail * (.3 + _h('${c.id}r') * .35);
          final trans = c.exportsKt * (.05 + _h('${c.id}t') * .05);
          final cap = avail * (.5 + _h('${c.id}c') * 1.2);
          double r1(double v) => double.parse(v.toStringAsFixed(1));
          return StockRow(c.id, c.exportsKt, r1(avail), r1(res), r1(trans), r1(cap));
        }()
    ];
