import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/notice_model.dart';
import '../../core/theme_provider.dart';

class NoticeCard extends StatelessWidget {
  final NoticeModel notice;

  const NoticeCard({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    // Dynamic theme brightness detection
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark ||
        AppThemeController.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.85)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    notice.category,
                    isDark,
                  ).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCategoryColor(
                      notice.category,
                      isDark,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  notice.category.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColor(notice.category, isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),

              // Timestamp Text
              Text(
                _formatTimestamp(notice.createdAt),
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.45),
                  fontSize: 11,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Notice Title Text
          Text(
            notice.title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Notice Content Text
          Text(
            notice.content,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF334155),
              fontSize: 13,
              fontFamily: 'Geist',
              height: 1.45,
            ),
          ),

          // Optional External Link Button
          if (notice.actionUrl != null && notice.actionUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  final Uri url = Uri.parse(notice.actionUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.cyanAccent
                            : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: isDark
                              ? Colors.cyanAccent
                              : const Color(0xFF0284C7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toUpperCase()) {
      case 'EXAMINATION':
        return isDark ? Colors.cyanAccent : const Color(0xFF0284C7);
      case 'ADMISSION':
        return isDark ? Colors.blueAccent : const Color(0xFF2563EB);
      case 'ROUTINE':
        return isDark ? Colors.greenAccent : const Color(0xFF16A34A);
      case 'EVENT':
        return isDark ? Colors.purpleAccent : const Color(0xFF7C3AED);
      case 'OFFER':
        return isDark ? Colors.orangeAccent : const Color(0xFFD97706);
      default:
        return isDark ? Colors.purpleAccent : const Color(0xFF7C3AED);
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Today at $hour:$minute';
  }
}
