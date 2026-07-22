import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/router.dart';

// --- WELCOME SCREEN VIEW ---
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // Dark glassmorphic base
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 35),

            // Web-Synced High-Contrast Aggressive Header Block
            const _SweepingWebHeader(),

            const SizedBox(height: 25),

            // Asymmetric High-Fidelity Capsule Grid Deck Layout
            const Expanded(child: CpiCapsuleGridDeck()),

            const SizedBox(height: 25),

            // Premium Web Blue Session Trigger Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006BB3).withAlpha(140),
                      blurRadius: 25,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006BB3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: Colors.white.withAlpha(50),
                        width: 1.2,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Start Session",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// --- FIXED PERFECTLY LOOPING TEXT GRADIENT ---
class _SweepingWebHeader extends StatefulWidget {
  const _SweepingWebHeader();

  @override
  State<_SweepingWebHeader> createState() => _SweepingWebHeaderState();
}

class _SweepingWebHeaderState extends State<_SweepingWebHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _gradientShift;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _gradientShift = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _sweepController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                'assets/cpi_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.school_rounded,
                  size: 32,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _gradientShift,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: const [
                        Color(0xFF3B82F6),
                        Color(0xFF67E8F9),
                        Colors.white,
                        Color(0xFF67E8F9),
                        Color(0xFF3B82F6),
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: _ExtendedGradientTransform(
                        value: _gradientShift.value,
                      ),
                    ).createShader(bounds);
                  },
                  child: const Text(
                    "CPI Portal",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Geist',
                      letterSpacing: -1.5,
                      height: 0.95,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "EST. 1962 • TECHNICAL EXCELLENCE",
          style: TextStyle(
            color: const Color(0xFF67E8F9),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            fontFamily: 'Geist',
            shadows: [
              Shadow(
                color: const Color(0xFF3B82F6).withAlpha(180),
                blurRadius: 10,
              ),
              Shadow(
                color: const Color(0xFF67E8F9).withAlpha(100),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExtendedGradientTransform extends GradientTransform {
  final double value;
  const _ExtendedGradientTransform({required this.value});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    double slidingOffset = bounds.width * (value * 3.0 - 1.5);
    return Matrix4.translationValues(slidingOffset, 0.0, 0.0);
  }
}

// --- RANDOMIZED GRID MATRIX DECK CONTROLLER ---
class CpiCapsuleGridDeck extends StatelessWidget {
  const CpiCapsuleGridDeck({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TrackScroller(
          scrollForward: true,
          images: [1, 2, 3],
          pacingSpeed: 0.40,
          rowSeed: 12,
        ),
        _TrackScroller(
          scrollForward: false,
          images: [4, 5, 6],
          pacingSpeed: 0.50,
          rowSeed: 45,
        ),
        _TrackScroller(
          scrollForward: true,
          images: [7, 8, 9],
          pacingSpeed: 0.35,
          rowSeed: 78,
        ),
        _TrackScroller(
          scrollForward: false,
          images: [10, 1, 2],
          pacingSpeed: 0.55,
          rowSeed: 23,
        ),
        _TrackScroller(
          scrollForward: true,
          images: [3, 4, 5],
          pacingSpeed: 0.45,
          rowSeed: 91,
        ),
      ],
    );
  }
}

// --- NATIVE SYSTEM TIMER AUTO-SCROLLER TRACK ---
class _TrackScroller extends StatefulWidget {
  final bool scrollForward;
  final List<int> images;
  final double pacingSpeed;
  final int rowSeed;

  const _TrackScroller({
    required this.scrollForward,
    required this.images,
    required this.pacingSpeed,
    required this.rowSeed,
  });

  @override
  State<_TrackScroller> createState() => _TrackScrollerState();
}

class _TrackScrollerState extends State<_TrackScroller> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 6000.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        if (_scrollController.hasClients) {
          double currentScroll = _scrollController.offset;
          double nextPosition = widget.scrollForward
              ? currentScroll + widget.pacingSpeed
              : currentScroll - widget.pacingSpeed;
          _scrollController.jumpTo(nextPosition);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _getImageAssetPath(int index) {
    if (index <= 1) return 'assets/cpi_bg.png';
    return 'assets/cpi_bg$index.png';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.builder(
        // ✅ FIX: Changed from ScrollCacheExtent.pixels(1500.0) to raw double value
        cacheExtent: 1500.0,
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20000,
        itemBuilder: (context, index) {
          int localizedPattern = (index + widget.rowSeed) % 7;

          if (localizedPattern == 1) {
            int imageKey = widget.images[index % widget.images.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    _getImageAssetPath(imageKey),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: const Color(0xFF0F172A)),
                  ),
                ),
              ),
            );
          } else if (localizedPattern == 4) {
            int imageKey = widget.images[(index + 1) % widget.images.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 125,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withAlpha(25),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    _getImageAssetPath(imageKey),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: const Color(0xFF0F172A)),
                  ),
                ),
              ),
            );
          } else if (localizedPattern == 3) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: const Color(0xFF67E8F9).withAlpha(40),
                  border: Border.all(
                    color: const Color(0xFF67E8F9).withAlpha(140),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF67E8F9).withAlpha(50),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          } else if (localizedPattern == 5) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 75,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withAlpha(25),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.blur_on_rounded,
                    size: 14,
                    color: Colors.white30,
                  ),
                ),
              ),
            );
          } else if (localizedPattern == 0) {
            int imageKey = widget.images[(index + 2) % widget.images.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    _getImageAssetPath(imageKey),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: const Color(0xFF0F172A)),
                  ),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: const Color(0xFF0F172A).withAlpha(150),
                  border: Border.all(
                    color: Colors.white.withAlpha(15),
                    width: 1,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
