import 'package:flutter/material.dart';

/// A reusable widget that renders a consistent deep-purple-to-indigo gradient
/// as the full-screen background of any ZenMind screen.
class GradientBackground extends StatelessWidget {
  /// The child widget displayed on top of the gradient.
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0533), // deep dark purple
            Color(0xFF2D0B60), // mid purple
            Color(0xFF0D1B6E), // indigo
            Color(0xFF1A2580), // lighter indigo
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: child,
    );
  }
}
