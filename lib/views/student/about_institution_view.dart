import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';

class AboutInstitutionView extends StatefulWidget {
  final AppUser user;

  const AboutInstitutionView({super.key, required this.user});

  @override
  State<AboutInstitutionView> createState() => _AboutInstitutionViewState();
}

class _AboutInstitutionViewState extends State<AboutInstitutionView>
    with TickerProviderStateMixin {
  Color _primaryText = Colors.white;
  Color _secondaryText = Colors.white60;

  late YoutubePlayerController _youtubeController;
  late AnimationController _flipAnimationController;
  late AnimationController _bgAnimationController;
  late Animation<double> _flipAnimation;
  bool _isSupportCardFlipped = false;

  final String _mapUrlString =
      "https://www.google.com/maps/place/Chattogram+Polytechnic+Institute/@22.369136,91.810557,1322m/data=!3m2!1e3!5s0x30acd8f525a6c075:0xab1700faa971f56e!4m6!3m5!1s0x30acd8f5243a983d:0x867de1c2f217eeb!8m2!3d22.3693276!4d91.8115314!16s%2Fm%2F0vpqq14?hl=en&entry=ttu&g_ep=EgoyMDI2MDcxNS4wIKXMDSoASAFQAw%3D%3D";

  @override
  void initState() {
    super.initState();

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: 'CD3lTqr0sys',
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
      ),
    );

    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _youtubeController.close();
    _flipAnimationController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _toggleSupportCard() {
    setState(() {
      _isSupportCardFlipped = !_isSupportCardFlipped;
      if (_isSupportCardFlipped) {
        _flipAnimationController.forward();
      } else {
        _flipAnimationController.reverse();
      }
    });
  }

  Future<void> _launchMapsUrl() async {
    final Uri url = Uri.parse(_mapUrlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not launch maps location destination pointer.",
            ),
          ),
        );
      }
    }
  }

  Widget _buildAnimatedBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: CustomPaint(
        painter: AnimatedBackgroundPainter(
          animation: _bgAnimationController,
          isLightMode: !isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    _secondaryText = isDark ? Colors.white60 : const Color(0xFF475569);

    return YoutubePlayerScaffold(
      controller: _youtubeController,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: _primaryText,
                                size: 18,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: player,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "CPI CAMPUS",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                                letterSpacing: -1.0,
                                color: _primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "TECHNICAL EXCELLENCE SINCE 1962",
                              style: TextStyle(
                                color: const Color(0xFF3B82F6),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                              Icons.school_rounded,
                              "CAMPUS LIFE",
                              _primaryText,
                            ),
                            const SizedBox(height: 12),
                            _buildSectionLabel(
                              Icons.map_rounded,
                              "FIND US",
                              _primaryText,
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: _launchMapsUrl,
                              borderRadius: BorderRadius.circular(20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.03)
                                          : Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: -20,
                                          bottom: -20,
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            size: 140,
                                            color: const Color(
                                              0xFF0EA5E9,
                                            ).withOpacity(0.05),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Chattogram Polytechnic Institute Campus Map",
                                                style: TextStyle(
                                                  fontFamily: 'Geist',
                                                  color: _primaryText,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.map_rounded,
                                                    color: Color(0xFF0EA5E9),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Open in Maps Location System",
                                                    style: TextStyle(
                                                      fontFamily: 'Geist',
                                                      color: _secondaryText,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildPhilosophyBlock(
                                    icon: Icons.track_changes_rounded,
                                    title: "OUR MISSION",
                                    desc:
                                        "EMPOWERING STUDENTS WITH TECHNICAL MASTERY TO LEAD THE INDUSTRIAL FUTURE.",
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildPhilosophyBlock(
                                    icon: Icons.remove_red_eye_rounded,
                                    title: "OUR VISION",
                                    desc:
                                        "TO BE THE PREMIER ENGINEERING HUB FOR INNOVATION AND EXCELLENCE.",
                                    color: const Color(0xFFA855F7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            _buildInteractiveSupportFlipCard(),

                            const SizedBox(height: 48),
                            Divider(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06),
                              height: 1,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "© 2026 CPI CAMPUS DESIGN",
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: _secondaryText,
                                  ),
                                ),
                                Icon(
                                  Icons.terminal_rounded,
                                  size: 14,
                                  color: _secondaryText,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(IconData icon, String label, Color primaryText) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPhilosophyBlock({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 10,
            height: 1.5,
            fontWeight: FontWeight.bold,
            color: _secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveSupportFlipCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.7);

    return GestureDetector(
      onTap: _toggleSupportCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final transformValue = _flipAnimation.value * math.pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(transformValue),
            alignment: Alignment.center,
            child: transformValue < math.pi / 2
                ? _buildFlipFront(cardColor)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildFlipBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFlipFront(Color cardColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.coffee_rounded,
                color: Color(0xFFFFDD00),
                size: 32,
              ),
              const SizedBox(height: 10),
              const Text(
                "SUPPORT THE DEV",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap to reveal channels",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipBack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0891B2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Column(
            children: [
              Text(
                "BKASH / NAGAD",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "01629648980",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}