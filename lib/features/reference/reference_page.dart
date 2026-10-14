import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/demo/sources_data.dart';
import '../../data/reference_data.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../shell/nav.dart';

/// Reference page: the 25 member countries, their national focal points and the catalogue of indicators
/// (definition + calculation method).
class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});
  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  String _tab = 'countries'; // countries | focal | indicators
  String _q = '';
  String _theme = 'all';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('ref_title', 'ref_sub'),
      Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Segmented<String>(
          values: const ['countries', 'focal', 'indicators'],
          selected: _tab,
          label: (v) => context.tr('ref_tab_${v == 'countries' ? 'countries' : (v == 'focal' ? 'focal' : 'indicators')}'),
          onChanged: (v) => setState(() {
            _tab = v;
            _q = '';
          }),
        ),
        SizedBox(
          width: context.isMobile ? context.w - 32 : 280,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 18), hintText: context.tr('ref_search'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      if (_tab == 'countries') _countries(context, p),
      if (_tab == 'focal') _focal(context, p),
      if (_tab == 'indicators') _indicators(context, p),
    ]);
  }

  bool _match(String text) => _q.trim().isEmpty || text.toLowerCase().contains(_q.trim().toLowerCase());

  // ---------------------------------------------------------------- countries
  Widget _countries(BuildContext context, Pal p) {
    final list = [...repo.countries(africaOnly: true)]..sort((a, b) => context.tr(a.nameKey).compareTo(context.tr(b.nameKey)));
    final shown = [for (final c in list) if (_match('${context.tr(c.nameKey)} ${c.id}')) c];
    String species(double a) => a >= .75 ? context.tr('ref_arabica') : (a <= .25 ? context.tr('ref_robusta') : context.tr('ref_mixed'));
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6), child: Text(context.tr('ref_count', [shown.length]), style: TS.bodyS(p))),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            headingTextStyle: TS.label(p),
            columns: [
              DataColumn(label: Text(context.tr('col_country').toUpperCase())),
              DataColumn(label: Text(context.tr('ref_col_species').toUpperCase())),
              DataColumn(label: Text(context.tr('kpi_prod').toUpperCase()), numeric: true),
              DataColumn(label: Text(context.tr('kpi_exports').toUpperCase()), numeric: true),
              DataColumn(label: Text(context.tr('kpi_producers').toUpperCase()), numeric: true),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final c in shown)
                DataRow(cells: [
                  DataCell(Text('${c.flag}  ${context.tr(c.nameKey)}', style: TextStyle(color: p.text, fontWeight: FontWeight.w700))),
                  DataCell(Text(species(c.arabicaShare), style: TextStyle(color: p.muted))),
                  DataCell(Text('${Fmt.num(c.prodKt, c.prodKt < 10 ? 1 : 0)} kt')),
                  DataCell(Text('${Fmt.num(c.exportsKt, c.exportsKt < 10 ? 1 : 0)} kt')),
                  DataCell(Text('${Fmt.num(c.producersK, 1)} k')),
                  DataCell(TextButton(
                    onPressed: () {
                      context.app.selectCountry(c.id);
                      context.app.goto(navIndex('map'));
                    },
                    child: Text(context.tr('ref_open_map')),
                  )),
                ]),
            ],
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------- focal points
  Widget _focal(BuildContext context, Pal p) {
    final list = [...focalPoints]..sort((a, b) => context.tr('c_${a.country}').compareTo(context.tr('c_${b.country}')));
    final shown = [for (final f in list) if (_match('${context.tr('c_${f.country}')} ${f.name} ${f.email}')) f];
    final flags = {for (final c in repo.countries(africaOnly: true)) c.id: c.flag};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const DemoHint('ref_focal_demo'),
      const SizedBox(height: 12),
      Grid(columns: context.cols(desktop: 3, tablet: 2, mobile: 1), gap: 12, children: [
        for (final f in shown)
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(flags[f.country] ?? '', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text(context.tr('c_${f.country}'), style: TS.h3(p))),
              ]),
              const SizedBox(height: 8),
              Text(f.name, style: TS.h3(p).copyWith(color: p.accent)),
              Text(context.tr(f.titleKey), style: TS.bodyS(p)),
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.mail_outline_rounded, size: 15, color: p.muted), const SizedBox(width: 6), Expanded(child: Text(f.email, overflow: TextOverflow.ellipsis, style: TS.bodyS(p).copyWith(color: p.text, fontSize: 12.5)))]),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.phone_outlined, size: 15, color: p.muted), const SizedBox(width: 6), Text(f.phone, style: TS.bodyS(p).copyWith(color: p.text, fontSize: 12.5))]),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: f.email));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr('ref_copied'))));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(context.tr('ref_copy_email')),
                ),
              ),
            ]),
          ),
      ]),
    ]);
  }

  // ---------------------------------------------------------------- indicators
  Widget _indicators(BuildContext context, Pal p) {
    final shown = [
      for (final i in indicatorCatalogue)
        if ((_theme == 'all' || i.theme == _theme) && _match('${context.tr(i.nameKey)} ${context.tr(i.defKey)}')) i
    ];
    final src = {for (final s in demoSources) s.id: s};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in ['all', ...indicatorThemes])
          ChoiceChip(
            label: Text(context.tr(t == 'all' ? 'ref_theme_all' : 'theme_$t')),
            selected: _theme == t,
            showCheckmark: false,
            selectedColor: p.accent.withValues(alpha: .25),
            onSelected: (_) => setState(() => _theme = t),
          ),
      ]),
      const SizedBox(height: 8),
      Text(context.tr('ref_count', [shown.length]), style: TS.bodyS(p)),
      const SizedBox(height: 8),
      for (final i in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(context.tr(i.nameKey), style: TS.h3(p)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: 6, runSpacing: 4, children: [
                    Chip2(context.tr('theme_${i.theme}'), p.accent),
                    Chip2(Fmt.unit(i.unit), p.muted),
                    Chip2(context.tr(i.partner ? 'ref_aud_partner' : 'ref_aud_public'), i.partner ? p.gold : p.green, icon: i.partner ? Icons.lock_rounded : Icons.public_rounded),
                  ]),
                ),
                children: [
                  _field(context, 'ref_ind_def', context.tr(i.defKey)),
                  _field(context, 'ref_ind_method', context.tr(i.methodKey), emphasise: true),
                  _field(context, 'ref_ind_source', src[i.sourceId] == null ? '' : context.tr(src[i.sourceId]!.nameKey)),
                  _field(context, 'ref_ind_freq', context.tr(i.freqKey)),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 4),
      Text(context.tr('ref_ind_note'), style: TS.bodyS(p).copyWith(fontSize: 11.5)),
    ]);
  }

  Widget _field(BuildContext context, String labelKey, String value, {bool emphasise = false}) {
    final p = context.pal;
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr(labelKey).toUpperCase(), style: TS.label(p)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: emphasise ? const EdgeInsets.all(10) : EdgeInsets.zero,
          decoration: emphasise ? BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)) : null,
          child: Text(value, style: TS.bodyS(p).copyWith(color: p.text, height: 1.45)),
        ),
      ]),
    );
  }
}

/// Small "demonstration" notice.
class DemoHint extends StatelessWidget {
  final String textKey;
  const DemoHint(this.textKey, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.gold.withValues(alpha: .5))),
      child: Row(children: [
        Icon(Icons.science_rounded, size: 16, color: p.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(context.tr(textKey), style: TS.bodyS(p).copyWith(fontSize: 12))),
      ]),
    );
  }
}
