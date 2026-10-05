import 'package:flutter/material.dart';
import '../core/ctx.dart';

/// Two columns on wide screens, stacked on small ones.
class TwoCol extends StatelessWidget {
  final Widget left, right;
  final int flexL, flexR;
  final double gap;
  final bool stretch;
  const TwoCol({super.key, required this.left, required this.right, this.flexL = 1, this.flexR = 1, this.gap = 16, this.stretch = true});
  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return Column(children: [left, SizedBox(height: gap), right]);
    }
    final row = Row(crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start, children: [
      Expanded(flex: flexL, child: left),
      SizedBox(width: gap),
      Expanded(flex: flexR, child: right),
    ]);
    return stretch ? IntrinsicHeight(child: row) : row;
  }
}

const gap16 = SizedBox(height: 16);
const gap24 = SizedBox(height: 24);
