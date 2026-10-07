import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import 'climate_view.dart';
import 'production_page.dart';
import 'quality_view.dart';

/// "Production & Quality" dashboard: production, cup quality and climate in one place.
class ProductionHubPage extends StatelessWidget {
  const ProductionHubPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final tab = app.productionTab;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('hub_title', 'hub_sub', exportId: 'production'),
      Reveal(
        child: Segmented<String>(
          values: const ['production', 'quality', 'climate'],
          selected: tab,
          label: (v) => context.tr('hub_$v'),
          onChanged: app.setProductionTab,
        ),
      ),
      gap24,
      AnimatedSwitcher(
        duration: context.dur(300),
        child: KeyedSubtree(
          key: ValueKey(tab),
          child: tab == 'quality' ? const QualityView() : (tab == 'climate' ? const ClimateView() : const ProductionPage(showHeader: false)),
        ),
      ),
    ]);
  }
}
