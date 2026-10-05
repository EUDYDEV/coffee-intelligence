import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../../widgets/map/map_view.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});
  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  bool _africaOnly = true;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final af = repo.countries(africaOnly: true);
    final c = repo.country(app.selectedCountry.isEmpty || !repo.country(app.selectedCountry).african ? 'ETH' : app.selectedCountry);
    final list = [...repo.countries(africaOnly: _africaOnly)]..sort((a, b) => b.prodKt.compareTo(a.prodKt));
    final coops = repo.coops().where((x) => x.country == c.id).toList();
    final totalProd = af.fold(0.0, (a, x) => a + x.prodKt);
    final totalProducers = af.fold(0.0, (a, x) => a + x.producersK);
    final totalArea = af.fold(0.0, (a, x) => a + x.areaKha);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('production_title', 'production_sub'),
      Grid(columns: context.cols(desktop: 4, tablet: 2, mobile: 2), gap: 12, children: [
        Reveal(child: KpiCard(labelKey: 'kpi_prod', metric: 'production', value: totalProd, unit: 'kt', trend: 3.4, icon: Icons.spa_rounded)),
        Reveal(delay: 80, child: KpiCard(labelKey: 'kpi_yield', metric: 'production', value: totalProd / totalArea * 1000, unit: 'kg/ha', trend: 1.9, icon: Icons.grass_rounded)),
        Reveal(delay: 160, child: KpiCard(labelKey: 'kpi_area', metric: 'production', value: totalArea, unit: 'kha', trend: .6, icon: Icons.landscape_rounded)),
        Reveal(delay: 240, child: KpiCard(labelKey: 'kpi_producers', metric: 'production', value: totalProducers, unit: 'k', trend: 1.2, icon: Icons.people_alt_rounded)),
      ]),
      gap24,
      TwoCol(
        flexL: 6,
        flexR: 4,
        left: Reveal(
          delay: 200,
          child: MapView(
            height: context.isMobile ? 380 : 500,
            layers: const {'production', 'coops'},
            selected: c.id,
            onSelect: app.selectCountry,
          ),
        ),
        right: Reveal(delay: 300, child: _CountryPanel(c: c, coops: coops)),
      ),
      gap24,
      Reveal(
        delay: 300,
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(context.tr('prod_by_country'), trailing: Segmented<bool>(values: const [true, false], selected: _africaOnly, label: (v) => v ? context.tr('africa') : context.tr('world'), onChanged: (v) => setState(() => _africaOnly = v))),
            BarChartW(
              height: 260,
              fmt: (v) => Fmt.num(v, 0),
              selected: list.indexWhere((x) => x.id == c.id),
              onTap: (i) {
                if (list[i].african) app.selectCountry(list[i].id);
              },
              items: [for (final x in list) BarItem('${x.flag} ${x.id}', x.prodKt, x.african ? p.accent : p.muted)],
            ),
          ]),
        ),
      ),
      gap24,
      TwoCol(
        left: Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('yield_by_country')),
              BarChartW(height: 230, fmt: (v) => Fmt.num(v, 0), items: [for (final x in [...af]..sort((a, b) => b.yieldKgHa.compareTo(a.yieldKgHa))) BarItem(x.id, x.yieldKgHa, p.green)]),
            ]),
          ),
        ),
        right: Reveal(
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(context.tr('annual_evolution')),
              LineChartW(
                height: 230,
                dates: [for (var i = 0; i < 8; i++) DateTime(2019 + i, 7, 1)],
                series: [ChartSeries(context.tr('africa'), repo.africaProdHistory(), p.accent)],
                yFmt: (v) => Fmt.num(v, 0),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _CountryPanel extends StatelessWidget {
  final Country c;
  final List<Coop> coops;
  const _CountryPanel({required this.c, required this.coops});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget stat(String k, double v, String u, {int d = 0}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(k).toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 4),
            AnimatedCounter(v, decimals: d, suffix: ' $u', style: TS.big(p, size: 20)),
          ]),
        );
    return GlassCard(
      accent: p.gold,
      child: AnimatedSwitcher(
        duration: context.dur(350),
        child: Column(
          key: ValueKey(c.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(c.flag, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr(c.nameKey), style: TS.h2(p))),
              Chip2(c.arabicaShare >= .5 ? 'Arabica' : 'Robusta', p.accent),
            ]),
            const SizedBox(height: 16),
            Row(children: [stat('kpi_prod', c.prodKt, 'kt'), stat('kpi_yield', c.yieldKgHa, 'kg/ha')]),
            const SizedBox(height: 14),
            Row(children: [stat('kpi_area', c.areaKha, 'kha'), stat('kpi_producers', c.producersK, 'k')]),
            const SizedBox(height: 14),
            Row(children: [stat('coops', c.coops, ''), stat('kpi_exports', c.exportsKt, 'kt')]),
            const Divider(height: 28),
            Text(context.tr('by_region').toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 8),
            for (final r in c.regions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 92, child: Text(r.name, style: TextStyle(color: p.text, fontSize: 12.5))),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: r.share),
                      duration: context.dur(1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(value: v / .45, minHeight: 9, borderRadius: BorderRadius.circular(5), color: p.green, backgroundColor: p.border),
                    ),
                  ),
                  SizedBox(width: 56, child: Text('${Fmt.num(c.prodKt * r.share, 0)} kt', textAlign: TextAlign.right, style: TextStyle(color: p.muted, fontSize: 12))),
                ]),
              ),
            const Divider(height: 28),
            Text(context.tr('coop_volumes').toUpperCase(), style: TS.label(p)),
            const SizedBox(height: 8),
            for (final k in coops)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Icon(Icons.circle, size: 8, color: p.gold),
                  const SizedBox(width: 8),
                  Expanded(child: Text(k.name, style: TextStyle(color: p.text, fontSize: 12.5))),
                  Text('${Fmt.num(k.volumeT, 0)} t', style: TextStyle(color: p.muted, fontSize: 12.5)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
