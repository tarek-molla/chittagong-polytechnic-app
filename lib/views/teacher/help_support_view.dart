import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';

class HelpSupportView extends StatefulWidget {
  final AppUser user;
  const HelpSupportView({Key? key, required this.user}) : super(key: key);

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView>
    with TickerProviderStateMixin {
  late AnimationController _glowPulseController;
  late AnimationController _flipAnimationController;
  late AnimationController _bgAnimationController;
  late AnimationController _textLoopController;
  late AnimationController _listAnimationController;

  late Animation<Color?> _textColorAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _flipAnimation;

  List<bool> _expandedFaqs = [];
  bool _isContactCardFlipped = false;

  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSendingFeedback = false;
  bool _isSent = false;

  List<Map<String, dynamic>> _faqItems(bool isDark) => [
    {
      'question': 'How to mark student attendance?',
      'answer':
          'Go to Dashboard → Record Attendance. Select the class and date, then mark each student as Present or Absent.',
      'icon': Icons.fact_check_rounded,
      'color': isDark ? const Color(0xFF00E5FF) : const Color(0xFF0891B2),
    },
    {
      'question': 'How to upload student marks?',
      'answer':
          'Go to Dashboard → Continuous Assessment. Select the subject and assessment type, then enter marks for each student.',
      'icon': Icons.edit_note_rounded,
      'color': isDark ? const Color(0xFF7B61FF) : const Color(0xFF6366F1),
    },
    {
      'question': 'How to post class notices?',
      'answer':
          'Go to Dashboard → Post Class Notice. Write your notice, select priority (Normal/Important/Urgent), and publish.',
      'icon': Icons.campaign_rounded,
      'color': isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
    },
    {
      'question': 'How to manage syllabus?',
      'answer':
          'Go to Dashboard → Syllabus & Topics. You can add, edit, or delete syllabus entries for your subjects.',
      'icon': Icons.menu_book_rounded,
      'color': isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
    },
  ];

  @override
  void initState() {
    super.initState();
    _expandedFaqs = List<bool>.filled(4, false);

    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _textLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

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

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _textLoopController.dispose();
    _flipAnimationController.dispose();
    _bgAnimationController.dispose();
    _glowPulseController.dispose();
    _listAnimationController.dispose();
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
      final Map<String, dynamic> templateParams = {
        'message': text,
        'from_name': widget.user.name ?? 'Faculty User',
        'to_email': 'faculty-support@cpi.edu.bd',
      };

      debugPrint('📧 Sending email with params: $templateParams');

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_25hvb3t',
          'template_id': 'template_8fx6hqv',
          'user_id': 'Bp7PNtQBBl6M1XPe-',
          'accessToken': 'uS2kTr_iP_QButUtuftkk',
          'template_params': templateParams,
        }),
      );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? Colors.white60
        : const Color(0xFF475569);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.7);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: primaryTextColor,
                                  size: 18,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                                letterSpacing: -0.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                shadows: [
                                  Shadow(
                                    color: glowColor.withOpacity(
                                      0.4 * glowIntensity,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "How can we assist you today?",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
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
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final faq = _faqItems(isDark)[index];
                      final bool isExpanded = _expandedFaqs[index];
                      final double start =
                          (index / _faqItems(isDark).length) * 0.4;
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
                        child: _buildInteractiveFaqCard(faq, index, isExpanded),
                      );
                    }, childCount: _faqItems(isDark).length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildUniverseFlipCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeedbackSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInteractiveFaqCard(
    Map<String, dynamic> faq,
    int index,
    bool isExpanded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = faq['color'] ?? const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(isExpanded ? 0.08 : 0.04)
                  : Colors.white.withOpacity(isExpanded ? 0.8 : 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded
                    ? accentColor.withOpacity(0.5)
                    : (isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.08)),
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
                          color: accentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
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
                                : const Color(0xFF0F172A),
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
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF64748B),
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
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF475569),
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

  Widget _buildUniverseFlipCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(isDark ? 0.3 : 0.2),
              width: 1.2,
            ),
          ),
          child: Column(
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
                              const Color(0xFF00E5FF).withOpacity(0.2),
                              const Color(0xFF00E5FF).withOpacity(0),
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
                      size: 28,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tap to view institutional details",
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF64748B),
                  fontSize: 13,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF00E5FF),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Flip to reveal",
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF7B61FF).withOpacity(isDark ? 0.3 : 0.2),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7B61FF).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFF7B61FF).withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Color(0xFF7B61FF),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Contact Information",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : const Color(0xFF64748B),
                  fontSize: 11,
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
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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

  Widget _buildFeedbackSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.02)
        : Colors.white.withOpacity(0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.08),
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
                    color: primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: InputDecoration(
                  hintText: "Your email address",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.02),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
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
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: InputDecoration(
                  hintText: "Write your message here...",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.02),
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
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
                  ),
                  const SizedBox(width: 8),
                  _buildEmojiActionButton(
                    icon: Icons.sentiment_very_dissatisfied_rounded,
                    color: const Color(0xFF7B61FF),
                    onTap: () => _handleEmojiClick("🙁"),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.bold,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
