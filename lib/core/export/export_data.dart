import 'dart:convert';
import 'dart:typed_data';
import '../../data/admin_data.dart';
import '../../data/demo/cert_weather_data.dart';
import '../../data/demo/countries_data.dart';
import '../../data/demo/quality_data.dart';
import '../../data/repository.dart';
import '../format.dart';

class ExportSection {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  const ExportSection(this.title, this.headers, this.rows);
}

class ExportDoc {
  final String title;
  final List<String> summary; // short text lines
  final List<ExportSection> sections;
  const ExportDoc(this.title, this.summary, this.sections);
}

ExportSection _dataset(String id, String Function(String, [List<Object>]) t) {
  final d = buildDatasets().firstWhere((x) => x.id == id);
  return ExportSection(t(d.nameKey), [for (final c in d.columns) t(c)], datasetRows(id, t));
}

/// Builds the tables behind a page (demo data) so they can be exported as CSV / PDF.
ExportDoc buildExport(String pageId, String Function(String, [List<Object>]) t) {
  final title = t('nav_$pageId');
  switch (pageId) {
    case 'market':
      return ExportDoc(title, [t('market_sub')], [_dataset('prices', t), _dataset('ports', t)]);
    case 'production':
      return ExportDoc(t('hub_title'), [t('hub_sub')], [
        _dataset('production', t),
        ExportSection(t('dset_coops'), [t('col_coop'), t('col_country'), t('col_tonnes'), t('ql_score'), t('ql_grade')], [
          for (final c in repo.coops()) [c.name, t(repo.country(c.country).nameKey), Fmt.num(c.volumeT, 0), Fmt.num(qualityFor(c.id).score, 1), t(qualityFor(c.id).grade)]
        ]),
      ]);
    case 'revenue':
      return ExportDoc(title, [t('revenue_sub')], [_dataset('costs', t)]);
    case 'sustain':
      return ExportDoc(title, [t('sustain_sub')], [_dataset('sustain', t)]);
    case 'certs':
      return ExportDoc(title, [t('certs_sub')], [
        ExportSection(t('certs_register'), [t('col_country'), t('cert_scheme'), t('cert_body'), t('cert_status'), t('cert_issued'), t('cert_expires'), t('cert_coverage'), t('cert_producers'), t('cert_volume')], [
          for (final c in demoCerts)
            [t('c_${c.country}'), t('cert_${c.scheme}'), c.body, t(['cert_st_valid', 'cert_st_expiring', 'cert_st_expired', 'cert_st_pending'][c.status]), '${c.issued.year}-${c.issued.month.toString().padLeft(2, '0')}', '${c.expires.year}-${c.expires.month.toString().padLeft(2, '0')}', Fmt.num(c.coverage, 1), Fmt.num(c.producers, 0), Fmt.num(c.volumeKt, 1)]
        ]),
      ]);
    case 'chain':
      return ExportDoc(title, [t('chain_sub')], [
        _dataset('chain', t),
        ExportSection(t('lots_title'), ['LOT', t('lot_coop'), t('lot_volume'), t('ql_score'), t('lot_status')], [
          for (final l in demoLots) [l.id, demoCoops.firstWhere((c) => c.id == l.coopId).name, Fmt.num(l.bags, 0), Fmt.num(qualityFor(l.id).score, 1), t(l.statusKey)]
        ]),
      ]);
    case 'forecast':
      return ExportDoc(title, [t('forecast_sub')], [_dataset('forecast', t)]);
    case 'anomalies':
      return ExportDoc(title, [t('anomalies_sub')], [_dataset('anomalies', t)]);
    case 'map':
      return ExportDoc(title, [t('map_sub')], [_dataset('coops', t), _dataset('ports', t)]);
    case 'compare':
      return ExportDoc(title, [t('compare_sub')], [
        ExportSection(title, [t('col_country'), t('cmp_prod'), t('cmp_yield'), t('cmp_income'), t('cmp_cost'), t('cmp_cert'), t('ql_score')], [
          for (final c in repo.countries()) [t(c.nameKey), Fmt.num(c.prodKt, 0), Fmt.num(c.yieldKgHa, 0), Fmt.money(c.incomeYr, 0), Fmt.money(c.costKg, 2), Fmt.num(c.certPct, 0), Fmt.num(qualityFor(c.id).score, 1)]
        ])
      ]);
    case 'alerts':
      return ExportDoc(title, [t('alerts_sub')], [
        ExportSection(title, [t('cat_all'), t('col_severity'), t('col_anomaly'), t('col_updated')], [
          for (final a in repo.alerts()) [t('cat_${a.category}'), t(['sev_critical', 'sev_important', 'sev_watch'][a.severity]), t(a.titleKey), t('ago', [a.ago])]
        ])
      ]);
    case 'sources':
      return ExportDoc(title, [t('sources_sub')], [
        ExportSection(title, [t('col_source'), t('col_data'), t('col_freq'), t('col_updated'), t('col_quality')], [
          for (final s in repo.sources()) [t(s.nameKey), t(s.dataKey), t(s.freqKey), t('ago', [s.updated]), '${Fmt.num(s.quality, 0)} %']
        ])
      ]);
    default:
      return ExportDoc(t('decision_title'), [t('decision_sub')], [
        ExportSection(t('key_indicators'), [t('metric'), t('col_value')], [
          [t('kpi_price'), Fmt.usd(repo.series('arabica').last.v) + '/lb'],
          [t('kpi_prod'), '${Fmt.num(repo.africaProduction(), 0)} kt'],
          [t('kpi_income'), Fmt.usd(repo.africaIncome(), 0)],
          [t('kpi_exports'), '${Fmt.num(repo.africaExports(), 0)} kt'],
        ])
      ]);
  }
}

String _csvCell(String c) => (c.contains(',') || c.contains('"') || c.contains('\n')) ? '"${c.replaceAll('"', '""')}"' : c;

/// UTF-8 CSV with BOM (opens correctly in Excel). All sections are written one after the other.
Uint8List docToCsv(ExportDoc d) {
  final b = StringBuffer('﻿');
  b.writeln(_csvCell(d.title));
  b.writeln(_csvCell('DATA DEMO / DONNEES DE DEMONSTRATION'));
  for (final s in d.sections) {
    b.writeln();
    b.writeln(_csvCell(s.title));
    b.writeln(s.headers.map(_csvCell).join(','));
    for (final r in s.rows) {
      b.writeln(r.map(_csvCell).join(','));
    }
  }
  return Uint8List.fromList(utf8.encode(b.toString()));
}

/// Report documents of the report center (demo content).
ExportDoc reportDoc(String id, String Function(String, [List<Object>]) t) {
  final sum = [t('rep_${id}_sum', [Fmt.usd(3.1)]), t('rep_period')];
  final kpi = ExportSection(t('key_indicators'), [t('metric'), t('col_value')], [
    [t('kpi_price'), '${Fmt.usd(repo.series('arabica').last.v)}/lb'],
    [t('kpi_prod'), '${Fmt.num(repo.africaProduction(), 0)} kt'],
    [t('kpi_income'), Fmt.usd(repo.africaIncome(), 0)],
    [t('kpi_exports'), '${Fmt.num(repo.africaExports(), 0)} kt'],
  ]);
  final quality = ExportSection(t('ql_ranking'), [t('col_coop'), t('col_country'), t('ql_score'), t('ql_grade'), t('ql_variety'), t('ql_process'), t('ql_altitude')], [
    for (final c in repo.coops())
      () {
        final q = qualityFor(c.id);
        return [c.name, t(repo.country(c.country).nameKey), Fmt.num(q.score, 1), t(q.grade), q.variety, t(q.process), '${q.altitude} m'];
      }()
  ]);
  switch (id) {
    case 'market':
      return ExportDoc(t('rep_market'), sum, [kpi, _dataset('prices', t), _dataset('ports', t), _dataset('forecast', t)]);
    case 'production':
      return ExportDoc(t('rep_production'), sum, [kpi, _dataset('production', t), _dataset('coops', t)]);
    case 'quality':
      return ExportDoc(t('rep_quality'), sum, [quality]);
    case 'sustain':
      return ExportDoc(t('rep_sustain'), sum, [_dataset('sustain', t), buildExport('certs', t).sections.first]);
    case 'risks':
      return ExportDoc(t('rep_risks'), sum, [_dataset('anomalies', t), buildExport('alerts', t).sections.first, _dataset('climate', t)]);
    case 'chain':
      return ExportDoc(t('rep_chain'), sum, buildExport('chain', t).sections);
    case 'africa':
      return ExportDoc(t('rep_africa'), sum, [kpi, _dataset('costs', t), _dataset('production', t)]);
    default:
      return ExportDoc(t('rep_monthly'), sum, [kpi, _dataset('anomalies', t), _dataset('forecast', t)]);
  }
}
