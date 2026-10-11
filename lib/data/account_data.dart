import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Front-end demo of visitor accounts and subscriptions.
/// Everything is stored locally in the browser / device (no server, no real payment).

/// Member countries of the organisation (id → i18n key `mc_<id>`).
const memberCountries = <String>[
  'AGO', 'BEN', 'BDI', 'CMR', 'CAF', 'COG', 'COD', 'CIV', 'ETH', 'GAB', 'GHA', 'GIN', 'GNQ',
  'KEN', 'LBR', 'MDG', 'MWI', 'NGA', 'UGA', 'RWA', 'SLE', 'TZA', 'TGO', 'ZMB', 'ZWE',
];

const genders = <String>['f', 'm', 'x', 'n']; // female, male, other, prefer not to say

/// Subscription plans. Prices are in USD (converted for display like every other amount).
class PlanDef {
  final String id, nameKey, descKey;
  final double monthUsd, yearUsd;
  final List<String> featureKeys;
  final bool downloads; // can download exports / reports
  const PlanDef(this.id, this.nameKey, this.descKey, this.monthUsd, this.yearUsd, this.featureKeys, this.downloads);
}

const plans = <PlanDef>[
  PlanDef('free', 'plan_free', 'plan_free_d', 0, 0, ['pf_browse', 'pf_guide', 'pf_nodl'], false),
  PlanDef('pro', 'plan_pro', 'plan_pro_d', 29, 290, ['pf_browse', 'pf_dl_all', 'pf_reports', 'pf_alerts'], true),
  PlanDef('inst', 'plan_inst', 'plan_inst_d', 99, 990, ['pf_browse', 'pf_dl_all', 'pf_reports', 'pf_alerts', 'pf_users', 'pf_sched', 'pf_support'], true),
];

PlanDef planById(String id) => plans.firstWhere((p) => p.id == id, orElse: () => plans.first);

/// One-off price of a single download, when the visitor has no active subscription.
double itemPriceUsd(String kind) => switch (kind) {
      'png' => 1.0,
      'csv' => 1.5,
      'pdf' => 3.0,
      'report' => 5.0,
      _ => 2.0,
    };

const payMethods = <String>['momo', 'card', 'bank'];

class Purchase {
  final String id, kind, label, method; // kind: plan | item
  final double amountUsd;
  final DateTime date;
  const Purchase(this.id, this.kind, this.label, this.amountUsd, this.method, this.date);

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'label': label, 'amount': amountUsd, 'method': method, 'date': date.toIso8601String()};
  factory Purchase.fromJson(Map<String, dynamic> j) =>
      Purchase(j['id'] as String, j['kind'] as String, j['label'] as String, (j['amount'] as num).toDouble(), j['method'] as String, DateTime.parse(j['date'] as String));
}

class Account {
  final String id;
  String fullName, username, email, passHash, salt, country, city, address, gender;
  DateTime birth;
  bool verified;
  String? social; // google | apple (simulated sign-in)
  final DateTime created;
  String plan; // free | pro | inst
  String cycle; // month | year
  DateTime? planUntil;
  final List<Purchase> purchases;

  Account({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.passHash,
    required this.salt,
    required this.country,
    required this.city,
    required this.address,
    required this.gender,
    required this.birth,
    required this.created,
    this.verified = false,
    this.social,
    this.plan = 'free',
    this.cycle = 'month',
    this.planUntil,
    List<Purchase>? purchases,
  }) : purchases = purchases ?? [];

  bool get hasActivePlan => planById(plan).downloads && planUntil != null && planUntil!.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'username': username,
        'email': email,
        'passHash': passHash,
        'salt': salt,
        'country': country,
        'city': city,
        'address': address,
        'gender': gender,
        'birth': birth.toIso8601String(),
        'verified': verified,
        'social': social,
        'created': created.toIso8601String(),
        'plan': plan,
        'cycle': cycle,
        'planUntil': planUntil?.toIso8601String(),
        'purchases': [for (final p in purchases) p.toJson()],
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        fullName: j['fullName'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
        passHash: j['passHash'] as String,
        salt: j['salt'] as String,
        country: j['country'] as String,
        city: j['city'] as String,
        address: (j['address'] as String?) ?? '',
        gender: j['gender'] as String,
        birth: DateTime.parse(j['birth'] as String),
        verified: j['verified'] as bool,
        social: j['social'] as String?,
        created: DateTime.parse(j['created'] as String),
        plan: j['plan'] as String,
        cycle: j['cycle'] as String,
        planUntil: j['planUntil'] == null ? null : DateTime.parse(j['planUntil'] as String),
        purchases: [for (final p in (j['purchases'] as List? ?? const [])) Purchase.fromJson(p as Map<String, dynamic>)],
      );
}

final _rnd = Random.secure();

String newSalt() => base64Url.encode(List<int>.generate(12, (_) => _rnd.nextInt(256)));

/// Salted SHA-256. NOTE: in a real product hashing is done server-side (bcrypt / argon2); this only avoids keeping the password in clear text in the demo storage.
String hashPassword(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

String newId(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rnd.nextInt(1 << 20).toRadixString(36)}';

String newCode() => (100000 + _rnd.nextInt(900000)).toString();

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
bool validEmail(String v) => _emailRe.hasMatch(v.trim());

/// Password rule: 8+ characters, at least one letter and one digit.
bool strongPassword(String v) => v.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v);
