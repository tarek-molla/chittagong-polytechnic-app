// =============================================================================
// lib/views/admin/teacher_management_view.dart
// Teacher Management View for CPI Admin Panel
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cpi_app/core/theme_provider.dart';
import 'package:cpi_app/core/colors.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/services/admin_service.dart';
import 'package:cpi_app/widgets/admin_common_widgets.dart';
import 'package:cpi_app/widgets/admin_dialogs.dart';
import 'package:cpi_app/services/supabase_service.dart';

class TeacherManagementView extends StatefulWidget {
  final AppUser user;

  const TeacherManagementView({super.key, required this.user});

  @override
  State<TeacherManagementView> createState() => _TeacherManagementViewState();
}

class _TeacherManagementViewState extends State<TeacherManagementView> {
  final AdminService _adminService = AdminService(SupabaseService.client);
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  void _loadTeachers() {
    _subscription = _adminService
        .getTeachersStream('CST')
        .listen(
          (teachers) {
            if (mounted) {
              setState(() {
                _teachers = teachers;
                _filteredTeachers = teachers;
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

  void _filterTeachers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTeachers = _teachers;
      } else {
        _filteredTeachers = _teachers.where((t) {
          final name = t['name']?.toString().toLowerCase() ?? '';
          final teacherId = t['teacher_id']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              teacherId.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _createTeacher() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Add New Teacher',
      fields: [
        FormFieldConfig(
          key: 'teacher_id',
          label: 'Teacher ID',
          hint: 'e.g., T001',
        ),
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., John Doe',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'e.g., john@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
        ),
        FormFieldConfig(
          key: 'department',
          label: 'Department',
          dropdownItems: ['CST', 'CIVIL', 'EE', 'ME', 'ECT'],
          initialValue: 'CST',
        ),
        FormFieldConfig(
          key: 'password',
          label: 'Password',
          hint: 'Default: teacher123',
          obscureText: true,
        ),
      ],
      submitText: 'Add Teacher',
    );

    if (result != null && mounted) {
      final teacher = await _adminService.createTeacher(result);
      if (teacher != null && mounted) {
        showAdminToast(
          context,
          message: 'Teacher added successfully!',
          isSuccess: true,
        );
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to add teacher',
          isError: true,
        );
      }
    }
  }

  Future<void> _editTeacher(Map<String, dynamic> teacher) async {
    final result = await showAdminFormDialog(
      context,
      title: 'Edit Teacher',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., John Doe',
          initialValue: teacher['name'],
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'e.g., john@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
          initialValue: teacher['email'],
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
          initialValue: teacher['phone'],
        ),
        FormFieldConfig(
          key: 'department',
          label: 'Department',
          dropdownItems: ['CST', 'CIVIL', 'EE', 'ME', 'ECT'],
          initialValue: teacher['department'],
        ),
      ],
      submitText: 'Save Changes',
      initialValues: teacher,
    );

    if (result != null && mounted) {
      final updated = await _adminService.updateTeacher(teacher['id'], result);
      if (updated != null && mounted) {
        showAdminToast(context, message: 'Teacher updated!', isSuccess: true);
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to update', isError: true);
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> teacher) async {
    final isActive = teacher['is_active'] == true;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: isActive ? 'Deactivate Teacher' : 'Activate Teacher',
      message:
          'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} ${teacher['name']}?',
      color: isActive ? Colors.red : Colors.green,
      confirmText: isActive ? 'Deactivate' : 'Activate',
    );

    if (confirmed && mounted) {
      final success = await _adminService.toggleUserStatus(
        'teachers_login',
        teacher['id'],
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

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Teacher',
      message:
          'Are you sure you want to delete ${teacher['name']}? This action cannot be undone.',
      color: Colors.red,
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final success = await _adminService.deleteUser(
        'teachers_login',
        teacher['id'],
      );
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Teacher deleted!' : 'Failed to delete',
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
          'Teacher Management',
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
            onPressed: _createTeacher,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminSearchBar(
                onChanged: _filterTeachers,
                hintText: 'Search by name or ID...',
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
          _loadTeachers();
        }),
        isDark: isDark,
      );
    }

    if (_filteredTeachers.isEmpty) {
      return AdminEmptyState(
        title: 'No Teachers',
        subtitle: _searchQuery.isEmpty
            ? 'Add your first teacher to get started'
            : 'No teachers match your search',
        icon: Icons.school_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTeachers(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredTeachers.length,
        itemBuilder: (context, index) =>
            _buildTeacherCard(_filteredTeachers[index], index, isDark),
      ),
    );
  }

  Widget _buildTeacherCard(
    Map<String, dynamic> teacher,
    int index,
    bool isDark,
  ) {
    final isActive = teacher['is_active'] == true;
    final staggerDelay = index * 50;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + staggerDelay),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withOpacity(isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (teacher['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'T'),
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher['name'] ?? 'Unknown',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${teacher['teacher_id'] ?? 'N/A'}',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                                fontFamily: 'Geist',
                              ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildDetailChip(
                        Icons.email_rounded,
                        teacher['email'] ?? '',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.phone_rounded,
                        teacher['phone'] ?? '',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.business_rounded,
                        teacher['department'] ?? 'CST',
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleStatus(teacher),
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
                        onPressed: () => _editTeacher(teacher),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteTeacher(teacher),
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

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label.length > 20 ? '${label.substring(0, 20)}...' : label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
