/// Locale-aware number formatting without external packages.
class Currency {
  final String code, symbol;
  final double perUsd; // indicative demo rate: units of this currency per 1 USD
  final bool prefix;
  final String fr, en;
  const Currency(this.code, this.symbol, this.perUsd, this.prefix, this.fr, this.en);
}

/// Indicative fixed rates for the demo (NOT live market rates).
const currencies = <Currency>[
  Currency('XOF', 'FCFA', 603.5, false, 'Franc CFA (UEMOA)', 'CFA franc (WAEMU)'),
  Currency('USD', r'$', 1, true, 'Dollar US', 'US dollar'),
  Currency('EUR', '€', 0.92, true, 'Euro', 'Euro'),
  Currency('NGN', '₦', 1500, true, 'Naira nigérian', 'Nigerian naira'),
  Currency('GHS', 'GH₵', 15, true, 'Cedi ghanéen', 'Ghanaian cedi'),
  Currency('XAF', 'FCFA', 603.5, false, 'Franc CFA (CEMAC)', 'CFA franc (CEMAC)'),
  Currency('KES', 'KSh', 129, true, 'Shilling kényan', 'Kenyan shilling'),
  Currency('UGX', 'USh', 3700, true, 'Shilling ougandais', 'Ugandan shilling'),
  Currency('RWF', 'FRw', 1350, true, 'Franc rwandais', 'Rwandan franc'),
  Currency('TZS', 'TSh', 2650, true, 'Shilling tanzanien', 'Tanzanian shilling'),
  Currency('ETB', 'Br', 120, true, 'Birr éthiopien', 'Ethiopian birr'),
  Currency('MAD', 'DH', 10, false, 'Dirham marocain', 'Moroccan dirham'),
  Currency('ZAR', 'R', 18, true, 'Rand sud-africain', 'South African rand'),
  Currency('GBP', '£', 0.78, true, 'Livre sterling', 'Pound sterling'),
];

class Fmt {
  static String lang = 'fr';
  static Currency cur = currencies.first; // Côte d'Ivoire → FCFA by default

  static String get sym => cur.symbol;
  static double conv(double usd) => usd * cur.perUsd;
  static int decFor(int d) => cur.perUsd >= 50 ? 0 : d;
  static String money(double usd, [int dec = 2]) => num(conv(usd), decFor(dec));

  /// Replaces a leading `$` in a unit like `$/kg` by the current currency symbol.
  static String unit(String u) => u.startsWith(r'$') ? sym + u.substring(1) : u;

  static String num(double v, [int dec = 0]) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(dec);
    final parts = s.split('.');
    final ip = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < ip.length; i++) {
      if (i > 0 && (ip.length - i) % 3 == 0) buf.write(lang == 'fr' ? ' ' : ',');
      buf.write(ip[i]);
    }
    var r = buf.toString();
    if (dec > 0) r += (lang == 'fr' ? ',' : '.') + parts[1];
    return neg ? '-$r' : r;
  }

  static String usd(double v, [int dec = 2]) {
    final n = money(v, dec);
    return cur.prefix ? '${cur.symbol}$n' : '$n\u00A0${cur.symbol}';
  }

  static String pct(double v, [int dec = 1, bool sign = false]) =>
      '${sign && v > 0 ? '+' : ''}${num(v, dec)}${lang == 'fr' ? ' %' : '%'}';

  static String compact(double v) {
    if (v.abs() >= 1e6) return '${num(v / 1e6, 1)}M';
    if (v.abs() >= 1e3) return '${num(v / 1e3, 1)}k';
    return num(v, 0);
  }
}
