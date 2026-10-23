import 'package:flutter/material.dart';

/// Observes two fingers without competing with one-finger reading gestures.
class PinchFontSize extends StatefulWidget {
  const PinchFontSize({
    super.key,
    required this.fontSize,
    required this.onChanged,
    required this.child,
  });
  final double fontSize;
  final ValueChanged<double> onChanged;
  final Widget child;

  @override
  State<PinchFontSize> createState() => _PinchFontSizeState();
}

class _PinchFontSizeState extends State<PinchFontSize> {
  final pointers = <int, Offset>{};
  double? startDistance;
  double startSize = 0;

  double get distance =>
      (pointers.values.first - pointers.values.last).distance;

  void remove(PointerEvent event) {
    pointers.remove(event.pointer);
    startDistance = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (event) {
      pointers[event.pointer] = event.position;
      if (pointers.length == 2) {
        startDistance = distance;
        startSize = widget.fontSize;
      } else {
        startDistance = null;
      }
    },
    onPointerMove: (event) {
      if (!pointers.containsKey(event.pointer)) return;
      pointers[event.pointer] = event.position;
      final initial = startDistance;
      if (pointers.length == 2 && initial != null && initial > 0) {
        widget.onChanged(startSize * distance / initial);
      }
    },
    onPointerUp: remove,
    onPointerCancel: remove,
    child: widget.child,
  );
}
