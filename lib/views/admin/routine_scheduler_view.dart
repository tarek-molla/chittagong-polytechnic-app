// =============================================================================
// lib/views/admin/routine_scheduler_view.dart
// Horizontal Routine Scheduling Matrix for System Admins.
// Features:
//   • Horizontal weekdays selection matrix
//   • Timeline list representing scheduled class slots
//   • Inline dialog form for adding new classes to the routine
//   • Real-time CRUD operations via Supabase
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import '../../services/admin_service.dart';
import '../../core/colors.dart';
import '../../core/theme_provider.dart';

class RoutineSchedulerView extends StatefulWidget {
  final AppUser user;
  const RoutineSchedulerView({super.key, required this.user});

  @override
  State<RoutineSchedulerView> createState() => _RoutineSchedulerViewState();
}

class _RoutineSchedulerViewState extends State<RoutineSchedulerView> {
  String _selectedDay = 'SUN';
  StreamSubscription? _routineSubscription;
  List<Map<String, dynamic>> _routineData = [];
  bool _isLoading = true;
  String? _errorMessage;
  AdminService? _adminService;

  // Form controllers
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '08:00 - 09:30');
  final _semesterCtrl = TextEditingController(text: '1');
  final _departmentCtrl = TextEditingController(text: 'CST');

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(SupabaseService.client);
    _loadRoutineData();
  }

  void _loadRoutineData() {
    _routineSubscription?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _routineSubscription = _adminService!
        .getRoutineStream('CST')
        .listen(
          (data) {
            if (mounted) {
              setState(() {
                _routineData = data;
                _isLoading = false;
              });
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

  @override
  void dispose() {
    _routineSubscription?.cancel();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    _roomCtrl.dispose();
    _teacherCtrl.dispose();
    _timeCtrl.dispose();
    _semesterCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSlotsForDay(String day) {
    // Map day abbreviation to full day name used in DB
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
    return _routineData
        .where(
          (slot) =>
              (slot['day'] ?? '').toString().toUpperCase() == day ||
              (slot['day_name'] ?? '').toString().toUpperCase() == day ||
              (slot['day_name'] ?? '').toString().substring(0, 3) == day,
        )
        .toList();
  }

  void _showAddSlotDialog() {
    _subjectCtrl.clear();
    _classCtrl.clear();
    _roomCtrl.clear();
    _teacherCtrl.clear();
    _timeCtrl.text = '08:00 - 09:30';
    _semesterCtrl.text = '1';
    _departmentCtrl.text = 'CST';

    showDialog(
      context: context,
      builder: (ctx) => _buildRoutineFormDialog(ctx, null),
    );
  }

  void _showEditSlotDialog(Map<String, dynamic> slot) {
    _subjectCtrl.text = slot['subject_name'] ?? slot['subject'] ?? '';
    _classCtrl.text = slot['class_name'] ?? slot['class'] ?? '';
    _roomCtrl.text = slot['room'] ?? '';
    _teacherCtrl.text = slot['teacher_name'] ?? slot['teacher'] ?? '';
    _timeCtrl.text =
        '${slot['start_time'] ?? '08:00'} - ${slot['end_time'] ?? '09:30'}';
    _semesterCtrl.text = (slot['semester'] ?? 1).toString();
    _departmentCtrl.text = slot['department'] ?? 'CST';

    showDialog(
      context: context,
      builder: (ctx) => _buildRoutineFormDialog(ctx, slot),
    );
  }

  Widget _buildRoutineFormDialog(
    BuildContext ctx,
    Map<String, dynamic>? existingSlot,
  ) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existingSlot != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200,
        ),
      ),
      title: Text(
        isEditing ? 'Edit Routine Slot' : 'Schedule New Slot',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField('Subject Name', _subjectCtrl, isDark),
              const SizedBox(height: 12),
              _buildDialogTextField(
                'Class / Batch (e.g., CST-3rd-A)',
                _classCtrl,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField('Room Number', _roomCtrl, isDark),
              const SizedBox(height: 12),
              _buildDialogTextField('Faculty Teacher', _teacherCtrl, isDark),
              const SizedBox(height: 12),
              _buildDialogTextField(
                'Time Slot (e.g. 08:00 - 09:30)',
                _timeCtrl,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                'Semester',
                _semesterCtrl,
                isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField('Department', _departmentCtrl, isDark),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx);
              await _saveRoutineSlot(existingSlot);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
          child: Text(
            isEditing ? 'Update' : 'Add Slot',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13.5,
      ),
      keyboardType: keyboardType,
      validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : Colors.grey,
          fontSize: 12,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Future<void> _saveRoutineSlot(Map<String, dynamic>? existingSlot) async {
    if (_adminService == null) return;

    final timeParts = _timeCtrl.text.split(' - ');
    final startTime = timeParts.isNotEmpty ? timeParts[0].trim() : '08:00';
    final endTime = timeParts.length > 1 ? timeParts[1].trim() : '09:30';

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
      'start_time': startTime,
      'end_time': endTime,
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
          'Routine slot updated successfully',
          const Color(0xFF10B981),
        );
      } else {
        await _adminService!.createRoutine(data);
        _showSnackBar(
          'Routine slot added successfully',
          const Color(0xFF10B981),
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', const Color(0xFFEF4444));
    }
  }

  Future<void> _deleteRoutineSlot(Map<String, dynamic> slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
          'Delete "${slot['subject_name'] ?? slot['subject']}" routine slot?',
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
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && _adminService != null) {
      try {
        await _adminService!.deleteRoutine(slot['id'].toString());
        if (mounted) {
          _showSnackBar('Routine slot deleted', const Color(0xFF10B981));
        }
      } catch (e) {
        _showSnackBar(
          'Error deleting: ${e.toString()}',
          const Color(0xFFEF4444),
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daySlots = _getSlotsForDay(_selectedDay);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Routine Scheduler Matrix',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _loadRoutineData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle context
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Text(
              'Select a day below to alter the live timetable dashboards.',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11.5,
              ),
            ),
          ),

          // Horizontal Weekdays bar
          _buildWeekdaysBar(isDark),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(height: 16),
                        Text(
                          'Loading routine data...',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
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
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRoutineData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : daySlots.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: daySlots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      return _buildRoutineCard(slot, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Map<String, dynamic> slot, bool isDark) {
    final startTime =
        slot['start_time'] ??
        slot['time']?.toString().split(' - ').first ??
        '08:00';
    final endTime =
        slot['end_time'] ??
        slot['time']?.toString().split(' - ').last ??
        '09:30';
    final subject =
        slot['subject_name'] ?? slot['subject'] ?? 'Unknown Subject';
    final className = slot['class_name'] ?? slot['class'] ?? 'Unknown Class';
    final teacher =
        slot['teacher_name'] ?? slot['teacher'] ?? 'Unknown Teacher';
    final room = slot['room'] ?? 'TBA';

    return Dismissible(
      key: Key(slot['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
      ),
      confirmDismiss: (_) async {
        await _deleteRoutineSlot(slot);
        return false;
      },
      child: GestureDetector(
        onTap: () => _showEditSlotDialog(slot),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF67E8F9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF67E8F9),
                      size: 16,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      startTime,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$className • $teacher',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room,
                      style: const TextStyle(
                        color: Color(0xFF67E8F9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endTime,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaysBar(bool isDark) {
    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.18)
                    : Colors.white.withAlpha(4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                      : isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF67E8F9)
                        : isDark
                        ? const Color(0xFF64748B)
                        : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: isDark ? const Color(0xFF475569) : Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "No scheduled classes for $_selectedDay",
            style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new routine slot',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
