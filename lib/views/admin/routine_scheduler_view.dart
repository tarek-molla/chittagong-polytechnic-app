// =============================================================================
// lib/views/admin/routine_scheduler_view.dart
// Premium Routine Scheduling Matrix - Fully Responsive & Fixed
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/user_role.dart' as role_model;
import '../../services/supabase_service.dart';
import '../../services/admin_service.dart';
import '../../core/colors.dart';
import '../../core/router.dart';
import '../../core/theme_provider.dart';
import '../../widgets/animated_background_painter.dart';
import '../../widgets/offline_indicator_badge.dart';
import '../../widgets/skeleton_loader.dart';

class RoutineSchedulerView extends StatefulWidget {
  final AppUser user;
  const RoutineSchedulerView({super.key, required this.user});

  @override
  State<RoutineSchedulerView> createState() => _RoutineSchedulerViewState();
}

class _RoutineSchedulerViewState extends State<RoutineSchedulerView>
    with TickerProviderStateMixin {
  String _selectedDay = 'SUN';
  StreamSubscription? _routineSubscription;
  List<Map<String, dynamic>> _routineData = [];
  bool _isLoading = true;
  String? _errorMessage;
  AdminService? _adminService;
  late AnimationController _bgAnimController;
  late AnimationController _staggerController;
  late AnimationController _fabController;
  late AnimationController _glowController;

  // Form controllers
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController(text: '08:00');
  final _endTimeCtrl = TextEditingController(text: '09:30');
  final _semesterCtrl = TextEditingController(text: '1');
  final _departmentCtrl = TextEditingController();

  final List<String> _days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  final List<Color> _dayColors = [
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
  ];

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
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _adminService = AdminService(SupabaseService.client);
    _departmentCtrl.text = _department;
    _loadRoutineData();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  String get _department => widget.user.department?.shortCode ?? 'CST';

  void _loadRoutineData() {
    _routineSubscription?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _routineSubscription = _adminService!
        .getRoutineStream(_department)
        .listen(
          (data) {
            if (mounted) {
              setState(() {
                _routineData = data;
                _isLoading = false;
              });
              _staggerController.forward(from: 0.0);
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.toString();
                _isLoading = false;
              });
            }
          },
        );
  }

  List<Map<String, dynamic>> _getSlotsForDay(String day) {
    final dayMap = {
      'SUN': 'Sunday',
      'MON': 'Monday',
      'TUE': 'Tuesday',
      'WED': 'Wednesday',
      'THU': 'Thursday',
      'FRI': 'Friday',
      'SAT': 'Saturday',
    };
    final fullDay = dayMap[day] ?? day;
    return _routineData.where((slot) {
      final slotDay = (slot['day'] ?? '').toString().toUpperCase();
      final slotDayName = (slot['day_name'] ?? '').toString().toUpperCase();
      final slotDayShort = slotDayName.isNotEmpty && slotDayName.length >= 3
          ? slotDayName.substring(0, 3)
          : '';
      return slotDay == day ||
          slotDayName == day ||
          slotDayName == fullDay ||
          slotDayShort == day;
    }).toList();
  }

  void _showAddSlotDialog() {
    _subjectCtrl.clear();
    _classCtrl.clear();
    _roomCtrl.clear();
    _teacherCtrl.clear();
    _startTimeCtrl.text = '08:00';
    _endTimeCtrl.text = '09:30';
    _semesterCtrl.text = '1';
    _departmentCtrl.text = _department;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildPremiumFormDialog(ctx, null),
    );
  }

  void _showEditSlotDialog(Map<String, dynamic> slot) {
    _subjectCtrl.text = slot['subject_name'] ?? slot['subject'] ?? '';
    _classCtrl.text = slot['class_name'] ?? slot['class'] ?? '';
    _roomCtrl.text = slot['room'] ?? '';
    _teacherCtrl.text = slot['teacher_name'] ?? slot['teacher'] ?? '';
    _startTimeCtrl.text = slot['start_time'] ?? '08:00';
    _endTimeCtrl.text = slot['end_time'] ?? '09:30';
    _semesterCtrl.text = (slot['semester'] ?? 1).toString();
    _departmentCtrl.text = slot['department'] ?? _department;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildPremiumFormDialog(ctx, slot),
    );
  }

  Widget _buildPremiumFormDialog(
    BuildContext ctx,
    Map<String, dynamic>? existingSlot,
  ) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existingSlot != null;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          maxWidth: 440,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1B2333), const Color(0xFF0F1522)]
                : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.7)
                  : const Color(0xFF3B82F6).withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isEditing
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF2563EB),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF06B6D4),
                                      Color(0xFF0891B2),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isEditing
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF06B6D4))
                                        .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_rounded
                                : Icons.schedule_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Edit Routine Slot'
                                    : 'Schedule New Slot',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0C4A6E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEditing
                                    ? 'Update the class schedule details'
                                    : 'Add a new class to the routine',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(
                                          0xFF0C4A6E,
                                        ).withOpacity(0.7),
                                  fontSize: 12,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF0C4A6E),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Form Fields
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildFormField(
                              label: 'Subject Name',
                              hint: 'Enter subject name',
                              controller: _subjectCtrl,
                              icon: Icons.book_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a subject';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              label: 'Class / Batch',
                              hint: 'e.g., CST-3rd-A',
                              controller: _classCtrl,
                              icon: Icons.class_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a class';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              label: 'Room Number',
                              hint: 'e.g., 301',
                              controller: _roomCtrl,
                              icon: Icons.meeting_room_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a room number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              label: 'Faculty Teacher',
                              hint: 'Enter teacher name',
                              controller: _teacherCtrl,
                              icon: Icons.person_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a teacher name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Start Time',
                                    hint: '08:00',
                                    controller: _startTimeCtrl,
                                    icon: Icons.access_time_rounded,
                                    isDark: isDark,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'End Time',
                                    hint: '09:30',
                                    controller: _endTimeCtrl,
                                    icon: Icons.access_time_rounded,
                                    isDark: isDark,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              label: 'Semester',
                              hint: 'e.g., 1',
                              controller: _semesterCtrl,
                              icon: Icons.numbers_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a semester';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              label: 'Department',
                              hint: 'e.g., CST',
                              controller: _departmentCtrl,
                              icon: Icons.business_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a department';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Bottom Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF0C4A6E),
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isEditing
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFF06B6D4))
                                          .withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(ctx);
                                  await _saveRoutineSlot(existingSlot);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: isEditing
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF06B6D4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? 'UPDATE SLOT' : 'ADD SLOT',
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF0C4A6E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C4A6E),
            fontSize: 14,
            fontFamily: 'Geist',
          ),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : const Color(0xFF0C4A6E).withOpacity(0.4),
              fontSize: 13,
              fontFamily: 'Geist',
            ),
            prefixIcon: Icon(
              icon,
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF0C4A6E).withOpacity(0.4),
              size: 18,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveRoutineSlot(Map<String, dynamic>? existingSlot) async {
    if (_adminService == null) return;

    final dayMap = {
      'SUN': 'Sunday',
      'MON': 'Monday',
      'TUE': 'Tuesday',
      'WED': 'Wednesday',
      'THU': 'Thursday',
      'FRI': 'Friday',
      'SAT': 'Saturday',
    };

    final data = {
      'subject_name': _subjectCtrl.text.trim(),
      'class_name': _classCtrl.text.trim(),
      'room': _roomCtrl.text.trim(),
      'teacher_name': _teacherCtrl.text.trim(),
      'start_time': _startTimeCtrl.text.trim(),
      'end_time': _endTimeCtrl.text.trim(),
      'semester': int.tryParse(_semesterCtrl.text.trim()) ?? 1,
      'department': _departmentCtrl.text.trim().toUpperCase(),
      'day': dayMap[_selectedDay] ?? _selectedDay,
      'day_name': dayMap[_selectedDay] ?? _selectedDay,
      'is_active': true,
    };

    try {
      if (existingSlot != null) {
        await _adminService!.updateRoutine(existingSlot['id'].toString(), data);
        _showSnackBar(
          'Routine slot updated successfully ✨',
          const Color(0xFF10B981),
        );
      } else {
        await _adminService!.createRoutine(data);
        _showSnackBar(
          'Routine slot added successfully 🎉',
          const Color(0xFF10B981),
        );
      }
      _refreshList();
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', const Color(0xFFEF4444));
    }
  }

  Future<void> _deleteRoutineSlot(Map<String, dynamic> slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            const Text('Delete Slot'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete "${slot['subject_name'] ?? slot['subject']}" routine slot?',
              style: TextStyle(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _adminService != null) {
      try {
        await _adminService!.deleteRoutine(slot['id'].toString());
        if (mounted) {
          _showSnackBar('Routine slot deleted 🗑️', const Color(0xFF10B981));
          _refreshList();
        }
      } catch (e) {
        _showSnackBar(
          'Error deleting: ${e.toString()}',
          const Color(0xFFEF4444),
        );
      }
    }
  }

  void _refreshList() {
    _loadRoutineData();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _bgAnimController.dispose();
    _staggerController.dispose();
    _fabController.dispose();
    _glowController.dispose();
    _routineSubscription?.cancel();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    _roomCtrl.dispose();
    _teacherCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _semesterCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daySlots = _getSlotsForDay(_selectedDay);
    final isDark = AppThemeController.isDarkMode;
    final isStandaloneRoute =
        ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isStandaloneRoute
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                  size: 18,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Routine Matrix',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Geist',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          const Center(child: OfflineIndicatorBadge()),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                ),
                onPressed: _loadRoutineData,
              );
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF06B6D4,
                  ).withOpacity(0.3 + (_glowController.value * 0.2)),
                  blurRadius: 16 + (_glowController.value * 8),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _showAddSlotDialog,
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'ADD SLOT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          );
        },
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
          if (isDark) ...[
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowController.value * 40),
                  right: -70 + (_glowController.value * 30),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF06B6D4).withOpacity(0.12),
                          const Color(0xFF06B6D4).withOpacity(0.02),
                          const Color(0xFF06B6D4).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  bottom: -60 - (_glowController.value * 30),
                  left: -60 - (_glowController.value * 20),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurpleAccent.withOpacity(0.08),
                          Colors.deepPurpleAccent.withOpacity(0.01),
                          Colors.deepPurpleAccent.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Select a day below to view and manage the timetable',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF0C4A6E).withOpacity(0.6),
                      fontSize: 11.5,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                _buildWeekdaysBar(isDark),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : _errorMessage != null
                      ? _buildErrorState(isDark)
                      : daySlots.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: daySlots.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final slot = daySlots[index];
                            return _buildAnimatedRoutineCard(
                              slot,
                              index,
                              isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return const SkeletonList(itemCount: 6);
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0C4A6E),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: isDark
                  ? Colors.white54
                  : const Color(0xFF0C4A6E).withOpacity(0.7),
              fontSize: 11,
              fontFamily: 'Geist',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRoutineData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF0C4A6E).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              color: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF0C4A6E).withOpacity(0.3),
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No classes scheduled for $_selectedDay",
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0C4A6E),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new routine slot',
            style: TextStyle(
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF0C4A6E).withOpacity(0.6),
              fontSize: 12,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRoutineCard(
    Map<String, dynamic> slot,
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
            offset: Offset(30 * (1 - cardAnimation.value), 0),
            child: child,
          ),
        );
      },
      child: _buildRoutineCard(slot, isDark),
    );
  }

  Widget _buildRoutineCard(Map<String, dynamic> slot, bool isDark) {
    final startTime = slot['start_time']?.toString() ?? '08:00';
    final endTime = slot['end_time']?.toString() ?? '09:30';
    final subject =
        slot['subject_name'] ?? slot['subject'] ?? 'Unknown Subject';
    final className = slot['class_name'] ?? slot['class'] ?? 'N/A';
    final teacher =
        slot['teacher_name'] ?? slot['teacher'] ?? 'Unknown Teacher';
    final room = slot['room'] ?? 'TBA';

    // Get color based on subject name
    final colorIndex = subject.hashCode.abs() % _dayColors.length;
    final cardColor = _dayColors[colorIndex];

    // Format times for display
    final formattedStart = _formatTime(startTime);
    final formattedEnd = _formatTime(endTime);

    return Dismissible(
      key: Key(slot['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Color(0xFFEF4444),
          size: 32,
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteRoutineSlot(slot);
        return false;
      },
      child: GestureDetector(
        onTap: () => _showEditSlotDialog(slot),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [cardColor.withOpacity(0.15), cardColor.withOpacity(0.05)]
                  : [cardColor.withOpacity(0.12), cardColor.withOpacity(0.04)],
            ),
            border: Border.all(
              color: isDark
                  ? cardColor.withOpacity(0.2)
                  : cardColor.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : cardColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time column
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor.withOpacity(0.3),
                            cardColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cardColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF67E8F9),
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedStart,
                            style: const TextStyle(
                              color: Color(0xFF67E8F9),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Text(
                            formattedEnd,
                            style: const TextStyle(
                              color: Color(0xFF67E8F9),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0C4A6E),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: cardColor.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  className != 'N/A' ? className : 'No Class',
                                  style: TextStyle(
                                    color: cardColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 8,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        teacher,
                                        style: TextStyle(
                                          color: const Color(0xFF8B5CF6),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Geist',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Room badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor.withOpacity(0.3),
                            cardColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cardColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.meeting_room_rounded,
                            color: Color(0xFF67E8F9),
                            size: 12,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            room,
                            style: const TextStyle(
                              color: Color(0xFF67E8F9),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  Widget _buildWeekdaysBar(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          final color = _dayColors[index];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
              _staggerController.forward(from: 0.0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          color.withOpacity(0.8),
                          color.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.05),
                                Colors.white.withOpacity(0.02),
                              ]
                            : [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.3),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? color
                      : isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF0C4A6E).withOpacity(0.15),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF0C4A6E).withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    fontFamily: 'Geist',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
