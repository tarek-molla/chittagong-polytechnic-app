// =============================================================================
// lib/views/admin/student_management_view.dart
// Student Management View for CPI Admin Panel
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

class StudentManagementView extends StatefulWidget {
  final AppUser user;

  const StudentManagementView({super.key, required this.user});

  @override
  State<StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<StudentManagementView> {
  final AdminService _adminService = AdminService(SupabaseService.client);
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedSemester = 'All';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _subscription = _adminService
        .getStudentsStream('CST')
        .listen(
          (students) {
            if (mounted) {
              setState(() {
                _students = students;
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
      _filteredStudents = _students.where((s) {
        final name = s['student_name']?.toString().toLowerCase() ?? '';
        final roll = s['roll_number']?.toString().toLowerCase() ?? '';
        final matchesSearch =
            _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            roll.contains(_searchQuery.toLowerCase());

        final matchesSemester =
            _selectedSemester == 'All' ||
            s['semester']?.toString() == _selectedSemester;

        return matchesSearch && matchesSemester;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onSemesterChanged(String semester) {
    setState(() => _selectedSemester = semester);
    _applyFilters();
  }

  Future<void> _createStudent() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Add New Student',
      fields: [
        FormFieldConfig(
          key: 'roll_number',
          label: 'Roll Number',
          hint: 'e.g., 26CST001',
        ),
        FormFieldConfig(
          key: 'student_name',
          label: 'Full Name',
          hint: 'e.g., Rahim Ahmed',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'e.g., rahim@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
        ),
        FormFieldConfig(
          key: 'semester',
          label: 'Semester',
          dropdownItems: ['1', '2', '3', '4', '5', '6', '7', '8'],
          initialValue: '1',
        ),
        FormFieldConfig(
          key: 'class_name',
          label: 'Class',
          hint: 'e.g., CST-1st-A',
        ),
        FormFieldConfig(
          key: 'department',
          label: 'Department',
          dropdownItems: ['CST', 'CIVIL', 'EE', 'ME', 'ECT'],
          initialValue: 'CST',
        ),
        FormFieldConfig(
          key: 'guardian_name',
          label: 'Guardian Name',
          hint: 'e.g., Karim Ahmed',
        ),
        FormFieldConfig(
          key: 'guardian_phone',
          label: 'Guardian Phone',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
        ),
      ],
      submitText: 'Add Student',
    );

    if (result != null && mounted) {
      final student = await _adminService.createStudent({
        ...result,
        'admission_year': DateTime.now().year,
      });
      if (student != null && mounted) {
        showAdminToast(
          context,
          message: 'Student added successfully!',
          isSuccess: true,
        );
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to add student',
          isError: true,
        );
      }
    }
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    final result = await showAdminFormDialog(
      context,
      title: 'Edit Student',
      fields: [
        FormFieldConfig(
          key: 'student_name',
          label: 'Full Name',
          initialValue: student['student_name'],
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          initialValue: student['email'],
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          keyboardType: TextInputType.phone,
          initialValue: student['phone'],
        ),
        FormFieldConfig(
          key: 'semester',
          label: 'Semester',
          dropdownItems: ['1', '2', '3', '4', '5', '6', '7', '8'],
          initialValue: student['semester']?.toString() ?? '1',
        ),
        FormFieldConfig(
          key: 'class_name',
          label: 'Class',
          initialValue: student['class_name'],
        ),
      ],
      submitText: 'Save Changes',
      initialValues: student,
    );

    if (result != null && mounted) {
      final updated = await _adminService.updateStudent(student['id'], result);
      if (updated != null && mounted) {
        showAdminToast(context, message: 'Student updated!', isSuccess: true);
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to update', isError: true);
      }
    }
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Student',
      message: 'Are you sure you want to delete ${student['student_name']}?',
      color: Colors.red,
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final success = await _adminService.deleteUser(
        'students_login',
        student['id'],
      );
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Student deleted!' : 'Failed to delete',
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
          'Student Management',
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
            onPressed: _createStudent,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminSearchBar(
                onChanged: _onSearchChanged,
                hintText: 'Search by roll or name...',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdminFilterChips(
                filters: ['All', '1', '2', '3', '4', '5', '6', '7', '8'],
                selectedFilter: _selectedSemester,
                onFilterSelected: _onSemesterChanged,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),
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
          _loadStudents();
        }),
        isDark: isDark,
      );
    }

    if (_filteredStudents.isEmpty) {
      return AdminEmptyState(
        title: 'No Students',
        subtitle: _searchQuery.isEmpty
            ? 'Add your first student to get started'
            : 'No students match your filters',
        icon: Icons.school_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadStudents(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) =>
            _buildStudentCard(_filteredStudents[index], index, isDark),
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, dynamic> student,
    int index,
    bool isDark,
  ) {
    final isActive = student['is_active'] == true;
    final staggerDelay = index * 40;

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
                            0xFF2563EB,
                          ).withOpacity(isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (student['student_name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'S'),
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
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
                              student['student_name'] ?? 'Unknown',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll: ${student['roll_number'] ?? 'N/A'}',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AdminStatusBadge(
                            status: '${student['semester'] ?? 0}th Sem',
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4),
                          AdminStatusBadge(
                            status: isActive ? 'Active' : 'Inactive',
                            color: isActive ? Colors.green : Colors.red,
                            isDark: isDark,
                          ),
                        ],
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
                        student['email'] ?? '',
                        isDark,
                      ),
                      _buildDetailChip(
                        Icons.class_rounded,
                        student['class_name'] ?? 'N/A',
                        isDark,
                      ),
                    ],
                  ),
                  if (student['guardian_name'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Guardian: ${student['guardian_name']}${student['guardian_phone'] != null ? ' • ${student['guardian_phone']}' : ''}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 11,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editStudent(student),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteStudent(student),
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
            label.length > 25 ? '${label.substring(0, 25)}...' : label,
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
