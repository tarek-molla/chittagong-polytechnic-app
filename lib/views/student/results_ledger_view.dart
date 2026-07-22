import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/theme_provider.dart';
import '../../widgets/cloud_loader.dart';
import '../../core/colors.dart';
import '../../widgets/animated_background_painter.dart';
import '../../services/supabase_service.dart';

class ResultsLedgerView extends StatefulWidget {
  final AppUser user;

  const ResultsLedgerView({super.key, required this.user});

  @override
  State<ResultsLedgerView> createState() => _ResultsLedgerViewState();
}

class _ResultsLedgerViewState extends State<ResultsLedgerView>
    with TickerProviderStateMixin {
  late AnimationController _radialController;
  late Animation<double> _radialAnimation;
  late ScrollController _scrollController;

  int _selectedSemesterIndex = 0;
  bool _isRefreshing = false;
  bool _isLoading = true;
  String? _errorMessage;
  double _scrollOffset = 0.0;
  double _cgpa = 0.0;

  List<Map<String, dynamic>> _resultsData = [];
  List<Map<String, dynamic>> _semesterMeta = [];
  List<Map<String, dynamic>> _subjectMarks = [];
  List<String> _semesters = [];

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

    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _radialAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _radialController, curve: Curves.easeOutCubic),
    );

    _fetchResultsData();
  }

  Future<void> _fetchResultsData() async {
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

      final results = await SupabaseService.instance.fetchStudentResults(
        rollNumber,
      );

      if (results.isEmpty) {
        setState(() {
          _resultsData = [];
          _semesterMeta = [];
          _subjectMarks = [];
          _semesters = [];
          _cgpa = 0.0;
          _isLoading = false;
          _errorMessage = 'No results found for roll: $rollNumber';
        });
        return;
      }

      setState(() {
        _resultsData = results;
        _processResultsData();
        _isLoading = false;
        _errorMessage = null;
      });

      if (_semesterMeta.isNotEmpty) {
        _selectedSemesterIndex = 0;
        _loadSemesterSubjects(0);

        _radialController.reset();
        _radialAnimation =
            Tween<double>(
              begin: 0.0,
              end: _semesterMeta[0]['gpa'] / 4.0,
            ).animate(
              CurvedAnimation(
                parent: _radialController,
                curve: Curves.easeOutCubic,
              ),
            );
        _radialController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processResultsData() {
    if (_resultsData.isEmpty) return;

    // Group by semester
    final Map<String, List<Map<String, dynamic>>> semesterGroups = {};
    for (var result in _resultsData) {
      final semester = result['semester']?.toString() ?? 'Unknown';
      if (!semesterGroups.containsKey(semester)) {
        semesterGroups[semester] = [];
      }
      semesterGroups[semester]!.add(result);
    }

    _semesterMeta = [];
    _semesters = [];

    semesterGroups.forEach((semester, subjects) {
      // FIX: Remove duplicate subjects within the same semester
      final Map<String, Map<String, dynamic>> uniqueSubjects = {};
      for (var subject in subjects) {
        // Use subject_code if available, otherwise use subject_name
        final String key =
            subject['subject_code']?.toString() ??
            subject['subject_name']?.toString() ??
            'unknown';

        // Keep the record with the highest GPA for duplicate subjects
        final double currentGp =
            (subject['grade_point'] as num?)?.toDouble() ?? 0.0;
        final double existingGp =
            (uniqueSubjects[key]?['grade_point'] as num?)?.toDouble() ?? 0.0;

        if (!uniqueSubjects.containsKey(key) || currentGp > existingGp) {
          uniqueSubjects[key] = subject;
        }
      }

      // Calculate GPA using unique subjects
      double totalGp = 0.0;
      int totalCredits = 0;
      int passedCount = 0;

      for (var subject in uniqueSubjects.values) {
        final gp = (subject['grade_point'] as num?)?.toDouble() ?? 0.0;
        final credits = subject['credits'] as int? ?? 3;
        totalGp += gp * credits;
        totalCredits += credits;
        if (gp >= 2.0) passedCount++;
      }

      final gpa = totalCredits > 0 ? totalGp / totalCredits : 0.0;

      _semesterMeta.add({
        'title': semester,
        'session': semester,
        'credits': '$totalCredits Credits',
        'gpa': gpa,
        'subjectsCount': uniqueSubjects.length,
        'passedCount': passedCount,
        'semester': semester,
        'subjects': uniqueSubjects.values.toList(),
      });

      _semesters.add(semester);
    });

    // Sort semesters by number
    _semesterMeta.sort((a, b) {
      final aSem = _extractSemesterNumber(a['semester'].toString());
      final bSem = _extractSemesterNumber(b['semester'].toString());
      return bSem.compareTo(aSem);
    });

    _semesters = _semesterMeta.map((e) => e['semester'].toString()).toList();

    // Calculate CGPA - average of semester GPAs
    double totalGpa = 0.0;
    for (var meta in _semesterMeta) {
      totalGpa += meta['gpa'] as double;
    }
    _cgpa = _semesterMeta.isNotEmpty ? totalGpa / _semesterMeta.length : 0.0;

    // Debug print
    print(
      '📊 CGPA calculated: ${_cgpa.toStringAsFixed(2)} from ${_semesterMeta.length} semesters',
    );
  }

  int _extractSemesterNumber(String semester) {
    final match = RegExp(r'(\d+)').firstMatch(semester);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final wordMatch = RegExp(
      r'(\d+)(?:ST|ND|RD|TH)',
    ).firstMatch(semester.toUpperCase());
    if (wordMatch != null) {
      return int.tryParse(wordMatch.group(1)!) ?? 0;
    }
    return 0;
  }

  String _formatSemesterDisplay(String semester) {
    String display = semester
        .replaceAll(' SEMESTER', '')
        .replaceAll('TH', '')
        .replaceAll('RD', '')
        .replaceAll('ND', '')
        .replaceAll('ST', '')
        .trim();

    if (RegExp(r'^\d+$').hasMatch(display)) {
      final num = int.tryParse(display) ?? 0;
      if (num == 1) return '1st';
      if (num == 2) return '2nd';
      if (num == 3) return '3rd';
      return '${num}th';
    }
    return display;
  }

  void _loadSemesterSubjects(int index) {
    if (index >= _semesterMeta.length) return;

    final semesterMeta = _semesterMeta[index];
    final subjects = semesterMeta['subjects'] as List;

    _subjectMarks = subjects.map((subject) {
      final tc = subject['theory_continuous'] as int? ?? 0;
      final tcMax = subject['theory_continuous_max'] as int? ?? 30;
      final pc = subject['practical_continuous'] as int? ?? 0;
      final pcMax = subject['practical_continuous_max'] as int? ?? 50;
      final finalScore = subject['final_exam'] as int? ?? 0;
      final finalMax = subject['final_exam_max'] as int? ?? 100;
      final total = tc + pc + finalScore;
      final totalMax = tcMax + pcMax + finalMax;
      final percentage = totalMax > 0 ? (total / totalMax) * 100 : 0.0;

      final grade = subject['grade']?.toString() ?? 'B';
      Color color;
      if (grade.startsWith('A')) {
        color = const Color(0xFF10B981);
      } else if (grade.startsWith('B')) {
        color = const Color(0xFF3B82F6);
      } else if (grade.startsWith('C')) {
        color = const Color(0xFFFFB74D);
      } else {
        color = const Color(0xFFFF6B6B);
      }

      return {
        'code': subject['subject_code']?.toString() ?? 'N/A',
        'subject': subject['subject_name']?.toString() ?? 'Unknown Subject',
        'credits': '${subject['credits'] ?? 3} Cr',
        'grade': grade,
        'gp': (subject['grade_point'] as num?)?.toDouble() ?? 0.0,
        'tc': tc,
        'tcMax': tcMax,
        'pc': pc,
        'pcMax': pcMax,
        'final': finalScore,
        'finalMax': finalMax,
        'total': total,
        'totalMax': totalMax,
        'percentage': percentage,
        'color': color,
      };
    }).toList();

    _subjectMarks.sort((a, b) => a['code'].compareTo(b['code']));
    setState(() {});
  }

  void _onSemesterChanged(int index) {
    setState(() {
      _selectedSemesterIndex = index;
      _loadSemesterSubjects(index);
    });

    _radialController.reset();
    _radialAnimation =
        Tween<double>(
          begin: 0.0,
          end: _semesterMeta[index]['gpa'] / 4.0,
        ).animate(
          CurvedAnimation(
            parent: _radialController,
            curve: Curves.easeOutCubic,
          ),
        );
    _radialController.forward();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    await _fetchResultsData();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _radialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    double clampedPullOffset = _scrollOffset < 0 ? _scrollOffset : 0.0;
    double typographyOpacity = (1.0 - (_scrollOffset / 120.0)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : Colors.transparent,
      body: Stack(
        children: [
          // Animated Background Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: AnimatedBackgroundPainter(
                animation: const AlwaysStoppedAnimation(0.5),
                isLightMode: !isDark,
              ),
            ),
          ),

          // Radial ambience glow underlay
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withAlpha(20),
                      const Color(0xFF6366F1).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ],

          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification.metrics.axis == Axis.vertical) {
                  setState(() {
                    _scrollOffset = notification.metrics.pixels;
                  });
                  if (_scrollOffset < -70 && !_isRefreshing) {
                    _handleRefresh();
                  }
                }
                return true;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  if (_errorMessage != null && !_isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          0.0,
                          20.0,
                          8.0,
                        ),
                        child: _buildWarningAlertCard(isDark),
                      ),
                    ),

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
                                    "Academic Results",
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
                                    "Historical Grade & Transcript Records",
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
                          _buildMiniCGPABadge(isDark),
                        ],
                      ),
                    ),
                  ),

                  if (_isLoading) _buildLoadingState(isDark),

                  if (!_isLoading && _semesters.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        child: _buildSemesterTabSelector(isDark),
                      ),
                    ),

                  if (!_isLoading && _semesterMeta.isNotEmpty)
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
                                                  : AppColors
                                                        .lightCardBorderAlt,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFF10B981)),
                                              strokeCap: StrokeCap.round,
                                            ),
                                          ),
                                          Text(
                                            (_radialAnimation.value * 4.0)
                                                .toStringAsFixed(2),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.lightPrimaryText,
                                              fontSize: 20,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatSemesterDisplay(
                                          _semesterMeta[_selectedSemesterIndex]['title'],
                                        ),
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
                                        "${_semesterMeta[_selectedSemesterIndex]['credits']}",
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
                                            "${_semesterMeta[_selectedSemesterIndex]['subjectsCount']} Subjects",
                                            AppColors.lightCaptionText,
                                            isDark,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadge(
                                            "${_semesterMeta[_selectedSemesterIndex]['passedCount']} Passed",
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

                  if (!_isLoading && _subjectMarks.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final mark = _subjectMarks[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 350 + (index * 150),
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, animValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1.0 - animValue)),
                                child: Opacity(
                                  opacity: animValue,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: _buildSubjectMarkGlassCard(
                                      mark,
                                      isDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }, childCount: _subjectMarks.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),

          if (_scrollOffset < -12 || _isRefreshing)
            Positioned(
              top: 25,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (_scrollOffset < -25 || _isRefreshing) ? 1.0 : 0.0,
                  child: const CloudLoader(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI COMPONENT BUILDERS ---

  Widget _buildWarningAlertCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withAlpha(isDark ? 15 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFB74D).withAlpha(35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFB74D),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Summary Results Only",
                      style: TextStyle(
                        color: const Color(0xFFFFB74D),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Showing semester GPA summary. Subject details not available.",
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
              _buildRefreshButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(bool isDark) {
    return InkWell(
      onTap: _isRefreshing ? null : _handleRefresh,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(10)
              : AppColors.lightCardBorderAlt.withAlpha(100),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isRefreshing
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              )
            : Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white70 : AppColors.lightPrimaryText,
                size: 14,
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

  Widget _buildMiniCGPABadge(bool isDark) {
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
                _cgpa.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Geist',
                ),
              ),
              const Text(
                "CGPA",
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

  Widget _buildSemesterTabSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : AppColors.lightCardBorderAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_semesters.length, (index) {
          final isSelected = _selectedSemesterIndex == index;
          final displayName = _formatSemesterDisplay(_semesters[index]);

          return Expanded(
            child: InkWell(
              onTap: () => _onSemesterChanged(index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF1E293B)
                            : AppColors.lightBackground)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF00E5FF)
                                : AppColors.lightPrimaryText)
                          : (isDark
                                ? Colors.white38
                                : AppColors.lightCaptionText),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
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

  Widget _buildSubjectMarkGlassCard(Map<String, dynamic> mark, bool isDark) {
    final Color accentColor = mark['color'];
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
                          mark['subject'],
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
                          "${mark['code']} • ${mark['credits']}",
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
                          color: accentColor.withAlpha(15),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withAlpha(30)),
                        ),
                        child: Center(
                          child: Text(
                            mark['grade'],
                            style: TextStyle(
                              color: accentColor,
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
                            mark['gp'].toStringAsFixed(2),
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
                            "GP",
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
                  _buildMarkSplitCol(
                    "TC",
                    "${mark['tc']}",
                    "/${mark['tcMax']}",
                    isDark,
                  ),
                  _buildMarkSplitCol(
                    "PC",
                    "${mark['pc']}",
                    "/${mark['pcMax']}",
                    isDark,
                  ),
                  _buildMarkSplitCol(
                    "Final",
                    "${mark['final']}",
                    "/${mark['finalMax']}",
                    isDark,
                  ),
                  _buildMarkSplitCol(
                    "Total",
                    "${mark['total']}",
                    "/${mark['totalMax']}",
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
                    tween: Tween(begin: 0.0, end: mark['percentage'] / 100.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    builder: (context, val, child) {
                      return LinearProgressIndicator(
                        value: val,
                        backgroundColor: isDark
                            ? Colors.white.withAlpha(12)
                            : AppColors.lightCardBorderAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                    "${mark['percentage'].toStringAsFixed(1)}%",
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

  Widget _buildMarkSplitCol(
    String label,
    String value,
    String max,
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
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
            Text(
              max,
              style: TextStyle(
                color: isDark ? Colors.white24 : AppColors.lightCaptionText,
                fontSize: 9,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ],
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
