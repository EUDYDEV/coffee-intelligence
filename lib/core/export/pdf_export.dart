import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'export_data.dart';

/// The built-in PDF fonts only cover Latin-1: map other typographic characters to ASCII.
String _a(String s) {
  const map = {'’': "'", '‘': "'", '“': '"', '”': '"', '–': '-', '—': '-', '·': '-', '…': '...', '→': '->', '←': '<-', '↓': 'v', '↑': '^', '€': 'EUR', '₦': 'NGN', 'GH₵': 'GHS', '£': 'GBP', 'σ': 'sigma', ' ': ' ', '✓': 'ok'};
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (map.containsKey(ch)) {
      b.write(map[ch]);
    } else if (r < 256) {
      b.write(ch);
    } else {
      b.write('?');
    }
  }
  return b.toString();
}

/// Real PDF generated locally (works on Web and Android). [footer] is the demo-data disclaimer.
Future<Uint8List> docToPdf(ExportDoc d, {required String footer, required String generated, String? org}) async {
  final doc = pw.Document(title: _a(d.title), author: 'OIAC / IACO');
  const brown = PdfColor.fromInt(0xFF4A2C20);
  const gold = PdfColor.fromInt(0xFFC9A45C);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 44),
    footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(_a(footer), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      pw.Text('${c.pageNumber}/${c.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ]),
    build: (c) => [
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: gold, width: 2))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(_a(org ?? 'OIAC / IACO'), style: pw.TextStyle(fontSize: 9, color: gold, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
          pw.SizedBox(height: 4),
          pw.Text(_a(d.title), style: pw.TextStyle(fontSize: 22, color: brown, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(_a(generated), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ]),
      ),
      pw.SizedBox(height: 10),
      for (final line in d.summary) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text(_a(line), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2))),
      for (final s in d.sections) ...[
        pw.SizedBox(height: 14),
        pw.Text(_a(s.title), style: pw.TextStyle(fontSize: 13, color: brown, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: [for (final h in s.headers) _a(h)],
          data: [for (final r in s.rows.take(60)) [for (final c in r) _a(c)]],
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: brown),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7EEDD)),
          border: null,
        ),
        if (s.rows.length > 60) pw.Text('... ${s.rows.length - 60} more rows', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ],
  ));
  return doc.save();
}
