import 'package:flutter/material.dart';

/// Three quick successive taps open the (hidden) admin login.
class SecretTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTriple;
  final int taps;
  const SecretTap({super.key, required this.child, required this.onTriple, this.taps = 3});
  @override
  State<SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<SecretTap> {
  int _n = 0;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  void _tap() {
    final now = DateTime.now();
    _n = now.difference(_last) < const Duration(milliseconds: 900) ? _n + 1 : 1;
    _last = now;
    if (_n >= widget.taps) {
      _n = 0;
      widget.onTriple();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, child: widget.child);
}
