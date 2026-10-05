import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../../widgets/map/map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Set<String> _layers = {'production', 'coops', 'exports', 'climate', 'cert'};
  bool _focus = false;

  static const _icons = {
    'production': Icons.spa_rounded,
    'coops': Icons.groups_rounded,
    'climate': Icons.thunderstorm_rounded,
    'exports': Icons.directions_boat_rounded,
    'cert': Icons.verified_rounded,
    'deforest': Icons.forest_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final c = repo.country(repo.country(app.selectedCountry).african ? app.selectedCountry : 'ETH');
    final filters = Wrap(spacing: 8, runSpacing: 8, children: [
      for (final k in mapLayerKeys)
        FilterChip(
          avatar: Icon(_icons[k], size: 16, color: _layers.contains(k) ? Colors.white : p.muted),
          label: Text(context.tr('layer_$k')),
          selected: _layers.contains(k),
          showCheckmark: false,
          selectedColor: p.accent,
          labelStyle: TextStyle(color: _layers.contains(k) ? Colors.white : p.text, fontWeight: FontWeight.w600, fontSize: 12.5),
          onSelected: (v) => setState(() => v ? _layers.add(k) : _layers.remove(k)),
        ),
    ]);
    final info = GlassCard(
      accent: p.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(c.nameKey), style: TS.h2(p))),
        ]),
        const SizedBox(height: 14),
        _kv(context, 'kpi_prod', '${Fmt.num(c.prodKt, 0)} kt'),
        _kv(context, 'kpi_yield', '${Fmt.num(c.yieldKgHa, 0)} kg/ha'),
        _kv(context, 'kpi_exports', '${Fmt.num(c.exportsKt, 0)} kt'),
        _kv(context, 'kpi_climate', '${Fmt.num(c.climateRisk, 0)}/100'),
        _kv(context, 'certified', Fmt.pct(c.certPct, 0)),
        _kv(context, 'sd_forest', '${Fmt.num(100 - c.deforestRisk, 0)}/100'),
        const SizedBox(height: 12),
        PrimaryButton(_focus ? context.tr('map_reset') : context.tr('map_zoom'), icon: _focus ? Icons.zoom_out_map_rounded : Icons.my_location_rounded, outlined: true, onTap: () => setState(() => _focus = !_focus)),
      ]),
    );
    final map = MapView(
      height: context.isMobile ? 440 : 620,
      layers: _layers,
      selected: c.id,
      focus: _focus ? c.id : null,
      onSelect: (id) {
        app.selectCountry(id);
      },
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('map_title', 'map_sub'),
      filters,
      gap16,
      context.isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: map),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: info),
            ])
          : Column(children: [map, gap16, info]),
      gap16,
      Text(context.tr('map_hint'), style: TS.bodyS(p)),
    ]);
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(context.tr(k), style: TS.bodyS(p))),
        Text(v, style: TS.h3(p)),
      ]),
    );
  }
}
