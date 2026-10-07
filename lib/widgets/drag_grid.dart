import 'package:flutter/material.dart';
import '../core/ctx.dart';

/// Responsive grid whose cards can be re-ordered by drag and drop (long-press on touch).
class DragGrid extends StatelessWidget {
  final List<Widget> children;
  final List<int> order;
  final int columns;
  final double gap;
  final ValueChanged<List<int>> onReorder;
  const DragGrid({super.key, required this.children, required this.order, required this.columns, required this.onReorder, this.gap = 16});

  @override
  Widget build(BuildContext context) {
    final ord = order.length == children.length ? order : List.generate(children.length, (i) => i);
    return LayoutBuilder(builder: (_, c) {
      final w = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (var pos = 0; pos < ord.length; pos++)
          DragTarget<int>(
            onWillAcceptWithDetails: (d) => d.data != pos,
            onAcceptWithDetails: (d) {
              final next = [...ord];
              final moved = next.removeAt(d.data);
              next.insert(pos, moved);
              onReorder(next);
            },
            builder: (_, cand, __) => LongPressDraggable<int>(
              data: pos,
              delay: Duration(milliseconds: context.isMobile ? 350 : 120),
              feedback: Material(color: Colors.transparent, elevation: 8, child: SizedBox(width: w, child: Opacity(opacity: .92, child: children[ord[pos]]))),
              childWhenDragging: Opacity(opacity: .25, child: SizedBox(width: w, child: children[ord[pos]])),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: cand.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2)),
                child: children[ord[pos]],
              ),
            ),
          ),
      ]);
    });
  }
}
