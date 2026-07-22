// =============================================================================
// lib/views/admin/admin_dashboard.dart
// CPI Admin Command Center — 1:1 Student Dashboard Parity Edition
// Features:
//   • Dynamic Role Background Painter Integration (Amber/Orange Drift)
//   • Exact Student Dashboard Glassmorphism Navbar & Animated Pill
//   • Staggered Entry Animations
//   • Re-ordered Metrics Grid at top
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../models/user.dart' as user_model;
import '../../core/router.dart';
import '../../widgets/animated_background_painter.dart';
import '../components/admin_operations_sheets.dart';

class AdminDashboard extends StatefulWidget {
  final user_model.AppUser user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;

  late Animation<double> _staggerAnimation;

  int _selectedSemester = 4;
  int _selectedNavIndex = 0;
  bool _isEmergencyModeActive = false;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _showQuickActionSnackBar(String title) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A).withAlpha(240),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
        ),
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 10),
            Text(
              "Launching $title Modal...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            // ── 1. DYNAMIC ROLE BACKGROUND (AMBER / ORANGE DRIFT) ──────────────
            AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: AnimatedBackgroundPainter(
                    animation: _bgAnimController,
                    isLightMode: false,
                    role: UserRole.admin,
                  ),
                );
              },
            ),

            // ── 2. MAIN SCROLLABLE DASHBOARD CONTENT ────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // Top Metrics Overview (Student Dashboard Stagger Style)
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
                            child: _buildMetricsGrid(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Control Operations Gateways
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
                            child: _buildActionGrid(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Relocated Emergency Banner
                    AnimatedBuilder(
                      animation: _staggerAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _staggerAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              35 * (1 - _staggerAnimation.value),
                            ),
                            child: _buildEmergencyBannerToggle(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Target Semester Picker
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
                            child: _buildSemesterChipsBlock(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Live System Dispatch Log
                    AnimatedBuilder(
                      animation: _staggerAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _staggerAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              45 * (1 - _staggerAnimation.value),
                            ),
                            child: _buildLiveSystemTerminal(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Department Activity Matrix
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
                            child: _buildDepartmentSection(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. EXACT STUDENT DASHBOARD GLASS NAVBAR ─────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _buildOriginalGlassNavbar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER (OVERFLOW SAFE) ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withAlpha(90),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFF030712),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
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
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isEmergencyModeActive
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFF59E0B))
                                      .withAlpha(
                                        (_pulseController.value * 255).toInt(),
                                      ),
                              blurRadius: 8 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _isEmergencyModeActive
                          ? "EMERGENCY BROADCAST ACTIVE • ID: ${widget.user.displayId}"
                          : "ADMIN NODE ONLINE • ID: ${widget.user.displayId}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
        const SizedBox(width: 8),
        IconButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          icon: const Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFFFFA0A0),
            size: 18,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(20),
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withAlpha(30)),
            ),
          ),
        ),
      ],
    );
  }

  // ── METRIC CARDS GRID (TOP PRIORITY) ──────────────────────────────────────
  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricGlassCard(
              "Total Students",
              "2,450",
              Icons.groups_rounded,
              const Color(0xFF00E5FF),
              cardWidth,
            ),
            _buildMetricGlassCard(
              "Active Faculty",
              "84",
              Icons.badge_rounded,
              const Color(0xFF10B981),
              cardWidth,
            ),
            _buildMetricGlassCard(
              "Pending Intake",
              "18",
              Icons.pending_actions_rounded,
              const Color(0xFFF59E0B),
              cardWidth,
            ),
            _buildMetricGlassCard(
              "Live Classrooms",
              "32",
              Icons.meeting_room_rounded,
              const Color(0xFF7B61FF),
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricGlassCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(16),
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
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Geist',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
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

  // ── ACTION GATEWAYS GRID ──────────────────────────────────────────────────
  Widget _buildActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CPI Admin Services",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildActionTile(
              title: "Routine Override",
              subtitle: "Class swaps & schedules",
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF2563EB),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RoutineOverrideSheet(),
              ),
            ),
            _buildActionTile(
              title: "Assessments Marks",
              subtitle: "Ingest TC/PC scores",
              icon: Icons.assessment_rounded,
              color: const Color(0xFF7B61FF),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AssessmentMarksSheet(),
              ),
            ),
            _buildActionTile(
              title: "Attendance Logger",
              subtitle: "Mass log & exemptions",
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF16A34A),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AttendanceLoggerSheet(),
              ),
            ),
            _buildActionTile(
              title: "Admit Clearance",
              subtitle: "Regulate exam tokens",
              icon: Icons.badge_rounded,
              color: const Color(0xFFD97706),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AdmitClearanceSheet(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _InteractiveScaleButton(
      onTap: onTap,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(125),
                fontSize: 9.5,
                fontFamily: 'Geist',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── EMERGENCY OVERRIDE BANNER ──────────────────────────────────────────────
  Widget _buildEmergencyBannerToggle() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: _isEmergencyModeActive
          ? const Color(0xFFEF4444).withAlpha(150)
          : Colors.white.withAlpha(30),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: Colors.white.withAlpha(140),
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
    );
  }

  // ── SEMESTER SELECTOR CHIPS ──────────────────────────────────────────────
  Widget _buildSemesterChipsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Academic Target Semester",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
            letterSpacing: 0.5,
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
                          : Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : Colors.white.withAlpha(25),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      "$semIndex${_getOrdinalSuffix(semIndex)} Sem",
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : Colors.white.withAlpha(150),
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

  // ── LIVE SYSTEM TERMINAL ──────────────────────────────────────────────────
  Widget _buildLiveSystemTerminal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Live System Dispatch Logs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildGlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _TerminalLogRow(
                time: "15:24",
                action: "NOTICE_BROADCAST",
                details: "Midterm Exam Routine Published for CST 6th Sem",
                color: Color(0xFF00E5FF),
              ),
              SizedBox(height: 8),
              _TerminalLogRow(
                time: "14:10",
                action: "ROOM_SWAP",
                details: "Class CST-601 moved to Rm 402 for Lab Slot",
                color: Color(0xFFF59E0B),
              ),
              SizedBox(height: 8),
              _TerminalLogRow(
                time: "12:05",
                action: "MARKS_INGEST",
                details: "24 Assessment Records updated by Admin",
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── DEPARTMENTS MATRIX ───────────────────────────────────────────────────
  Widget _buildDepartmentSection() {
    final depts = [
      _DeptData(
        name: "Computer Science & Tech",
        short: "CST",
        students: 480,
        health: 0.98,
      ),
      _DeptData(
        name: "Electronics Tech",
        short: "ET",
        students: 310,
        health: 0.95,
      ),
      _DeptData(
        name: "Civil Tech",
        short: "CIVIL",
        students: 400,
        health: 0.92,
      ),
      _DeptData(
        name: "Mechanical Tech",
        short: "MECH",
        students: 360,
        health: 0.94,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Department Matrix",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: depts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final dept = depts[index];
            return _buildGlassContainer(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(80),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dept.short,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Enrolled Students: ${dept.students}",
                          style: TextStyle(
                            color: Colors.white.withAlpha(125),
                            fontSize: 11,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${(dept.health * 100).toInt()}% Active",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── EXACT STUDENT DASHBOARD GLASS BOTTOM NAVBAR ───────────────────────────
  Widget _buildOriginalGlassNavbar() {
    return _buildNavbarGlassContainer(
      borderRadius: 24,
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
                    color: const Color(0xFFF59E0B).withAlpha(35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withAlpha(60),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withAlpha(15),
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
                _buildNavbarItem(Icons.grid_view_rounded, "Overview", index: 0),
                _buildNavbarItem(Icons.tune_rounded, "Controls", index: 1),
                _buildNavbarItem(
                  Icons.supervisor_account_rounded,
                  "Faculty",
                  index: 2,
                  onTapOverride: () =>
                      _showQuickActionSnackBar("Faculty Directory"),
                ),
                _buildNavbarItem(Icons.settings_outlined, "Settings", index: 3),
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
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withAlpha(16), Colors.white.withAlpha(4)],
            ),
            border: Border.all(color: Colors.white.withAlpha(30), width: 1.0),
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
    VoidCallback? onTapOverride,
  }) {
    final active = _selectedNavIndex == index;
    final activeColor = active ? const Color(0xFFF59E0B) : Colors.white38;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTapOverride != null) {
            onTapOverride();
          } else {
            if (mounted) {
              setState(() {
                _selectedNavIndex = index;
              });
            }
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

  // ── REUSABLE GLASS CONTAINER ──────────────────────────────────────────────
  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? Colors.white.withAlpha(12),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── INTERACTIVE SCALE BUTTON WIDGET ───────────────────────────────────────
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

// ── TERMINAL LOG ROW WIDGET ────────────────────────────────────────────────
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "[$time]",
          style: TextStyle(
            color: Colors.white.withAlpha(100),
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
              color: Colors.white.withAlpha(200),
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

class _DeptData {
  final String name;
  final String short;
  final int students;
  final double health;

  _DeptData({
    required this.name,
    required this.short,
    required this.students,
    required this.health,
  });
}
