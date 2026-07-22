// =============================================================================
// lib/views/admin/admin_dashboard.dart
// CPI Admin Command Center — High-Tech Cyberpunk & Glassmorphism Interface
// Features:
//   • Full Operational Gateways (Routine, Notices, Marks, Attendance, Clearance)
//   • Live System Terminal Activity Feed
//   • iOS Frosted Glass Floating Navbar Dock
//   • Dynamic Pulsing Ambient Mesh Shaders
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../models/user.dart';
import '../../core/router.dart';
import '../components/admin_input_sheet.dart';
import '../components/admin_operations_sheets.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _pulseController;
  late AnimationController _entryController;

  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  int _selectedSemester = 4;
  int _activeNavIndex = 0;
  bool _isEmergencyModeActive = false;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.decelerate),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _showBroadcastNoticeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const AdminInputSheet(),
    );
  }

  void _showQuickActionSnackBar(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              "Launching $title Modal...",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
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
        backgroundColor: const Color(0xFF030712),
        body: Stack(
          children: [
            // ── 1. DYNAMIC ANIMATED MESH BG ───────────────────────────────────
            AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CyberMeshBgPainter(
                    progress: _bgAnimController.value,
                  ),
                );
              },
            ),

            // ── 2. SCROLLABLE DASHBOARD CONTENT ─────────────────────────────
            SafeArea(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Opacity(opacity: _fadeAnim.value, child: child),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildEmergencyBannerToggle(),
                      const SizedBox(height: 20),
                      _buildMetricsGrid(),
                      const SizedBox(height: 28),
                      _buildActionGrid(),
                      const SizedBox(height: 28),
                      _buildSemesterChipsBlock(),
                      const SizedBox(height: 28),
                      _buildLiveSystemTerminal(),
                      const SizedBox(height: 28),
                      _buildDepartmentSection(),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. iOS FROSTED GLASS FLOATING NAVBAR ─────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _buildIosGlassNavbar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER WITH LIVE HEARTBEAT ──────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFF030712),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isEmergencyModeActive
                              ? const Color(0xFFEF4444)
                              : Colors.cyanAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isEmergencyModeActive
                                          ? const Color(0xFFEF4444)
                                          : Colors.cyanAccent)
                                      .withOpacity(_pulseController.value),
                              blurRadius: 8 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEmergencyModeActive
                        ? "ALERT MODE ACTIVE • ID: ${widget.user.displayId}"
                        : "COMMAND NODE ONLINE • ID: ${widget.user.displayId}",
                    style: TextStyle(
                      color: _isEmergencyModeActive
                          ? const Color(0xFFEF4444)
                          : Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          icon: const Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFFFF6B6B),
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.06),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── EMERGENCY OVERRIDE BANNER ──────────────────────────────────────────────
  Widget _buildEmergencyBannerToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isEmergencyModeActive
            ? const Color(0xFFEF4444).withOpacity(0.15)
            : const Color(0xFF0F172A).withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isEmergencyModeActive
              ? const Color(0xFFEF4444)
              : Colors.white.withOpacity(0.12),
          width: _isEmergencyModeActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isEmergencyModeActive
                  ? const Color(0xFFEF4444).withOpacity(0.2)
                  : Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEmergencyModeActive
                  ? Icons.warning_amber_rounded
                  : Icons.shield_rounded,
              color: _isEmergencyModeActive
                  ? const Color(0xFFEF4444)
                  : Colors.amber,
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
                      ? "Pushing instant alert banners to all student dashboards."
                      : "System operating under normal academic schedules.",
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEmergencyModeActive,
            activeColor: const Color(0xFFEF4444),
            onChanged: (value) {
              setState(() {
                _isEmergencyModeActive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── METRIC CARDS GRID ─────────────────────────────────────────────────────
  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildIosGlassMetricCard(
              title: "Total Students",
              value: "2,450",
              icon: Icons.groups_rounded,
              color: Colors.cyanAccent,
              width: cardWidth,
            ),
            _buildIosGlassMetricCard(
              title: "Active Faculty",
              value: "84",
              icon: Icons.badge_rounded,
              color: const Color(0xFF10B981),
              width: cardWidth,
            ),
            _buildIosGlassMetricCard(
              title: "Pending Intake",
              value: "18",
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFF59E0B),
              width: cardWidth,
            ),
            _buildIosGlassMetricCard(
              title: "Live Classrooms",
              value: "32",
              icon: Icons.meeting_room_rounded,
              color: const Color(0xFFA855F7),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildIosGlassMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Geist',
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ACTION GATEWAYS GRID (FULL OPERATIONS CONTROL) ────────────────────────
  Widget _buildActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Admin Operation Control Gateways",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildIosActionTile(
              title: "Broadcast Notice",
              subtitle: "Publish campus notices",
              icon: Icons.campaign_rounded,
              color: Colors.cyanAccent,
              onTap: _showBroadcastNoticeSheet,
            ),
            _buildIosActionTile(
              title: "Routine & Slot Override",
              subtitle: "Class swaps & schedules",
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RoutineOverrideSheet(),
              ),
            ),
            _buildIosActionTile(
              title: "Assessments Marks",
              subtitle: "Ingest TC/PC scores",
              icon: Icons.analytics_rounded,
              color: const Color(0xFFA855F7),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AssessmentMarksSheet(),
              ),
            ),
            _buildIosActionTile(
              title: "Attendance Logger",
              subtitle: "Mass log & exemptions",
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF10B981),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AttendanceLoggerSheet(),
              ),
            ),
            _buildIosActionTile(
              title: "Admit Clearance",
              subtitle: "Regulate exam tokens",
              icon: Icons.verified_user_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AdmitClearanceSheet(),
              ),
            ),
            _buildIosActionTile(
              title: "Faculty Directory",
              subtitle: "Teacher profiles & status",
              icon: Icons.supervisor_account_rounded,
              color: const Color(0xFFEC4899),
              onTap: () => _showQuickActionSnackBar("Faculty Directory"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIosActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Icon(icon, color: color, size: 18),
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
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontFamily: 'Geist',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SEMESTER CHIPS ────────────────────────────────────────────────────────
  Widget _buildSemesterChipsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Academic Semester Target",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(8, (index) {
            final semIndex = index + 1;
            final isSelected = _selectedSemester == semIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedSemester = semIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : const Color(0xFF0F172A).withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  "$semIndex${_getOrdinalSuffix(semIndex)} Sem",
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontFamily: 'Geist',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
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

  // ── REAL-TIME LIVE SYSTEM TERMINAL ────────────────────────────────────────
  Widget _buildLiveSystemTerminal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Colors.cyanAccent, size: 18),
            SizedBox(width: 8),
            Text(
              "Live System Dispatch Logs",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: 'Geist',
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TerminalLogRow(
                time: "15:24",
                action: "NOTICE_BROADCAST",
                details: "Midterm Exam Routine Published for CST 6th Sem",
                color: Colors.cyanAccent,
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

  // ── DEPARTMENTS MATRIX ────────────────────────────────────────────────────
  Widget _buildDepartmentSection() {
    final depts = [
      _DeptData(
        name: "Computer Science & Technology",
        short: "CST",
        students: 480,
        faculty: 12,
        health: 0.98,
      ),
      _DeptData(
        name: "Electronics Technology",
        short: "ET",
        students: 310,
        faculty: 8,
        health: 0.95,
      ),
      _DeptData(
        name: "Civil Technology",
        short: "CIVIL",
        students: 400,
        faculty: 10,
        health: 0.92,
      ),
      _DeptData(
        name: "Mechanical Technology",
        short: "MECH",
        students: 360,
        faculty: 9,
        health: 0.94,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Technical Departments Matrix",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
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
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dept.short,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
                          dept.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Students: ${dept.students}  •  Faculty: ${dept.faculty}",
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${(dept.health * 100).toInt()}%",
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const Text(
                        "Activity",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── iOS GLASS FLOATING BOTTOM NAVBAR ──────────────────────────────────────
  Widget _buildIosGlassNavbar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.70),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIosNavItem(0, Icons.grid_view_rounded, "Overview"),
                _buildIosNavItem(
                  1,
                  Icons.campaign_rounded,
                  "Notices",
                  onTapOverride: _showBroadcastNoticeSheet,
                ),
                _buildIosNavItem(
                  2,
                  Icons.supervisor_account_rounded,
                  "Faculty",
                ),
                _buildIosNavItem(3, Icons.settings_rounded, "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIosNavItem(
    int index,
    IconData icon,
    String label, {
    VoidCallback? onTapOverride,
  }) {
    final bool isSelected = _activeNavIndex == index;
    return InkWell(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          setState(() => _activeNavIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Colors.cyanAccent.withOpacity(0.4),
                  width: 1.2,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.cyanAccent : const Color(0xFF94A3B8),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ],
        ),
      ),
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
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
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
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
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

// ── CYBER BG SHADER PAINTER ─────────────────────────────────────────────────
class _CyberMeshBgPainter extends CustomPainter {
  final double progress;

  _CyberMeshBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double shiftX = math.sin(progress * math.pi * 2) * 30;
    final double shiftY = math.cos(progress * math.pi * 2) * 20;

    final Paint amberPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFF59E0B).withOpacity(0.14),
              const Color(0xFFF59E0B).withOpacity(0.02),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                (size.width * 0.85) + shiftX,
                (size.height * 0.12) + shiftY,
              ),
              radius: 220,
            ),
          );
    canvas.drawCircle(
      Offset((size.width * 0.85) + shiftX, (size.height * 0.12) + shiftY),
      220,
      amberPaint,
    );

    final Paint cyanPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.cyanAccent.withOpacity(0.12),
              Colors.cyanAccent.withOpacity(0.01),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                (size.width * 0.15) - shiftX,
                (size.height * 0.65) - shiftY,
              ),
              radius: 240,
            ),
          );
    canvas.drawCircle(
      Offset((size.width * 0.15) - shiftX, (size.height * 0.65) - shiftY),
      240,
      cyanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberMeshBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DeptData {
  final String name;
  final String short;
  final int students;
  final int faculty;
  final double health;

  _DeptData({
    required this.name,
    required this.short,
    required this.students,
    required this.faculty,
    required this.health,
  });
}
