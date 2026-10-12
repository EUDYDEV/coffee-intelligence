import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// IANA time zone of the browser (e.g. "Africa/Abidjan"), read from Intl — no network, no permission.
String? deviceTimeZone() {
  try {
    final intl = globalContext['Intl'] as JSObject;
    final fmt = intl.callMethod<JSObject>('DateTimeFormat'.toJS);
    final opts = fmt.callMethod<JSObject>('resolvedOptions'.toJS);
    return (opts['timeZone'] as JSString?)?.toDart;
  } catch (_) {
    return null;
  }
}
