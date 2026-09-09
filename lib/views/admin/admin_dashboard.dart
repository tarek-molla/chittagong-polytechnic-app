// =============================================================================
// lib/views/admin/admin_dashboard.dart
// CPI Admin Command Center — Connected & Animated Metric Grid Edition
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart' as user_model;
import '../../core/router.dart'
    show AppRoutes, AdminRouteArgs, TeacherRouteArgs;
import '../../core/theme_provider.dart';
import '../../../widgets/theme_toggle_switch.dart';
import '../../core/colors.dart';
import '../../models/user_role.dart' as role_model;
import '../../widgets/animated_background_painter.dart' hide UserRole;
import '../../widgets/premium_refresh_indicator.dart';
import '../../widgets/offline_indicator_badge.dart';
import 'admin_controls_view.dart';
import 'faculty_management_view.dart';
import 'system_settings_view.dart';
import 'admission_triage_view.dart';

class AdminDashboard extends StatefulWidget {
  final user_model.AppUser user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late PageController _pageController;

  Timer? _profileBgTimer;

  late AnimationController _contentAnimationController;
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late AnimationController _bgAnimController;
  late AnimationController _glowController;

  late Animation<double> _staggerAnimation;
  late Animation<double> _fadeAnimation;

  double _scrollOffset = 0.0;
  int _currentBgIndex = 0;
  int _selectedNavIndex = 0;
  int _selectedSemester = 4;
  bool _isEmergencyModeActive = false;

  final List<String> _bgAssets = [
    'assets/cpi_bg.png',
    'assets/cpi_bg2.png',
    'assets/cpi_bg3.png',
    'assets/cpi_bg4.png',
    'assets/cpi_bg5.png',
  ];

  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isStatsLoading = true;

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

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _profileBgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgAssets.length;
        });
      }
    });

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadDashboardData();
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

  void _navigateToRoute(String routeName) {
    Navigator.pushNamed(
      context,
      routeName,
      arguments: AdminRouteArgs(user: widget.user),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isStatsLoading = true;
    });

    try {
      final adminService = AdminService(SupabaseService.client);
      final department = widget.user.department?.shortCode ?? 'CST';

      final stats = await adminService.getDashboardStats(department);
      final activities = await adminService.getRecentActivity().first;

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _recentActivities = activities;
          _isStatsLoading = false;
        });
        _contentAnimationController.forward();
        _staggerController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStatsLoading = false;
        });
      }
    }
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
    _bgAnimController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _openAdminSearchPage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Admin Search",
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
                                color: Color(0xFFF59E0B),
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
                                        "Search students, faculty, departments...",
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
                          "Search students, faculty, or departments",
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
                          const Color(0xFFF59E0B).withAlpha(30),
                          const Color(0xFFF59E0B).withAlpha(0),
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
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withAlpha(isDark ? 20 : 35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withAlpha(60),
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/applogo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CPI Admin",
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
                                "Admin Options",
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
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildDrawerFrostedLinkTile(
                                Icons.supervisor_account_rounded,
                                "Teacher Roster",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.teacherManagement);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.school_rounded,
                                "Student Directory",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.studentManagement);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.assessment_rounded,
                                "Result Portal",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.resultManagement);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.campaign_rounded,
                                "Notice Board",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.noticeManagement);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.calendar_today_rounded,
                                "Routine Matrix",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.routineScheduler);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.how_to_reg_rounded,
                                "Admission Triage",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToRoute(AppRoutes.admissionTriage);
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.info_outline_rounded,
                                "About Institution",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.teacherAboutInstitution,
                                    arguments: TeacherRouteArgs(
                                      user: widget.user,
                                    ),
                                  );
                                },
                              ),
                              _buildDrawerFrostedLinkTile(
                                Icons.security_rounded,
                                "Privacy & Policy",
                                isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.teacherPrivacyPolicy,
                                    arguments: TeacherRouteArgs(
                                      user: widget.user,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
              Icon(icon, color: const Color(0xFFF59E0B), size: 20),
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
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedBackgroundPainter(
                    animation: _bgAnimController,
                    isLightMode: !isDark,
                    role: role_model.UserRole.admin,
                  ),
                );
              },
            ),
          ),
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
                AdminControlsView(user: widget.user),
                FacultyManagementView(user: widget.user),
                SystemSettingsView(user: widget.user),
                AdmissionTriageView(user: widget.user),
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
              alignment: Alignment(-1.0 + (_selectedNavIndex * 0.5), 0.0),
              child: FractionallySizedBox(
                widthFactor: 0.2,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFF59E0B).withAlpha(35)
                        : const Color(0xFFF59E0B).withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFF59E0B).withAlpha(60)
                          : const Color(0xFFF59E0B).withAlpha(40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFFF59E0B).withAlpha(15)
                            : const Color(0xFFF59E0B).withAlpha(10),
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
                  "Dashboard",
                  index: 0,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.tune_rounded,
                  "Controls",
                  index: 1,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.supervisor_account_rounded,
                  "Faculty",
                  index: 2,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.settings_outlined,
                  "Settings",
                  index: 3,
                  isDark: isDark,
                ),
                _buildNavbarItem(
                  Icons.how_to_reg_rounded,
                  "Intake",
                  index: 4,
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
        ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))
        : (isDark ? Colors.white38 : AppColors.lightSubtitleText);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedNavIndex = index;
            });
          }
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

  // ===========================================================================
  // DASHBOARD CONTENT
  // ===========================================================================
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
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  top: 240 + (_glowController.value * 30),
                  left: -80 + (_glowController.value * 20),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFF59E0B).withAlpha(30),
                          const Color(0xFFF59E0B).withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  bottom: 100 - (_glowController.value * 30),
                  right: -80 - (_glowController.value * 20),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7B61FF).withAlpha(25),
                          const Color(0xFF7B61FF).withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          Positioned.fill(
            child: PremiumRefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(isDark),
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
                              // Metrics Grid - Connected to Real-time Stream with Number Counter Animations
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
                                      child: _buildMetricsGrid(isDark),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Department Operations Hub
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
                                          Text(
                                            "Department Operations Hub",
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
                                          const SizedBox(height: 14),
                                          _buildActionGrid(isDark),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Emergency Banner
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
                                      child: _buildEmergencyBannerToggle(
                                        isDark,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Semester Chips
                              AnimatedBuilder(
                                animation: _staggerAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _staggerAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        50 * (1 - _staggerAnimation.value),
                                      ),
                                      child: _buildSemesterChipsBlock(isDark),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Live System Dispatch Logs
                              AnimatedBuilder(
                                animation: _staggerAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _staggerAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        60 * (1 - _staggerAnimation.value),
                                      ),
                                      child: _buildLiveSystemTerminal(isDark),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Department Roster
                              AnimatedBuilder(
                                animation: _staggerAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _staggerAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        70 * (1 - _staggerAnimation.value),
                                      ),
                                      child: _buildDepartmentSection(isDark),
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
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _buildHeader(bool isDark) {
    return Padding(
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
                        onTap: () => Scaffold.of(context).openEndDrawer(),
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
                            Icons.admin_panel_settings_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _isEmergencyModeActive
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isEmergencyModeActive
                                    ? "EMERGENCY MODE • CST DEPT"
                                    : "CI SIR • CST DEPT ADMIN",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _isEmergencyModeActive
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OfflineIndicatorBadge(),
                const SizedBox(width: 8),
                const ThemeToggleSwitch(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openAdminSearchPage(context),
                  icon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFF59E0B),
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
                IconButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
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
    );
  }

  // ===========================================================================
  // METRICS GRID - ANIMATED COUNTERS CONNECTED TO DATABASE
  // ===========================================================================
  Widget _buildMetricsGrid(bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AdminService(
        SupabaseService.client,
      ).getDashboardStatsStream(widget.user.department?.shortCode ?? 'CST'),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? _dashboardStats;
        final totalStudents =
            (stats['totalStudents'] as num?)?.toDouble() ?? 0.0;
        final activeFaculty =
            (stats['activeFaculty'] as num?)?.toDouble() ?? 0.0;
        final pendingIntake =
            (stats['pendingAdmissions'] as num?)?.toDouble() ?? 0.0;
        final liveClassrooms =
            (stats['liveClassrooms'] as num?)?.toDouble() ?? 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAnimatedMetricGlassCard(
                  "Total Students",
                  totalStudents,
                  Icons.groups_rounded,
                  const Color(0xFF00E5FF),
                  cardWidth,
                  isDark,
                  isInteger: true,
                  onTap: () => _navigateToRoute(AppRoutes.studentManagement),
                ),
                _buildAnimatedMetricGlassCard(
                  "Active Faculty",
                  activeFaculty,
                  Icons.badge_rounded,
                  const Color(0xFF10B981),
                  cardWidth,
                  isDark,
                  isInteger: true,
                  onTap: () => _navigateToRoute(AppRoutes.teacherManagement),
                ),
                _buildAnimatedMetricGlassCard(
                  "Pending Intake",
                  pendingIntake,
                  Icons.pending_actions_rounded,
                  const Color(0xFFF59E0B),
                  cardWidth,
                  isDark,
                  isInteger: true,
                  onTap: () => _navigateToRoute(AppRoutes.admissionTriage),
                ),
                _buildAnimatedMetricGlassCard(
                  "Live Classrooms",
                  liveClassrooms,
                  Icons.meeting_room_rounded,
                  const Color(0xFF7B61FF),
                  cardWidth,
                  isDark,
                  isInteger: true,
                  onTap: () => _navigateToRoute(AppRoutes.routineScheduler),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedMetricGlassCard(
    String title,
    double targetValue,
    IconData icon,
    Color accentColor,
    double width,
    bool isDark, {
    required bool isInteger,
    required VoidCallback onTap,
  }) {
    return _InteractiveScaleButton(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(8)
                    : Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: accentColor, size: 20),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: targetValue),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final displayString = isInteger
                          ? value.toInt().toString()
                          : value.toStringAsFixed(1);
                      return Text(
                        displayString,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Geist',
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withAlpha(150)
                          : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ACTION GRID
  // ===========================================================================
  Widget _buildActionGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildActionTile(
          "Teacher Roster",
          Icons.supervisor_account_rounded,
          const Color(0xFF10B981),
          () => _navigateToRoute(AppRoutes.teacherManagement),
          isDark,
        ),
        _buildActionTile(
          "Student Directory",
          Icons.school_rounded,
          const Color(0xFF2563EB),
          () => _navigateToRoute(AppRoutes.studentManagement),
          isDark,
        ),
        _buildActionTile(
          "Result Portal",
          Icons.assessment_rounded,
          const Color(0xFF7B61FF),
          () => _navigateToRoute(AppRoutes.resultManagement),
          isDark,
        ),
        _buildActionTile(
          "Notice Board",
          Icons.campaign_rounded,
          const Color(0xFFF59E0B),
          () => _navigateToRoute(AppRoutes.noticeManagement),
          isDark,
        ),
        _buildActionTile(
          "Routine Matrix",
          Icons.calendar_today_rounded,
          const Color(0xFF00E5FF),
          () => _navigateToRoute(AppRoutes.routineScheduler),
          isDark,
        ),
        _buildActionTile(
          "Admission Triage",
          Icons.how_to_reg_rounded,
          const Color(0xFFEF4444),
          () => _navigateToRoute(AppRoutes.admissionTriage),
          isDark,
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

  // ===========================================================================
  // EMERGENCY BANNER TOGGLE
  // ===========================================================================
  Widget _buildEmergencyBannerToggle(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(8)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEmergencyModeActive
                  ? const Color(0xFFEF4444).withAlpha(150)
                  : (isDark
                        ? Colors.white.withAlpha(30)
                        : AppColors.lightCardBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isEmergencyModeActive
                      ? const Color(0xFFEF4444).withAlpha(50)
                      : const Color(0xFFF59E0B).withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isEmergencyModeActive
                      ? Icons.warning_amber_rounded
                      : Icons.campaign_rounded,
                  color: _isEmergencyModeActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEmergencyModeActive
                          ? "Emergency Dispatch Active"
                          : "Campus Live Broadcast Status",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEmergencyModeActive
                          ? "Pushing alert banners to all student portals."
                          : "System operating under normal academic schedule.",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withAlpha(140)
                            : Colors.black54,
                        fontSize: 10.5,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isEmergencyModeActive,
                activeColor: const Color(0xFFEF4444),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      _isEmergencyModeActive = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SEMESTER CHIPS
  // ===========================================================================
  Widget _buildSemesterChipsBlock(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Academic Target Semester",
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(8, (index) {
              final semIndex = index + 1;
              final isSelected = _selectedSemester == semIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() => _selectedSemester = semIndex);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF59E0B).withAlpha(50)
                          : (isDark
                                ? Colors.white.withAlpha(12)
                                : Colors.black.withAlpha(8)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : (isDark
                                  ? Colors.white.withAlpha(25)
                                  : Colors.black.withAlpha(15)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      "$semIndex${_getOrdinalSuffix(semIndex)} Sem",
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : (isDark
                                  ? Colors.white.withAlpha(150)
                                  : Colors.black54),
                        fontSize: 12,
                        fontFamily: 'Geist',
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int value) {
    if (value == 1) return 'st';
    if (value == 2) return 'nd';
    if (value == 3) return 'rd';
    return 'th';
  }

  // ===========================================================================
  // LIVE SYSTEM DISPATCH LOGS
  // ===========================================================================
  Widget _buildLiveSystemTerminal(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Live System Dispatch Logs",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminService(SupabaseService.client).getRecentActivity(),
          builder: (context, snapshot) {
            final activities = snapshot.data ?? _recentActivities;
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(8)
                        : Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: activities.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                "No recent system logs recorded",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 11,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          ]
                        : List.generate(activities.length.clamp(0, 4), (idx) {
                            final log = activities[idx];
                            final time = log['time'] ?? '';
                            final action = (log['type'] ?? 'EVENT')
                                .toString()
                                .toUpperCase();
                            final details = log['title'] ?? 'System Event';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _TerminalLogRow(
                                time: time is String ? time : time.toString(),
                                action: action,
                                details: details is String
                                    ? details
                                    : details.toString(),
                                color: const Color(0xFF10B981),
                              ),
                            );
                          }),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // DEPARTMENT ROSTER
  // ===========================================================================
  Widget _buildDepartmentSection(bool isDark) {
    return StreamBuilder<Map<String, int>>(
      stream: AdminService(SupabaseService.client).getDepartmentStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final cstCount = stats['CST'] ?? 0;
        final civilCount = stats['CIVIL'] ?? 0;
        final eeCount = stats['EE'] ?? 0;
        final meCount = stats['ME'] ?? 0;
        final ectCount = stats['ECT'] ?? 0;
        final total = cstCount + civilCount + eeCount + meCount + ectCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                "Department Roster Matrix",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(12)
                        : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDepartmentRow("CST", cstCount, isDark),
                    const SizedBox(height: 8),
                    _buildDepartmentRow("CIVIL", civilCount, isDark),
                    const SizedBox(height: 8),
                    _buildDepartmentRow("EE", eeCount, isDark),
                    const SizedBox(height: 8),
                    _buildDepartmentRow("ME", meCount, isDark),
                    const SizedBox(height: 8),
                    _buildDepartmentRow("ECT", ectCount, isDark),
                    const Divider(height: 16),
                    _buildDepartmentRow("Total", total, isDark, isBold: true),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDepartmentRow(
    String name,
    int count,
    bool isDark, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: TextStyle(
            color: isDark
                ? (isBold ? Colors.white : Colors.white70)
                : (isBold ? Colors.black87 : Colors.black54),
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'Geist',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(30)),
          ),
          child: Text(
            "$count Students",
            style: TextStyle(
              color: const Color(0xFFF59E0B),
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================
  Future<void> _refreshAll() async {
    setState(() {});
    _staggerController.forward(from: 0);
    await _loadDashboardData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dashboard refreshed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ===========================================================================
// TERMINAL LOG ROW
// ===========================================================================
class _TerminalLogRow extends StatelessWidget {
  final String time;
  final String action;
  final String details;
  final Color color;

  const _TerminalLogRow({
    required this.time,
    required this.action,
    required this.details,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final displayTime = time.length > 10 ? time.substring(0, 19) : time;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "[$displayTime]",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            action,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            details,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 10.5,
              fontFamily: 'Geist',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// INTERACTIVE SCALE BUTTON
// ===========================================================================
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
