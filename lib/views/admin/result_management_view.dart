// =============================================================================
// lib/views/admin/result_management_view.dart
// Result Management View for CPI Admin Panel
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

class ResultManagementView extends StatefulWidget {
  final AppUser user;

  const ResultManagementView({super.key, required this.user});

  @override
  State<ResultManagementView> createState() => _ResultManagementViewState();
}

class _ResultManagementViewState extends State<ResultManagementView> {
  final AdminService _adminService = AdminService(SupabaseService.client);
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedSemester = 'All';

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  void _loadResults() {
    _subscription = _adminService
        .getResultsStream('CST')
        .listen(
          (results) {
            if (mounted) {
              setState(() {
                _results = results;
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
      _filteredResults = _results.where((r) {
        final name = r['student_name']?.toString().toLowerCase() ?? '';
        final roll = r['roll_number']?.toString().toLowerCase() ?? '';
        final subject = r['subject_name']?.toString().toLowerCase() ?? '';
        final matchesSearch =
            _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            roll.contains(_searchQuery.toLowerCase()) ||
            subject.contains(_searchQuery.toLowerCase());

        final matchesSemester =
            _selectedSemester == 'All' ||
            r['semester']?.toString() == _selectedSemester;

        return matchesSearch && matchesSemester;
      }).toList();
    });
  }

  String _calculateGrade(num percentage) {
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  double _calculateGradePoint(String grade) {
    switch (grade) {
      case 'A+':
        return 4.0;
      case 'A':
        return 3.75;
      case 'B':
        return 3.0;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return const Color(0xFF10B981);
      case 'B':
        return const Color(0xFF2563EB);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Future<void> _createResult() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Add New Result',
      fields: [
        FormFieldConfig(
          key: 'roll_number',
          label: 'Roll Number',
          hint: 'e.g., 26CST001',
        ),
        FormFieldConfig(
          key: 'student_name',
          label: 'Student Name',
          hint: 'e.g., Rahim Ahmed',
        ),
        FormFieldConfig(
          key: 'subject_code',
          label: 'Subject Code',
          hint: 'e.g., 66641',
        ),
        FormFieldConfig(
          key: 'subject_name',
          label: 'Subject Name',
          hint: 'e.g., Data Structures',
        ),
        FormFieldConfig(
          key: 'semester',
          label: 'Semester',
          dropdownItems: ['1', '2', '3', '4', '5', '6', '7', '8'],
          initialValue: '1',
        ),
        FormFieldConfig(
          key: 'total_marks',
          label: 'Total Marks',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'obtained_marks',
          label: 'Obtained Marks',
          hint: 'e.g., 85',
          keyboardType: TextInputType.number,
        ),
      ],
      submitText: 'Add Result',
    );

    if (result != null && mounted) {
      final totalMarks = double.tryParse(result['total_marks'].toString()) ?? 0;
      final obtainedMarks =
          double.tryParse(result['obtained_marks'].toString()) ?? 0;
      final percentage = totalMarks > 0
          ? (obtainedMarks / totalMarks) * 100
          : 0;
      final grade = _calculateGrade(percentage);

      final newResult = await _adminService.createResult({
        ...result,
        'grade': grade,
        'grade_point': _calculateGradePoint(grade),
      });

      if (newResult != null && mounted) {
        showAdminToast(
          context,
          message: 'Result added successfully!',
          isSuccess: true,
        );
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to add result', isError: true);
      }
    }
  }

  Future<void> _editResult(Map<String, dynamic> result) async {
    final editResult = await showAdminFormDialog(
      context,
      title: 'Edit Result',
      fields: [
        FormFieldConfig(
          key: 'total_marks',
          label: 'Total Marks',
          keyboardType: TextInputType.number,
          initialValue: result['total_marks']?.toString(),
        ),
        FormFieldConfig(
          key: 'obtained_marks',
          label: 'Obtained Marks',
          keyboardType: TextInputType.number,
          initialValue: result['obtained_marks']?.toString(),
        ),
      ],
      submitText: 'Save Changes',
      initialValues: result,
    );

    if (editResult != null && mounted) {
      final totalMarks =
          double.tryParse(editResult['total_marks'].toString()) ?? 0;
      final obtainedMarks =
          double.tryParse(editResult['obtained_marks'].toString()) ?? 0;
      final percentage = totalMarks > 0
          ? (obtainedMarks / totalMarks) * 100
          : 0;
      final grade = _calculateGrade(percentage);

      final updated = await _adminService.updateResult(result['id'], {
        'total_marks': totalMarks,
        'obtained_marks': obtainedMarks,
        'grade': grade,
        'grade_point': _calculateGradePoint(grade),
      });

      if (updated != null && mounted) {
        showAdminToast(context, message: 'Result updated!', isSuccess: true);
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to update', isError: true);
      }
    }
  }

  Future<void> _deleteResult(Map<String, dynamic> result) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Result',
      message: 'Are you sure you want to delete this result?',
      color: Colors.red,
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final success = await _adminService.deleteResult(result['id']);
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Result deleted!' : 'Failed to delete',
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
          'Result Management',
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
            onPressed: _createResult,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminSearchBar(
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _applyFilters();
                },
                hintText: 'Search by roll, name, or subject...',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdminFilterChips(
                filters: ['All', '1', '2', '3', '4', '5', '6', '7', '8'],
                selectedFilter: _selectedSemester,
                onFilterSelected: (s) {
                  setState(() => _selectedSemester = s);
                  _applyFilters();
                },
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
          _loadResults();
        }),
        isDark: isDark,
      );
    }

    if (_filteredResults.isEmpty) {
      return AdminEmptyState(
        title: 'No Results',
        subtitle: 'Add student results to get started',
        icon: Icons.assessment_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadResults(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) =>
            _buildResultCard(_filteredResults[index], index, isDark),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, int index, bool isDark) {
    final grade = result['grade']?.toString() ?? 'F';
    final gradeColor = _gradeColor(grade);
    final obtained = (result['obtained_marks'] ?? 0).toDouble();
    final total = (result['total_marks'] ?? 0).toDouble();
    final percentage = total > 0
        ? (obtained / total * 100).toStringAsFixed(1)
        : '0.0';

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
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gradeColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                          result['student_name'] ?? 'Unknown',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${result['subject_code']} • ${result['subject_name']}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 11,
                            fontFamily: 'Geist',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AdminStatusBadge(
                              status: 'Sem ${result['semester']}',
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$obtained/$total ($percentage%)',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editResult(result);
                      } else if (value == 'delete') {
                        _deleteResult(result);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
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
