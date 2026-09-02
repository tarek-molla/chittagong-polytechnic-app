import 'dart:async';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const LoadingScreen({super.key, required this.onComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  int _percent = 0;
  bool _isFadingOut = false;
  late Timer _percentTimer;
  late Timer _fadeTimer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _percentTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (_percent >= 100) {
        timer.cancel();
      } else {
        setState(() {
          _percent++;
        });
      }
    });

    _fadeTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) {
        setState(() => _isFadingOut = true);
        Timer(const Duration(milliseconds: 400), () {
          widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _percentTimer.cancel();
    _fadeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isFadingOut ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        color: const Color(0xFF050505),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loader Icon (Animated Book)
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withOpacity(0.3),
                      blurRadius: 35,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Center(
                    child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
                ),
              ),

              // Brand Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFF93C5FD)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  "CPI",
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
              ),

              // Progress Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                child: Column(
                  children: [
                    Text(
                      "$_percent%",
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _percent / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            boxShadow: [BoxShadow(color: const Color(0xFF3B82F6), blurRadius: 15)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TECHNICAL EXCELLENCE",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 8,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
