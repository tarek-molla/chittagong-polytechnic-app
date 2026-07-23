// =============================================================================
// lib/views/teacher/teacher_dashboard.dart
// CPI Faculty Portal — Production-Ready Teacher Dashboard
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user.dart' as user_model;
import '../../core/router.dart';
import '../../core/theme_provider.dart';
import '../../../widgets/theme_toggle_switch.dart';
import '../../core/colors.dart';
import 'attendance_management_view.dart';
import 'support_view.dart';
import 'help_support_view.dart';
import 'alerts_view.dart';
import 'profile_view.dart';
import 'teacher_search_delegate.dart';

class TeacherDashboard extends StatefulWidget {
  final user_model.AppUser user;

  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late PageController _pageController;

  Timer? _profileBgTimer;

  late AnimationController _contentAnimationController;
  late AnimationController _staggerController;

  late Animation<double> _staggerAnimation;

  double _scrollOffset = 0.0;
  int _currentBgIndex = 0;
  int _selectedNavIndex = 0;

  final List<String> _bgAssets = [
    'assets/cpi_bg.png',
    'assets/cpi_bg2.png',
    'assets/cpi_bg3.png',
    'assets/cpi_bg4.png',
    'assets/cpi_bg5.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_handlePageChange);

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );

    _profileBgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgAssets.length;
        });
      }
    });

    _contentAnimationController.forward();
    _staggerController.forward();

    AppThemeController.themeModeNotifier.addListener(_themeListener);
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  void _handlePageChange() {
    if (_pageController.hasClients && _pageController.page != null) {
      final currentIndex = _pageController.page!.round();
      if (_selectedNavIndex != currentIndex) {
        if (mounted) {
          setState(() {
            _selectedNavIndex = currentIndex;
          });
        }
        if (currentIndex == 0) {
          _triggerDashboardReentrySequence();
        }
      }
    }
  }

  void _triggerDashboardReentrySequence() {
    _scrollOffset = 0.0;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _replayAnimations();
  }

  void _replayAnimations() {
    _contentAnimationController.reset();
    _staggerController.reset();

    _contentAnimationController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _profileBgTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _contentAnimationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // Navigates directly to the dedicated full-page Routine view
  void _navigateToRoutinePage(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.teacherRoutine);
  }

  // Opens Dedicated Faculty Search Experience
  void _openFacultySearchPage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Faculty Search",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        final isDark = AppThemeController.isDarkMode;
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF020617).withAlpha(240)
              : AppColors.lightBackground.withAlpha(245),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightPrimaryText,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha(12)
                                : AppColors.lightCardBorderAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withAlpha(25)
                                  : AppColors.lightCardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  autofocus: true,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightPrimaryText,
                                    fontSize: 14,
                                    fontFamily: 'Geist',
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        "Search student roll, name, subject...",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.lightCaptionText,
                                      fontSize: 13,
                                      fontFamily: 'Geist',
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white24 : Colors.black26,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Search student roll, syllabus, or assessment ledger",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : AppColors.lightSubtitleText,
                            fontSize: 13,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsDrawer(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        bottomLeft: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: 295,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF020617).withAlpha(165)
                : AppColors.lightBackground.withAlpha(220),
            border: Border(
              left: BorderSide(
                color: isDark
                    ? Colors.white.withAlpha(25)
                    : Colors.black.withAlpha(15),
                width: 1.2,
              ),
            ),
          ),
          child: Stack(
            children: [
              if (isDark)
                Positioned(
                  top: -55,
                  right: -55,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF10B981).withAlpha(30),
                          const Color(0xFF10B981).withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withAlpha(isDark ? 15 : 30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981).withAlpha(50),
                              ),
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CPI Menu",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightPrimaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                "Faculty Options",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : AppColors.lightCaptionText,
                                  fontSize: 11,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Divider(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      _buildDrawerFrostedLinkTile(
                        Icons.info_outline_rounded,
                        "About Institution",
                        isDark,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.teacherAboutInstitution,
                            arguments: TeacherRouteArgs(user: widget.user),
                          );
                        },
                      ),
                      _buildDrawerFrostedLinkTile(
                        Icons.security_rounded,
                        "Privacy & Policy",
                        isDark,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.teacherPrivacyPolicy,
                            arguments: TeacherRouteArgs(user: widget.user),
                          );
                        },
                      ),
                      _buildDrawerFrostedLinkTile(
                        Icons.headset_mic_rounded,
                        "Help & Support Desk",
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HelpSupportView(user: widget.user),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      _InteractiveScaleButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withAlpha(isDark ? 12 : 20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withAlpha(50),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.power_settings_new_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Sign Out",
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "App Version 2.4.0 (2026)",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : AppColors.lightSubtitleText,
                            fontSize: 10,
                            fontFamily: 'Geist',
                          ),
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
    );
  }

  Widget _buildDrawerFrostedLinkTile(
    IconData icon,
    String title,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: _InteractiveScaleButton(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(6)
                : AppColors.lightCardBorderAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withAlpha(215)
                        : AppColors.lightPrimaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white24 : AppColors.lightCaptionText,
                size: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    double calculatedAlpha = (90 + (_scrollOffset * 0.85)).clamp(90.0, 255.0);
    double dynamicImageOpacity = (1.0 - (_scrollOffset / 140.0)).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      endDrawer: _buildOptionsDrawer(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardContent(
                  isDark,
                  calculatedAlpha,
                  dynamicImageOpacity,
                ),
                // ✅ Support tab - use SupportView (quick support)
                SupportView(user: widget.user),
                AlertsView(user: widget.user),
                ProfileView(user: widget.user),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildOriginalGlassNavbar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, bool isDark) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildOriginalGlassNavbar(bool isDark) {
    return _buildNavbarGlassContainer(
      borderRadius: 24,
      isDark: isDark,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: const Cubic(0.175, 0.885, 0.32, 1.15),
              alignment: Alignment(
                -1.0 + (_selectedNavIndex * (2.0 / 3.0)),
                0.0,
              ),
              child: FractionallySizedBox(
                widthFactor: 0.25,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withAlpha(35)
                        : const Color(0xFF10B981).withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF10B981).withAlpha(60)
                          : const Color(0xFF10B981).withAlpha(40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF10B981).withAlpha(15)
                            : const Color(0xFF10B981).withAlpha(10),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavbarItem(
                  Icons.grid_view_rounded,
                  "Portal",
                  index: 0,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.chat_bubble_outline_rounded,
                  "Support",
                  index: 1,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.notifications_none_rounded,
                  "Alerts",
                  index: 2,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.person_outline_rounded,
                  "Profile",
                  index: 3,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbarGlassContainer({
    required double borderRadius,
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.transparent
                : AppColors.lightBackground.withAlpha(235),
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(16),
                      Colors.white.withAlpha(4),
                    ],
                  )
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(30)
                  : AppColors.lightCardBorder,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildNavbarItem(
    IconData icon,
    String label, {
    required int index,
    required bool isDark,
  }) {
    final active = _selectedNavIndex == index;
    final activeColor = active
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
        : (isDark ? Colors.white38 : AppColors.lightSubtitleText);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedNavIndex = index;
            });
          }
          // ✅ For ALL tabs, use PageView (including Profile)
          _pageController.jumpToPage(index);

          if (index == 0) {
            _triggerDashboardReentrySequence();
          }
        },
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: const Cubic(0.175, 0.885, 0.32, 1.2),
                scale: active ? 1.22 : 0.95,
                child: Icon(
                  icon,
                  color: activeColor,
                  size: 20,
                  shadows: active
                      ? [
                          Shadow(
                            color: activeColor.withAlpha(100),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: activeColor,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Geist',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    bool isDark,
    double calculatedAlpha,
    double dynamicImageOpacity,
  ) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Opacity(
              opacity: dynamicImageOpacity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      child: Image.asset(
                        _bgAssets[_currentBgIndex],
                        key: ValueKey<int>(_currentBgIndex),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: isDark
                              ? AppColors.lightPrimaryText
                              : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        color: isDark
                            ? Colors.black.withAlpha(calculatedAlpha.toInt())
                            : Colors.white.withAlpha(
                                (calculatedAlpha.toInt() - 20).clamp(0, 255),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isDark) ...[
            Positioned(
              top: 240,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withAlpha(35),
                      const Color(0xFF10B981).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 450,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0284C7).withAlpha(25),
                      const Color(0xFF0284C7).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 52.0, 20.0, 36.0),
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    return InkWell(
                                      onTap: () {
                                        Scaffold.of(context).openEndDrawer();
                                      },
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withAlpha(20)
                                              : Colors.black.withAlpha(15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withAlpha(40)
                                                : Colors.black.withAlpha(20),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.badge_rounded,
                                          color: Color(0xFF10B981),
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.user.name.toUpperCase(),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightPrimaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Geist',
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        "Faculty • Dept: ${widget.user.department?.shortCode ?? 'CST'}",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white.withAlpha(140)
                                              : AppColors.lightSubtitleText,
                                          fontSize: 11,
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // HEADER ACTION BUTTONS: [ Theme Toggle ] -> [ Search ] -> [ Logout ]
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Theme Toggle
                              const ThemeToggleSwitch(),
                              const SizedBox(width: 8),

                              // Search Button
                              IconButton(
                                onPressed: () {
                                  showSearch(
                                    context: context,
                                    delegate: TeacherSearchDelegate(user: widget.user),
                                  );
                                },
                                icon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF10B981),
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.white.withAlpha(12)
                                      : Colors.black.withAlpha(8),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Power Off / Logout
                              IconButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                                icon: const Icon(
                                  Icons.power_settings_new_rounded,
                                  color: Color(0xFFFFA0A0),
                                  size: 16,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.white.withAlpha(12)
                                      : Colors.black.withAlpha(8),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          24.0,
                          20.0,
                          160.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(6)
                              : AppColors.lightBackground.withAlpha(180),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(25)
                                  : AppColors.lightCardBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Interactive Live Lecture Tracker Card
                            AnimatedBuilder(
                              animation: _staggerAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _staggerAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      20 * (1 - _staggerAnimation.value),
                                    ),
                                    child: _buildLiveScheduleTimelineTracker(
                                      isDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Faculty Operations Control Center
                            AnimatedBuilder(
                              animation: _staggerAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _staggerAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      30 * (1 - _staggerAnimation.value),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                          ),
                                          child: Text(
                                            "Faculty Control Center",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.lightPrimaryText,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Geist',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.35,
                                          children: [
                                            _buildActionTile(
                                              "Record Attendance",
                                              Icons.fact_check_rounded,
                                              const Color(0xFF10B981),
                                              () {
                                                // Using router with proper arguments
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.attendanceLogger,
                                                  arguments:
                                                      AttendanceLoggerArgs(
                                                        teacher: widget.user,
                                                        subjectCode: '66641',
                                                        subjectName:
                                                            'Data Structures',
                                                        className: 'CMT-4th-B2',
                                                        semester: 4,
                                                        department: 'CST',
                                                      ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildActionTile(
                                              "Continuous Assessment",
                                              Icons
                                                  .drive_file_rename_outline_rounded,
                                              const Color(0xFF0284C7),
                                              () {
                                                // ✅ FIXED: Using the new Continuous Assessment route
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes
                                                      .continuousAssessment,
                                                  arguments:
                                                      ContinuousAssessmentArgs(
                                                        teacher: widget.user,
                                                        className: 'CMT-4th-B2',
                                                        subjectCode: '66641',
                                                        subjectName:
                                                            'Data Structures',
                                                        semester: 4,
                                                        department: 'CST',
                                                      ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildActionTile(
                                              "Syllabus & Topics",
                                              Icons.menu_book_rounded,
                                              const Color(0xFF8B5CF6),
                                              () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.teacherSyllabus,
                                                  arguments: TeacherRouteArgs(
                                                    user: widget.user,
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildActionTile(
                                              "Post Class Notice",
                                              Icons.campaign_rounded,
                                              const Color(0xFFF59E0B),
                                              () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.teacherNotice,
                                                  arguments: TeacherRouteArgs(
                                                    user: widget.user,
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // QUICK STATS BANNER
                            _buildQuickStatsBanner(isDark),
                            const SizedBox(height: 24),

                            // Faculty Course Assignments & Syllabus Tracking
                            AnimatedBuilder(
                              animation: _staggerAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _staggerAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      40 * (1 - _staggerAnimation.value),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                          ),
                                          child: Text(
                                            "Assigned Courses & Syllabus",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.lightPrimaryText,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Geist',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildFacultyManagementGrid(isDark),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD METHODS ====================

  Widget _buildLiveScheduleTimelineTracker(bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getCurrentClassStream(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'current': 'No Active Lecture',
              'next': 'Day Completed / No Class',
            };

        return _InteractiveScaleButton(
          onTap: () => _navigateToRoutinePage(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(8)
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(12)
                    : AppColors.lightCardBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(isDark ? 20 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "LIVE ACTIVE ASSIGNMENT",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withAlpha(isDark ? 20 : 30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF10B981).withAlpha(50),
                              ),
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data['current'] ?? 'No Active Lecture',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightPrimaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Next Up: ${data['next'] ?? 'Day Completed'}",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppColors.lightSubtitleText,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>> _getCurrentClassStream() async* {
    while (true) {
      try {
        final client = SupabaseService.client;
        final now = DateTime.now();
        final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        final currentDay = dayNames[now.weekday - 1];
        final currentTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        final department = widget.user.department?.shortCode ?? 'CST';

        final currentClass = await client
            .from('routine')
            .select()
            .eq('department', department)
            .eq('day', currentDay)
            .eq('is_active', true)
            .lte('start_time', currentTime)
            .gte('end_time', currentTime)
            .limit(1);

        final nextClass = await client
            .from('routine')
            .select()
            .eq('department', department)
            .eq('day', currentDay)
            .eq('is_active', true)
            .gt('start_time', currentTime)
            .order('start_time', ascending: true)
            .limit(1);

        yield {
          'current': currentClass.isNotEmpty
              ? '${currentClass[0]['subject_name']} • ${currentClass[0]['class_name']} (Rm ${currentClass[0]['room']})'
              : 'No Active Lecture',
          'next': nextClass.isNotEmpty
              ? '${nextClass[0]['subject_name']} at ${nextClass[0]['start_time']}'
              : 'Day Completed / No Class',
        };
      } catch (e) {
        print('❌ Error fetching current class: $e');
        yield {
          'current': 'No Active Lecture',
          'next': 'Day Completed / No Class',
        };
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Widget _buildQuickStatsBanner(bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getDashboardStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {'students': '0', 'attendance': '0/0', 'marks': '0%'};

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(6)
                : AppColors.lightCardBorderAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Students", stats['students'].toString(), isDark),
              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildStatItem(
                "Attendance",
                stats['attendance'].toString(),
                isDark,
              ),
              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildStatItem("Marks Ledger", stats['marks'].toString(), isDark),
            ],
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>> _getDashboardStats() async* {
    while (true) {
      try {
        final client = SupabaseService.client;
        final department = widget.user.department?.shortCode ?? 'CST';

        final students = await client
            .from('students')
            .select()
            .eq('class_name', 'CMT-4th-B2');
        final studentCount = students.length;

        final attendance = await client
            .from('attendance_daily')
            .select('status')
            .eq('date', DateTime.now().toIso8601String().split('T').first)
            .eq('department', department);

        final present = attendance
            .where((a) => a['status'] == 'Present')
            .length;
        final total = attendance.length;
        final attendanceStr = total > 0 ? '$present/$total' : '0/0';

        final marks = await client
            .from('continuous_assessment')
            .select('obtained_marks, total_marks')
            .eq('department', department);

        double totalObtained = 0;
        double totalPossible = 0;
        for (var m in marks) {
          totalObtained += (m['obtained_marks'] ?? 0).toDouble();
          totalPossible += (m['total_marks'] ?? 0).toDouble();
        }
        final marksPercent = totalPossible > 0
            ? '${((totalObtained / totalPossible) * 100).toInt()}%'
            : '0%';

        yield {
          'students': studentCount.toString(),
          'attendance': attendanceStr,
          'marks': marksPercent,
        };
      } catch (e) {
        print('❌ Error fetching dashboard stats: $e');
        yield {'students': '0', 'attendance': '0/0', 'marks': '0%'};
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : AppColors.lightCaptionText,
            fontSize: 10,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return _InteractiveScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(12)
                : AppColors.lightCardBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 20 : 30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withAlpha(215)
                      : AppColors.lightPrimaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, bool isDark) {
    final isWrapUp = course['status'] == 'Wrap Up';
    final double progress = (course['syllabusProgress'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(12)
              : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      (isWrapUp
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0284C7))
                          .withAlpha(isDark ? 25 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    course['code'] ?? '',
                    style: TextStyle(
                      color: isWrapUp
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['name'] ?? '',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightPrimaryText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${course['class'] ?? ''} • ${course['lectures'] ?? '0/0'}",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withAlpha(140)
                            : AppColors.lightCaptionText,
                        fontSize: 11,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isWrapUp
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD97706))
                          .withAlpha(isDark ? 25 : 20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        (isWrapUp
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD97706))
                            .withAlpha(50),
                  ),
                ),
                child: Text(
                  (course['status'] ?? 'Ongoing').toUpperCase(),
                  style: TextStyle(
                    color: isWrapUp
                        ? const Color(0xFF10B981)
                        : const Color(0xFFD97706),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white10
                        : AppColors.lightCardBorderAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWrapUp
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${(progress * 100).toInt()}% Syllabus",
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.lightSubtitleText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMicroShortcutChip(
                "Log Attendance",
                Icons.check_circle_outline_rounded,
                const Color(0xFF10B981),
                () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.attendanceLogger,
                    arguments: AttendanceLoggerArgs(
                      teacher: widget.user,
                      subjectCode: course['code'] ?? '',
                      subjectName: course['name'] ?? '',
                      className: course['class'] ?? '',
                      semester: 4,
                      department: 'CST',
                    ),
                  );
                },
                isDark,
              ),
              const SizedBox(width: 8),
              _buildMicroShortcutChip(
                "Marks",
                Icons.edit_note_rounded,
                const Color(0xFF0284C7),
                () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.continuousAssessment,
                    arguments: ContinuousAssessmentArgs(
                      teacher: widget.user,
                      className: course['class'] ?? '',
                      subjectCode: course['code'] ?? '',
                      subjectName: course['name'] ?? '',
                      semester: 4,
                      department: 'CST',
                    ),
                  );
                },
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyManagementGrid(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getCoursesStream(),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No courses assigned',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightCaptionText,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _buildCourseCard(courses[index], isDark),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getCoursesStream() async* {
    while (true) {
      try {
        final client = SupabaseService.client;
        final department = widget.user.department?.shortCode ?? 'CST';
        final teacherName = widget.user.name;

        final courses = await client
            .from('routine')
            .select()
            .eq('department', department)
            .eq('teacher_name', teacherName)
            .eq('is_active', true)
            .order('subject_name', ascending: true);

        final transformed = courses
            .map(
              (c) => {
                'code': c['subject_code'] ?? '',
                'name': c['subject_name'] ?? '',
                'class': c['class_name'] ?? '',
                'lectures': '0/0',
                'syllabusProgress': 0.0,
                'status': 'Ongoing',
              },
            )
            .toList();

        yield transformed;
      } catch (e) {
        print('❌ Error fetching courses: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Widget _buildMicroShortcutChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return _InteractiveScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 20 : 15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveScaleButton({required this.child, required this.onTap});

  @override
  State<_InteractiveScaleButton> createState() =>
      _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<_InteractiveScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
