import '../../models/models.dart';

/// Coffee journey, producer → roaster. Volumes in kt for the demo African basket.
const demoChain = <ChainStep>[
  ChainStep('producer', 1062, 0, 0, ['actors_producer'], 'loc_highlands', 34),
  ChainStep('coop', 842, 3, 0, ['actors_coop'], 'loc_washing', 29),
  ChainStep('collect', 790, 4, 1, ['actors_collect'], 'loc_roads', 52),
  ChainStep('process', 760, 9, 0, ['actors_process'], 'loc_mills', 38),
  ChainStep('export', 731, 6, 1, ['actors_export'], 'loc_capitals', 41),
  ChainStep('port', 725, 5, 2, ['actors_port'], 'loc_ports', 63),
  ChainStep('transport', 721, 24, 1, ['actors_transport'], 'loc_sea', 48),
  ChainStep('buyer', 700, 8, 0, ['actors_buyer'], 'loc_markets', 35),
  ChainStep('roaster', 665, 12, 0, ['actors_roaster'], 'loc_roasters', 27),
];
