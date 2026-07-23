import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../../widgets/animated_background_painter.dart';

class AlertsView extends StatefulWidget {
  final AppUser user;
  const AlertsView({super.key, required this.user});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;

  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fetchNotices();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
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
      case 'EXAMINATION':
        return const Color(0xFF00E5FF);
      case 'ADMISSION':
        return const Color(0xFF3B82F6);
      case 'ROUTINE':
        return const Color(0xFF10B981);
      case 'EVENT':
        return const Color(0xFFF59E0B);
      case 'OFFER':
        return const Color(0xFF7B61FF);
      case 'GENERAL':
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'EXAMINATION':
        return Icons.school_rounded;
      case 'ADMISSION':
        return Icons.app_registration_rounded;
      case 'ROUTINE':
        return Icons.calendar_today_rounded;
      case 'EVENT':
        return Icons.emoji_events_rounded;
      case 'OFFER':
        return Icons.attach_money_rounded;
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
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final fallbackLightBackground = const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : fallbackLightBackground,
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
            child: _isLoading
                ? _buildLoadingState(isDark)
                : _errorMessage != null
                ? _buildErrorState(isDark)
                : _notices.isEmpty
                ? _buildEmptyState(isDark)
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Alerts & Notifications",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF070B19),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Geist',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${_notices.length} notifications",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
        ],
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]
              : [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.005),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
    );
  }
}
