import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/router.dart';
import '../../core/theme_provider.dart';
import '../../views/student/student_search_delegate.dart';
import '../../../widgets/theme_toggle_switch.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';
import '../../services/routine_service.dart';
import '../../services/database_service.dart';
import '../../models/notice_model.dart';
import '../../models/assessment_model.dart';
import 'support_view.dart';
import 'alerts_view.dart';
import 'profile_view.dart';
import 'routine_view.dart';
import 'admit_card_view.dart';
import 'notice_board_screen.dart';
import 'about_institution_view.dart';
import 'privacy_policy_view.dart';
import 'help_support_view.dart';
import 'syllabus_view.dart';

class StudentDashboard extends StatefulWidget {
  final AppUser user;

  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late PageController _pageController;

  Timer? _profileBgTimer;
  Timer? _carouselAutoScrollTimer;

  late RoutineService _routineService;
  StreamSubscription<List<RoutineEntry>>? _routineSubscription;

  // ✅ Notice Stream
  StreamSubscription<List<NoticeModel>>? _noticeSubscription;
  List<NoticeModel> _latestNotices = [];
  List<Map<String, String>> _noticeOffers = [];

  // ✅ Assessment Data
  List<AssessmentModel> _assessments = [];
  bool _isAssessmentsLoading = true;

  late AnimationController _contentAnimationController;
  late AnimationController _shimmerAnimationController;
  late AnimationController _staggerController;

  late Animation<double> _attendanceCountAnimation;
  late Animation<double> _cgpaCountAnimation;
  late Animation<double> _shimmerLinearAnimation;
  late Animation<double> _staggerAnimation;

  final PageController _carouselPageController = PageController(initialPage: 0);
  int _currentCarouselPage = 0;
  double _scrollOffset = 0.0;
  int _currentBgIndex = 0;
  int _selectedNavIndex = 0;

  // Real data from Supabase
  double _realAttendance = 0.0;
  double _realCGPA = 0.0;
  bool _isDataLoaded = false;

  String _currentClassDisplay = "No Active Class";
  String _nextClassDisplay = "Day Completed / No Class";

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

    _shimmerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _attendanceCountAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _cgpaCountAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _shimmerLinearAnimation = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _shimmerAnimationController,
        curve: Curves.linear,
      ),
    );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );

    _routineService = RoutineService(SupabaseService.client);
    _listenToRoutineUpdates();
    _fetchRealData();
    _listenToNotices();
    _fetchAssessments();

    _profileBgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgAssets.length;
        });
      }
    });

    _carouselAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) {
      if (_carouselPageController.hasClients) {
        _currentCarouselPage =
            (_currentCarouselPage + 1) % _noticeOffers.length;
        _carouselPageController.animateToPage(
          _currentCarouselPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    AppThemeController.themeModeNotifier.addListener(_themeListener);
  }

  void _handlePageChange() {
    if (_pageController.hasClients && _pageController.page != null) {
      final currentIndex = _pageController.page!.round();
      if (_selectedNavIndex != currentIndex) {
        setState(() {
          _selectedNavIndex = currentIndex;
        });
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

    _attendanceCountAnimation = Tween<double>(begin: 0.0, end: _realAttendance)
        .animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _cgpaCountAnimation = Tween<double>(begin: 0.0, end: _realCGPA).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _contentAnimationController.forward();
    _staggerController.forward();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  // ✅ Fetch assessments
  Future<void> _fetchAssessments() async {
    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) {
        setState(() => _isAssessmentsLoading = false);
        return;
      }

      final assessments = await SupabaseService.instance
          .fetchStudentAssessments(rollNumber);

      if (!mounted) return;
      setState(() {
        _assessments = assessments;
        _isAssessmentsLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching assessments: $e');
      if (mounted) setState(() => _isAssessmentsLoading = false);
    }
  }

  // ✅ Listen to real-time notices
  void _listenToNotices() {
    _noticeSubscription = DatabaseService().getNoticesStream().listen(
      (notices) {
        if (!mounted) return;

        setState(() {
          _latestNotices = notices.take(3).toList();

          _noticeOffers = _latestNotices.map((notice) {
            return {
              'title': notice.title,
              'subtitle': notice.content.length > 60
                  ? '${notice.content.substring(0, 60)}...'
                  : notice.content,
              'tag': notice.category,
              'color': _getCategoryColor(notice.category),
            };
          }).toList();

          if (_noticeOffers.isNotEmpty &&
              _currentCarouselPage >= _noticeOffers.length) {
            _currentCarouselPage = 0;
            if (_carouselPageController.hasClients) {
              _carouselPageController.jumpToPage(0);
            }
          }
        });
      },
      onError: (error) {
        print('❌ Notice stream error: $error');
        if (mounted) {
          setState(() {
            _noticeOffers = [
              {
                'title': '📢 Welcome to CPI Portal',
                'subtitle': 'No notices available yet. Check back later!',
                'tag': 'GENERAL',
                'color': '0xFF7C3AED',
              },
            ];
          });
        }
      },
    );
  }

  String _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'EXAMINATION':
        return '0xFF0284C7';
      case 'ADMISSION':
        return '0xFF2563EB';
      case 'ROUTINE':
        return '0xFF16A34A';
      case 'EVENT':
        return '0xFF3B82F6';
      case 'OFFER':
        return '0xFFD97706';
      case 'GENERAL':
      default:
        return '0xFF7C3AED';
    }
  }

  Future<void> _fetchRealData() async {
    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) return;

      final attendanceData = await SupabaseService.instance
          .fetchStudentAttendance(rollNumber);

      if (attendanceData.isNotEmpty) {
        int totalPresent = 0;
        int totalClasses = 0;
        for (var subject in attendanceData) {
          totalPresent += subject['present_classes'] as int? ?? 0;
          totalClasses += subject['total_classes'] as int? ?? 0;
        }
        _realAttendance = totalClasses > 0
            ? (totalPresent / totalClasses) * 100
            : 0.0;
      }

      final resultsData = await SupabaseService.instance.fetchStudentResults(
        rollNumber,
      );

      if (resultsData.isNotEmpty) {
        final Map<String, List<Map<String, dynamic>>> semesterGroups = {};
        for (var result in resultsData) {
          final semester = result['semester']?.toString() ?? 'Unknown';
          if (!semesterGroups.containsKey(semester)) {
            semesterGroups[semester] = [];
          }
          semesterGroups[semester]!.add(result);
        }

        double totalGpa = 0.0;
        int semesterCount = 0;

        for (var semester in semesterGroups.keys) {
          final subjects = semesterGroups[semester]!;
          double semesterTotalGp = 0.0;
          int semesterTotalCredits = 0;

          for (var subject in subjects) {
            final gp = (subject['grade_point'] as num?)?.toDouble() ?? 0.0;
            final credits = subject['credits'] as int? ?? 3;
            semesterTotalGp += gp * credits;
            semesterTotalCredits += credits;
          }

          if (semesterTotalCredits > 0) {
            final semesterGpa = semesterTotalGp / semesterTotalCredits;
            totalGpa += semesterGpa;
            semesterCount++;
          }
        }

        _realCGPA = semesterCount > 0 ? totalGpa / semesterCount : 0.0;
      }

      if (!mounted) return;

      setState(() {
        _isDataLoaded = true;
        _attendanceCountAnimation =
            Tween<double>(begin: 0.0, end: _realAttendance).animate(
              CurvedAnimation(
                parent: _contentAnimationController,
                curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
              ),
            );
        _cgpaCountAnimation = Tween<double>(begin: 0.0, end: _realCGPA).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
          ),
        );
        _contentAnimationController.forward(from: 0);
        _staggerController.forward(from: 0);
      });
    } catch (e) {
      print('Error fetching real data: $e');
      _realAttendance = 88.4;
      _realCGPA = 3.86;
      if (!mounted) return;
      setState(() {
        _isDataLoaded = true;
        _contentAnimationController.forward();
        _staggerController.forward();
      });
    }
  }

  // ✅ Listen to routine updates
  void _listenToRoutineUpdates() {
    final department = widget.user.department?.shortCode ?? 'CST';
    final semester = widget.user.semester ?? 6;

    print(
      '📚 Listening to routine updates for $department - Semester $semester',
    );

    _routineSubscription?.cancel();

    _routineSubscription = _routineService
        .getRoutineStream(department, semester)
        .listen(
          (routineEntries) {
            if (!mounted) return;
            print('📊 Received ${routineEntries.length} routine entries');
            _updateCurrentAndNextClassDisplay(routineEntries);
          },
          onError: (error) {
            if (!mounted) return;
            print('❌ Routine stream error: $error');
            setState(() {
              _currentClassDisplay = "Error loading schedule";
              _nextClassDisplay = "Please check your connection";
            });
          },
        );
  }

  void _updateCurrentAndNextClassDisplay(List<RoutineEntry> routineEntries) {
    if (!mounted) return;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    RoutineEntry? currentClass;
    RoutineEntry? nextClass;

    final todayRoutine =
        routineEntries.where((entry) => entry.day == currentDay).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (var entry in todayRoutine) {
      if (currentTime.compareTo(entry.startTime) >= 0 &&
          currentTime.compareTo(entry.endTime) < 0) {
        currentClass = entry;
      } else if (currentTime.compareTo(entry.startTime) < 0) {
        if (nextClass == null ||
            entry.startTime.compareTo(nextClass.startTime) < 0) {
          nextClass = entry;
        }
      }
    }

    if (currentClass != null) {
      setState(() {
        _currentClassDisplay =
            "${currentClass!.subjectName} • Rm ${currentClass.room}";
        if (nextClass != null) {
          _nextClassDisplay =
              "${nextClass.subjectName} at ${_formatTime(nextClass.startTime)} (${nextClass.room})";
        } else {
          _nextClassDisplay = "Day Completed";
        }
      });
    } else if (nextClass != null) {
      setState(() {
        _currentClassDisplay = "No Active Class";
        _nextClassDisplay =
            "${nextClass!.subjectName} at ${_formatTime(nextClass.startTime)} (${nextClass.room})";
      });
    } else {
      RoutineEntry? upcomingClass;
      for (int i = 1; i <= 7; i++) {
        final searchDay = (currentDay % 7) + i;
        final nextDaysRoutine =
            routineEntries.where((entry) => entry.day == searchDay).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (nextDaysRoutine.isNotEmpty) {
          upcomingClass = nextDaysRoutine.first;
          break;
        }
      }

      if (upcomingClass != null) {
        setState(() {
          _currentClassDisplay = "No Active Class";
          _nextClassDisplay =
              "${upcomingClass!.subjectName} on ${_routineService.getDayName(upcomingClass.day)} at ${_formatTime(upcomingClass.startTime)} (${upcomingClass.room})";
        });
      } else {
        setState(() {
          _currentClassDisplay = "No Classes Today";
          _nextClassDisplay = "Enjoy your day off! 🎉";
        });
      }
    }
  }

  String _formatTime(String time) {
    try {
      if (time.isEmpty) return '';
      final parts = time.split(':');
      if (parts.length < 2) return time;
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  Future<void> _updateLiveScheduleEngine() async {
    try {
      final department = widget.user.department?.shortCode ?? 'CST';
      final semester = widget.user.semester ?? 6;

      final current = await _routineService.fetchCurrentClass(
        department,
        semester,
      );
      final next = await _routineService.fetchNextClass(department, semester);

      if (!mounted) return;

      setState(() {
        if (current != null) {
          _currentClassDisplay = "${current.subjectName} • Rm ${current.room}";
        } else {
          _currentClassDisplay = "No Active Class";
        }

        if (next != null) {
          _nextClassDisplay =
              "${next.subjectName} at ${_formatTime(next.startTime)} (${next.room})";
        } else {
          _nextClassDisplay = "Day Completed / No Class";
        }
      });
    } catch (e) {
      print('❌ Error fetching current/next class: $e');
      if (!mounted) return;
      setState(() {
        _currentClassDisplay = "Error loading schedule";
        _nextClassDisplay = "Please check your connection";
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        _listenToRoutineUpdates();
        _fetchRealData();
        _listenToNotices();
        _fetchAssessments();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _scrollController.dispose();
    _pageController.dispose();
    _profileBgTimer?.cancel();
    _carouselAutoScrollTimer?.cancel();
    _routineSubscription?.cancel();
    _noticeSubscription?.cancel();
    _carouselPageController.dispose();
    _contentAnimationController.dispose();
    _shimmerAnimationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
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
                          const Color(0xFF00B2FF).withAlpha(30),
                          const Color(0xFF00B2FF).withAlpha(0),
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
                                0xFF0284C7,
                              ).withAlpha(isDark ? 15 : 30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0284C7).withAlpha(50),
                              ),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Color(0xFF0284C7),
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
                                "Student Options",
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
                      // ✅ About Institution - Navigate to dedicated page
                      _buildDrawerFrostedLinkTile(
                        Icons.info_outline_rounded,
                        "About Institution",
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AboutInstitutionView(user: widget.user),
                            ),
                          );
                        },
                      ),
                      // ✅ Privacy & Policy - Navigate to dedicated page
                      _buildDrawerFrostedLinkTile(
                        Icons.security_rounded,
                        "Privacy & Policy",
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PrivacyPolicyView(user: widget.user),
                            ),
                          );
                        },
                      ),
                      // ✅ Help & Support Desk - Navigate to dedicated page
                      _buildDrawerFrostedLinkTile(
                        Icons.headset_mic_rounded,
                        "Help & Support Desk",
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HelpSupportView(user: widget.user),
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
              Icon(icon, color: const Color(0xFF0284C7), size: 20),
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
                        ? const Color(0xFF67E8F9).withAlpha(35)
                        : const Color(0xFF0284C7).withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF67E8F9).withAlpha(60)
                          : const Color(0xFF0284C7).withAlpha(40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF67E8F9).withAlpha(15)
                            : const Color(0xFF0284C7).withAlpha(10),
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
        ? (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0284C7))
        : (isDark ? Colors.white38 : AppColors.lightSubtitleText);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedNavIndex = index;
          });
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
                      const Color(0xFF00B2FF).withAlpha(35),
                      const Color(0xFF00B2FF).withAlpha(0),
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
                      const Color(0xFF6366F1).withAlpha(25),
                      const Color(0xFF6366F1).withAlpha(0),
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
                                      child: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          Container(
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
                                                    : Colors.black.withAlpha(
                                                        20,
                                                      ),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: Image.asset(
                                                'assets/cpi_logo.png',
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => Icon(
                                                  Icons.person_rounded,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF006BB3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.menu_rounded,
                                              color: Colors.white,
                                              size: 8,
                                            ),
                                          ),
                                        ],
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
                                        "${widget.user.department?.shortCode ?? 'CST'} • Roll: ${widget.user.rollNumber ?? '823791'}",
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const ThemeToggleSwitch(),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () {
                                  showSearch(
                                    context: context,
                                    delegate: StudentSearchDelegate(
                                      user: widget.user,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightPrimaryText,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.06),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          130.0,
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
                            // Attendance & CGPA Cards
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
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: AnimatedBuilder(
                                            animation:
                                                _attendanceCountAnimation,
                                            builder: (context, child) {
                                              return _buildMetricGlassCard(
                                                "Attendance",
                                                "${_attendanceCountAnimation.value.toStringAsFixed(1)}%",
                                                Icons.bolt_rounded,
                                                const Color(0xFF00E5FF),
                                                hasIndicator: true,
                                                onTap: () =>
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes
                                                          .attendanceDetail,
                                                      arguments:
                                                          StudentRouteArgs(
                                                            user: widget.user,
                                                          ),
                                                    ),
                                                isDark: isDark,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: AnimatedBuilder(
                                            animation: _cgpaCountAnimation,
                                            builder: (context, child) {
                                              return _buildMetricGlassCard(
                                                "Current CGPA",
                                                _cgpaCountAnimation.value
                                                    .toStringAsFixed(2),
                                                Icons.emoji_events_rounded,
                                                const Color(0xFF7B61FF),
                                                hasIndicator: false,
                                                onTap: () =>
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes.resultsLedger,
                                                      arguments:
                                                          StudentRouteArgs(
                                                            user: widget.user,
                                                          ),
                                                    ),
                                                isDark: isDark,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Live Schedule Tracker
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
                                    child: _buildLiveScheduleTimelineTracker(
                                      isDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // CPI Services Grid - ✅ Fees Removed
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
                                            "CPI Services",
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
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.0,
                                          children: [
                                            _buildAnimatedServiceTile(
                                              "Routine",
                                              Icons.calendar_today_rounded,
                                              const Color(0xFF2563EB),
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        RoutineView(
                                                          user: widget.user,
                                                        ),
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildAnimatedServiceTile(
                                              "Results",
                                              Icons.assessment_rounded,
                                              const Color(0xFF16A34A),
                                              () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.resultsLedger,
                                                  arguments: StudentRouteArgs(
                                                    user: widget.user,
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildAnimatedServiceTile(
                                              "Admit Card",
                                              Icons.badge_rounded,
                                              const Color(0xFFD97706),
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AdmitCardView(
                                                          user: widget.user,
                                                        ),
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            // ✅ Fees REMOVED
                                            _buildAnimatedServiceTile(
                                              "Syllabus",
                                              Icons.menu_book_rounded,
                                              const Color(0xFF7C3AED),
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SyllabusView(
                                                          user: widget.user,
                                                        ),
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            _buildAnimatedServiceTile(
                                              "Notices",
                                              Icons.campaign_rounded,
                                              const Color(0xFFE11D48),
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const NoticeBoardScreen(),
                                                  ),
                                                );
                                              },
                                              isDark,
                                            ),
                                            // Empty tile to maintain grid
                                            const SizedBox(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Recent Notices Carousel
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
                                    child: _buildPromoCarouselSection(isDark),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Continuous Assessments
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                          ),
                                          child: Text(
                                            "Continuous Assessments",
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
                                        _buildContinuousAssessmentsLedger(
                                          isDark,
                                        ),
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

  Widget _buildPromoCarouselSection(bool isDark) {
    if (_noticeOffers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
            child: Text(
              "Recent Notices & Updates",
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0891B2)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            "Recent Notices & Updates",
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 115,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (int pageIndex) {
              setState(() {
                _currentCarouselPage = pageIndex;
              });
            },
            itemCount: _noticeOffers.length,
            itemBuilder: (context, index) {
              final promoItem = _noticeOffers[index];
              final Color accentThemeColor = Color(
                int.parse(promoItem['color']!),
              );
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.transparent
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : AppColors.lightCardBorder,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      if (isDark)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(12),
                                  Colors.white.withAlpha(3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -25,
                        top: -25,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accentThemeColor.withAlpha(isDark ? 45 : 20),
                                accentThemeColor.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _shimmerAnimationController,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(
                                    _shimmerLinearAnimation.value - 1.0,
                                    -0.5,
                                  ),
                                  end: Alignment(
                                    _shimmerLinearAnimation.value,
                                    0.5,
                                  ),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withAlpha(0),
                                    Colors.white.withAlpha(isDark ? 20 : 40),
                                    Colors.white.withAlpha(0),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentThemeColor.withAlpha(
                                        isDark ? 30 : 25,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      promoItem['tag']!,
                                      style: TextStyle(
                                        color: accentThemeColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    promoItem['title']!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightPrimaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Geist',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    promoItem['subtitle']!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white.withAlpha(140)
                                          : AppColors.lightCaptionText,
                                      fontSize: 10,
                                      fontFamily: 'Geist',
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(8)
                                    : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withAlpha(25)
                                      : AppColors.lightCardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.campaign_rounded,
                                color: accentThemeColor,
                                size: 24,
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
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_noticeOffers.length, (dotIndex) {
            final bool isCurrentDot = _currentCarouselPage == dotIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              height: 4,
              width: isCurrentDot ? 14 : 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isCurrentDot
                    ? const Color(0xFF0284C7)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMetricGlassCard(
    String label,
    String score,
    IconData icon,
    Color accentColor, {
    required bool hasIndicator,
    required VoidCallback onTap,
    required bool isDark,
  }) {
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  if (hasIndicator)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark
                          ? Colors.white24
                          : AppColors.lightCaptionText,
                      size: 10,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                score,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withAlpha(140)
                      : AppColors.lightCaptionText,
                  fontSize: 10,
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

  Widget _buildLiveScheduleTimelineTracker(bool isDark) {
    return Container(
      width: double.infinity,
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
          Text(
            _currentClassDisplay,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Next Up: $_nextClassDisplay",
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.lightCaptionText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedServiceTile(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 20 : 30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withAlpha(215)
                    : AppColors.lightPrimaryText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuousAssessmentsLedger(bool isDark) {
    // Show loading state
    if (_isAssessmentsLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(12)
                : AppColors.lightCardBorder,
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
            ),
          ),
        ),
      );
    }

    // If no assessments found
    if (_assessments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(12)
                : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assessment_rounded,
              size: 48,
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            Text(
              'No assessments found',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      );
    }

    // Group assessments by subject
    final Map<String, List<AssessmentModel>> subjectMap = {};
    for (var assessment in _assessments) {
      if (!subjectMap.containsKey(assessment.subjectName)) {
        subjectMap[assessment.subjectName] = [];
      }
      subjectMap[assessment.subjectName]!.add(assessment);
    }

    return Container(
      width: double.infinity,
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
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continuous Assessments',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B61FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_assessments.length} Assessments',
                  style: TextStyle(
                    color: const Color(0xFF7B61FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subject-wise breakdown
          ...subjectMap.keys.map((subjectName) {
            final assessments = subjectMap[subjectName]!;
            final totalObtained = assessments.fold(
              0.0,
              (sum, a) => sum + a.obtainedMarks,
            );
            final totalPossible = assessments.fold(
              0.0,
              (sum, a) => sum + a.totalMarks,
            );
            final overallPercentage = totalPossible > 0
                ? (totalObtained / totalPossible) * 100
                : 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subjectName,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightPrimaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: overallPercentage >= 70
                            ? Colors.green.withOpacity(0.15)
                            : overallPercentage >= 40
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${overallPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: overallPercentage >= 70
                              ? Colors.green
                              : overallPercentage >= 40
                              ? Colors.orange
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: assessments.map((assessment) {
                    final p = assessment.percentage;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            assessment.assessmentName,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 10,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: p >= 70
                                  ? Colors.green
                                  : p >= 40
                                  ? Colors.orange
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${assessment.obtainedMarks.toStringAsFixed(0)}/${assessment.totalMarks.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),
              ],
            );
          }),
        ],
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
