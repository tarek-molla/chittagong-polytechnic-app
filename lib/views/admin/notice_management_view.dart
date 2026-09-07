// =============================================================================
// lib/views/admin/notice_management_view.dart
// Notice Management View for CPI Admin Panel
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cpi_app/core/theme_provider.dart';
import 'package:cpi_app/core/colors.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/services/admin_service.dart';
import 'package:cpi_app/widgets/admin_common_widgets.dart';
import 'package:cpi_app/widgets/admin_dialogs.dart';
import 'package:cpi_app/services/supabase_service.dart';

class NoticeManagementView extends StatefulWidget {
  final AppUser user;

  const NoticeManagementView({super.key, required this.user});

  @override
  State<NoticeManagementView> createState() => _NoticeManagementViewState();
}

class _NoticeManagementViewState extends State<NoticeManagementView> {
  final AdminService _adminService = AdminService(SupabaseService.client);
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;

  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _filteredNotices = [];
  bool _isLoading = true;
  String? _error;
  String _selectedPriority = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    _subscription = _adminService.getNoticesStream().listen(
      (notices) {
        if (mounted) {
          setState(() {
            _notices = notices;
            _applyFilters();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredNotices = _notices.where((n) {
        if (_selectedPriority == 'ALL') return true;
        return n['priority']?.toString().toLowerCase() ==
            _selectedPriority.toLowerCase();
      }).toList();
    });
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'important':
        return const Color(0xFFF59E0B);
      case 'normal':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Future<void> _createNotice() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Post New Notice',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Title',
          hint: 'e.g., Midterm Exam Schedule',
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Content',
          hint: 'Notice content...',
        ),
        FormFieldConfig(
          key: 'priority',
          label: 'Priority',
          dropdownItems: ['normal', 'important', 'urgent'],
          initialValue: 'normal',
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Category',
          dropdownItems: [
            'GENERAL',
            'EXAMINATION',
            'ADMISSION',
            'ROUTINE',
            'EVENT',
          ],
          initialValue: 'GENERAL',
        ),
        FormFieldConfig(
          key: 'action_url',
          label: 'Action URL (optional)',
          hint: 'https://...',
        ),
      ],
      submitText: 'Post Notice',
    );

    if (result != null && mounted) {
      final notice = await _adminService.createNotice({
        ...result,
        'department': 'CST',
      });
      if (notice != null && mounted) {
        showAdminToast(context, message: 'Notice posted!', isSuccess: true);
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to post notice',
          isError: true,
        );
      }
    }
  }

  Future<void> _editNotice(Map<String, dynamic> notice) async {
    final result = await showAdminFormDialog(
      context,
      title: 'Edit Notice',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Title',
          initialValue: notice['title'],
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Content',
          initialValue: notice['content'],
        ),
        FormFieldConfig(
          key: 'priority',
          label: 'Priority',
          dropdownItems: ['normal', 'important', 'urgent'],
          initialValue: notice['priority'] ?? 'normal',
        ),
      ],
      submitText: 'Save Changes',
      initialValues: notice,
    );

    if (result != null && mounted) {
      final updated = await _adminService.updateNotice(notice['id'], result);
      if (updated != null && mounted) {
        showAdminToast(context, message: 'Notice updated!', isSuccess: true);
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to update', isError: true);
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> notice) async {
    final isActive = notice['is_active'] == true;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: isActive ? 'Deactivate Notice' : 'Activate Notice',
      message:
          'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this notice?',
      color: isActive ? Colors.red : Colors.green,
      confirmText: isActive ? 'Deactivate' : 'Activate',
    );

    if (confirmed && mounted) {
      final success = await _adminService.toggleUserStatus(
        'notices',
        notice['id'],
        !isActive,
      );
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Status updated!' : 'Failed to update',
          isSuccess: success,
          isError: !success,
        );
      }
    }
  }

  Future<void> _deleteNotice(Map<String, dynamic> notice) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Notice',
      message:
          'Are you sure you want to delete this notice? This action cannot be undone.',
      color: Colors.red,
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final success = await _adminService.deleteNotice(notice['id']);
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Notice deleted!' : 'Failed to delete',
          isSuccess: success,
          isError: !success,
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Notice Management',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: const Color(0xFFF59E0B)),
            onPressed: _createNotice,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminFilterChips(
                filters: const ['ALL', 'URGENT', 'IMPORTANT', 'NORMAL'],
                selectedFilter: _selectedPriority,
                onFilterSelected: (filter) {
                  setState(() => _selectedPriority = filter);
                  _applyFilters();
                },
                isDark: isDark,
              ),
            ),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const AdminLoadingShimmer();
    }

    if (_error != null) {
      return AdminErrorState(
        error: _error!,
        onRetry: () => setState(() {
          _isLoading = true;
          _error = null;
          _loadNotices();
        }),
        isDark: isDark,
      );
    }

    if (_filteredNotices.isEmpty) {
      return AdminEmptyState(
        title: 'No Notices',
        subtitle: 'Post a notice to get started',
        icon: Icons.campaign_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadNotices(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredNotices.length,
        itemBuilder: (context, index) =>
            _buildNoticeCard(_filteredNotices[index], index, isDark),
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice, int index, bool isDark) {
    final priority = notice['priority']?.toString() ?? 'normal';
    final priorityColor = _priorityColor(priority);
    final isActive = notice['is_active'] == true;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.85),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          priority == 'urgent'
                              ? Icons.warning_amber_rounded
                              : priority == 'important'
                              ? Icons.priority_high_rounded
                              : Icons.info_rounded,
                          color: priorityColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice['title'] ?? 'Untitled',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AdminStatusBadge(
                                  status: priority,
                                  color: priorityColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                if (notice['category'] != null)
                                  AdminStatusBadge(
                                    status: notice['category'],
                                    color: const Color(0xFF6B7280),
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AdminStatusBadge(
                        status: isActive ? 'Active' : 'Inactive',
                        color: isActive ? Colors.green : Colors.red,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice['content'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleStatus(notice),
                        icon: Icon(
                          isActive
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded,
                          size: 18,
                        ),
                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                        style: TextButton.styleFrom(
                          foregroundColor: isActive
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _editNotice(notice),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteNotice(notice),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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
