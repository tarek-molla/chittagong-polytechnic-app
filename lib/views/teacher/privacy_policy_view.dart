import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';

class PrivacyPolicyView extends StatefulWidget {
  final AppUser user;

  const PrivacyPolicyView({super.key, required this.user});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  final Color _accentColor = const Color(0xFF7B61FF);
  Color _primaryText = Colors.white;
  Color _secondaryText = Colors.white60;
  Color _cardColor = Colors.white.withOpacity(0.05);
  Color _borderColor = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    _secondaryText = isDark ? Colors.white60 : const Color(0xFF475569);
    _cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.7);
    _borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Privacy Policy",
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontSize: 26,
                              color: _primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Data security & user rights",
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader("DATA COLLECTION"),
                    _buildGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "We collect data necessary to provide you with a seamless institutional experience. This includes academic records, personal identification information, and device-specific usage data to improve our service performance and security.",
                          style: TextStyle(
                            fontFamily: 'Geist',
                            color: _secondaryText,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("SECURITY PROTOCOLS"),
                    _buildGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Your information is protected with industry-standard encryption protocols. We employ strict access controls and real-time monitoring to ensure your academic and personal data remains immutable and secure.",
                          style: TextStyle(
                            fontFamily: 'Geist',
                            color: _secondaryText,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("YOUR RIGHTS"),
                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildListTile(
                            Icons.visibility_rounded,
                            "Access your data",
                          ),
                          _buildDivider(),
                          _buildListTile(
                            Icons.edit_note_rounded,
                            "Request data correction",
                          ),
                          _buildDivider(),
                          _buildListTile(
                            Icons.delete_forever_rounded,
                            "Request data deletion",
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
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

  Widget _buildBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: _cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _primaryText,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: _secondaryText,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _accentColor),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Geist', color: _primaryText),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: _borderColor, height: 1);
  }
}
