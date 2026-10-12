import 'package:flutter/material.dart';
import '../core/ctx.dart';
import '../data/repository.dart';
import 'common.dart';

/// Compact selector for the member countries (25): replaces long rows of chips, readable on phones.
class CountryPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll; // adds an "All" entry (null value)
  const CountryPicker({super.key, required this.value, required this.onChanged, this.allowAll = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final list = [...repo.countries(africaOnly: true)]..sort((a, b) => context.tr(a.nameKey).compareTo(context.tr(b.nameKey)));
    return Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.isMobile ? context.w - 32 : 340),
        child: DropdownButtonFormField<String?>(
          key: ValueKey(value),
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(
            labelText: context.tr('member_country'),
            prefixIcon: const Icon(Icons.public_rounded, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            if (allowAll) DropdownMenuItem<String?>(value: null, child: Text(context.tr('cat_all'))),
            for (final c in list) DropdownMenuItem<String?>(value: c.id, child: Text('${c.flag} ${context.tr(c.nameKey)}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
      Chip2(context.tr('members_count', [list.length]), p.gold, icon: Icons.groups_rounded),
    ]);
  }
}
