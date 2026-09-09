// =============================================================================
// lib/views/admin/student_management_view.dart
// Student Management View for CPI Admin Panel
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

class StudentManagementView extends StatefulWidget {
  final AppUser user;

  const StudentManagementView({super.key, required this.user});

  @override
  State<StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<StudentManagementView>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService(SupabaseService.client);
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  late AnimationController _bgAnimController;
  late AnimationController _staggerController;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  String _searchQuery = '';
  String _selectedSemester = 'All';

  String get _department {
    final deptMap = {
      'CST': 'COMPUTER SCIENCE',
      'CIVIL': 'CIVIL TECHNOLOGY',
      'EE': 'ELECTRICAL',
      'ME': 'MECHANICAL',
      'ECT': 'ELECTRONICS',
    };
    final shortCode = widget.user.department?.shortCode ?? 'CST';
    return deptMap[shortCode] ?? shortCode;
  }

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadStudents();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  void _loadStudents() {
    _subscription?.cancel();
    setState(() => _isLoading = true);

    _subscription = _adminService
        .getStudentsStream(_department)
        .listen(
          (students) {
            if (mounted) {
              setState(() {
                _students = students;
                _applyFilters();
                _isLoading = false;
                _isProcessing = false;
              });
              _staggerController.forward(from: 0.0);
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

  void _refreshList() {
    _loadStudents();
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
          dropdownItems: [
            'COMPUTER SCIENCE',
            'CIVIL TECHNOLOGY',
            'ELECTRICAL',
            'MECHANICAL',
            'ELECTRONICS',
          ],
          initialValue: _department,
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
      setState(() => _isProcessing = true);
      final student = await _adminService.createStudent({
        ...result,
        'admission_year': DateTime.now().year,
      });
      setState(() => _isProcessing = false);
      if (student != null && mounted) {
        showAdminToast(
          context,
          message: 'Student added successfully!',
          isSuccess: true,
        );
        _refreshList();
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
    final semesterValue = student['semester'];
    final semesterString = semesterValue?.toString() ?? '1';

    print('🔍 Editing student: ${student['student_name']}');
    print('🔍 Student ID: ${student['id']}');
    print(
      '🔍 Semester raw: $semesterValue (type: ${semesterValue.runtimeType})',
    );

    final result = await showAdminFormDialog(
      context,
      title: 'Edit Student',
      fields: [
        FormFieldConfig(
          key: 'student_name',
          label: 'Full Name',
          initialValue: student['student_name']?.toString() ?? '',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          initialValue: student['email']?.toString() ?? '',
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone',
          keyboardType: TextInputType.phone,
          initialValue: student['phone']?.toString() ?? '',
        ),
        FormFieldConfig(
          key: 'semester',
          label: 'Semester',
          dropdownItems: ['1', '2', '3', '4', '5', '6', '7', '8'],
          initialValue: semesterString,
        ),
        FormFieldConfig(
          key: 'class_name',
          label: 'Class',
          initialValue: student['class_name']?.toString() ?? '',
        ),
      ],
      submitText: 'Save Changes',
      initialValues: student,
    );

    print('🔍 Dialog result received: ${result != null ? 'YES' : 'NO'}');

    if (result != null && mounted) {
      print('🔍 Result data: $result');
      setState(() => _isProcessing = true);

      // Build update data with proper types
      final updateData = <String, dynamic>{};

      if (result.containsKey('student_name') &&
          result['student_name'] != null) {
        updateData['student_name'] = result['student_name'].toString();
      }
      if (result.containsKey('email') && result['email'] != null) {
        updateData['email'] = result['email'].toString();
      }
      if (result.containsKey('phone') && result['phone'] != null) {
        updateData['phone'] = result['phone'].toString();
      }
      if (result.containsKey('semester') && result['semester'] != null) {
        // Convert to int
        updateData['semester'] =
            int.tryParse(result['semester'].toString()) ?? 1;
      }
      if (result.containsKey('class_name') && result['class_name'] != null) {
        updateData['class_name'] = result['class_name'].toString();
      }

      print('🔍 Update data prepared: $updateData');

      try {
        final updated = await _adminService.updateStudent(
          student['id'].toString(),
          updateData,
        );

        print('🔍 Update response: $updated');

        setState(() => _isProcessing = false);

        if (updated != null && mounted) {
          showAdminToast(
            context,
            message: 'Student updated successfully!',
            isSuccess: true,
          );
          _refreshList();
        } else if (mounted) {
          showAdminToast(
            context,
            message: 'Failed to update student - no response',
            isError: true,
          );
        }
      } catch (e) {
        print('❌ Update error: $e');
        setState(() => _isProcessing = false);
        if (mounted) {
          showAdminToast(
            context,
            message: 'Failed to update: ${e.toString()}',
            isError: true,
          );
        }
      }
    } else {
      print('🔍 Dialog was cancelled');
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
      setState(() => _isProcessing = true);
      final success = await _adminService.deleteUser(
        'students_login',
        student['id'],
      );
      setState(() => _isProcessing = false);
      if (mounted) {
        showAdminToast(
          context,
          message: success ? 'Student deleted!' : 'Failed to delete',
          isSuccess: success,
          isError: !success,
        );
        if (success) _refreshList();
      }
    }
  }

  @override
  void dispose() {
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _bgAnimController.dispose();
    _staggerController.dispose();
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB).withAlpha(80),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF2563EB),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Student Directory',
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
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _ScaleIconButton(
              onTap: _isProcessing ? null : _createStudent,
              icon: Icons.person_add_alt_1_rounded,
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
        ],
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) =>
            _buildAnimatedStudentCard(_filteredStudents[index], index, isDark),
      ),
    );
  }

  Widget _buildAnimatedStudentCard(
    Map<String, dynamic> student,
    int index,
    bool isDark,
  ) {
    final double start = (index * 0.08).clamp(0.0, 0.6);
    final double end = (start + 0.4).clamp(0.0, 1.0);

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
            offset: Offset(0, 20 * (1 - cardAnimation.value)),
            child: child,
          ),
        );
      },
      child: _StudentGlassCard(
        student: student,
        isDark: isDark,
        isProcessing: _isProcessing,
        onEdit: () => _editStudent(student),
        onDelete: () => _deleteStudent(student),
      ),
    );
  }
}

// ── INTERACTIVE STUDENT CARD ──────────────────────────────────────────────────
class _StudentGlassCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentGlassCard({
    required this.student,
    required this.isDark,
    required this.isProcessing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_StudentGlassCard> createState() => _StudentGlassCardState();
}

class _StudentGlassCardState extends State<_StudentGlassCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final student = widget.student;
    final isDark = widget.isDark;
    final isActive = student['is_active'] == true;

    final name = student['student_name']?.toString() ?? 'Unknown';
    final roll = student['roll_number']?.toString() ?? 'N/A';
    final email = student['email']?.toString() ?? '';
    final className = student['class_name']?.toString() ?? 'N/A';
    final semester = student['semester']?.toString() ?? '0';
    final guardian = student['guardian_name']?.toString();

    final cardColor = isActive
        ? (isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(230))
        : (isDark ? Colors.white.withAlpha(3) : Colors.grey.withAlpha(30));

    final borderColor = isActive
        ? (isDark
              ? const Color(0xFF2563EB).withAlpha(50)
              : const Color(0xFF2563EB).withAlpha(40))
        : (isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(80));

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: cardColor,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [
                                      const Color(0xFF2563EB).withAlpha(90),
                                      const Color(0xFF1D4ED8).withAlpha(40),
                                    ]
                                  : [
                                      Colors.grey.withAlpha(60),
                                      Colors.grey.withAlpha(20),
                                    ],
                            ),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.withAlpha(80),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                fontFamily: 'Geist',
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
                                name,
                                style: TextStyle(
                                  color: isActive
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark
                                            ? Colors.white38
                                            : Colors.grey.shade600),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Roll: $roll',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AdminStatusBadge(
                              status: '${semester}th Sem',
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.withAlpha(60)
                                      : Colors.red.withAlpha(60),
                                ),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildDetailChip(
                          Icons.email_rounded,
                          email,
                          isDark,
                          isActive,
                        ),
                        _buildDetailChip(
                          Icons.class_rounded,
                          className,
                          isDark,
                          isActive,
                        ),
                      ],
                    ),
                    if (guardian != null && guardian.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Guardian: $guardian',
                        style: TextStyle(
                          color: isActive
                              ? (isDark ? Colors.white60 : Colors.black54)
                              : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400),
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButtonPill(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF2563EB),
                          onTap: widget.onEdit,
                          isDark: isDark,
                          isProcessing: widget.isProcessing,
                        ),
                        const SizedBox(width: 6),
                        _ActionButtonPill(
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

  Widget _buildDetailChip(
    IconData icon,
    String label,
    bool isDark,
    bool isActive,
  ) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? (isActive
                  ? Colors.white.withAlpha(10)
                  : Colors.white.withAlpha(5))
            : (isActive
                  ? Colors.black.withAlpha(5)
                  : Colors.grey.withAlpha(20)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? (isActive
                    ? Colors.white.withAlpha(18)
                    : Colors.white.withAlpha(8))
              : (isActive
                    ? Colors.black.withAlpha(10)
                    : Colors.grey.withAlpha(40)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isActive
                ? (isDark ? Colors.white54 : Colors.black54)
                : (isDark ? Colors.white24 : Colors.grey.shade400),
          ),
          const SizedBox(width: 4),
          Text(
            label.length > 20 ? '${label.substring(0, 20)}...' : label,
            style: TextStyle(
              color: isActive
                  ? (isDark ? Colors.white60 : Colors.black54)
                  : (isDark ? Colors.white24 : Colors.grey.shade400),
              fontSize: 10.5,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION BUTTON PILL ───────────────────────────────────────────────────
class _ActionButtonPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool isProcessing;

  const _ActionButtonPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isProcessing
              ? color.withAlpha(10)
              : color.withAlpha(isDark ? 25 : 30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isProcessing ? color.withAlpha(20) : color.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isProcessing ? Icons.hourglass_empty_rounded : icon,
              size: 13,
              color: isProcessing ? color.withAlpha(50) : color,
            ),
            const SizedBox(width: 4),
            Text(
              isProcessing ? '...' : label,
              style: TextStyle(
                color: isProcessing ? color.withAlpha(50) : color,
                fontSize: 11,
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

// ── SCALE ICON BUTTON ──────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
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
            color: widget.accentColor.withAlpha(widget.isDark ? 30 : 40),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.accentColor.withAlpha(80),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.onTap == null ? Colors.grey : widget.accentColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
