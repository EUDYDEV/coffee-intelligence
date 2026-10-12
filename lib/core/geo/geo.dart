import 'dart:ui' as ui;
import 'geo_stub.dart' if (dart.library.js_interop) 'geo_web.dart';

/// Approximate location from the device settings only (no GPS, no server):
/// country from the device region, city from the time zone name when available.
({String? iso2, String? city}) approximateLocation() {
  final iso2 = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
  final tz = deviceTimeZone();
  String? city;
  if (tz != null && tz.contains('/')) city = tz.split('/').last.replaceAll('_', ' ');
  return (iso2: iso2, city: city);
}
