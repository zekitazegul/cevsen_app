import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ScrollContinuation extends StatefulWidget {
  const ScrollContinuation({
    super.key,
    required this.builder,
    this.readingProgress,
  });
  final Widget Function(ScrollController) builder;
  final double? readingProgress;
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
  void didUpdateWidget(covariant ScrollContinuation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readingProgress != oldWidget.readingProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => followReading());
    }
  }

  void followReading() {
    final progress = widget.readingProgress;
    if (!mounted || progress == null || !controller.hasClients) return;
    final position = controller.position;
    if (position.maxScrollExtent <= 0) return;
    // Keep the estimated reading location above the lower edge of the page.
    final target =
        (progress * (position.maxScrollExtent + position.viewportDimension) -
                position.viewportDimension * .65)
            .clamp(0.0, position.maxScrollExtent);
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.linear,
    );
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            check();
            followReading();
          });
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
