import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/layout.dart';
import '../shell/top_controls.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    Widget row(IconData i, String t, String d, Widget trailing) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(i, color: p.accent),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(t), style: TS.h3(p)), const SizedBox(height: 2), Text(context.tr(d), style: TS.bodyS(p))])),
            trailing,
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('settings_title', 'settings_sub'),
      GlassCard(
        child: Column(children: [
          row(Icons.translate_rounded, 'set_language', 'set_language_d', const LangToggle()),
          const Divider(),
          row(Icons.currency_exchange_rounded, 'set_currency', 'set_currency_d', const CurrencyPicker()),
          const Divider(),
          row(Icons.dark_mode_rounded, 'set_theme', 'set_theme_d', const ThemeToggle()),
          const Divider(),
          row(Icons.animation_rounded, 'reduce_motion', 'reduce_motion_d', Switch(value: app.reduceMotion, onChanged: app.setReduce)),
          const Divider(),
          row(Icons.slideshow_rounded, 'presentation_mode', 'set_presentation_d', PrimaryButton(context.tr('start'), onTap: () => app.setPresentation(true), outlined: true)),
          const Divider(),
          row(Icons.local_florist_rounded, 'intro', 'set_intro_d', PrimaryButton(context.tr('open'), onTap: app.openLanding, outlined: true)),
        ]),
      ),
      gap24,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('photo_credits')),
          Text(context.tr('photo_credits_note'), style: TS.bodyS(p)),
          const SizedBox(height: 10),
          FutureBuilder<String>(
            future: rootBundle.loadString('assets/CREDITS.json'),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox();
              final m = jsonDecode(snap.data!) as Map<String, dynamic>;
              return Column(children: [
                for (final e in m.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Expanded(child: Text('${e['title']} — ${e['artist']}', style: TS.bodyS(p).copyWith(fontSize: 11.5), overflow: TextOverflow.ellipsis)),
                      Text(e['license'] as String, style: TS.bodyS(p).copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]);
            },
          ),
        ]),
      ),
      gap24,
      GlassCard(
        accent: p.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(context.tr('about_demo')),
          Text(context.tr('about_demo_text'), style: TextStyle(color: p.text, height: 1.55, fontSize: 14)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip2('Flutter · Web · Android · iOS', p.green),
            Chip2(context.tr('no_backend'), p.accent),
            Chip2(context.tr('replaceable_data'), p.gold),
          ]),
          const SizedBox(height: 16),
          Text(context.tr('future_arch').toUpperCase(), style: TS.label(p)),
          const SizedBox(height: 8),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 6, children: [
            for (final (i, s) in ['Flutter', 'API', context.tr('arch_server'), context.tr('arch_db'), context.tr('arch_collect'), context.tr('arch_sources')].indexed) ...[
              if (i > 0) Icon(Icons.arrow_forward_rounded, size: 14, color: p.muted),
              Chip2(s, p.muted),
            ],
          ]),
        ]),
      ),
    ]);
  }
}
