import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/colors.dart';
import '../../core/theme_provider.dart';
import '../../../widgets/animated_background_painter.dart';
import '../../services/supabase_service.dart';

class AttendanceDetailView extends StatefulWidget {
  const AttendanceDetailView({super.key, required this.user});

  final AppUser user;

  @override
  State<AttendanceDetailView> createState() => _AttendanceDetailViewState();
}

class _AttendanceDetailViewState extends State<AttendanceDetailView>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _subjectsAttendance = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _totalPresent = 0;
  int _totalAbsent = 0;
  int _totalClasses = 0;
  double _overallPercentage = 0.0;
  final List<String> _lowAttendanceSubjects = [];

  late AnimationController _radialController;
  late Animation<double> _radialAnimation;
  late AnimationController _backgroundAnimationController;

  @override
  void initState() {
    super.initState();

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _radialAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _radialController, curve: Curves.easeOutCubic),
    );

    _fetchAttendanceData();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _radialController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) {
        setState(() {
          _errorMessage = 'No roll number found';
          _isLoading = false;
        });
        return;
      }

      final attendanceData = await SupabaseService.instance
          .fetchStudentAttendance(rollNumber);

      if (attendanceData.isEmpty) {
        setState(() {
          _subjectsAttendance = [];
          _isLoading = false;
          _errorMessage = 'No attendance records found for roll: $rollNumber';
        });
        return;
      }

      setState(() {
        _subjectsAttendance = attendanceData;
        _calculateOverallStats();
        _isLoading = false;
        _errorMessage = null;
      });

      _radialController.reset();
      _radialAnimation =
          Tween<double>(begin: 0.0, end: _overallPercentage / 100.0).animate(
            CurvedAnimation(
              parent: _radialController,
              curve: Curves.easeOutCubic,
            ),
          );
      _radialController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateOverallStats() {
    _totalPresent = 0;
    _totalAbsent = 0;
    _totalClasses = 0;
    _lowAttendanceSubjects.clear();

    for (var subject in _subjectsAttendance) {
      final present = subject['present_classes'] as int? ?? 0;
      final absent = subject['absent_classes'] as int? ?? 0;
      final total = subject['total_classes'] as int? ?? 0;

      _totalPresent += present;
      _totalAbsent += absent;
      _totalClasses += total;

      final percentage = total > 0 ? (present / total) * 100 : 0.0;
      if (percentage < 75.0 && total > 0) {
        _lowAttendanceSubjects.add(
          subject['subject_name'] ?? 'Unknown Subject',
        );
      }
    }

    _overallPercentage = _totalClasses > 0
        ? (_totalPresent / _totalClasses) * 100
        : 0.0;
  }

  String _generateSubjectCode(String subjectName) {
    if (subjectName.isEmpty) return 'N/A';
    final words = subjectName.split(' ');
    if (words.length == 1) {
      return subjectName
          .substring(0, words[0].length > 4 ? 4 : words[0].length)
          .toUpperCase();
    }
    return words.map((w) => w[0]).join('').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : Colors.transparent,
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
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Warning card removed - data is loading successfully
                // if (_errorMessage != null && !_isLoading && _subjectsAttendance.isEmpty)
                //   SliverToBoxAdapter(
                //     child: Padding(
                //       padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 8.0),
                //       child: _buildWarningAlertCard(isDark),
                //     ),
                //   ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGlassRoundButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                          isDark: isDark,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attendance Report",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightPrimaryText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Historical Attendance & Subject Records",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.lightSubtitleText,
                                    fontSize: 11,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_isLoading && _errorMessage == null)
                          _buildMiniTotalBadge(isDark),
                      ],
                    ),
                  ),
                ),

                if (_isLoading) _buildLoadingState(isDark),

                // Error State - Only show when there's an error and no data
                if (_errorMessage != null &&
                    !_isLoading &&
                    _subjectsAttendance.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 40.0,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: isDark
                                ? Colors.red.withValues(alpha: 0.6)
                                : Colors.red.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Attendance Records",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _fetchAttendanceData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Retry",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_isLoading &&
                    _errorMessage == null &&
                    _subjectsAttendance.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: _buildGlassCard(
                        isDark: isDark,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: AnimatedBuilder(
                                  animation: _radialAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: CircularProgressIndicator(
                                            value: _radialAnimation.value,
                                            strokeWidth: 10,
                                            backgroundColor: isDark
                                                ? Colors.white10
                                                : AppColors.lightCardBorderAlt,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF10B981)),
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        Text(
                                          "${(_radialAnimation.value * 100.0).toStringAsFixed(1)}%",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.lightPrimaryText,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${_subjectsAttendance.isNotEmpty ? _subjectsAttendance[0]['semester'] ?? 'Current' : 'Current'} Semester Attendance",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightPrimaryText,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Running Term • $_totalClasses Classes Total",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.lightCaptionText,
                                        fontSize: 12,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _buildStatusBadge(
                                          "${_subjectsAttendance.length} Subjects",
                                          AppColors.lightCaptionText,
                                          isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildStatusBadge(
                                          "$_totalPresent Attended",
                                          const Color(0xFF10B981),
                                          isDark,
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

                if (!_isLoading &&
                    _errorMessage == null &&
                    _subjectsAttendance.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No Attendance Records",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightPrimaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No attendance data found for roll: ${widget.user.rollNumber ?? 'N/A'}",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 13,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_isLoading &&
                    _errorMessage == null &&
                    _subjectsAttendance.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 22.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        "Subject Breakdown Details",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : AppColors.lightCaptionText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),

                if (!_isLoading &&
                    _errorMessage == null &&
                    _subjectsAttendance.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final subject = _subjectsAttendance[index];
                        final present = subject['present_classes'] as int? ?? 0;
                        final absent = subject['absent_classes'] as int? ?? 0;
                        final total = subject['total_classes'] as int? ?? 0;
                        final percentage = total > 0
                            ? (present / total) * 100
                            : 0.0;

                        final subjectName =
                            subject['subject_name']?.toString() ?? 'Unknown';
                        final subjectCode = _generateSubjectCode(subjectName);

                        Color statusColor = const Color(0xFF00E5FF);
                        String customGradePill = "A";
                        if (percentage < 60) {
                          statusColor = const Color(0xFFFF6B6B);
                          customGradePill = "F";
                        } else if (percentage < 75) {
                          statusColor = const Color(0xFFFFB74D);
                          customGradePill = "B";
                        } else if (percentage >= 85) {
                          statusColor = const Color(0xFF10B981);
                          customGradePill = "A+";
                        }

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 350 + (index * 150)),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1.0 - animValue)),
                              child: Opacity(
                                opacity: animValue,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildSubjectAttendanceGlassCard(
                                    subject: subject,
                                    subjectCode: subjectCode,
                                    present: present,
                                    absent: absent,
                                    total: total,
                                    percentage: percentage,
                                    statusColor: statusColor,
                                    customGradePill: customGradePill,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }, childCount: _subjectsAttendance.length),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAttendanceGlassCard({
    required Map<String, dynamic> subject,
    required String subjectCode,
    required int present,
    required int absent,
    required int total,
    required double percentage,
    required Color statusColor,
    required String customGradePill,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(8)
                : AppColors.lightBackground.withAlpha(230),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : AppColors.lightCardBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['subject_name'] ?? 'Unknown Subject',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightPrimaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$subjectCode • ${subject['teacher_name'] ?? 'Faculty'}",
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
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(15),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withAlpha(30)),
                        ),
                        child: Center(
                          child: Text(
                            customGradePill,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            percentage.toStringAsFixed(1),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const Text(
                            "RATE",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataMetricItem("TC", "$total", "/$total", isDark),
                  _buildDataMetricItem("PC", "$present", "/$total", isDark),
                  _buildDataMetricItem("AC", "$absent", "/$total", isDark),
                  _buildDataMetricItem(
                    "Ratio",
                    "${((total > 0 ? present / total : 0) * 100).toStringAsFixed(0)}%",
                    "",
                    isDark,
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 5,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: percentage / 100.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    builder: (context, val, child) {
                      return LinearProgressIndicator(
                        value: val,
                        backgroundColor: isDark
                            ? Colors.white.withAlpha(12)
                            : AppColors.lightCardBorderAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : AppColors.lightCaptionText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
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

  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(10)
                : AppColors.lightBackground.withAlpha(235),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : AppColors.lightCardBorder,
              width: 1.2,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : AppColors.lightCardBorder,
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTotalBadge(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2563EB).withAlpha(50),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _overallPercentage.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                ),
              ),
              const Text(
                "TOTAL",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
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

  Widget _buildStatusBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildDataMetricItem(
    String label,
    String value,
    String totalText,
    bool isDark, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : AppColors.lightCaptionText,
            fontSize: 10,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isBold
                    ? (isDark
                          ? const Color(0xFF00E5FF)
                          : AppColors.lightPrimaryText)
                    : (isDark ? Colors.white : AppColors.lightSubtitleText),
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            if (totalText.isNotEmpty) ...[
              const SizedBox(width: 1),
              Text(
                totalText,
                style: TextStyle(
                  color: isDark ? Colors.white24 : AppColors.lightCaptionText,
                  fontSize: 9,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWarningAlertCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withAlpha(isDark ? 15 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withAlpha(35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFFCA5A5),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Could not fetch live report",
                      style: TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _errorMessage ?? "Unknown error",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightCaptionText,
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFFFCA5A5),
                  size: 18,
                ),
                onPressed: _fetchAttendanceData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 90.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
    );
  }
}
