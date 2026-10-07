import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/ctx.dart';
import '../core/export/download.dart';
import '../core/export/export_data.dart';
import '../core/export/pdf_export.dart';
import '../core/theme/palette.dart';

String _stamp() {
  final n = DateTime.now();
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

/// "Export" menu: CSV, PDF and PNG generated locally from the demo data and the visible page.
class ExportButton extends StatelessWidget {
  final String pageId;
  const ExportButton({super.key, required this.pageId});

  Future<void> _run(BuildContext context, String kind) async {
    final app = context.app;
    final msg = ScaffoldMessenger.of(context);
    final done = context.tr('export_done');
    final fail = context.tr('export_fail');
    try {
      final doc = buildExport(pageId, context.tr);
      final base = 'oiac_${pageId}_${_stamp()}';
      if (kind == 'csv') {
        await saveFile('$base.csv', docToCsv(doc), 'text/csv');
      } else if (kind == 'pdf') {
        final bytes = await docToPdf(doc, footer: context.tr('pdf_footer'), generated: context.tr('pdf_generated', [_stamp()]), org: context.tr('org_name'));
        await saveFile('$base.pdf', bytes, 'application/pdf');
      } else {
        final b = app.exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (b == null) throw StateError('no boundary');
        final raw = await b.toImage(pixelRatio: 2);
        // paint on the page background so the PNG is not transparent
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        final bg = Pal.of(context).bg;
        canvas.drawRect(Rect.fromLTWH(0, 0, raw.width.toDouble(), raw.height.toDouble()), Paint()..color = bg);
        canvas.drawImage(raw, Offset.zero, Paint());
        final img = await rec.endRecording().toImage(raw.width, raw.height);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        await saveFile('$base.png', Uint8List.view(data!.buffer), 'image/png');
      }
      app.addLog('log_export', pageId);
      msg.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('$done · ${kind.toUpperCase()}')));
    } catch (e) {
      msg.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('$fail ($e)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PopupMenuButton<String>(
      tooltip: context.tr('export_title'),
      color: p.surface,
      onSelected: (k) => _run(context, k),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'csv', child: _item(context, Icons.table_chart_rounded, 'CSV', context.tr('export_csv_d'))),
        PopupMenuItem(value: 'pdf', child: _item(context, Icons.picture_as_pdf_rounded, 'PDF', context.tr('export_pdf_d'))),
        PopupMenuItem(value: 'png', child: _item(context, Icons.image_rounded, 'PNG', context.tr('export_png_d'))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: p.gold)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.ios_share_rounded, size: 16, color: p.gold),
          const SizedBox(width: 8),
          Text(context.tr('export_title'), style: TextStyle(color: p.gold, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, IconData i, String t, String d) {
    final p = context.pal;
    return Row(children: [
      Icon(i, color: p.accent),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
        Text(d, style: TextStyle(fontSize: 11, color: p.muted)),
      ]),
    ]);
  }
}
