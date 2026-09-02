import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final Widget child;

  const LoadingScreen({super.key, required this.child});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  int _percent = 0;
  bool _isFadingOut = false;
  bool _shouldRender = true;

  late Timer _percentTimer;
  late Timer _fadeoutTimer;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();

    // 1. Book Flip Controller (1.5s loop like CSS animation)
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 2. Percentage Counter (Increments every 12ms to 100)
    _percentTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (_percent >= 100) {
        timer.cancel();
      } else {
        setState(() {
          _percent++;
        });
      }
    });

    // 3. Fade out after 1900ms and remove from widget tree 400ms later
    _fadeoutTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) {
        setState(() {
          _isFadingOut = true;
        });
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _shouldRender = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _percentTimer.cancel();
    _fadeoutTimer.cancel();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main App underlying view
        widget.child,

        // Overlay Loading View
        if (_shouldRender)
          AnimatedOpacity(
            opacity: _isFadingOut ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: Scaffold(
              backgroundColor: const Color(0xFF050505),
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top: Animated Book
                      Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withOpacity(0.3),
                              blurRadius: 35,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: List.generate(5, (index) {
                            return _AnimatedBookPage(
                              controller: _flipController,
                              delayFraction:
                                  index * 0.1, // Staggered delay matching CSS
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Middle: Brand Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFF93C5FD)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          'CPI',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -2.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Bottom: Progress Section
                      Column(
                        children: [
                          // Percentage Text
                          Text(
                            '$_percent%',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                              shadows: [
                                Shadow(
                                  color: Color(0x803B82F6),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress Bar Track & Fill
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.fastOutSlowIn,
                                    width:
                                        constraints.maxWidth * (_percent / 100),
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF3B82F6),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tagline
                          const Text(
                            'TECHNICAL EXCELLENCE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 8.0,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Sub-widget: Book Page SVG path drawing with 3D Y-Axis Flip Transform
class _AnimatedBookPage extends StatelessWidget {
  final AnimationController controller;
  final double delayFraction;

  const _AnimatedBookPage({
    required this.controller,
    required this.delayFraction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate progress with staggered delay
        double value = (controller.value - delayFraction) % 1.0;
        if (value < 0) value += 1.0;

        // Map CSS keyframe flip curve (180deg to 0deg)
        double angle = (1.0 - value) * math.pi;
        double opacity = 0.0;

        if (value < 0.2) {
          opacity = value / 0.2;
        } else if (value <= 0.5) {
          opacity = (0.5 - value) / 0.3;
        } else {
          opacity = 0.0;
        }

        return Positioned(
          top: 10,
          left: 10,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective depth
                ..rotateY(angle),
              child: CustomPaint(
                size: const Size(60, 80),
                painter: _BookSvgPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Outer SVG Path scaling
    final scaleX = size.width / 90;
    final scaleY = size.height / 120;

    final path = Path();
    path.moveTo(90 * scaleX, 0);
    path.lineTo(90 * scaleX, 120 * scaleY);
    path.lineTo(11 * scaleX, 120 * scaleY);
    path.cubicTo(
      4.92 * scaleX,
      120 * scaleY,
      0,
      115.07 * scaleY,
      0,
      109 * scaleY,
    );
    path.lineTo(0, 11 * scaleY);
    path.cubicTo(0, 4.92 * scaleY, 4.92 * scaleX, 0, 11 * scaleX, 0);
    path.close();

    // Page lines
    void addLine(double top) {
      path.addRRect(
        RRect.fromLTRBR(
          16 * scaleX,
          top * scaleY,
          74 * scaleX,
          (top + 5) * scaleY,
          const Radius.circular(2),
        ),
      );
    }

    addLine(33);
    addLine(57);
    addLine(81);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
