/// Reference data of the platform: focal points of the member countries and the catalogue of indicators.
/// DEMO: contacts are fictitious; definitions and calculation methods describe the intended production logic.

class FocalPoint {
  final String country; // ISO-3 id of a member country
  final String name, titleKey, email, phone;
  const FocalPoint(this.country, this.name, this.titleKey, this.email, this.phone);
}

/// One national focal point per member country (fictitious people and numbers).
const focalPoints = <FocalPoint>[
  FocalPoint('AGO', 'Mateus Fernandes', 'fp_title_director', 'mateus.fernandes@fp-demo.example', '+244 923 000 101'),
  FocalPoint('BEN', 'Aïcha Dossou', 'fp_title_coord', 'aicha.dossou@fp-demo.example', '+229 97 00 01 02'),
  FocalPoint('BDI', 'Jean-Claude Niyonkuru', 'fp_title_director', 'jc.niyonkuru@fp-demo.example', '+257 79 00 01 03'),
  FocalPoint('CMR', 'Estelle Mbarga', 'fp_title_coord', 'estelle.mbarga@fp-demo.example', '+237 677 00 01 04'),
  FocalPoint('CAF', 'Désiré Ngaïkosset', 'fp_title_officer', 'desire.ngaikosset@fp-demo.example', '+236 72 00 01 05'),
  FocalPoint('COG', 'Prisca Mabiala', 'fp_title_officer', 'prisca.mabiala@fp-demo.example', '+242 06 000 01 06'),
  FocalPoint('COD', 'Patient Kabasele', 'fp_title_coord', 'patient.kabasele@fp-demo.example', '+243 81 000 01 07'),
  FocalPoint('CIV', 'Awa Koné', 'fp_title_director', 'awa.kone@fp-demo.example', '+225 07 00 01 08 09'),
  FocalPoint('ETH', 'Selamawit Bekele', 'fp_title_director', 'selamawit.bekele@fp-demo.example', '+251 91 000 0109'),
  FocalPoint('GAB', 'Hugues Obame', 'fp_title_officer', 'hugues.obame@fp-demo.example', '+241 06 00 01 10'),
  FocalPoint('GHA', 'Kwame Mensah', 'fp_title_coord', 'kwame.mensah@fp-demo.example', '+233 24 000 0111'),
  FocalPoint('GIN', 'Mariama Camara', 'fp_title_coord', 'mariama.camara@fp-demo.example', '+224 622 00 01 12'),
  FocalPoint('GNQ', 'Santiago Nsue', 'fp_title_officer', 'santiago.nsue@fp-demo.example', '+240 222 00 0113'),
  FocalPoint('KEN', 'Wanjiru Kamau', 'fp_title_director', 'wanjiru.kamau@fp-demo.example', '+254 712 000 114'),
  FocalPoint('LBR', 'Comfort Weah', 'fp_title_officer', 'comfort.weah@fp-demo.example', '+231 77 000 0115'),
  FocalPoint('MDG', 'Hery Rakotoarisoa', 'fp_title_coord', 'hery.rakotoarisoa@fp-demo.example', '+261 34 00 011 16'),
  FocalPoint('MWI', 'Chikondi Banda', 'fp_title_officer', 'chikondi.banda@fp-demo.example', '+265 99 000 0117'),
  FocalPoint('NGA', 'Chinedu Okafor', 'fp_title_coord', 'chinedu.okafor@fp-demo.example', '+234 803 000 0118'),
  FocalPoint('UGA', 'Grace Namukasa', 'fp_title_director', 'grace.namukasa@fp-demo.example', '+256 772 000 119'),
  FocalPoint('RWA', 'Eric Habimana', 'fp_title_director', 'eric.habimana@fp-demo.example', '+250 788 000 120'),
  FocalPoint('SLE', 'Fatmata Kamara', 'fp_title_officer', 'fatmata.kamara@fp-demo.example', '+232 76 000 121'),
  FocalPoint('TZA', 'Neema Mwakyusa', 'fp_title_director', 'neema.mwakyusa@fp-demo.example', '+255 754 000 122'),
  FocalPoint('TGO', 'Koffi Agbodjan', 'fp_title_coord', 'koffi.agbodjan@fp-demo.example', '+228 90 00 01 23'),
  FocalPoint('ZMB', 'Mutale Chanda', 'fp_title_officer', 'mutale.chanda@fp-demo.example', '+260 97 000 0124'),
  FocalPoint('ZWE', 'Tendai Moyo', 'fp_title_officer', 'tendai.moyo@fp-demo.example', '+263 77 000 0125'),
];

/// An indicator of the platform. Texts live in the translation table under `ix_<id>_n` (name),
/// `ix_<id>_d` (definition) and `ix_<id>_m` (calculation method).
class IndicatorDef {
  final String id, unit, sourceId, freqKey, theme; // theme: market | production | income | sustain | quality | chain
  final bool partner; // shown with the "partners" tag (private spaces)
  const IndicatorDef(this.id, this.theme, this.unit, this.sourceId, this.freqKey, {this.partner = false});
  String get nameKey => 'ix_${id}_n';
  String get defKey => 'ix_${id}_d';
  String get methodKey => 'ix_${id}_m';
}

const indicatorThemes = ['market', 'production', 'income', 'sustain', 'quality', 'chain'];

const indicatorCatalogue = <IndicatorDef>[
  IndicatorDef('price_arabica', 'market', r'$/lb', 'markets', 'f_30min'),
  IndicatorDef('price_robusta', 'market', r'$/lb', 'markets', 'f_30min'),
  IndicatorDef('spread', 'market', r'$/lb', 'markets', 'f_30min'),
  IndicatorDef('volatility', 'market', '%', 'markets', 'f_30min'),
  IndicatorDef('differential', 'market', 'c/lb', 'markets', 'f_monthly'),
  IndicatorDef('exports', 'market', 'kt', 'customs', 'f_monthly'),
  IndicatorDef('prod', 'production', 'kt', 'production', 'f_monthly'),
  IndicatorDef('yield', 'production', 'kg/ha', 'production', 'f_monthly'),
  IndicatorDef('area', 'production', 'kha', 'production', 'f_yearly'),
  IndicatorDef('producers', 'production', 'k', 'coops', 'f_variable'),
  IndicatorDef('climate', 'production', '/100', 'weather', 'f_1h'),
  IndicatorDef('income', 'income', r'$/an', 'survey', 'f_yearly', partner: true),
  IndicatorDef('cost', 'income', r'$/kg', 'survey', 'f_yearly', partner: true),
  IndicatorDef('margin', 'income', r'$/kg', 'survey', 'f_yearly', partner: true),
  IndicatorDef('cert', 'sustain', '%', 'certs', 'f_quarterly'),
  IndicatorDef('sustain', 'sustain', '/100', 'certs', 'f_quarterly'),
  IndicatorDef('governance', 'sustain', '/100', 'certs', 'f_quarterly'),
  IndicatorDef('deforest', 'sustain', '/100', 'satellite', 'f_weekly'),
  IndicatorDef('quality', 'quality', '/100', 'coops', 'f_variable', partner: true),
  IndicatorDef('stock', 'chain', 'kt', 'ports', 'f_daily', partner: true),
  IndicatorDef('transit', 'chain', 'kt', 'ports', 'f_daily', partner: true),
  IndicatorDef('transport', 'chain', r'$/t', 'ports', 'f_daily', partner: true),
  IndicatorDef('delay', 'chain', 'jours', 'ports', 'f_daily', partner: true),
];
