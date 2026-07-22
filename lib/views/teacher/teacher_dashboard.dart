// =============================================================================
// lib/views/teacher/teacher_dashboard.dart
// Teacher Dashboard — Chittagong Polytechnic Institute Faculty Portal.
// Features:
//   • Animated ambient background mesh paint
//   • Dynamic profile header (Teacher Name, Employee ID, Department info)
//   • Live ongoing lecture timeline tracker (real-time countdown & schedule)
//   • Faculty management matrix (courses and department active statistics)
//   • Operations control grid (Record Attendance, Upload Marks)
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';



import '../../core/router.dart';
import '../../models/user.dart';

class TeacherDashboard extends StatefulWidget {
  final AppUser user;

  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ScrollController _scrollController;

  Timer? _profileBgTimer;
  Timer? _timeCheckerTimer;

  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  double _scrollOffset = 0.0;
  int _currentBgIndex = 0;

  String _currentClassDisplay = "No Active Lecture";
  String _nextClassDisplay = "Day Completed / No Class";

  final List<String> _bgAssets = [
    'assets/cpi_bg.png',
    'assets/cpi_bg2.png',
    'assets/cpi_bg3.png',
  ];

  // Routine Matrix Configuration for Teachers (CMT Department Node)
  final Map<String, List<Map<String, dynamic>>> _teacherRoutine = {
    'SUN': [
      {
        'subject': 'Data Structures',
        'room': '302',
        'class': 'CMT-3rd-A',
        'start': '08:00',
        'end': '09:30',
      },
      {
        'subject': 'Microprocessor Lab',
        'room': 'LAB-2',
        'class': 'CMT-5th-B',
        'start': '10:00',
        'end': '12:15',
      },
    ],
    'MON': [
      {
        'subject': 'OOP in Java',
        'room': '204',
        'class': 'CMT-3rd-B',
        'start': '09:30',
        'end': '11:00',
      },
    ],
    'TUE': [
      {
        'subject': 'Data Structures',
        'room': '302',
        'class': 'CMT-3rd-A',
        'start': '08:00',
        'end': '09:30',
      },
    ],
    'WED': [
      {
        'subject': 'System Analysis',
        'room': '401',
        'class': 'CMT-5th-A',
        'start': '11:00',
        'end': '12:30',
      },
    ],
    'THU': [
      {
        'subject': 'OOP in Java',
        'room': 'LAB-1',
        'class': 'CMT-3rd-B',
        'start': '08:00',
        'end': '10:15',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.decelerate),
      ),
    );

    _contentAnimationController.forward();
    _updateLiveScheduleEngine();

    _profileBgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(
          () => _currentBgIndex = (_currentBgIndex + 1) % _bgAssets.length,
        );
      }
    });

    _timeCheckerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _updateLiveScheduleEngine(),
    );
  }

  void _updateLiveScheduleEngine() {
    final now = DateTime.now();
    final List<String> weekDays = [
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ];
    String currentDayStr = weekDays[now.weekday % 7];

    if (!_teacherRoutine.containsKey(currentDayStr)) {
      if (mounted) {
        setState(() {
          _currentClassDisplay = "No Active Lectures";
          _nextClassDisplay = "Weekend / Off-duty block";
        });
      }
      return;
    }

    final todayClasses = _teacherRoutine[currentDayStr]!;
    String activeClass = "No Active Lecture";
    String nextClass = "Day Completed";
    int currentMinutes = (now.hour * 60) + now.minute;

    for (int i = 0; i < todayClasses.length; i++) {
      final c = todayClasses[i];
      final startParts = c['start'].split(':');
      final endParts = c['end'].split(':');
      int startMins =
          (int.parse(startParts[0]) * 60) + int.parse(startParts[1]);
      int endMins = (int.parse(endParts[0]) * 60) + int.parse(endParts[1]);

      if (currentMinutes >= startMins && currentMinutes < endMins) {
        activeClass = "${c['subject']} • ${c['class']} (Rm ${c['room']})";
        if (i + 1 < todayClasses.length) {
          final nextC = todayClasses[i + 1];
          nextClass =
              "${nextC['subject']} at ${nextC['start']} for ${nextC['class']}";
        }
        break;
      } else if (currentMinutes < startMins) {
        nextClass = "${c['subject']} at ${c['start']} (${c['class']})";
        break;
      }
    }

    if (mounted) {
      setState(() {
        _currentClassDisplay = activeClass;
        _nextClassDisplay = nextClass;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _profileBgTimer?.cancel();
    _timeCheckerTimer?.cancel();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double calculatedAlpha = (90 + (_scrollOffset * 0.85)).clamp(90.0, 255.0);
    double dynamicImageOpacity = (1.0 - (_scrollOffset / 140.0)).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. PINNED BACKGROUND CANVAS LAYER
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
                        errorBuilder: (c, e, s) =>
                            Container(color: const Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withAlpha(calculatedAlpha.toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FIXED TOOLBAR LAYER (Clean Profile Frame Context)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 130,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 48.0, 20.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.user.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Geist',
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Faculty • Dept: ${widget.user.department?.shortCode ?? 'CST'}",
                                style: TextStyle(
                                  color: Colors.white.withAlpha(160),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      backgroundColor: Colors.white.withAlpha(12),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. MAIN SMOOTH SCROLL OVERLAPPING SHELF
          Positioned(
            top: 132,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _contentAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withAlpha(25),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        24.0,
                        20.0,
                        40.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live active assignment track
                          _buildLiveTickerTrack(),
                          const SizedBox(height: 28),

                          const Text(
                            "Faculty Control Center",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Operations matrix links
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                            children: [
                              _buildActionTile(
                                "Record Attendance",
                                Icons.fact_check_rounded,
                                const Color(0xFF67E8F9),
                                () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.attendanceLogger,
                                    arguments: AttendanceLoggerArgs(
                                      teacher: widget.user,
                                      subjectCode: '66641',
                                      className: 'CMT-4th-B2',
                                      semester: 4,
                                    ),
                                  );
                                },
                              ),
                              _buildActionTile(
                                "Upload Marks Ledger",
                                Icons.drive_file_rename_outline_rounded,
                                const Color(0xFF60A5FA),
                                () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.marksUploader,
                                    arguments: MarksUploaderArgs(
                                      teacher: widget.user,
                                      subjectCode: '66641',
                                      subjectName: 'Data Structures',
                                      semester: 4,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // NEW: Faculty Course Management & Status Grid
                          const Text(
                            "Faculty Course Assignments",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFacultyManagementGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTickerTrack() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF67E8F9).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radar_rounded,
              color: Color(0xFF67E8F9),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LIVE ACTIVE ASSIGNMENT",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentClassDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Next Up: $_nextClassDisplay",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

  Widget _buildFacultyManagementGrid() {
    final List<Map<String, String>> courses = [
      {
        'code': '6641',
        'name': 'Application Development',
        'class': 'CMT-4th-B2',
        'lectures': '23/26 completed',
        'status': 'Ongoing',
      },
      {
        'code': '6642',
        'name': 'Computer Networking',
        'class': 'CMT-4th-A1',
        'lectures': '21/28 completed',
        'status': 'Ongoing',
      },
      {
        'code': '6643',
        'name': 'Cyber Security',
        'class': 'CMT-4th-B2',
        'lectures': '29/30 completed',
        'status': 'Wrap Up',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = courses[index];
        final isWrapUp = course['status'] == 'Wrap Up';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      (isWrapUp
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    course['code']!,
                    style: TextStyle(
                      color: isWrapUp
                          ? const Color(0xFF10B981)
                          : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
                      course['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${course['class']} • ${course['lectures']}",
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
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
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        (isWrapUp
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  course['status']!.toUpperCase(),
                  style: TextStyle(
                    color: isWrapUp
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
