import 'package:flutter/material.dart';

/// Custom page route with slide + fade transition.
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideFadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final slideAnim = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curvedAnim);

          final fadeAnim = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnim);

          return SlideTransition(
            position: slideAnim,
            child: FadeTransition(opacity: fadeAnim, child: child),
          );
        },
      );
}

/// Slide-up from bottom transition (for modals, sheets).
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(curvedAnim),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim),
              child: child,
            ),
          );
        },
      );
}
