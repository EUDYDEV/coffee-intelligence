import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_data.dart';
import '../../data/repository.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';

String _monthLabel(DateTime d, String lang) {
  const fr = ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return (lang == 'fr' ? fr : en)[d.month - 1];
}

String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

int _records(BuildContext c, DataSet d) =>
    datasetRows(d.id, c.tr).length + c.app.manual.where((e) => e.dataset == d.id).length;

// ===========================================================================
// 1. Dashboard
// ===========================================================================
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final ds = app.datasets;
    final total = ds.fold(0, (a, d) => a + _records(context, d));
    final sale = ds.where((d) => d.forSale).length;
    final revenue = app.orders.fold(0.0, (a, o) => a + o.usd);
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
    final rev = [for (final m in months) app.orders.where((o) => o.ts.year == m.year && o.ts.month == m.month).fold(0.0, (a, o) => a + o.usd)];
    final byBuyer = <String, double>{};
    for (final o in app.orders) {
      byBuyer[o.buyer] = (byBuyer[o.buyer] ?? 0) + o.usd;
    }
    final top = byBuyer.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_dash_title', 'adm_dash_sub'),
      Grid(columns: context.cols(desktop: 3, tablet: 3, mobile: 2), gap: 12, children: [
        Reveal(child: KpiCard(labelKey: 'adm_k_datasets', metric: 'default', value: ds.length.toDouble(), icon: Icons.dataset_rounded)),
        Reveal(delay: 70, child: KpiCard(labelKey: 'adm_k_records', metric: 'default', value: total.toDouble(), icon: Icons.table_rows_rounded)),
        Reveal(delay: 140, child: KpiCard(labelKey: 'adm_k_forsale', metric: 'default', value: sale.toDouble(), unit: '/ ${ds.length}', icon: Icons.sell_rounded)),
        Reveal(delay: 210, child: KpiCard(labelKey: 'adm_k_revenue', metric: 'default', value: revenue, unit: r'$', icon: Icons.payments_rounded, trend: 12.4)),
        Reveal(delay: 280, child: KpiCard(labelKey: 'adm_k_orders', metric: 'default', value: app.orders.length.toDouble(), icon: Icons.receipt_long_rounded)),
        Reveal(delay: 350, child: KpiCard(labelKey: 'adm_k_manual', metric: 'default', value: app.manual.length.toDouble(), icon: Icons.edit_note_rounded)),
      ]),
      gap24,
      TwoCol(
        left: Reveal(
          delay: 150,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('adm_rev_month')),
              BarChartW(
                height: 230,
                unit: Fmt.sym,
                legend: [(p.accent, context.tr('adm_sales'))],
                fmt: (v) => Fmt.compact(v),
                items: [for (var i = 0; i < months.length; i++) BarItem(_monthLabel(months[i], app.lang), Fmt.conv(rev[i]), p.accent)],
              ),
              Text(context.tr('adm_src_sales'), style: TS.bodyS(p).copyWith(fontSize: 11)),
            ]),
          ),
        ),
        right: Reveal(
          delay: 250,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('adm_records_ds')),
              BarChartW(
                height: 230,
                unit: context.tr('adm_records'),
                legend: [(p.green, context.tr('adm_records'))],
                fmt: (v) => Fmt.num(v, 0),
                onTap: (i) => app.gotoAdmin(1, dataset: ds[i].id),
                items: [for (final d in ds) BarItem(context.tr(d.nameKey).split(' ').first, _records(context, d).toDouble(), p.green)],
              ),
              Text(context.tr('adm_src_catalog'), style: TS.bodyS(p).copyWith(fontSize: 11)),
            ]),
          ),
        ),
      ),
      gap24,
      TwoCol(
        left: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('adm_top_buyers')),
            for (final e in top.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(Icons.business_rounded, size: 18, color: p.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key, style: TS.h3(p).copyWith(fontSize: 13.5))),
                  Text(Fmt.usd(e.value, 0), style: TS.h3(p)),
                ]),
              ),
          ]),
        ),
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('adm_activity')),
            if (app.log.isEmpty) Text(context.tr('adm_no_activity'), style: TS.bodyS(p)),
            for (final l in app.log.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Text(_time(l.ts), style: TS.bodyS(p).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${context.tr(l.actionKey)}${l.detail.isEmpty ? '' : ' · ${datasetName(context, l.detail)}'}', style: TS.h3(p).copyWith(fontWeight: FontWeight.w500, fontSize: 13))),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }
}

String datasetName(BuildContext c, String id) {
  final d = c.app.datasets.where((x) => x.id == id).firstOrNull;
  return d == null ? id : c.tr(d.nameKey);
}

// ===========================================================================
// 2. All data
// ===========================================================================
class AdminDataPage extends StatefulWidget {
  const AdminDataPage({super.key});
  @override
  State<AdminDataPage> createState() => _AdminDataPageState();
}

class _AdminDataPageState extends State<AdminDataPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final d = app.datasets.firstWhere((x) => x.id == app.adminDataset, orElse: () => app.datasets.first);
    final src = repo.sources().firstWhere((s) => s.id == d.sourceId);
    final demoRows = datasetRows(d.id, context.tr);
    final man = app.manual.where((e) => e.dataset == d.id).toList();
    final rows = <(List<String>, bool)>[
      for (final e in man) (manualRowDisplay(e), true),
      for (final r in demoRows) (r, false),
    ].where((r) => _q.isEmpty || r.$1.any((c) => c.toLowerCase().contains(_q.toLowerCase()))).toList();

    final list = GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        for (final x in app.datasets)
          GestureDetector(
            onTap: () => app.gotoAdmin(1, dataset: x.id),
            child: AnimatedContainer(
              duration: context.dur(200),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: x.id == d.id ? p.accent.withValues(alpha: .14) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: x.id == d.id ? p.accent : p.border),
              ),
              child: Row(children: [
                Icon(Icons.table_chart_rounded, size: 18, color: x.id == d.id ? p.accent : p.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(context.tr(x.nameKey), style: TS.h3(p).copyWith(fontSize: 13.5))),
                Text(Fmt.num(_records(context, x).toDouble(), 0), style: TS.bodyS(p)),
                if (x.forSale) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.sell_rounded, size: 14, color: p.gold)),
              ]),
            ),
          ),
      ]),
    );

    final table = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr(d.nameKey), style: TS.h2(p))),
          Chip2(context.tr(d.forSale ? 'adm_on_sale' : 'adm_not_sale'), d.forSale ? p.gold : p.muted, icon: Icons.sell_rounded),
        ]),
        const SizedBox(height: 4),
        Text(context.tr(d.descKey), style: TS.bodyS(p)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip2('${context.tr('trust_source')} : ${context.tr(src.nameKey)}', p.green, icon: Icons.hub_rounded),
          Chip2('${context.tr('col_updated')} : ${context.tr('ago', [src.updated])}', p.muted),
          Chip2('${context.tr('col_quality')} ${Fmt.num(src.quality, 0)} %', p.accent),
          Chip2('${Fmt.num(_records(context, d).toDouble(), 0)} ${context.tr('adm_records')}', p.accent),
          if (man.isNotEmpty) Chip2('${man.length} ${context.tr('adm_manual_rows')}', p.warn, icon: Icons.edit_rounded),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(isDense: true, hintText: context.tr('adm_search'), prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: context.tr('adm_copy_csv'),
            onPressed: () {
              final head = d.columns.map(context.tr).join(',');
              final body = rows.map((r) => r.$1.map((c) => c.contains(',') ? '"$c"' : c).join(',')).join('\n');
              Clipboard.setData(ClipboardData(text: '$head\n$body'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('adm_csv_copied', [rows.length]))));
              app.addLog('log_export', d.id);
            },
            icon: const Icon(Icons.copy_all_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filled(tooltip: context.tr('adm_add_data'), style: IconButton.styleFrom(backgroundColor: p.accent), onPressed: () => app.gotoAdmin(3, dataset: d.id), icon: const Icon(Icons.add_rounded)),
        ]),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 42,
                columnSpacing: 28,
                headingTextStyle: TS.label(p),
                columns: [
                  for (final c in d.columns) DataColumn(label: Text(context.tr(c).toUpperCase())),
                  DataColumn(label: Text(context.tr('col_origin').toUpperCase())),
                ],
                rows: [
                  for (final r in rows.take(80))
                    DataRow(
                      color: r.$2 ? WidgetStatePropertyAll(p.warn.withValues(alpha: .1)) : null,
                      cells: [
                        for (final c in r.$1) DataCell(Text(c, style: TextStyle(color: p.text, fontSize: 13))),
                        DataCell(Chip2(context.tr(r.$2 ? 'adm_origin_manual' : 'adm_origin_demo'), r.$2 ? p.warn : p.muted)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (rows.length > 80) Padding(padding: const EdgeInsets.only(top: 8), child: Text(context.tr('adm_showing', [80, rows.length]), style: TS.bodyS(p))),
        if (rows.isEmpty) Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(context.tr('adm_no_rows'), style: TS.bodyS(p)))),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_data_title', 'adm_data_sub'),
      TwoCol(flexL: 3, flexR: 8, stretch: false, left: list, right: table),
    ]);
  }
}

// ===========================================================================
// 3. Sell data
// ===========================================================================
class AdminSalesPage extends StatelessWidget {
  const AdminSalesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final revenue = app.orders.fold(0.0, (a, o) => a + o.usd);
    final byDs = <String, double>{};
    for (final o in app.orders) {
      byDs[o.datasetId] = (byDs[o.datasetId] ?? 0) + o.usd;
    }
    final top = byDs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_sales_title', 'adm_sales_sub'),
      Grid(columns: context.cols(desktop: 3, tablet: 3, mobile: 1), gap: 12, children: [
        KpiCard(labelKey: 'adm_k_revenue', metric: 'default', value: revenue, unit: r'$', icon: Icons.payments_rounded, trend: 12.4),
        KpiCard(labelKey: 'adm_k_orders', metric: 'default', value: app.orders.length.toDouble(), icon: Icons.receipt_long_rounded),
        KpiCard(labelKey: 'adm_k_forsale', metric: 'default', value: app.datasets.where((d) => d.forSale).length.toDouble(), unit: '/ ${app.datasets.length}', icon: Icons.sell_rounded),
      ]),
      gap24,
      SectionLabel(context.tr('adm_catalog')),
      Grid(columns: context.cols(desktop: 2, tablet: 2, mobile: 1), gap: 14, children: [
        for (final d in app.datasets) _SaleCard(d: d),
      ]),
      gap24,
      TwoCol(
        left: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('adm_rev_by_ds')),
            BarChartW(
              height: 240,
              unit: Fmt.sym,
              legend: [(p.gold, context.tr('adm_sales'))],
              fmt: (v) => Fmt.compact(v),
              items: [for (final e in top) BarItem(datasetName(context, e.key).split(' ').first, Fmt.conv(e.value), p.gold)],
            ),
            Text(context.tr('adm_src_sales'), style: TS.bodyS(p).copyWith(fontSize: 11)),
          ]),
        ),
        right: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('adm_orders')),
            for (final o in app.orders.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: p.green)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.buyer, style: TS.h3(p).copyWith(fontSize: 13.5)),
                      Text('${datasetName(context, o.datasetId)} · ${o.ts.day}/${o.ts.month}/${o.ts.year}', style: TS.bodyS(p).copyWith(fontSize: 11.5)),
                    ]),
                  ),
                  Text(Fmt.usd(o.usd, 0), style: TS.h3(p)),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Text(context.tr('adm_sales_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
    ]);
  }
}

class _SaleCard extends StatefulWidget {
  final DataSet d;
  const _SaleCard({required this.d});
  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  late final TextEditingController _c = TextEditingController();
  String? _shownFor;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final d = widget.d;
    final src = repo.sources().firstWhere((s) => s.id == d.sourceId);
    final key = '${Fmt.cur.code}${d.priceUsd}';
    if (_shownFor != key) {
      _c.text = Fmt.money(d.priceUsd, 0).replaceAll(' ', '').replaceAll(',', '');
      _shownFor = key;
    }
    return GlassCard(
      accent: d.forSale ? p.gold : p.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr(d.nameKey), style: TS.h3(p).copyWith(fontSize: 15))),
          Switch(
            value: d.forSale,
            onChanged: (v) {
              d.forSale = v;
              app.addLog(v ? 'log_list' : 'log_unlist', d.id);
              app.touch();
            },
          ),
        ]),
        Text(context.tr(d.descKey), style: TS.bodyS(p)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          Chip2(context.tr(src.nameKey), p.green, icon: Icons.hub_rounded),
          Chip2('${Fmt.num(_records(context, d).toDouble(), 0)} ${context.tr('adm_records')}', p.muted),
          for (final f in d.formats) Chip2(f, p.accent),
          Chip2(context.tr(d.license), p.gold),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 10, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 150,
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final n = double.tryParse(v.replaceAll(' ', ''));
                if (n != null && n > 0) {
                  d.priceUsd = n / Fmt.cur.perUsd;
                  app.addLog('log_price', d.id);
                  app.touch();
                }
              },
              decoration: InputDecoration(isDense: true, labelText: '${context.tr('adm_price')} (${Fmt.sym})', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          PrimaryButton(context.tr('adm_simulate_sale'), icon: Icons.shopping_cart_checkout_rounded, outlined: true, onTap: d.forSale
              ? () {
                  final buyer = buyers[(app.orders.length * 3 + d.id.length) % buyers.length];
                  app.sell(d, buyer);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('adm_sold', [buyer, Fmt.usd(d.priceUsd, 0)]))));
                }
              : null),
        ]),
      ]),
    );
  }
}

// ===========================================================================
// 4. Add data manually
// ===========================================================================
class AdminAddPage extends StatefulWidget {
  const AdminAddPage({super.key});
  @override
  State<AdminAddPage> createState() => _AdminAddPageState();
}

class _AdminAddPageState extends State<AdminAddPage> {
  final Map<String, TextEditingController> _ctl = {};
  final TextEditingController _csv = TextEditingController();
  String? _error;

  TextEditingController _c(String ds, int i) => _ctl.putIfAbsent('$ds$i', () => TextEditingController());

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    _csv.dispose();
    super.dispose();
  }

  List<String>? _validate(String ds, List<String> raw) {
    final defs = manualFields[ds]!;
    if (raw.length != defs.length) return null;
    final out = <String>[];
    for (var i = 0; i < defs.length; i++) {
      final v = raw[i].trim();
      if (v.isEmpty) return null;
      if (defs[i].type == 'number' || defs[i].type == 'money') {
        final n = double.tryParse(v.replaceAll(',', '.').replaceAll(' ', ''));
        if (n == null) return null;
        out.add(defs[i].type == 'money' ? (n / Fmt.cur.perUsd).toString() : Fmt.num(n, n == n.roundToDouble() ? 0 : 2));
      } else {
        out.add(v);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final ids = manualFields.keys.toList();
    final ds = ids.contains(app.adminDataset) ? app.adminDataset : ids.first;
    final defs = manualFields[ds]!;
    final entries = app.manual;

    Widget field(int i) {
      final f = defs[i];
      if (f.type == 'country') {
        return DropdownButtonFormField<String>(isExpanded: true, 
          initialValue: repo.countries().first.id,
          decoration: InputDecoration(labelText: context.tr(f.key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: [for (final c in repo.countries()) DropdownMenuItem(value: context.tr(c.nameKey), child: Text('${c.flag} ${context.tr(c.nameKey)}'))],
          onChanged: (v) => _c(ds, i).text = v ?? '',
        );
      }
      if (f.type == 'port') {
        return DropdownButtonFormField<String>(isExpanded: true, 
          decoration: InputDecoration(labelText: context.tr(f.key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: [for (final x in repo.ports()) DropdownMenuItem(value: x.id, child: Text('${x.id} · ${x.name}'))],
          onChanged: (v) => _c(ds, i).text = v ?? '',
        );
      }
      final money = f.type == 'money';
      return TextField(
        controller: _c(ds, i),
        keyboardType: f.type == 'text' ? TextInputType.text : TextInputType.number,
        decoration: InputDecoration(
          labelText: money ? '${context.tr(f.key)} (${Fmt.sym})' : context.tr(f.key),
          hintText: f.key == 'col_month' ? '2026-10' : (f.key == 'col_season' ? '2026/27' : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    final form = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('adm_new_entry')),
        DropdownButtonFormField<String>(isExpanded: true, 
          key: ValueKey(ds),
          initialValue: ds,
          decoration: InputDecoration(labelText: context.tr('adm_dataset'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(datasetName(context, id)))],
          onChanged: (v) {
            _error = null;
            app.gotoAdmin(3, dataset: v);
          },
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < defs.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: field(i)),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: TextStyle(color: p.alert, fontWeight: FontWeight.w600))),
        PrimaryButton(context.tr('adm_save'), icon: Icons.save_rounded, onTap: () {
          final raw = [for (var i = 0; i < defs.length; i++) _c(ds, i).text];
          final v = _validate(ds, raw);
          if (v == null) {
            setState(() => _error = context.tr('adm_invalid'));
            return;
          }
          app.addManual(ManualEntry(ds, v));
          for (var i = 0; i < defs.length; i++) {
            _c(ds, i).clear();
          }
          setState(() => _error = null);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('adm_saved'))));
        }),
      ]),
    );

    final import = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('adm_import_csv')),
        Text(context.tr('adm_import_hint', [defs.map((d) => context.tr(d.key)).join(', ')]), style: TS.bodyS(p)),
        const SizedBox(height: 10),
        TextField(controller: _csv, minLines: 4, maxLines: 8, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: ds == 'prices' ? '2026-10, ${Fmt.money(3.2)}, ${Fmt.money(2.4)}\n2026-11, ${Fmt.money(3.3)}, ${Fmt.money(2.5)}' : null)),
        const SizedBox(height: 10),
        PrimaryButton(context.tr('adm_import'), icon: Icons.upload_file_rounded, outlined: true, onTap: () {
          var ok = 0, bad = 0;
          for (final line in _csv.text.split('\n')) {
            if (line.trim().isEmpty) continue;
            final v = _validate(ds, line.split(RegExp(r'[;\t,]')).map((e) => e.trim()).toList());
            if (v == null) {
              bad++;
            } else {
              app.addManual(ManualEntry(ds, v));
              ok++;
            }
          }
          _csv.clear();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('adm_imported', [ok, bad]))));
        }),
      ]),
    );

    final recent = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(context.tr('adm_my_entries'), trailing: Chip2('${entries.length}', p.warn)),
        if (entries.isEmpty) Text(context.tr('adm_no_entries'), style: TS.bodyS(p)),
        for (final e in entries.take(12))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Chip2(datasetName(context, e.dataset).split(' ').first, p.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(manualRowDisplay(e).join(' · '), style: TS.bodyS(p).copyWith(color: p.text), overflow: TextOverflow.ellipsis)),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => app.removeManual(e), icon: Icon(Icons.delete_outline_rounded, color: p.muted, size: 20)),
            ]),
          ),
        if (entries.isNotEmpty)
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => app.gotoAdmin(1, dataset: entries.first.dataset), icon: const Icon(Icons.table_chart_rounded, size: 18), label: Text(context.tr('adm_see_in_data')))),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('adm_add_title', 'adm_add_sub'),
      TwoCol(flexL: 5, flexR: 5, stretch: false, left: form, right: Column(children: [import, gap16, recent])),
    ]);
  }
}
