import 'package:flutter/material.dart';

class SplashController {
  final TickerProvider vsync;

  late AnimationController controller;

  late Animation<double> calendarFade;
  late Animation<double> tickScale;
  late Animation<Offset> textSlide;
  late Animation<double> taglineFade;

  SplashController(this.vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 5),
    );

    // Calendar fade
    calendarFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Tick scale
    tickScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.25, 0.45, curve: Curves.elasticOut),
      ),
    );

    //  Text slide
    textSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    // Tagline fade
    taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void start() {
    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }
}