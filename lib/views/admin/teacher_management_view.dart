// =============================================================================
// lib/views/admin/teacher_management_view.dart
// CPI Admin Command Center — Ultra-Premium Teacher Roster
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

class TeacherManagementView extends StatefulWidget {
  final AppUser user;

  const TeacherManagementView({super.key, required this.user});

  @override
  State<TeacherManagementView> createState() => _TeacherManagementViewState();
}

class _TeacherManagementViewState extends State<TeacherManagementView>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService(SupabaseService.client);
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  late AnimationController _bgAnimController;
  late AnimationController _staggerController;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  String _searchQuery = '';

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
    _loadTeachers();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  String get _department => widget.user.department?.shortCode ?? 'CST';

  void _loadTeachers() {
    _subscription?.cancel();
    setState(() => _isLoading = true);

    _subscription = _adminService
        .getTeachersStream(_department)
        .listen(
          (teachers) {
            if (mounted) {
              setState(() {
                _teachers = teachers;
                _filterTeachers(_searchQuery);
                _isLoading = false;
                _isProcessing = false;
              });
              // Restart stagger animation for new items
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

  void _filterTeachers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTeachers = _teachers;
      } else {
        _filteredTeachers = _teachers.where((t) {
          final name = t['name']?.toString().toLowerCase() ?? '';
          final teacherId = t['teacher_id']?.toString().toLowerCase() ?? '';
          final dept = t['department']?.toString().toLowerCase() ?? '';
          final q = query.toLowerCase();
          return name.contains(q) || teacherId.contains(q) || dept.contains(q);
        }).toList();
      }
    });
  }

  // ✅ Refresh after any CRUD operation
  void _refreshList() {
    _loadTeachers();
  }

  Future<void> _createTeacher() async {
    final result = await showAdminFormDialog(
      context,
      title: 'Add Faculty Member',
      fields: [
        FormFieldConfig(
          key: 'teacher_id',
          label: 'Teacher ID',
          hint: 'e.g., TCH009',
        ),
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., Dr. Anisur Rahman',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Institutional Email',
          hint: 'e.g., anisur@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone Number',
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
          key: 'password',
          label: 'Initial Password',
          hint: 'Default: teacher123',
          obscureText: true,
        ),
      ],
      submitText: 'Add Faculty',
    );

    if (result != null && mounted) {
      setState(() => _isProcessing = true);
      final teacher = await _adminService.createTeacher(result);
      setState(() => _isProcessing = false);
      if (teacher != null && mounted) {
        showAdminToast(
          context,
          message: 'Faculty added successfully!',
          isSuccess: true,
        );
        _refreshList(); // ✅ Auto-refresh
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to add faculty account',
          isError: true,
        );
      }
    }
  }

  Future<void> _editTeacher(Map<String, dynamic> teacher) async {
    final result = await showAdminFormDialog(
      context,
      title: 'Edit Faculty Profile',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Full Name',
          hint: 'e.g., Dr. Anisur Rahman',
          initialValue: teacher['name'],
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email Address',
          hint: 'e.g., anisur@cpi.edu.bd',
          keyboardType: TextInputType.emailAddress,
          initialValue: teacher['email'],
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Phone Contact',
          hint: 'e.g., 01712345678',
          keyboardType: TextInputType.phone,
          initialValue: teacher['phone'],
        ),
        FormFieldConfig(
          key: 'department',
          label: 'Department',
          dropdownItems: ['CST', 'CIVIL', 'EE', 'ME', 'ECT'],
          initialValue: teacher['department'] ?? _department,
        ),
      ],
      submitText: 'Save Changes',
      initialValues: teacher,
    );

    if (result != null && mounted) {
      setState(() => _isProcessing = true);
      final updated = await _adminService.updateTeacher(teacher['id'], result);
      setState(() => _isProcessing = false);
      if (updated != null && mounted) {
        showAdminToast(
          context,
          message: 'Faculty profile updated!',
          isSuccess: true,
        );
        _refreshList(); // ✅ Auto-refresh
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to save changes',
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> teacher) async {
    final isActive = teacher['is_active'] == true;
    final newStatus = !isActive;

    final confirmed = await showAdminConfirmDialog(
      context,
      title: isActive ? 'Deactivate Access' : 'Activate Access',
      message:
          'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} ${teacher['name']}?',
      color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      confirmText: isActive ? 'Deactivate' : 'Activate',
    );

    if (confirmed && mounted) {
      setState(() => _isProcessing = true);

      try {
        final success = await _adminService.toggleUserStatus(
          'teachers_login',
          teacher['id'],
          newStatus,
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          if (success) {
            showAdminToast(
              context,
              message: isActive ? 'Teacher deactivated!' : 'Teacher activated!',
              isSuccess: true,
            );
            _refreshList(); // ✅ Auto-refresh
          } else {
            showAdminToast(
              context,
              message: 'Status update failed',
              isError: true,
            );
          }
        }
      } catch (e) {
        print('❌ Error toggling status: $e');
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

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Faculty Account',
      message:
          'Are you sure you want to delete ${teacher['name']}? This action is permanent.',
      color: const Color(0xFFEF4444),
      confirmText: 'Delete Account',
    );

    if (confirmed && mounted) {
      setState(() => _isProcessing = true);

      try {
        final success = await _adminService.deleteUser(
          'teachers_login',
          teacher['id'],
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          if (success) {
            showAdminToast(
              context,
              message: 'Account deleted successfully!',
              isSuccess: true,
            );
            _refreshList(); // ✅ Auto-refresh
          } else {
            showAdminToast(context, message: 'Deletion failed', isError: true);
          }
        }
      } catch (e) {
        print('❌ Error deleting teacher: $e');
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
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withAlpha(80),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.supervisor_account_rounded,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Teacher Roster',
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
              onTap: _isProcessing ? null : _createTeacher,
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
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AdminSearchBar(
                    onChanged: _filterTeachers,
                    hintText: 'Search by name, ID, or department...',
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
          _loadTeachers();
        }),
        isDark: isDark,
      );
    }

    if (_filteredTeachers.isEmpty) {
      return AdminEmptyState(
        title: 'No Faculty Found',
        subtitle: _searchQuery.isEmpty
            ? 'Tap + to add your first faculty member.'
            : 'No matching teachers found.',
        icon: Icons.supervisor_account_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTeachers(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filteredTeachers.length,
        itemBuilder: (context, index) =>
            _buildAnimatedTeacherCard(_filteredTeachers[index], index, isDark),
      ),
    );
  }

  Widget _buildAnimatedTeacherCard(
    Map<String, dynamic> teacher,
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
      child: _InteractiveGlassCard(
        teacher: teacher,
        isDark: isDark,
        isProcessing: _isProcessing,
        onToggleStatus: () => _toggleStatus(teacher),
        onEdit: () => _editTeacher(teacher),
        onDelete: () => _deleteTeacher(teacher),
      ),
    );
  }
}

// ── INTERACTIVE CARD WITH TACTILE TOUCH ──────────────────────────────────
class _InteractiveGlassCard extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InteractiveGlassCard({
    required this.teacher,
    required this.isDark,
    required this.isProcessing,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InteractiveGlassCard> createState() => _InteractiveGlassCardState();
}

class _InteractiveGlassCardState extends State<_InteractiveGlassCard>
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
    final teacher = widget.teacher;
    final isDark = widget.isDark;
    final isActive = teacher['is_active'] == true;

    final name = teacher['name']?.toString() ?? 'Unknown';
    final teacherId = teacher['teacher_id']?.toString() ?? 'N/A';
    final email = teacher['email']?.toString() ?? '';
    final phone = teacher['phone']?.toString() ?? '';
    final dept = teacher['department']?.toString() ?? 'CST';

    // 🔥 Card style based on active status
    final cardColor = isActive
        ? (isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(230))
        : (isDark
              ? Colors.white.withAlpha(3) // Almost transparent - dead look
              : Colors.grey.withAlpha(30)); // Greyed out - dead look

    final borderColor = isActive
        ? (isDark
              ? const Color(0xFF10B981).withAlpha(50)
              : const Color(0xFF10B981).withAlpha(40))
        : (isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(80));

    final avatarGradient = isActive
        ? [
            const Color(0xFF10B981).withAlpha(90),
            const Color(0xFF059669).withAlpha(40),
          ]
        : [Colors.grey.withAlpha(60), Colors.grey.withAlpha(20)];

    final nameColor = isActive
        ? (isDark ? Colors.white : AppColors.lightPrimaryText)
        : (isDark ? Colors.white38 : Colors.grey.shade600);

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
                            gradient: LinearGradient(colors: avatarGradient),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.withAlpha(80),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'T',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade500),
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
                                  color: nameColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
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
                                  'ID: $teacherId',
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
                        // Status Badge with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withAlpha(30)
                                : const Color(0xFFEF4444).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF10B981).withAlpha(60)
                                  : const Color(0xFFEF4444).withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          Icons.phone_rounded,
                          phone,
                          isDark,
                          isActive,
                        ),
                        _buildDetailChip(
                          Icons.business_rounded,
                          dept,
                          isDark,
                          isActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                          label: isActive ? 'Deactivate' : 'Activate',
                          icon: isActive
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded,
                          color: isActive
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                          onTap: widget.onToggleStatus,
                          isDark: isDark,
                          isProcessing: widget.isProcessing,
                        ),
                        const SizedBox(width: 6),
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
                          icon: Icons.delete_outline_rounded,
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
                  ? AppColors.lightCardBorderAlt
                  : Colors.grey.withAlpha(20)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? (isActive
                    ? Colors.white.withAlpha(18)
                    : Colors.white.withAlpha(8))
              : (isActive
                    ? AppColors.lightCardBorder
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
                ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))
                : (isDark ? Colors.white24 : Colors.grey.shade500),
          ),
          const SizedBox(width: 5),
          Text(
            label.length > 22 ? '${label.substring(0, 22)}...' : label,
            style: TextStyle(
              color: isActive
                  ? (isDark
                        ? Colors.white.withAlpha(210)
                        : AppColors.lightPrimaryText)
                  : (isDark ? Colors.white24 : Colors.grey.shade500),
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

// ── SCALE ICON BUTTON FOR APPBAR ──────────────────────────────────────────
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
