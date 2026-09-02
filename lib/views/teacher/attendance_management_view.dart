// =============================================================================
// lib/views/teacher/attendance_management_view.dart
// CPI Faculty Portal — Enhanced Premium Attendance Logger
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/supabase_service.dart';

class AttendanceManagementView extends StatefulWidget {
  final AppUser teacher;
  final String className;
  final String subjectCode;
  final String subjectName;
  final int semester;
  final String department;

  const AttendanceManagementView({
    super.key,
    required this.teacher,
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
    required this.department,
  });

  @override
  State<AttendanceManagementView> createState() =>
      _AttendanceManagementViewState();
}

class _AttendanceManagementViewState extends State<AttendanceManagementView>
    with TickerProviderStateMixin {
  late AttendanceService _attendanceService;
  StreamSubscription<List<DailyAttendanceEntry>>? _attendanceSubscription;

  List<DailyAttendanceEntry> _attendanceEntries = [];
  List<DailyAttendanceEntry> _filteredEntries = [];
  List<DailyAttendanceEntry> _originalEntries = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false; // Locks stream from overriding edits
  String? _errorMessage;
  String _selectedDate = '';
  String _searchQuery = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService(SupabaseService.client);
    _selectedDate = _getTodayDate();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _listenToAttendance();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _listenToAttendance() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasChanges = false;
    });

    _attendanceSubscription?.cancel();
    _attendanceSubscription = _attendanceService
        .getDailyAttendanceStream(
          widget.className,
          widget.semester,
          widget.subjectCode,
          widget.subjectName,
          widget.department,
          _selectedDate,
          widget.teacher.name,
        )
        .listen(
          (entries) {
            if (!mounted) return;
            // ✅ PREVENT STREAM FROM OVERWRITING UNSAVED LOCAL USER EDITS
            if (_hasChanges) return;

            setState(() {
              _attendanceEntries = entries;
              _originalEntries = entries.map((e) => e.copyWith()).toList();
              _filterEntries();
              _isLoading = false;
            });
          },
          onError: (error) {
            if (!mounted) return;
            if (_hasChanges) return;
            setState(() {
              _errorMessage = 'Failed to load attendance: $error';
              _isLoading = false;
            });
          },
        );
  }

  void _filterEntries() {
    if (_searchQuery.isEmpty) {
      _filteredEntries = List.from(_attendanceEntries);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredEntries = _attendanceEntries.where((entry) {
        return entry.studentName.toLowerCase().contains(query) ||
            entry.studentRoll.toLowerCase().contains(query);
      }).toList();
    }
  }

  void _toggleAttendanceStatus(DailyAttendanceEntry entry) {
    setState(() {
      final newStatus = entry.status == 'Present' ? 'Absent' : 'Present';
      final index = _attendanceEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _attendanceEntries[index] = entry.copyWith(status: newStatus);
        _filterEntries();
        _hasChanges = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _confirmAttendance() async {
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No pending changes to save',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: Colors.amber.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final isDark = AppThemeController.isDarkMode;
    final presentCount = _attendanceEntries
        .where((e) => e.status == 'Present')
        .length;
    final absentCount = _attendanceEntries
        .where((e) => e.status == 'Absent')
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white12 : AppColors.lightCardBorder,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Save Attendance',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm daily register commit for $_selectedDate?',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.lightSubtitleText,
                fontFamily: 'Geist',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(8)
                    : AppColors.lightCardBorderAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.lightCardBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildConfirmStat(
                    'Present',
                    presentCount.toString(),
                    const Color(0xFF10B981),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildConfirmStat(
                    'Absent',
                    absentCount.toString(),
                    const Color(0xFFEF4444),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildConfirmStat(
                    'Total',
                    _attendanceEntries.length.toString(),
                    const Color(0xFF8B5CF6),
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightSubtitleText,
                fontFamily: 'Geist',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Confirm & Save',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _saveAttendanceToDatabase();
    }
  }

  Future<void> _saveAttendanceToDatabase() async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (var entry in _attendanceEntries) {
        final original = _originalEntries.firstWhere(
          (e) => e.id == entry.id,
          orElse: () => entry,
        );

        if (original.status != entry.status) {
          await _attendanceService.updateDailyAttendanceStatus(
            entry.id,
            entry.status,
          );
        }
      }

      setState(() {
        _originalEntries = _attendanceEntries.map((e) => e.copyWith()).toList();
        _hasChanges = false;
        _isSaving = false;
      });

      final presentCount = _attendanceEntries
          .where((e) => e.status == 'Present')
          .length;
      final absentCount = _attendanceEntries
          .where((e) => e.status == 'Absent')
          .length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Saved! ($presentCount Present, $absentCount Absent)',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildConfirmStat(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  int get _presentCount =>
      _attendanceEntries.where((e) => e.status == 'Present').length;
  int get _absentCount =>
      _attendanceEntries.where((e) => e.status == 'Absent').length;

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final totalStudents = _attendanceEntries.length;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await _showDiscardChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF020617)
            : AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Clean Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightPrimaryText,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_hasChanges) {
                          _showDiscardChangesDialog();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.className,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.subjectCode} • ${widget.subjectName}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.lightSubtitleText,
                              fontSize: 11,
                              fontFamily: 'Geist',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Sub-Header with Unsaved Indicator & Save Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hasChanges
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Unsaved Edits',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedDate,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _confirmAttendance,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.task_alt_rounded, size: 16),
                      label: Text(_isSaving ? 'Saving...' : 'Confirm & Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? Colors.white12
                                  : AppColors.lightCardBorderAlt),
                        foregroundColor: _hasChanges
                            ? Colors.white
                            : (isDark
                                  ? Colors.white38
                                  : AppColors.lightSubtitleText),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Stats Banner Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(6)
                      : AppColors.lightCardBorderAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(12)
                        : AppColors.lightCardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      totalStudents.toString(),
                      isDark,
                      const Color(0xFF8B5CF6),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _buildStatItem(
                      'Present',
                      _presentCount.toString(),
                      isDark,
                      const Color(0xFF10B981),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _buildStatItem(
                      'Absent',
                      _absentCount.toString(),
                      isDark,
                      const Color(0xFFEF4444),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _buildStatItem(
                      'Rate',
                      totalStudents > 0
                          ? '${((_presentCount / totalStudents) * 100).toInt()}%'
                          : '0%',
                      isDark,
                      const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),

              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(8)
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightCaptionText,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filterEntries();
                            });
                          },
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightPrimaryText,
                            fontSize: 13,
                            fontFamily: 'Geist',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search student by name or roll...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _filterEntries();
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white38
                                : AppColors.lightCaptionText,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Student List View
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Colors.red.withAlpha(120),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.lightCaptionText,
                                fontSize: 13,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _listenToAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 44,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No students found'
                                  : 'No results for "$_searchQuery"',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.lightSubtitleText,
                                fontSize: 13,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildStudentCard(entry, isDark),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(DailyAttendanceEntry entry, bool isDark) {
    final isPresent = entry.status == 'Present';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF10B981).withAlpha(80)
              : (isDark
                    ? Colors.white.withAlpha(10)
                    : AppColors.lightCardBorder),
          width: isPresent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Student Roll Badge
          Container(
            width: 52,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(8)
                  : AppColors.lightCardBorderAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                entry.studentRoll.replaceAll('CMT-', ''),
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.lightPrimaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll: ${entry.studentRoll}',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.lightCaptionText,
                    fontSize: 10,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          // Interactive Action Toggle Chips
          Row(
            children: [
              _buildStatusButton(
                'P',
                isPresent,
                const Color(0xFF10B981),
                () => _toggleAttendanceStatus(entry),
                isDark,
              ),
              const SizedBox(width: 8),
              _buildStatusButton(
                'A',
                !isPresent,
                const Color(0xFFEF4444),
                () => _toggleAttendanceStatus(entry),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    bool isActive,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: isActive ? 1.05 : 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : (isDark
                      ? Colors.white.withAlpha(6)
                      : AppColors.lightCardBorderAlt),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? color
                  : (isDark
                        ? Colors.white.withAlpha(15)
                        : AppColors.lightCardBorder),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white38 : AppColors.lightCaptionText),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    if (_hasChanges) {
      final shouldDiscard = await _showDiscardChangesDialog();
      if (!shouldDiscard) return;
    }

    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: const Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      final dateStr =
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
      setState(() {
        _selectedDate = dateStr;
        _hasChanges = false;
      });
      _listenToAttendance();
    }
  }

  Future<bool> _showDiscardChangesDialog() async {
    final isDark = AppThemeController.isDarkMode;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Unsaved Edits',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Discard attendance changes for $_selectedDate?',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.lightSubtitleText,
            fontFamily: 'Geist',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Editing',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightSubtitleText,
                fontFamily: 'Geist',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // ✅ UNDO ALL CHANGES - Reset to original state
      setState(() {
        _attendanceEntries = _originalEntries.map((e) => e.copyWith()).toList();
        _filterEntries();
        _hasChanges = false;
      });

      // ✅ GO BACK TO DASHBOARD
      Navigator.pop(context);
      return true;
    }

    return false;
  }
}
