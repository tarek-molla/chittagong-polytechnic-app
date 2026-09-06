// lib/views/student/notice_board_screen.dart
// CPI Notice Board — Matching Alerts View Card Design with proper navigation

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../components/admin_input_sheet.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowAnimationController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track expanded cards by ID
  final Set<String> _expandedNoticeIds = {};

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _fetchNotices();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notices = await DatabaseService().getNoticesStream().first;

      if (!mounted) return;

      setState(() {
        _notices = notices;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load notifications';
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ACADEMIC':
        return const Color(0xFF10B981);
      case 'CLASS':
        return const Color(0xFF3B82F6);
      case 'SUGGESTION':
        return const Color(0xFF8B5CF6);
      case 'GENERAL':
        return const Color(0xFF6B7280);
      case 'EXAMINATION':
        return const Color(0xFFEC4899);
      case 'ADMISSION':
        return const Color(0xFFF59E0B);
      case 'ROUTINE':
        return const Color(0xFF06B6D4);
      case 'ADMINISTRATIVE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'ACADEMIC':
        return Icons.school_rounded;
      case 'CLASS':
        return Icons.class_rounded;
      case 'SUGGESTION':
        return Icons.lightbulb_rounded;
      case 'EXAMINATION':
        return Icons.assignment_rounded;
      case 'ADMISSION':
        return Icons.app_registration_rounded;
      case 'ROUTINE':
        return Icons.calendar_today_rounded;
      case 'ADMINISTRATIVE':
        return Icons.admin_panel_settings_rounded;
      case 'GENERAL':
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return '1d ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months mo ago';
    }
  }

  bool _isAdminOrTeacher() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final role = user.userMetadata?['role']?.toString().toLowerCase();
      return role == 'admin' || role == 'teacher';
    } catch (e) {
      return false;
    }
  }

  void _showAdminInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const AdminInputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final showFab = _isAdminOrTeacher();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Ambient Glow Backdrops
          if (isDark) ...[
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowAnimationController.value * 30),
                  right: -100 + (_glowAnimationController.value * 20),
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.12),
                          const Color(0xFF7B61FF).withOpacity(0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                // Custom Header with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          size: 20,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOTICE BOARD',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Geist',
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.cyanAccent.withOpacity(0.08)
                                    : Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.cyanAccent.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                '${_notices.length} NOTIFICATIONS',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.cyanAccent
                                      : Colors.blue,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isLoading
                        ? _buildLoadingState(isDark)
                        : _errorMessage != null
                        ? _buildErrorState(isDark)
                        : _notices.isEmpty
                        ? _buildEmptyState(isDark)
                        : CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  100,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final notice = _notices[index];
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOutCubic,
                                      duration: Duration(
                                        milliseconds: 500 + (index * 80),
                                      ),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 30 * (1.0 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: _buildAlertCard(
                                              notice,
                                              isDark,
                                              index,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }, childCount: _notices.length),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: showFab
          ? AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(
                          0.2 + (_glowAnimationController.value * 0.15),
                        ),
                        blurRadius: 16 + (_glowAnimationController.value * 8),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _showAdminInputSheet(context),
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: const Color(0xFF070B19),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 18),
                    label: const Text(
                      'BROADCAST',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E5FF),
              ),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: isDark
                ? Colors.red.withOpacity(0.6)
                : Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchNotices,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF070B19),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All notifications will appear here.',
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

  Widget _buildAlertCard(NoticeModel notice, bool isDark, int index) {
    final Color color = _getCategoryColor(notice.category);
    final bool isNew = notice.createdAt.isAfter(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    final isExpanded = _expandedNoticeIds.contains(notice.id);

    // Priority handling
    final isUrgent = notice.priority.toLowerCase() == 'urgent';
    final isImportant = notice.priority.toLowerCase() == 'important';
    final isHighPriority = isUrgent || isImportant;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? color.withOpacity(0.5)
              : isUrgent
              ? Colors.red.withOpacity(0.5)
              : isImportant
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          width: isExpanded ? 1.5 : 1.0,
        ),
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.02)]
              : isImportant
              ? [
                  const Color(0xFFF59E0B).withOpacity(0.08),
                  const Color(0xFFF59E0B).withOpacity(0.02),
                ]
              : isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]
              : [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.005),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (isUrgent && !isDark)
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          if (isImportant && !isDark)
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedNoticeIds.remove(notice.id);
                } else {
                  _expandedNoticeIds.add(notice.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Icon(
                      _getCategoryIcon(notice.category),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notice.title,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF070B19),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  "NEW",
                                  style: TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Geist',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white38 : Colors.black38,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedCrossFade(
                          firstChild: Text(
                            notice.content,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF64748B),
                              fontSize: 13,
                              fontFamily: 'Geist',
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            notice.content,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13,
                              fontFamily: 'Geist',
                              height: 1.5,
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (isHighPriority)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? Colors.red.withOpacity(0.15)
                                      : const Color(
                                          0xFFF59E0B,
                                        ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isUrgent ? 'URGENT' : 'IMPORTANT',
                                  style: TextStyle(
                                    color: isUrgent
                                        ? Colors.red
                                        : const Color(0xFFF59E0B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            if (isHighPriority) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                notice.category.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(notice.createdAt),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withOpacity(0.35)
                                    : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Geist',
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
          ),
        ),
      ),
    );
  }
}
