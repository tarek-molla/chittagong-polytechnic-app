// lib/components/notice_card.dart
// CPI Notice Card — Premium Glassmorphism Design

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../core/theme_provider.dart';

class NoticeCard extends StatelessWidget {
  final NoticeModel notice;

  const NoticeCard({super.key, required this.notice});

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return const Color(0xFFEF4444);
      case 'IMPORTANT':
        return const Color(0xFFF59E0B);
      case 'CLASS':
        return const Color(0xFF3B82F6);
      case 'SUGGESTION':
        return const Color(0xFF8B5CF6);
      case 'GENERAL':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return Icons.warning_amber_rounded;
      case 'IMPORTANT':
        return Icons.priority_high_rounded;
      case 'CLASS':
        return Icons.class_rounded;
      case 'SUGGESTION':
        return Icons.lightbulb_rounded;
      case 'GENERAL':
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final priorityColor = _getPriorityColor(notice.priority);
    final priorityIcon = _getPriorityIcon(notice.priority);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: priorityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(priorityIcon, color: priorityColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              notice.priority.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(notice.createdAt),
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 10,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    notice.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Geist',
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Content
                  Text(
                    notice.content,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Optional: Show creator if available (using createdBy or similar field)
                  // Check what field your NoticeModel has for the creator
                  // If you have a 'createdBy' field, use that instead
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted by Admin',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 10,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
