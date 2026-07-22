// =============================================================================
// lib/widgets/animated_background_painter.dart
// CPI App — Dynamic Role-Based Ambient Glass Mesh Painter
// Supports: Student (Blue), Teacher (Green), Admin (Amber/Orange)
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum UserRole { student, teacher, admin }

class AnimatedBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isLightMode;
  final UserRole role;

  const AnimatedBackgroundPainter({
    required this.animation,
    required this.isLightMode,
    this.role = UserRole.student,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    // 1. Base Foundational Background Layer
    final basePaint = Paint()
      ..color = isLightMode
          ? const Color(0xFFF8FAFC) // Crisp slate light background
          : const Color(0xFF030712); // Deep premium cyber night background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. Dynamic Palette Selection Based on User Role
    late Color primaryAccent;
    late Color secondaryAccent;
    late Color tertiaryAccent;

    switch (role) {
      case UserRole.teacher:
        // Emerald / Cyber Green (Teacher Theme)
        primaryAccent = isLightMode
            ? const Color(0xFFE6F4EA).withValues(alpha: 0.5)
            : const Color(0xFF00FF87).withValues(alpha: 0.08);
        secondaryAccent = isLightMode
            ? const Color(0xFFC8E6C9).withValues(alpha: 0.4)
            : const Color(0xFF059669).withValues(alpha: 0.06);
        tertiaryAccent = isLightMode
            ? const Color(0xFFA5D6A7).withValues(alpha: 0.3)
            : const Color(0xFF10B981).withValues(alpha: 0.03);
        break;

      case UserRole.admin:
        // Amber / Electric Sunrise Orange (Admin Theme)
        primaryAccent = isLightMode
            ? const Color(0xFFFFF3E0).withValues(alpha: 0.5)
            : const Color(0xFFFFB800).withValues(alpha: 0.08);
        secondaryAccent = isLightMode
            ? const Color(0xFFFFE0B2).withValues(alpha: 0.4)
            : const Color(0xFFD97706).withValues(alpha: 0.06);
        tertiaryAccent = isLightMode
            ? const Color(0xFFFFCC80).withValues(alpha: 0.3)
            : const Color(0xFFF59E0B).withValues(alpha: 0.03);
        break;

      case UserRole.student:
      default:
        // Electric Blue / Cyber Cyan (Student Theme)
        primaryAccent = isLightMode
            ? const Color(0xFFE0F7FA).withValues(alpha: 0.4)
            : const Color(0xFF00E5FF).withValues(alpha: 0.08);
        secondaryAccent = isLightMode
            ? const Color(0xFFEDE7F6).withValues(alpha: 0.55)
            : const Color(0xFF2563EB).withValues(alpha: 0.06);
        tertiaryAccent = isLightMode
            ? const Color(0xFFE3F2FD).withValues(alpha: 0.35)
            : const Color(0xFF3B82F6).withValues(alpha: 0.03);
        break;
    }

    // 3. Dynamic Ambient Orb 1 (Top Right Swirl)
    final double orb1X =
        size.width * 0.75 + (math.sin(t * 2 * math.pi) * size.width * 0.1);
    final double orb1Y =
        size.height * 0.2 - (math.cos(t * 2 * math.pi) * size.height * 0.08);
    final double orb1Radius = size.width * 0.65 + (math.sin(t * math.pi) * 40);

    final paint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [primaryAccent, primaryAccent.withValues(alpha: 0)],
          ).createShader(
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
      ..shader =
          RadialGradient(
            colors: [secondaryAccent, secondaryAccent.withValues(alpha: 0)],
          ).createShader(
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
      ..shader =
          RadialGradient(
            colors: [tertiaryAccent, tertiaryAccent.withValues(alpha: 0)],
          ).createShader(
            Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: orb3Radius),
          );

    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, paint3);
  }

  @override
  bool shouldRepaint(covariant AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isLightMode != isLightMode ||
        oldDelegate.role != role;
  }
}
