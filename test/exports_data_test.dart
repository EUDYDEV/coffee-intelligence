import 'dart:convert';
import 'package:coffee_intelligence/app/app_state.dart';
import 'package:coffee_intelligence/core/export/export_data.dart';
import 'package:coffee_intelligence/core/export/pdf_export.dart';
import 'package:coffee_intelligence/core/i18n/strings.dart';
import 'package:coffee_intelligence/data/admin2_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final lang in ['fr', 'en']) {
    String t(String k, [List<Object> a = const []]) {
      var s = Strings.t(lang, k);
      for (var i = 0; i < a.length; i++) {
        s = s.replaceAll('{$i}', '${a[i]}');
      }
      return s;
    }

    test('every exportable page builds CSV + PDF ($lang)', () async {
      for (final id in AppState.exportable) {
        final d = buildExport(id, t);
        expect(d.sections, isNotEmpty, reason: id);
        final csv = docToCsv(d);
        expect(csv.sublist(0, 3), [0xEF, 0xBB, 0xBF], reason: '$id BOM');
        expect(utf8.decode(csv).split('\n').length, greaterThan(3), reason: id);
        final pdf = await docToPdf(d, footer: 'f', generated: 'g', org: 'OIAC');
        expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF', reason: id);
      }
    });
  }

  for (final lang in ['fr', 'en']) {
    test('all report types build ($lang)', () async {
      String t(String k, [List<Object> a = const []]) => Strings.t(lang, k);
      for (final id in ['market', 'production', 'quality', 'sustain', 'risks', 'chain', 'africa', 'monthly']) {
        final d = reportDoc(id, t);
        final pdf = await docToPdf(d, footer: 'f', generated: 'g');
        expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF', reason: id);
        expect(docToCsv(d).length, greaterThan(50), reason: id);
      }
    });
  }

  test('data-quality seed has 8 issues to check', () {
    final i = seedIssues();
    expect(i.length, 8);
    expect(i.every((x) => x.status == 0), isTrue);
  });

  test('KPI definitions and rules evaluate', () {
    for (final k in seedKpis()) {
      expect(k.current().isFinite, isTrue, reason: k.id);
      expect(kpiValueText(k), isNotEmpty);
    }
  });
}
