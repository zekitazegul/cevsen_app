import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Leaves diagonal reading gestures to the vertical scroll view.
class PageSwipe extends StatelessWidget {
  const PageSwipe({
    super.key,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.child,
  });

  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final GestureDragCancelCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _PageDragRecognizer:
          GestureRecognizerFactoryWithHandlers<_PageDragRecognizer>(
            () => _PageDragRecognizer(),
            (recognizer) => recognizer
              ..onStart = onStart
              ..onUpdate = onUpdate
              ..onEnd = onEnd
              ..onCancel = onCancel,
          ),
    },
    child: child,
  );
}

class _PageDragRecognizer extends HorizontalDragGestureRecognizer {
  Offset _movement = Offset.zero;
  int? _pointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) {
      resolve(GestureDisposition.rejected);
      return;
    }
    _pointer = event.pointer;
    _movement = Offset.zero;
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _movement += event.delta;
    if (event is PointerPanZoomUpdateEvent) _movement += event.panDelta;
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) =>
      _movement.dx.abs() > _movement.dy.abs() * 1.75 &&
      super.hasSufficientGlobalDistanceToAccept(
        pointerDeviceKind,
        deviceTouchSlop,
      );
}
