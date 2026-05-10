// lib/core/router/slide_transition_page.dart
// Custom GoRouter page with directional slide animation.
// Forward = new screen slides in from right.
// Back    = new screen slides in from left.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/nav_direction.dart';

/// Creates a [CustomTransitionPage] with a horizontal slide + fade.
/// Reads [currentNavDirection] and resets it to forward after use.
CustomTransitionPage<void> slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Capture direction at build time
      final isBack = currentNavDirection == NavDirection.back;
      // Reset for next navigation
      currentNavDirection = NavDirection.forward;

      final beginOffset = isBack
          ? const Offset(-0.25, 0)  // slide from left
          : const Offset(0.25, 0);  // slide from right

      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ));

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}
