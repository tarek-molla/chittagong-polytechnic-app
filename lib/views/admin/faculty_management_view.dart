// =============================================================================
// lib/views/admin/faculty_management_view.dart
// Faculty Management View for CPI Admin Panel
// Manages faculty members with CRUD operations
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cpi_app/core/theme_provider.dart';
import 'package:cpi_app/core/colors.dart';
import 'package:cpi_app/core/router.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/models/user_role.dart' as role_model;
import 'package:cpi_app/services/admin_service.dart';
import 'package:cpi_app/widgets/admin_common_widgets.dart';
import 'package:cpi_app/widgets/admin_dialogs.dart';
import 'package:cpi_app/widgets/animated_background_painter.dart';
import 'package:cpi_app/services/supabase_service.dart';

class FacultyManagementView extends StatefulWidget {
  final AppUser user;

  const FacultyManagementView({super.key, required this.user});

  @override
  State<FacultyManagementView> createState() => _FacultyManagementViewState();
}

class _FacultyManagementViewState extends State<FacultyManagementView>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService(SupabaseService.client);
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  late AnimationController _bgAnimController;

  List<Map<String, dynamic>> _faculty = [];
  List<Map<String, dynamic>> _filteredFaculty = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadFaculty();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  String get _department => widget.user.department?.shortCode ?? 'CST';

  void _loadFaculty() {
    _subscription = _adminService
        .getTeachersStream(_department)
        .listen(
          (faculty) {
            if (mounted) {
              setState(() {
                _faculty = faculty;
                _filteredFaculty = faculty;
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

  void _filterFaculty(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFaculty = _faculty;
      } else {
        _filteredFaculty = _faculty.where((f) {
          final name = f['name']?.toString().toLowerCase() ?? '';
          final facultyId = f['teacher_id']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              facultyId.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _createFaculty() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Add New Faculty Member',
      fields: [
        FormFieldConfig(
          key: 'teacher_id',
          label: 'Faculty ID',
          hint: 'e.g., F001',
        ),
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., Prof. Ahmed Hassan',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'e.g., ahmed@cpi.edu.bd',
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
          initialValue: _department,
        ),
        FormFieldConfig(
          key: 'designation',
          label: 'Designation',
          hint: 'e.g., Professor, Associate Professor',
        ),
        FormFieldConfig(
          key: 'password',
          label: 'Password',
          hint: 'Default: faculty123',
          obscureText: true,
        ),
      ],
      submitText: 'Add Faculty Member',
    );

    if (result != null && mounted) {
      final faculty = await _adminService.createTeacher(result);
      if (faculty != null && mounted) {
        showAdminToast(
          context,
          message: 'Faculty member added successfully!',
          isSuccess: true,
        );
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to add faculty member',
          isError: true,
        );
      }
    }
  }

  Future<void> _editFaculty(Map<String, dynamic> faculty) async {
    final result = await showAdminFormDialog(
      context,
      title: 'Edit Faculty Member',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., Prof. Ahmed Hassan',
          initialValue: faculty['name'],
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'e.g., ahmed@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
          initialValue: faculty['email'],
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
          initialValue: faculty['phone'],
        ),
        FormFieldConfig(
          key: 'department',
          label: 'Department',
          dropdownItems: ['CST', 'CIVIL', 'EE', 'ME', 'ECT'],
          initialValue: faculty['department'],
        ),
        FormFieldConfig(
          key: 'designation',
          label: 'Designation',
          hint: 'e.g., Professor, Associate Professor',
          initialValue: faculty['designation'],
        ),
      ],
      submitText: 'Save Changes',
      initialValues: faculty,
    );

    if (result != null && mounted) {
      final updated = await _adminService.updateTeacher(faculty['id'], result);
      if (updated != null && mounted) {
        showAdminToast(
          context,
          message: 'Faculty member updated!',
          isSuccess: true,
        );
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to update', isError: true);
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> faculty) async {
    final isActive = faculty['is_active'] == true;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: isActive ? 'Deactivate Faculty' : 'Activate Faculty',
      message:
          'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} ${faculty['name']}?',
      color: isActive ? Colors.red : Colors.green,
      confirmText: isActive ? 'Deactivate' : 'Activate',
    );

    if (confirmed && mounted) {
      final success = await _adminService.toggleUserStatus(
        'teachers_login',
        faculty['id'],
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

  Future<void> _deleteFaculty(Map<String, dynamic> faculty) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Faculty Member',
      message:
          'Are you sure you want to delete ${faculty['name']}? This action cannot be undone.',
      color: Colors.red,
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final success = await _adminService.deleteUser(
        'teachers_login',
        faculty['id'],
      );
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Faculty member deleted!' : 'Failed to delete',
          isSuccess: success,
          isError: !success,
        );
      }
    }
  }

  @override
  void dispose() {
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _bgAnimController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final isStandaloneRoute = ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Faculty Roster',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isStandaloneRoute
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  size: 18,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFF59E0B)),
            onPressed: _createFaculty,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedBackgroundPainter(
                    animation: _bgAnimController,
                    isLightMode: !isDark,
                    role: role_model.UserRole.admin,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdminSearchBar(
                    onChanged: _filterFaculty,
                    hintText: 'Search by name or faculty ID...',
                  ),
                ),
                Expanded(child: _buildContent(isDark)),
              ],
            ),
          ),
        ],
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
          _loadFaculty();
        }),
        isDark: isDark,
      );
    }

    if (_filteredFaculty.isEmpty) {
      return AdminEmptyState(
        title: 'No Faculty Members',
        subtitle: _searchQuery.isEmpty
            ? 'Add your first faculty member to get started'
            : 'No faculty members match your search',
        icon: Icons.school_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadFaculty(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredFaculty.length,
        itemBuilder: (context, index) =>
            _buildFacultyCard(_filteredFaculty[index], index, isDark),
      ),
    );
  }

  Widget _buildFacultyCard(
    Map<String, dynamic> faculty,
    int index,
    bool isDark,
  ) {
    final isActive = faculty['is_active'] == true;
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
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.85),
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
                          ).withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (faculty['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'F'),
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
                              faculty['name'] ?? 'Unknown',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${faculty['teacher_id'] ?? 'N/A'}',
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
                        faculty['email'] ?? '',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.phone_rounded,
                        faculty['phone'] ?? '',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.business_rounded,
                        faculty['department'] ?? 'CST',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.work_rounded,
                        faculty['designation'] ?? 'N/A',
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleStatus(faculty),
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
                        onPressed: () => _editFaculty(faculty),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteFaculty(faculty),
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
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
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
