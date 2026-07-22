import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isLightMode;

  const AnimatedBackgroundPainter({
    required this.animation,
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    // 1. Draw the base foundational layer color
    final basePaint = Paint()
      ..color = isLightMode
          ? const Color(0xFFF8FAFC) // Crisp slate light background
          : const Color(0xFF030712); // Deep premium cyber night background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. Define High-End Vibe Color Palettes
    // Light Mode: Dreamy, soft, elite translucent pastels
    // Dark Mode: Pure high-contrast cyber-glow accents (Cyan and Hyper-Purple)
    final Color color1 = isLightMode
        ? const Color(0xFFE0F7FA).withValues(alpha: 0.4) // Ethereal Soft Cyan
        : const Color(0xFF00E5FF).withValues(alpha: 0.08); // Neon Cyan Gas

    final Color color2 = isLightMode
        ? const Color(0xFFEDE7F6).withValues(
            alpha: 0.55,
          ) // Ethereal Soft Lavender
        : const Color(
            0xFF7B61FF,
          ).withValues(alpha: 0.06); // Deep Electric Purple

    final Color color3 = isLightMode
        ? const Color(0xFFFFF3E0).withValues(
            alpha: 0.35,
          ) // Soft warm sunrise tone
        : const Color(
            0xFF00E5FF,
          ).withValues(alpha: 0.03); // Subtle secondary ambient fill

    // 3. Dynamic Ambient Orb 1 (Top Right Swirl)
    final double orb1X =
        size.width * 0.75 + (math.sin(t * 2 * math.pi) * size.width * 0.1);
    final double orb1Y =
        size.height * 0.2 - (math.cos(t * 2 * math.pi) * size.height * 0.08);
    final double orb1Radius = size.width * 0.65 + (math.sin(t * math.pi) * 40);

    final paint1 = Paint()
      ..shader = RadialGradient(colors: [color1, color1.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: orb1Radius),
          );

    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, paint1);

    // 4. Dynamic Ambient Orb 2 (Bottom Left Swirl)
    final double orb2X =
        size.width * 0.20 - (math.cos(t * 2 * math.pi) * size.width * 0.08);
    final double orb2Y =
        size.height * 0.75 + (math.sin(t * 2 * math.pi) * size.height * 0.1);
    final double orb2Radius = size.width * 0.7 + (math.cos(t * math.pi) * 30);

    final paint2 = Paint()
      ..shader = RadialGradient(colors: [color2, color2.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: orb2Radius),
          );

    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, paint2);

    // 5. Dynamic Center Ambient Drift Orb
    final double orb3X =
        size.width * 0.5 + (math.sin(t * 2 * math.pi) * size.width * 0.05);
    final double orb3Y =
        size.height * 0.45 + (math.cos(t * 2 * math.pi) * size.height * 0.05);
    final double orb3Radius = size.width * 0.5;

    final paint3 = Paint()
      ..shader = RadialGradient(colors: [color3, color3.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: orb3Radius),
          );

    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, paint3);
  }

  @override
  bool shouldRepaint(covariant AnimatedBackgroundPainter oldDelegate) {
    // Repaints on every value emission for silky-smooth 60fps/120fps background shifting
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isLightMode != isLightMode;
  }
}
