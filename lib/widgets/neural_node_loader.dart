import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeuralNodeLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const NeuralNodeLoader({super.key, this.size = 50.0, this.color});

  @override
  State<NeuralNodeLoader> createState() => _NeuralNodeLoaderState();
}

class _NeuralNodeLoaderState extends State<NeuralNodeLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _pulseController]),
          builder: (context, child) {
            return CustomPaint(
              painter: _NeuralNodePainter(
                rotation: _rotationController.value * 2 * math.pi,
                pulse: _pulseController.value,
                color: themeColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NeuralNodePainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color color;

  _NeuralNodePainter({
    required this.rotation,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Draw central glowing microprocessor core
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.2 + (pulse * 0.3))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.25, corePaint);

    final coreSolidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.12, coreSolidPaint);

    // 2. Draw outer orbiting data nodes
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const int nodeCount = 4;
    for (int i = 0; i < nodeCount; i++) {
      // Offset individual angles slightly to distribute nodes
      final double angle = rotation + (i * (2 * math.pi / nodeCount));

      // Dynamic orbital distance based on pulse speed
      final double orbitalRadius = maxRadius * (0.6 + (pulse * 0.18));

      final double nodeX = center.dx + orbitalRadius * math.cos(angle);
      final double nodeY = center.dy + orbitalRadius * math.sin(angle);
      final Offset nodeOffset = Offset(nodeX, nodeY);

      // Draw connection bus line to core
      canvas.drawLine(center, nodeOffset, linePaint);

      // Draw orbital satellite node with sizing pulse alternation
      final double dynamicNodeRadius =
          maxRadius * (0.07 + ((i % 2 == 0 ? pulse : 1.0 - pulse) * 0.05));
      canvas.drawCircle(nodeOffset, dynamicNodeRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralNodePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.color != color;
  }
}
