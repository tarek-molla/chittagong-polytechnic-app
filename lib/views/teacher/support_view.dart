import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';

class SupportView extends StatefulWidget {
  final AppUser user;
  const SupportView({super.key, required this.user});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late AnimationController _textLoopController;
  late AnimationController _glowPulseController;
  late AnimationController _spinController;
  late AnimationController _flipAnimationController;

  late Animation<Color?> _textColorAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _flipAnimation;

  List<bool> _expandedFaqs = [];
  bool _isContactCardFlipped = false;

  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSendingFeedback = false;
  bool _isSent = false;

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I check my attendance?',
      'answer':
          'Go to Dashboard → Attendance Report to view your subject-wise attendance. You can see detailed breakdown by subject with percentages.',
      'icon': Icons.assignment_turned_in_rounded,
      'color': const Color(0xFF00E5FF),
    },
    {
      'question': 'How to download admit card?',
      'answer':
          'Go to Dashboard → Admit Card from the services menu. Your admit card will be available for download 2 weeks before exams.',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF7B61FF),
    },
    {
      'question': 'How to pay semester fees?',
      'answer':
          'Go to Dashboard → Fees from the services menu. You can view your payment history and make online payments securely.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'question': 'How to check exam results?',
      'answer':
          'Go to Dashboard → Results from the services menu. View semester-wise GPAs and subject-wise marks instantly.',
      'icon': Icons.assessment_rounded,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _expandedFaqs = List<bool>.filled(_faqItems.length, false);

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _textLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textColorAnimation =
        ColorTween(
          begin: const Color(0xFF00E5FF),
          end: const Color(0xFF7B61FF),
        ).animate(
          CurvedAnimation(parent: _textLoopController, curve: Curves.easeInOut),
        );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.linear));

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _textLoopController.dispose();
    _glowPulseController.dispose();
    _spinController.dispose();
    _flipAnimationController.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleFaqExpansion(int index) {
    setState(() {
      _expandedFaqs[index] = !_expandedFaqs[index];
    });
  }

  void _toggleContactCard() {
    setState(() {
      _isContactCardFlipped = !_isContactCardFlipped;
      if (_isContactCardFlipped) {
        _flipAnimationController.forward();
      } else {
        _flipAnimationController.reverse();
      }
    });
  }

  void _handleEmojiClick(String emoji) {
    setState(() {
      _feedbackController.text = "${_feedbackController.text} $emoji".trim();
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleFeedbackSubmit() async {
    final text = _feedbackController.text.trim();
    final userEmail = _emailController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write your message first."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    if (!_isValidEmail(userEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isSendingFeedback = true;
      _isSent = false;
    });

    try {
      // Using the exact same parameters as your web version
      final Map<String, dynamic> templateParams = {
        'message': text,
        'from_name': widget.user.name ?? 'Portal User',
        'to_email': 'tarekmolla228@gmail.com',
      };

      debugPrint('📧 Sending email with params: $templateParams');

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_25hvb3t',
          'template_id': 'template_8fx6hqv',
          'user_id': 'Bp7PNtQBBl6M1XPe-',
          'template_params': templateParams,
        }),
      );

      debugPrint('📧 Response status: ${response.statusCode}');
      debugPrint('📧 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        setState(() {
          _isSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Message sent successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _feedbackController.clear();
        _emailController.clear();
      } else {
        throw Exception('Failed to send: ${response.body}');
      }
    } catch (err) {
      debugPrint('❌ Error: $err');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${err.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AnimatedBackgroundPainter(
                animation: const AlwaysStoppedAnimation(0.5),
                isLightMode: !isDark,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Segment
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _textLoopController,
                            _glowPulseController,
                          ]),
                          builder: (context, child) {
                            final Color glowColor =
                                _textColorAnimation.value ??
                                const Color(0xFF00E5FF);
                            final double glowIntensity = _glowAnimation.value;

                            return Text(
                              "Help & Support",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Geist',
                                letterSpacing: -0.5,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightPrimaryText,
                                shadows: [
                                  Shadow(
                                    color: glowColor.withValues(
                                      alpha: 0.4 * glowIntensity,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "How can we help you today?",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.lightCaptionText,
                            fontSize: 14,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // FAQ Header Title Block
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),

                // Interactive FAQ Expansion Collection Loop
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final faq = _faqItems[index];
                      final bool isExpanded = _expandedFaqs[index];
                      final double start = (index / _faqItems.length) * 0.4;
                      final double end = start + 0.6;
                      final Animation<double> itemAnimation =
                          Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _listAnimationController,
                              curve: Interval(
                                start.clamp(0.0, 1.0),
                                end.clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          );

                      return AnimatedBuilder(
                        animation: _listAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: itemAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                (1.0 - itemAnimation.value) * 20,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: _buildInteractiveFaqCard(
                          faq,
                          isDark,
                          index,
                          isExpanded,
                        ),
                      );
                    }, childCount: _faqItems.length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Unified Premium 3D Flipping Grid Component View
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildUniverseFlipCard(isDark),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Feedback Section with Email Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeedbackSection(isDark),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFaqCard(
    Map<String, dynamic> faq,
    bool isDark,
    int index,
    bool isExpanded,
  ) {
    final Color accentColor = faq['color'] ?? const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: isExpanded ? 0.08 : 0.04)
                  : Colors.white.withValues(alpha: isExpanded ? 0.8 : 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.white.withValues(alpha: 0.4)),
                width: isExpanded ? 1.5 : 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleFaqExpansion(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(faq['icon'], color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          faq['question'],
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightPrimaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.lightCaptionText,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          faq['answer'],
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.lightCaptionText,
                            fontSize: 13,
                            fontFamily: 'Geist',
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseFlipCard(bool isDark) {
    return GestureDetector(
      onTap: _toggleContactCard,
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
                ? _buildCardFront(isDark)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildCardBack(isDark),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B1329).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _glowPulseController,
                    builder: (context, child) {
                      return Container(
                        width: 60 + (16 * _glowAnimation.value),
                        height: 60 + (16 * _glowAnimation.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              const Color(0xFF00E5FF).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                "NEED SUPPORT?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tap to view contact details",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.lightCaptionText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF00E5FF),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Flip to reveal",
                      style: TextStyle(
                        color: const Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Geist',
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

  Widget _buildCardBack(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B1329).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Color(0xFF7B61FF),
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Contact Information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 14),
              _buildContactDetailRow(
                Icons.email_rounded,
                "info@cpi.gov.bd",
                const Color(0xFF00E5FF),
                isDark,
              ),
              const SizedBox(height: 8),
              _buildContactDetailRow(
                Icons.phone_rounded,
                "+880 31 681031",
                const Color(0xFF7B61FF),
                isDark,
              ),
              const SizedBox(height: 12),
              Text(
                "Tap to flip back",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppColors.lightCaptionText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDetailRow(
    IconData icon,
    String text,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.lightBackground.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  "Contact Us",
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Geist',
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Email Input
              TextField(
                controller: _emailController,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: InputDecoration(
                  hintText: "Your email address",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00E5FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Message Input
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: InputDecoration(
                  hintText: "Write your message here...",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00E5FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildEmojiActionButton(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    color: const Color(0xFF00E5FF),
                    onTap: () => _handleEmojiClick("😊"),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildEmojiActionButton(
                    icon: Icons.sentiment_very_dissatisfied_rounded,
                    color: const Color(0xFF7B61FF),
                    onTap: () => _handleEmojiClick("🙁"),
                    isDark: isDark,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSendingFeedback
                          ? null
                          : _handleFeedbackSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSendingFeedback) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else if (_isSent) ...[
                            const Icon(Icons.check_circle_rounded, size: 14),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Icon(Icons.send_rounded, size: 14),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _isSent ? "SENT" : "SUBMIT",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Geist',
                              fontWeight: _isSent
                                  ? FontWeight.w600
                                  : FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
