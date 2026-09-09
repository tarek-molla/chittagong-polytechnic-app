// =============================================================================
// lib/views/admin/result_management_view.dart
// Premium Result Management View with Animations - FULLY FIXED
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
import 'package:cpi_app/widgets/offline_indicator_badge.dart';
import 'package:cpi_app/widgets/skeleton_loader.dart';
import 'package:cpi_app/services/supabase_service.dart';

class ResultManagementView extends StatefulWidget {
  final AppUser user;

  const ResultManagementView({super.key, required this.user});

  @override
  State<ResultManagementView> createState() => _ResultManagementViewState();
}

class _ResultManagementViewState extends State<ResultManagementView>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService(SupabaseService.client);
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  late AnimationController _bgAnimController;
  late AnimationController _staggerController;
  late AnimationController _fabController;

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  String _searchQuery = '';
  String _selectedSemester = 'All';
  bool _isSearching = false;

  // Stats
  int _totalStudents = 0;
  double _averageGPA = 0.0;
  Map<String, int> _gradeDistribution = {};

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadResults();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  String get _department {
    final deptMap = {
      'CST': 'CST',
      'CIVIL': 'CIVIL TECHNOLOGY',
      'EE': 'ELECTRICAL',
      'ME': 'MECHANICAL',
      'ECT': 'ELECTRONICS',
      'POWER': 'POWER',
      'ENVIRONMENTAL': 'ENVIRONMENTAL',
    };
    final shortCode = widget.user.department?.shortCode ?? '';
    return deptMap[shortCode] ?? shortCode;
  }

  void _loadResults() {
    _subscription?.cancel();
    setState(() => _isLoading = true);

    _subscription = _adminService
        .getResultsStream(_department)
        .listen(
          (results) {
            if (mounted) {
              setState(() {
                _results = results;
                _calculateStats();
                _applyFilters();
                _isLoading = false;
                _isProcessing = false;
              });
              _staggerController.forward(from: 0.0);
              _fabController.forward();
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _error = error.toString();
                _isLoading = false;
                _isProcessing = false;
              });
            }
          },
        );
  }

  void _calculateStats() {
    if (_results.isEmpty) {
      _totalStudents = 0;
      _averageGPA = 0.0;
      _gradeDistribution = {};
      return;
    }

    final uniqueStudents = _results
        .map((r) => r['student_name']?.toString())
        .toSet();
    _totalStudents = uniqueStudents.length;

    double totalGPA = 0;
    int count = 0;
    _gradeDistribution = {};

    for (var r in _results) {
      final gpa = (r['gpa'] as num?)?.toDouble() ?? 0;
      if (gpa > 0) {
        totalGPA += gpa;
        count++;
      }
      final grade = r['grade']?.toString() ?? 'N/A';
      _gradeDistribution[grade] = (_gradeDistribution[grade] ?? 0) + 1;
    }
    _averageGPA = count > 0 ? totalGPA / count : 0.0;
  }

  void _refreshList() {
    _loadResults();
  }

  void _applyFilters() {
    setState(() {
      _filteredResults = _results.where((r) {
        final name = r['student_name']?.toString().toLowerCase() ?? '';
        final roll = r['roll_num']?.toString().toLowerCase() ?? '';
        final reg = r['reg_num']?.toString().toLowerCase() ?? '';
        final subject = r['subject_name']?.toString().toLowerCase() ?? '';
        final matchesSearch =
            _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            roll.contains(_searchQuery.toLowerCase()) ||
            reg.contains(_searchQuery.toLowerCase()) ||
            subject.contains(_searchQuery.toLowerCase());

        final matchesSemester =
            _selectedSemester == 'All' ||
            r['semester']?.toString() == _selectedSemester;

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
        return const Color(0xFF10B981);
      case 'A':
        return const Color(0xFF34D399);
      case 'A-':
        return const Color(0xFF6EE7B7);
      case 'B+':
        return const Color(0xFF60A5FA);
      case 'B':
        return const Color(0xFF93C5FD);
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
          key: 'roll_num',
          label: 'Roll Number',
          hint: 'e.g., 786602',
        ),
        FormFieldConfig(
          key: 'reg_num',
          label: 'Registration Number',
          hint: 'e.g., 1502301901',
        ),
        FormFieldConfig(
          key: 'student_name',
          label: 'Student Name',
          hint: 'e.g., RAHAT KHAN',
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
          dropdownItems: const [
            '1ST SEMESTER',
            '2ND SEMESTER',
            '3RD SEMESTER',
            '4TH SEMESTER',
            '5TH SEMESTER',
            '6TH SEMESTER',
            '7TH SEMESTER',
            '8TH SEMESTER',
          ],
          initialValue: '1ST SEMESTER',
        ),
        FormFieldConfig(
          key: 'credits',
          label: 'Credits',
          hint: 'e.g., 3',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'theory_continuous',
          label: 'Theory Continuous Marks',
          hint: 'e.g., 85',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'theory_continuous_max',
          label: 'Theory Continuous Max',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'practical_continuous',
          label: 'Practical Continuous Marks',
          hint: 'e.g., 90',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'practical_continuous_max',
          label: 'Practical Continuous Max',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'final_exam',
          label: 'Final Exam Marks',
          hint: 'e.g., 88',
          keyboardType: TextInputType.number,
        ),
        FormFieldConfig(
          key: 'final_exam_max',
          label: 'Final Exam Max',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
      ],
      submitText: 'Add Result',
    );

    if (result != null && mounted) {
      setState(() => _isProcessing = true);

      final theory =
          double.tryParse(result['theory_continuous']?.toString() ?? '0') ?? 0;
      final theoryMax =
          double.tryParse(
            result['theory_continuous_max']?.toString() ?? '100',
          ) ??
          100;
      final practical =
          double.tryParse(result['practical_continuous']?.toString() ?? '0') ??
          0;
      final practicalMax =
          double.tryParse(
            result['practical_continuous_max']?.toString() ?? '100',
          ) ??
          100;
      final finalExam =
          double.tryParse(result['final_exam']?.toString() ?? '0') ?? 0;
      final finalMax =
          double.tryParse(result['final_exam_max']?.toString() ?? '100') ?? 100;

      final totalObtained = theory + practical + finalExam;
      final totalMax = theoryMax + practicalMax + finalMax;
      final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
      final grade = _calculateGrade(percentage);
      final gradePoint = _calculateGradePoint(grade);
      final credits =
          double.tryParse(result['credits']?.toString() ?? '3') ?? 3;
      final gpa = (gradePoint * credits) / credits;

      final newResult = await _adminService.createResult({
        ...result,
        'grade': grade,
        'grade_point': gradePoint,
        'gpa': gpa,
        'department': _department,
      });

      setState(() => _isProcessing = false);

      if (newResult != null && mounted) {
        showAdminToast(
          context,
          message: 'Result added successfully! 🎉',
          isSuccess: true,
        );
        _refreshList();
      } else if (mounted) {
        showAdminToast(context, message: 'Failed to add result', isError: true);
      }
    }
  }

  // ===========================================================================
  // FIXED: _editResult - Uses showAdminFormDialog properly
  // ===========================================================================
  Future<void> _editResult(Map<String, dynamic> result) async {
    print('🔍 Editing result: ${result['student_name']}');
    print('🔍 Result ID: ${result['id']}');

    try {
      final editResult = await showAdminFormDialog(
        context,
        title: 'Edit Result',
        fields: [
          FormFieldConfig(
            key: 'theory_continuous',
            label: 'Theory Continuous Marks',
            keyboardType: TextInputType.number,
            initialValue: result['theory_continuous']?.toString() ?? '0',
          ),
          FormFieldConfig(
            key: 'theory_continuous_max',
            label: 'Theory Continuous Max',
            keyboardType: TextInputType.number,
            initialValue: result['theory_continuous_max']?.toString() ?? '100',
          ),
          FormFieldConfig(
            key: 'practical_continuous',
            label: 'Practical Continuous Marks',
            keyboardType: TextInputType.number,
            initialValue: result['practical_continuous']?.toString() ?? '0',
          ),
          FormFieldConfig(
            key: 'practical_continuous_max',
            label: 'Practical Continuous Max',
            keyboardType: TextInputType.number,
            initialValue:
                result['practical_continuous_max']?.toString() ?? '100',
          ),
          FormFieldConfig(
            key: 'final_exam',
            label: 'Final Exam Marks',
            keyboardType: TextInputType.number,
            initialValue: result['final_exam']?.toString() ?? '0',
          ),
          FormFieldConfig(
            key: 'final_exam_max',
            label: 'Final Exam Max',
            keyboardType: TextInputType.number,
            initialValue: result['final_exam_max']?.toString() ?? '100',
          ),
        ],
        submitText: 'Save Changes',
      );

      print('🔍 Dialog result received: ${editResult != null ? 'YES' : 'NO'}');

      if (editResult != null && mounted) {
        setState(() => _isProcessing = true);

        final theory =
            double.tryParse(
              editResult['theory_continuous']?.toString() ?? '0',
            ) ??
            0;
        final theoryMax =
            double.tryParse(
              editResult['theory_continuous_max']?.toString() ?? '100',
            ) ??
            100;
        final practical =
            double.tryParse(
              editResult['practical_continuous']?.toString() ?? '0',
            ) ??
            0;
        final practicalMax =
            double.tryParse(
              editResult['practical_continuous_max']?.toString() ?? '100',
            ) ??
            100;
        final finalExam =
            double.tryParse(editResult['final_exam']?.toString() ?? '0') ?? 0;
        final finalMax =
            double.tryParse(
              editResult['final_exam_max']?.toString() ?? '100',
            ) ??
            100;

        final totalObtained = theory + practical + finalExam;
        final totalMax = theoryMax + practicalMax + finalMax;
        final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
        final grade = _calculateGrade(percentage);
        final gradePoint = _calculateGradePoint(grade);
        final credits =
            double.tryParse(result['credits']?.toString() ?? '3') ?? 3;
        final gpa = (gradePoint * credits) / credits;

        final updateData = {
          'theory_continuous': theory,
          'theory_continuous_max': theoryMax,
          'practical_continuous': practical,
          'practical_continuous_max': practicalMax,
          'final_exam': finalExam,
          'final_exam_max': finalMax,
          'grade': grade,
          'grade_point': gradePoint,
          'gpa': gpa,
        };

        print('🔍 Update data: $updateData');

        final updated = await _adminService.updateResult(
          result['id'].toString(),
          updateData,
        );

        setState(() => _isProcessing = false);

        if (updated != null && mounted) {
          showAdminToast(
            context,
            message: 'Result updated successfully! ✨',
            isSuccess: true,
          );
          _refreshList();
        } else if (mounted) {
          showAdminToast(
            context,
            message: 'Failed to update result',
            isError: true,
          );
        }
      }
    } catch (e) {
      print('❌ Edit error: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        showAdminToast(
          context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // ===========================================================================
  // FIXED: _deleteResult - Uses showAdminConfirmDialog properly
  // ===========================================================================
  Future<void> _deleteResult(Map<String, dynamic> result) async {
    // Use the properly working showAdminConfirmDialog
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Result',
      message:
          'Are you sure you want to delete this result for "${result['student_name']}"?\n\nSubject: ${result['subject_name'] ?? 'N/A'}\nGrade: ${result['grade'] ?? 'N/A'}',
      color: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );

    print('🔍 Delete confirmed: $confirmed');

    if (confirmed && mounted) {
      setState(() => _isProcessing = true);
      try {
        final success = await _adminService.deleteResult(
          result['id'].toString(),
        );
        setState(() => _isProcessing = false);

        if (mounted) {
          if (success) {
            showAdminToast(
              context,
              message: 'Result deleted successfully! 🗑️',
              isSuccess: true,
            );
            _refreshList();
          } else {
            showAdminToast(
              context,
              message: 'Failed to delete result',
              isError: true,
            );
          }
        }
      } catch (e) {
        print('❌ Delete error: $e');
        setState(() => _isProcessing = false);
        if (mounted) {
          showAdminToast(
            context,
            message: 'Error: ${e.toString()}',
            isError: true,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _bgAnimController.dispose();
    _staggerController.dispose();
    _fabController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final isStandaloneRoute =
        ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF7B61FF), const Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assessment_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Result Portal',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          const Center(child: OfflineIndicatorBadge()),
          const SizedBox(width: 8),
          if (_filteredResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _ScaleIconButton(
                onTap: () => _showStatsDialog(isDark),
                icon: Icons.bar_chart_rounded,
                accentColor: const Color(0xFF7B61FF),
                isDark: isDark,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _ScaleIconButton(
              onTap: _isProcessing ? null : _createResult,
              icon: Icons.add_rounded,
              accentColor: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
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
                if (_filteredResults.isNotEmpty) _buildStatsBar(isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildAnimatedSearchBar(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAnimatedFilterChips(isDark),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildContent(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withAlpha(10)
            : Colors.white.withAlpha(200),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '🎓',
            '$_totalStudents',
            'Students',
            isDark,
            const Color(0xFF7B61FF),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(20),
          ),
          _buildStatItem(
            '📈',
            _averageGPA.toStringAsFixed(2),
            'Avg GPA',
            isDark,
            const Color(0xFF10B981),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(20),
          ),
          _buildStatItem(
            '📊',
            '${_filteredResults.length}',
            'Records',
            isDark,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String icon,
    String value,
    String label,
    bool isDark,
    Color color,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 9,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSearchBar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withAlpha(10)
            : Colors.white.withAlpha(220),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(_isSearching ? 40 : 15)
              : Colors.black.withAlpha(_isSearching ? 30 : 10),
          width: _isSearching ? 2 : 1,
        ),
        boxShadow: _isSearching
            ? [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withAlpha(30),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        onTap: () => setState(() => _isSearching = true),
        onSubmitted: (_) => setState(() => _isSearching = false),
        decoration: InputDecoration(
          hintText: '🔍 Search students, roll, or subject...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
            fontFamily: 'Geist',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                    });
                    _applyFilters();
                  },
                )
              : null,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildAnimatedFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('All', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('1ST SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('2ND SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('3RD SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('4TH SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('5TH SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('6TH SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('7TH SEMESTER', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('8TH SEMESTER', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedSemester == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? const Color(0xFF7B61FF)
            : isDark
            ? Colors.white.withAlpha(10)
            : Colors.white.withAlpha(200),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7B61FF)
              : isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(15),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: GestureDetector(
        onTap: () => _onSemesterChanged(label),
        child: Text(
          label == 'All' ? 'All' : label.replaceAll(' SEMESTER', ''),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white70
                : Colors.black87,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const SkeletonList(itemCount: 6);
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
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadResults(),
      color: const Color(0xFF7B61FF),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) =>
            _buildAnimatedResultCard(_filteredResults[index], index, isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B61FF).withAlpha(30),
                  const Color(0xFFF59E0B).withAlpha(30),
                ],
              ),
            ),
            child: Icon(
              Icons.assessment_rounded,
              size: 60,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedSemester == 'All'
                ? 'Add student results to get started 🚀'
                : 'Try adjusting your filters or search',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _selectedSemester != 'All')
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedSemester = 'All';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
                side: const BorderSide(color: Color(0xFF7B61FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedResultCard(
    Map<String, dynamic> result,
    int index,
    bool isDark,
  ) {
    final double start = (index * 0.06).clamp(0.0, 0.5);
    final double end = (start + 0.3).clamp(0.0, 1.0);

    final Animation<double> cardAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: cardAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: cardAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - cardAnimation.value)),
            child: child,
          ),
        );
      },
      child: _PremiumResultCard(
        result: result,
        isDark: isDark,
        isProcessing: _isProcessing,
        onEdit: () => _editResult(result),
        onDelete: () => _deleteResult(result),
      ),
    );
  }

  void _showStatsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _PremiumStatsDialog(
        totalStudents: _totalStudents,
        averageGPA: _averageGPA,
        totalRecords: _filteredResults.length,
        gradeDistribution: _gradeDistribution,
        isDark: isDark,
      ),
    );
  }
}

// ── PREMIUM RESULT CARD ──────────────────────────────────────────────────────
class _PremiumResultCard extends StatefulWidget {
  final Map<String, dynamic> result;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PremiumResultCard({
    required this.result,
    required this.isDark,
    required this.isProcessing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PremiumResultCard> createState() => _PremiumResultCardState();
}

class _PremiumResultCardState extends State<_PremiumResultCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isDark = widget.isDark;

    final grade = result['grade']?.toString() ?? 'F';
    final gradeColor = _gradeColor(grade);

    final theory = (result['theory_continuous'] ?? 0).toDouble();
    final theoryMax = (result['theory_continuous_max'] ?? 100).toDouble();
    final practical = (result['practical_continuous'] ?? 0).toDouble();
    final practicalMax = (result['practical_continuous_max'] ?? 100).toDouble();
    final finalExam = (result['final_exam'] ?? 0).toDouble();
    final finalMax = (result['final_exam_max'] ?? 100).toDouble();

    final totalObtained = theory + practical + finalExam;
    final totalMax = theoryMax + practicalMax + finalMax;

    final gpa = result['gpa']?.toStringAsFixed(2) ?? '0.00';

    final studentName = result['student_name']?.toString() ?? 'Unknown';
    final rollNumber = result['roll_num']?.toString() ?? 'N/A';
    final regNumber = result['reg_num']?.toString() ?? 'N/A';
    final subjectCode = result['subject_code']?.toString() ?? '';
    final subjectName = result['subject_name']?.toString() ?? '';
    final semester = result['semester']?.toString() ?? '0';

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.white.withAlpha(15), Colors.white.withAlpha(5)]
                  : [Colors.white.withAlpha(240), Colors.white.withAlpha(220)],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(40)
                    : Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
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
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [gradeColor, gradeColor.withAlpha(180)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: gradeColor.withAlpha(80),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gradeColor.withAlpha(40),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              grade,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  _buildBadge(
                                    '🎓 $rollNumber',
                                    const Color(0xFFF59E0B),
                                  ),
                                  _buildBadge(
                                    '📋 $regNumber',
                                    const Color(0xFF7B61FF),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSemesterBadge(semester, isDark),
                            const SizedBox(height: 6),
                            _buildGPABadge(gpa),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$subjectCode • $subjectName',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB).withAlpha(30),
                                const Color(0xFF7B61FF).withAlpha(30),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withAlpha(40),
                            ),
                          ),
                          child: Text(
                            '${totalObtained.round()}/$totalMax',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(10),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: totalMax > 0
                            ? totalObtained / totalMax
                            : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [gradeColor, gradeColor.withAlpha(180)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _PremiumActionButton(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF7B61FF),
                          onTap: widget.onEdit,
                          isDark: isDark,
                          isProcessing: widget.isProcessing,
                        ),
                        const SizedBox(width: 8),
                        _PremiumActionButton(
                          label: 'Delete',
                          icon: Icons.delete_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: widget.onDelete,
                          isDark: isDark,
                          isProcessing: widget.isProcessing,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildSemesterBadge(String semester, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(40)),
      ),
      child: Text(
        '📚 $semester',
        style: const TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildGPABadge(String gpa) {
    final gpaValue = double.tryParse(gpa) ?? 0;
    final color = gpaValue >= 3.5
        ? const Color(0xFF10B981)
        : gpaValue >= 3.0
        ? const Color(0xFF60A5FA)
        : gpaValue >= 2.5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(30), color.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '⭐ $gpa',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }
}

// ── PREMIUM ACTION BUTTON ──────────────────────────────────────────────────
class _PremiumActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool isProcessing;

  const _PremiumActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 15 : 20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isProcessing ? Icons.hourglass_empty_rounded : icon,
              size: 14,
              color: isProcessing ? color.withAlpha(50) : color,
            ),
            const SizedBox(width: 4),
            Text(
              isProcessing ? '...' : label,
              style: TextStyle(
                color: isProcessing ? color.withAlpha(50) : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PREMIUM STATS DIALOG ──────────────────────────────────────────────────
class _PremiumStatsDialog extends StatelessWidget {
  final int totalStudents;
  final double averageGPA;
  final int totalRecords;
  final Map<String, int> gradeDistribution;
  final bool isDark;

  const _PremiumStatsDialog({
    required this.totalStudents,
    required this.averageGPA,
    required this.totalRecords,
    required this.gradeDistribution,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? const Color(0xFF1A1F36) : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(10),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B61FF).withAlpha(20),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF7B61FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistics',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('🎓', '$totalStudents', 'Students', isDark),
                const SizedBox(width: 12),
                _buildStatCard(
                  '📈',
                  averageGPA.toStringAsFixed(2),
                  'Avg GPA',
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStatCard('📊', '$totalRecords', 'Records', isDark),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(5)
                    : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Grade Distribution',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gradeDistribution.entries.map((entry) {
                      final color = _gradeColor(entry.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withAlpha(40)),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7B61FF),
                  backgroundColor: const Color(0xFF7B61FF).withAlpha(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 10,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SCALE ICON BUTTON ────────────────────────────────────────────────────────
class _ScaleIconButton extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _ScaleIconButton({
    this.onTap,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_ScaleIconButton> createState() => _ScaleIconButtonState();
}

class _ScaleIconButtonState extends State<_ScaleIconButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accentColor.withAlpha(widget.isDark ? 30 : 40),
                widget.accentColor.withAlpha(widget.isDark ? 15 : 20),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.accentColor.withAlpha(60),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.onTap == null ? Colors.grey : widget.accentColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────
Color _gradeColor(String grade) {
  switch (grade) {
    case 'A+':
      return const Color(0xFF10B981);
    case 'A':
      return const Color(0xFF34D399);
    case 'A-':
      return const Color(0xFF6EE7B7);
    case 'B+':
      return const Color(0xFF60A5FA);
    case 'B':
      return const Color(0xFF93C5FD);
    case 'C':
      return const Color(0xFFF59E0B);
    case 'D':
      return const Color(0xFFEF4444);
    default:
      return Colors.grey;
  }
}
