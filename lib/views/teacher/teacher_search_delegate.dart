// lib/views/teacher/teacher_search_delegate.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../teacher/teacher_routine_view.dart';
import '../student/results_ledger_view.dart';
import '../student/admit_card_view.dart';
import '../student/notice_board_screen.dart';
import '../student/syllabus_view.dart';
import '../student/attendance_detail_view.dart';
import 'attendance_management_view.dart';
import 'continuous_assessment_view.dart';
import 'teacher_syllabus_view.dart';
import 'teacher_notice_view.dart';

class TeacherSearchDelegate extends SearchDelegate<String> {
  final AppUser? user;

  TeacherSearchDelegate({this.user});

  // ✅ Teacher-specific search items
  final List<Map<String, dynamic>> _searchItems = [
    {
      'title': 'Class Routine',
      'subtitle': 'View your teaching schedule',
      'icon': Icons.calendar_today_rounded,
      'route': 'routine',
      'color': 0xFF2563EB,
      'keywords': ['routine', 'schedule', 'class', 'time table', 'teaching'],
    },
    {
      'title': 'Record Attendance',
      'subtitle': 'Mark student attendance',
      'icon': Icons.fact_check_rounded,
      'route': 'attendance',
      'color': 0xFF10B981,
      'keywords': ['attendance', 'present', 'absent', 'mark', 'log'],
    },
    {
      'title': 'Continuous Assessment',
      'subtitle': 'Manage student marks',
      'icon': Icons.drive_file_rename_outline_rounded,
      'route': 'assessment',
      'color': 0xFF0284C7,
      'keywords': [
        'marks',
        'assessment',
        'continuous',
        'grade',
        'ct',
        'assignment',
      ],
    },
    {
      'title': 'Syllabus',
      'subtitle': 'Manage subject syllabus',
      'icon': Icons.menu_book_rounded,
      'route': 'syllabus',
      'color': 0xFF8B5CF6,
      'keywords': ['syllabus', 'curriculum', 'subject', 'course', 'study'],
    },
    {
      'title': 'Post Notice',
      'subtitle': 'Broadcast class announcements',
      'icon': Icons.campaign_rounded,
      'route': 'notice',
      'color': 0xFFF59E0B,
      'keywords': ['notice', 'announcement', 'post', 'broadcast', 'class'],
    },
    {
      'title': 'Exam Results',
      'subtitle': 'Check student results',
      'icon': Icons.assessment_rounded,
      'route': 'results',
      'color': 0xFF16A34A,
      'keywords': ['results', 'exam', 'cgpa', 'gpa', 'marks', 'grade'],
    },
    {
      'title': 'Admit Card',
      'subtitle': 'Download exam admit cards',
      'icon': Icons.badge_rounded,
      'route': 'admit_card',
      'color': 0xFFD97706,
      'keywords': ['admit', 'card', 'exam', 'download', 'hall ticket'],
    },
    {
      'title': 'Notice Board',
      'subtitle': 'View campus announcements',
      'icon': Icons.notifications_rounded,
      'route': 'notices',
      'color': 0xFFE11D48,
      'keywords': ['notice', 'announcement', 'news', 'update', 'campus'],
    },
  ];

  // ✅ Quick action tags for teachers
  final List<Map<String, String>> _quickTags = [
    {'label': 'Routine', 'emoji': '📅', 'filter': 'routine'},
    {'label': 'Attendance', 'emoji': '✅', 'filter': 'attendance'},
    {'label': 'Marks', 'emoji': '📊', 'filter': 'assessment'},
    {'label': 'Syllabus', 'emoji': '📚', 'filter': 'syllabus'},
    {'label': 'Notice', 'emoji': '📢', 'filter': 'notice'},
    {'label': 'Results', 'emoji': '🎓', 'filter': 'results'},
  ];

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 16,
          fontFamily: 'Geist',
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white30
              : AppColors.lightCaptionText.withOpacity(0.6),
          fontSize: 16,
          fontFamily: 'Geist',
          letterSpacing: 0.5,
        ),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 16,
          fontFamily: 'Geist',
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(
            Icons.clear_rounded,
            color: isDark ? Colors.white70 : AppColors.lightCaptionText,
          ),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
        color: isDark ? Colors.white : AppColors.lightPrimaryText,
      ),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchItems.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final subtitle = (item['subtitle'] as String).toLowerCase();
      final keywords = (item['keywords'] as List<String>)
          .map((k) => k.toLowerCase())
          .toList();
      final queryLower = query.toLowerCase();

      return title.contains(queryLower) ||
          subtitle.contains(queryLower) ||
          keywords.any((k) => k.contains(queryLower));
    }).toList();

    return _buildSearchBody(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _searchItems.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final subtitle = (item['subtitle'] as String).toLowerCase();
      final keywords = (item['keywords'] as List<String>)
          .map((k) => k.toLowerCase())
          .toList();
      final queryLower = query.toLowerCase();

      return title.contains(queryLower) ||
          subtitle.contains(queryLower) ||
          keywords.any((k) => k.contains(queryLower));
    }).toList();

    return _buildSearchBody(context, suggestions);
  }

  void _navigateToRoute(BuildContext context, String route) {
    if (user == null) {
      close(context, '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to access this feature'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    close(context, '');

    switch (route) {
      case 'routine':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeacherRoutineView()),
        );
        break;
      case 'attendance':
        if (user!.department == null) {
          // Redirect to a placeholder for subject selection if missing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject/Class info missing')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceManagementView(
              teacher: user!,
              className: 'Not Assigned',
              subjectCode: 'N/A',
              subjectName: 'Unknown Subject',
              semester: 1,
              department: user!.department?.shortCode ?? 'CST',
            ),
          ),
        );
        break;
      case 'assessment':
        if (user!.department == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject/Class info missing')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContinuousAssessmentView(
              teacher: user!,
              className: 'Not Assigned',
              subjectCode: 'N/A',
              subjectName: 'Unknown Subject',
              semester: 1,
              department: user!.department?.shortCode ?? 'CST',
            ),
          ),
        );
        break;
      case 'syllabus':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherSyllabusView(teacher: user!),
          ),
        );
        break;
      case 'notice':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherNoticeView(teacher: user!),
          ),
        );
        break;
      case 'results':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsLedgerView(user: user!),
          ),
        );
        break;
      case 'admit_card':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdmitCardView(user: user!)),
        );
        break;
      case 'notices':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NoticeBoardScreen()),
        );
        break;
      default:
        break;
    }
  }

  Widget _buildSearchBody(
    BuildContext context,
    List<Map<String, dynamic>> results,
  ) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      body: Stack(
        children: [
          // Glow underlays
          if (isDark) ...[
            Positioned(
              top: 100,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.08),
                      const Color(0xFF10B981).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.06),
                      const Color(0xFF6366F1).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Positioned(
              top: 100,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0284C7).withOpacity(0.05),
                      const Color(0xFF0284C7).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Content
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionTags(context, isDark),
                Expanded(child: _buildResultsList(context, results, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTags(BuildContext context, bool isDark) {
    final accentColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickTags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tag = _quickTags[index];
          final isSelected =
              query.isNotEmpty &&
              tag['filter']!.toLowerCase().contains(query.toLowerCase());

          return GestureDetector(
            onTap: () {
              final matched = _searchItems.firstWhere(
                (item) => (item['keywords'] as List<String>).any(
                  (k) => k == tag['filter'],
                ),
                orElse: () => _searchItems.first,
              );
              _navigateToRoute(context, matched['route'] as String);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.12)
                    : (isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withOpacity(0.2)
                      : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06)),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(tag['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    tag['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? accentColor
                          : (isDark
                                ? Colors.white70
                                : AppColors.lightSubtitleText),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    List<Map<String, dynamic>> results,
    bool isDark,
  ) {
    final accentColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);

    final displayItems = query.isEmpty ? _searchItems : results;

    if (displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? Colors.white24
                  : AppColors.lightCaptionText.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "No services found",
              style: TextStyle(
                color: isDark
                    ? Colors.white38
                    : AppColors.lightCaptionText.withOpacity(0.6),
                fontSize: 14,
                fontFamily: 'Geist',
              ),
            ),
            Text(
              "Try searching for 'attendance', 'marks', etc.",
              style: TextStyle(
                color: isDark
                    ? Colors.white24
                    : AppColors.lightCaptionText.withOpacity(0.4),
                fontSize: 12,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final color = Color(item['color'] as int);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: _buildHighlightedText(
                    item['title'] as String,
                    query,
                    isDark,
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : AppColors.lightCaptionText,
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark
                        ? Colors.white24
                        : AppColors.lightCaptionText.withOpacity(0.3),
                    size: 14,
                  ),
                  onTap: () {
                    _navigateToRoute(context, item['route'] as String);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, String query, bool isDark) {
    final accentColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);

    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              color: accentColor,
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(isDark ? 0.3 : 0.15),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
