import 'dart:math' as math;
import 'package:flutter/material.dart';

class CloudLoader extends StatefulWidget {
  const CloudLoader({super.key});

  @override
  State<CloudLoader> createState() => _CloudLoaderState();
}

class _CloudLoaderState extends State<CloudLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Subtle organic scale breathing effect (cycles from 0.96 to 1.04)
        double breatheScale =
            1.0 + (math.sin(_controller.value * math.pi * 2) * 0.04);

        return Transform.scale(
          scale: breatheScale,
          child: SizedBox(
            width: 55, // Downsized for a modern, compact profile
            height: 55,
            child: CustomPaint(
              painter: _CloudLoaderPainter(
                animationValue: _controller.value,
                cloudColor: const Color(0xFF4387F4),
                arrowsColor: const Color(0xFF80B1FF),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CloudLoaderPainter extends CustomPainter {
  final double animationValue;
  final Color cloudColor;
  final Color arrowsColor;

  _CloudLoaderPainter({
    required this.animationValue,
    required this.cloudColor,
    required this.arrowsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Build Vector Cloud Path Geometric Mask
    final Path cloudPath = Path();
    cloudPath.addPolygon([
      Offset(w * 0.50, h * 0.35),
      Offset(w * 0.82, h * 0.75),
      Offset(w * 0.18, h * 0.75),
    ], true);
    cloudPath.addOval(
      Rect.fromCircle(center: Offset(w * 0.18, h * 0.58), radius: w * 0.16),
    );
    cloudPath.addOval(
      Rect.fromCircle(center: Offset(w * 0.82, h * 0.58), radius: w * 0.16),
    );

    // Secondary soft dynamic arches
    double waveOffset = math.sin(animationValue * math.pi * 2);
    cloudPath.addOval(
      Rect.fromCircle(
        center: Offset(
          w * 0.36 + (waveOffset * 1),
          h * 0.48 + (waveOffset * 1),
        ),
        radius: w * 0.18,
      ),
    );
    cloudPath.addOval(
      Rect.fromCircle(center: Offset(w * 0.58, h * 0.44), radius: w * 0.20),
    );

    canvas.save();
    canvas.clipPath(cloudPath);

    // 2. Base Solid Fill
    final Paint bgPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 3. Dynamic Streaming Diagonals Layer (Fades softly across cycles)
    double linesAlpha =
        0.12 + (math.sin(animationValue * math.pi * 2).abs() * 0.10);
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: linesAlpha)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double lineScroll = (animationValue * 14) % 14;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-65 * math.pi / 180);
    canvas.translate(-w * 0.5, -h * 0.5);

    for (double y = -h * 0.5; y < h * 1.5; y += 11) {
      double currentY = y + lineScroll;
      canvas.drawLine(
        Offset(-w * 0.5, currentY),
        Offset(w * 1.5, currentY),
        linePaint,
      );
    }
    canvas.restore();
    canvas.restore();

    // 4. Smooth Rotation Sync Arrows
    final double centerX = w * 0.50;
    final double centerY = h * 0.64;
    final double radius = w * 0.18;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(animationValue * math.pi * 2);

    final Paint arrowPaint = Paint()
      ..color = arrowsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Top loop branch
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -math.pi * 0.75,
      math.pi * 0.65,
      false,
      arrowPaint,
    );

    final Path head1 = Path();
    head1.moveTo(radius - 4, -2);
    head1.lineTo(radius, 2);
    head1.lineTo(radius + 4, -2);
    canvas.drawPath(
      head1,
      Paint()
        ..color = arrowsColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Bottom loop branch
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      math.pi * 0.25,
      math.pi * 0.65,
      false,
      arrowPaint,
    );

    final Path head2 = Path();
    head2.moveTo(-radius - 4, 2);
    head2.lineTo(-radius, -2);
    head2.lineTo(-radius + 4, 2);
    canvas.drawPath(
      head2,
      Paint()
        ..color = arrowsColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CloudLoaderPainter oldDelegate) => true;
}
