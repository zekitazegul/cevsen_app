import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ScrollContinuation extends StatefulWidget {
  const ScrollContinuation({super.key, required this.builder});
  final Widget Function(ScrollController) builder;
  @override
  State<ScrollContinuation> createState() => _ScrollContinuationState();
}

class _ScrollContinuationState extends State<ScrollContinuation> {
  final controller = ScrollController();
  bool remaining = false;
  @override
  void initState() {
    super.initState();
    controller.addListener(check);
  }

  void check() {
    if (!mounted || !controller.hasClients) return;
    final next = controller.position.extentAfter > 3;
    if (next != remaining) setState(() => remaining = next);
  }

  @override
  void dispose() {
    controller.removeListener(check);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) => check());
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(child: widget.builder(controller)),
            if (remaining)
              Positioned(
                left: 1,
                right: 1,
                bottom: 0,
                height: 32,
                child: IgnorePointer(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: const DecoratedBox(
                        key: ValueKey('continuation-mist'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00f3e8d1), Color(0xc0f3e8d1)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
