// =============================================================================
// lib/views/teacher/continuous_assessment_view.dart
// CPI Faculty Portal — Continuous Assessment View with Animations
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../models/assessment_model.dart';
import '../../services/assessment_service.dart';
import '../../services/supabase_service.dart';

class ContinuousAssessmentView extends StatefulWidget {
  final AppUser teacher;
  final String className;
  final String subjectCode;
  final String subjectName;
  final int semester;
  final String department;

  const ContinuousAssessmentView({
    super.key,
    required this.teacher,
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
    required this.department,
  });

  @override
  State<ContinuousAssessmentView> createState() =>
      _ContinuousAssessmentViewState();
}

class _ContinuousAssessmentViewState extends State<ContinuousAssessmentView>
    with TickerProviderStateMixin {
  late AssessmentService _assessmentService;
  StreamSubscription<List<AssessmentModel>>? _assessmentSubscription;

  List<AssessmentModel> _assessments = [];
  List<AssessmentModel> _filteredAssessments = [];
  List<AssessmentModel> _originalAssessments = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _savingFromDiscard = false;
  String _selectedAssessmentName = 'all';

  // Creation options
  String _selectedAssessmentType = 'CT';
  String _selectedAssessmentNameForCreate = 'CT-1';
  double _selectedTotalMarks = 10;

  final List<Map<String, dynamic>> _assessmentOptions = [
    {'label': 'CT-1', 'type': 'CT', 'total': 10.0},
    {'label': 'CT-2', 'type': 'CT', 'total': 10.0},
    {'label': 'CT-3', 'type': 'CT', 'total': 10.0},
    {'label': 'Quiz 1', 'type': 'Quiz', 'total': 5.0},
    {'label': 'Quiz 2', 'type': 'Quiz', 'total': 5.0},
    {'label': 'Assignment 1', 'type': 'Assignment', 'total': 20.0},
    {'label': 'Assignment 2', 'type': 'Assignment', 'total': 20.0},
    {'label': 'Lab Performance', 'type': 'Lab', 'total': 25.0},
    {'label': 'Project', 'type': 'Project', 'total': 30.0},
    {'label': 'Midterm', 'type': 'Exam', 'total': 30.0},
    {'label': 'Final', 'type': 'Exam', 'total': 50.0},
  ];

  final List<String> _quickTypes = [
    'CT',
    'Quiz',
    'Assignment',
    'Lab',
    'Project',
    'Exam',
  ];

  late AnimationController _glowAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  final Map<String, TextEditingController> _obtainedControllers = {};

  @override
  void initState() {
    super.initState();
    _assessmentService = AssessmentService(SupabaseService.client);

    _selectedAssessmentNameForCreate = _assessmentOptions.first['label'];
    _selectedTotalMarks = (_assessmentOptions.first['total'] as num).toDouble();
    _selectedAssessmentType = _assessmentOptions.first['type'];

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _listenToAssessments();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _assessmentSubscription?.cancel();
    for (var controller in _obtainedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _listenToAssessments() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasChanges = false;
    });

    _assessmentSubscription?.cancel();
    _assessmentSubscription = _assessmentService
        .getAssessmentStream(
          widget.className,
          widget.subjectCode,
          widget.semester,
        )
        .listen(
          (entries) {
            if (!mounted) return;
            if (_hasChanges || _isSaving) return;

            setState(() {
              _assessments = entries;
              _originalAssessments = entries.map((e) => e.copyWith()).toList();
              _syncControllers();
              _filterAssessments();
              _isLoading = false;
            });
          },
          onError: (error) {
            if (!mounted) return;
            if (_hasChanges || _isSaving) return;
            setState(() {
              _errorMessage = 'Failed to load assessments: $error';
              _isLoading = false;
            });
          },
        );
  }

  void _syncControllers() {
    for (var entry in _assessments) {
      final formattedText = entry.obtainedMarks.toStringAsFixed(
        entry.obtainedMarks.truncateToDouble() == entry.obtainedMarks ? 0 : 1,
      );

      if (!_obtainedControllers.containsKey(entry.id)) {
        _obtainedControllers[entry.id] = TextEditingController(
          text: formattedText,
        );
      } else if (!_hasChanges && !_isSaving) {
        _obtainedControllers[entry.id]!.text = formattedText;
      }
    }
  }

  void _filterAssessments() {
    List<AssessmentModel> filtered = List.from(_assessments);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((entry) {
        return entry.studentName.toLowerCase().contains(query) ||
            entry.studentRoll.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedAssessmentName != 'all') {
      filtered = filtered.where((entry) {
        return entry.assessmentName == _selectedAssessmentName;
      }).toList();
    }

    setState(() {
      _filteredAssessments = filtered;
    });
  }

  /// Returns list of (id, oldValue, newValue) tuples for changed entries
  List<Map<String, dynamic>> _getChangedEntries() {
    final changes = <Map<String, dynamic>>[];
    for (var entry in _assessments) {
      final controller = _obtainedControllers[entry.id];
      if (controller != null) {
        final val = double.tryParse(controller.text) ?? 0.0;
        if (val != entry.obtainedMarks) {
          changes.add({
            'id': entry.id,
            'roll': entry.studentRoll,
            'name': entry.studentName,
            'old': entry.obtainedMarks,
            'new': val,
            'total': entry.totalMarks,
            'assessmentName': entry.assessmentName,
          });
        }
      }
    }
    return changes;
  }

  Future<void> _saveAllMarks({bool skipConfirmation = false}) async {
    final isDark = AppThemeController.isDarkMode;
    final changes = _getChangedEntries();

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No changes detected to save.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show redesigned glass-morphism save dialog with changes preview
    // (skip when called from discard flow - user already confirmed intent)
    bool confirmed = skipConfirmation;
    if (!skipConfirmation) {
      confirmed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildSaveDialog(isDark, changes),
          ) ??
          false;
    }

    if (confirmed == true && mounted) {
      setState(() {
        _isSaving = true;
      });

      int successfulUpdates = 0;
      int failedUpdates = 0;

      try {
        for (var change in changes) {
          final id = change['id'] as String;
          final obtained = change['new'] as double;
          final original = _assessments.firstWhere(
            (item) => item.id == id,
            orElse: () => AssessmentModel(
              id: id,
              rollNumber: '',
              studentName: '',
              department: widget.department,
              semester: widget.semester,
              subjectCode: widget.subjectCode,
              subjectName: widget.subjectName,
              className: widget.className,
              assessmentType: 'CT',
              assessmentName: '',
              obtainedMarks: 0,
              totalMarks: 30,
              teacherName: widget.teacher.name,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          print(
            '💾 Saving $id: $obtained / ${original.totalMarks} (${original.assessmentName})',
          );

          final updatedModel = await _assessmentService.updateAssessmentMarks(
            id,
            obtainedMarks: obtained,
            totalMarks: original.totalMarks,
          );

          if (updatedModel != null) {
            successfulUpdates++;
            final index = _assessments.indexWhere((item) => item.id == id);
            if (index != -1) {
              _assessments[index] = updatedModel;
            }
            // Sync controller to the canonical saved value
            final controller = _obtainedControllers[id];
            if (controller != null) {
              controller.text = obtained.toStringAsFixed(
                obtained.truncateToDouble() == obtained ? 0 : 1,
              );
            }
          } else {
            failedUpdates++;
            print('❌ Failed updating $id');
          }
        }

        setState(() {
          _isSaving = false;
          _hasChanges = failedUpdates > 0;
          _originalAssessments = _assessments.map((e) => e.copyWith()).toList();
          _filterAssessments();
        });

        if (mounted) {
          if (failedUpdates == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated $successfulUpdates records successfully!',
                      style: const TextStyle(fontFamily: 'Geist'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            HapticFeedback.heavyImpact();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saved $successfulUpdates records, $failedUpdates failed.',
                ),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save marks: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildSaveDialog(bool isDark, List<Map<String, dynamic>> changes) {
    const accentColor = Color(0xFF7B61FF);
    final previewCount = changes.length > 5 ? 5 : changes.length;
    final remaining = changes.length - previewCount;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withOpacity(0.85)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(isDark ? 0.25 : 0.15),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated Glow
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accentColor.withOpacity(
                                  0.2 + (0.15 * _pulseController.value),
                                ),
                                accentColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with slide animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: -20.0, end: 0.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value, 0),
                              child: child,
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.save_rounded,
                                  color: accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Save Marks',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightPrimaryText,
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      '${changes.length} change${changes.length == 1 ? '' : 's'} to commit',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.lightSubtitleText,
                                        fontFamily: 'Geist',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Changes preview list
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 20.0, end: 0.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: child,
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 280),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: previewCount + (remaining > 0 ? 1 : 0),
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.04),
                              ),
                              itemBuilder: (context, idx) {
                                if (remaining > 0 && idx == previewCount) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      '…and $remaining more',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        fontFamily: 'Geist',
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  );
                                }
                                final change = changes[idx];
                                final oldVal = change['old'] as double;
                                final newVal = change['new'] as double;
                                final roll = change['roll'] as String;
                                final name = change['name'] as String;
                                final increased = newVal > oldVal;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: increased
                                              ? const Color(
                                                  0xFF10B981,
                                                ).withOpacity(0.15)
                                              : const Color(
                                                  0xFFEF4444,
                                                ).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          increased
                                              ? Icons.trending_up_rounded
                                              : Icons.trending_down_rounded,
                                          size: 14,
                                          color: increased
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              roll.replaceAll('CMT-', ''),
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors
                                                          .lightPrimaryText,
                                                fontFamily: 'Geist',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              name,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : AppColors
                                                          .lightSubtitleText,
                                                fontFamily: 'Geist',
                                                fontSize: 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${oldVal.toStringAsFixed(oldVal.truncateToDouble() == oldVal ? 0 : 1)} → ${newVal.toStringAsFixed(newVal.truncateToDouble() == newVal ? 0 : 1)}',
                                        style: TextStyle(
                                          color: increased
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context, false);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.lightSubtitleText,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  Navigator.pop(context, true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: accentColor.withOpacity(0.5),
                                ),
                                child: const Text(
                                  'Confirm & Save',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  void _addNewAssessment() {
    final isDark = AppThemeController.isDarkMode;

    String dialogCategory = _selectedAssessmentType;
    final initialOptions = _assessmentOptions
        .where((opt) => opt['type'] == dialogCategory)
        .toList();
    final initialOpt = initialOptions.isNotEmpty
        ? initialOptions.first
        : _assessmentOptions.first;

    String dialogName = initialOpt['label'] as String;
    double dialogMarks = (initialOpt['total'] as num).toDouble();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final matchingOptions = _assessmentOptions
              .where((opt) => opt['type'] == dialogCategory)
              .toList();

          final isValidValue = matchingOptions.any(
            (opt) => opt['label'] == dialogName,
          );
          if (!isValidValue && matchingOptions.isNotEmpty) {
            dialogName = matchingOptions.first['label'] as String;
            dialogMarks = (matchingOptions.first['total'] as num).toDouble();
          }

          final activeColor = _getTypeColor(dialogCategory);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withOpacity(0.85)
                          : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(isDark ? 0.25 : 0.15),
                          blurRadius: 30,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated Glow
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      activeColor.withOpacity(
                                        0.2 + (0.15 * _pulseController.value),
                                      ),
                                      activeColor.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with slide animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: -20.0, end: 0.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(value, 0),
                                    child: child,
                                  );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: activeColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: activeColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: activeColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Add Assessment',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightPrimaryText,
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Category Selector
                              Text(
                                'Category',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.lightSubtitleText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Geist',
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Dynamic Colored Category Chips with animation
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _quickTypes.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final type = entry.value;
                                  final isSelected = dialogCategory == type;
                                  final chipColor = _getTypeColor(type);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.7 + (0.3 * value),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setModalState(() {
                                          dialogCategory = type;
                                          final matching = _assessmentOptions
                                              .where(
                                                (opt) => opt['type'] == type,
                                              )
                                              .toList();
                                          if (matching.isNotEmpty) {
                                            dialogName =
                                                matching.first['label']
                                                    as String;
                                            dialogMarks =
                                                (matching.first['total'] as num)
                                                    .toDouble();
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? chipColor
                                              : (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.05,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.04,
                                                      )),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? chipColor
                                                : (isDark
                                                      ? Colors.white
                                                            .withOpacity(0.1)
                                                      : Colors.black
                                                            .withOpacity(0.08)),
                                            width: 1.2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: chipColor
                                                        .withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : AppColors
                                                            .lightPrimaryText),
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),

                              // Assessment Dropdown with slide animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 20.0, end: 0.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, value),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: dialogName,
                                    dropdownColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightPrimaryText,
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: matchingOptions
                                        .map<DropdownMenuItem<String>>((
                                          option,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: option['label'] as String,
                                            child: Text(
                                              '${option['label']} (${option['total']} marks)',
                                            ),
                                          );
                                        })
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        HapticFeedback.lightImpact();
                                        final option = _assessmentOptions
                                            .firstWhere(
                                              (opt) => opt['label'] == value,
                                            );
                                        setModalState(() {
                                          dialogName = value;
                                          dialogMarks = (option['total'] as num)
                                              .toDouble();
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Assessment Name',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.lightSubtitleText,
                                        fontSize: 12,
                                        fontFamily: 'Geist',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.12)
                                              : Colors.black.withOpacity(0.08),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: activeColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Total Marks Field with slide animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 20.0, end: 0.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, value),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: TextFormField(
                                    key: ValueKey(dialogName),
                                    initialValue: dialogMarks.toStringAsFixed(
                                      0,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightPrimaryText,
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Total Marks',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.lightSubtitleText,
                                        fontSize: 12,
                                        fontFamily: 'Geist',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.12)
                                              : Colors.black.withOpacity(0.08),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: activeColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(value);
                                      if (parsed != null) {
                                        setModalState(() {
                                          dialogMarks = parsed;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Actions with fade animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(opacity: value, child: child);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.pop(context);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : AppColors.lightSubtitleText,
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.heavyImpact();
                                        _selectedAssessmentType =
                                            dialogCategory;
                                        _selectedAssessmentNameForCreate =
                                            dialogName;
                                        _selectedTotalMarks = dialogMarks;
                                        Navigator.pop(context);
                                        _createNewAssessment();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: activeColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        shadowColor: activeColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                      child: const Text(
                                        'Create',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
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
          );
        },
      ),
    );
  }

  Future<void> _createNewAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _assessmentService.getStudents(
        widget.className,
        widget.semester,
      );

      print('📊 Found ${students.length} students');

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No active students found registered for this class!',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      int created = 0;
      int failed = 0;

      for (var s in students) {
        print('📝 Processing student: ${s.roll} - ${s.name}');
        final res = await _assessmentService.getOrCreateAssessment(
          s.roll,
          s.name,
          widget.subjectCode,
          widget.subjectName,
          widget.className,
          widget.semester,
          widget.department,
          widget.teacher.name,
          assessmentName: _selectedAssessmentNameForCreate,
          assessmentType: _selectedAssessmentType,
          totalMarks: _selectedTotalMarks,
        );
        if (res != null) {
          created++;
          print('✅ Created for ${s.roll}');
        } else {
          failed++;
          print('❌ Failed for ${s.roll}');
        }
      }

      print('📊 Created: $created, Failed: $failed');

      // Immediately fetch the latest assessments so the dropdown + list update
      final fresh = await _assessmentService.getClassAssessments(
        widget.className,
        widget.subjectCode,
        widget.semester,
      );

      if (mounted) {
        setState(() {
          _assessments = fresh;
          _originalAssessments = fresh.map((e) => e.copyWith()).toList();
          _selectedAssessmentName = _selectedAssessmentNameForCreate;
          _isLoading = false;
          _syncControllers();
          _filterAssessments();
        });

        if (created > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created $created records for $_selectedAssessmentNameForCreate${failed > 0 ? " ($failed failed)" : ""}',
                    style: const TextStyle(fontFamily: 'Geist'),
                  ),
                ],
              ),
              backgroundColor: failed > 0
                  ? Colors.orange
                  : const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to create any records. Check RLS policy in Supabase.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _createNewAssessment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed creating entries: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final totalCount = _assessments.length;
    final uniqueTypes = _assessments
        .map((e) => e.assessmentName)
        .toSet()
        .toList();

    final isFilterValid =
        _selectedAssessmentName == 'all' ||
        uniqueTypes.contains(_selectedAssessmentName);
    final activeFilterValue = isFilterValid ? _selectedAssessmentName : 'all';

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldDiscard = await _showDiscardChangesDialog();
          return shouldDiscard;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF070B19)
            : AppColors.lightBackground,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                'Continuous Assessment',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                ),
              ),
              Text(
                '${widget.className} • ${widget.subjectCode}',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.lightSubtitleText,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              size: 20,
            ),
            onPressed: () async {
              if (_hasChanges) {
                final shouldDiscard = await _showDiscardChangesDialog();
                if (shouldDiscard == true && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: _addNewAssessment,
              icon: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    Icons.add_rounded,
                    color: Color.lerp(
                      const Color(0xFF7B61FF),
                      const Color(0xFFA78BFA),
                      _pulseController.value,
                    ),
                    size: 28,
                  );
                },
              ),
              tooltip: 'Add Assessment',
            ),
          ],
        ),
        body: Stack(
          children: [
            if (isDark) ...[
              AnimatedBuilder(
                animation: _glowAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: -120 + (_glowAnimationController.value * 30),
                    right: -120 + (_glowAnimationController.value * 20),
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7B61FF).withOpacity(0.12),
                            const Color(0xFF00E5FF).withOpacity(0.02),
                            const Color(0xFF7B61FF).withOpacity(0),
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
                children: [
                  // Filter bar & Save Action Container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Search Input
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.white.withAlpha(200),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha(15)
                                    : Colors.black.withAlpha(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                        _filterAssessments();
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
                                      hintText: 'Search roll or name...',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        fontSize: 12,
                                        fontFamily: 'Geist',
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _filterAssessments();
                                      });
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Premium Filter Dropdown
                        _buildPremiumFilterDropdown(
                          isDark,
                          activeFilterValue,
                          uniqueTypes,
                        ),
                        const SizedBox(width: 8),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveAllMarks,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasChanges
                                ? const Color(0xFF7B61FF)
                                : (isDark
                                      ? Colors.white.withAlpha(8)
                                      : Colors.black.withAlpha(5)),
                            foregroundColor: _hasChanges
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                            elevation: 0,
                            minimumSize: const Size(40, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _hasChanges
                                    ? const Color(0xFF7B61FF)
                                    : (isDark
                                          ? Colors.white.withAlpha(15)
                                          : Colors.black.withAlpha(8)),
                              ),
                            ),
                          ),
                          child: _isSaving
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
                              : Row(
                                  children: [
                                    const Icon(Icons.save_rounded, size: 16),
                                    if (_hasChanges) ...[
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Metrics Analytics Banner with animations
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.black.withAlpha(8),
                        ),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.01),
                                ]
                              : [
                                  Colors.black.withOpacity(0.02),
                                  Colors.black.withOpacity(0.005),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Records',
                            totalCount.toString(),
                            isDark,
                            const Color(0xFFA855F7),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          _buildStatItem(
                            'Avg Mark',
                            _calculateAverage().toString(),
                            isDark,
                            const Color(0xFF10B981),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          _buildStatItem(
                            'Accumulated',
                            _calculateTotal().toStringAsFixed(0),
                            isDark,
                            const Color(0xFF3B82F6),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          _buildStatItem(
                            'Types',
                            uniqueTypes.length.toString(),
                            isDark,
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Table Headings Column
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            'Roll',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Student Name',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Center(
                            child: Text(
                              'Marks',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.lightCaptionText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Center(
                            child: Text(
                              'Tag',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.lightCaptionText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Assessment Card List
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState(isDark)
                        : _errorMessage != null
                        ? _buildErrorState(isDark)
                        : _filteredAssessments.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                            itemCount: _filteredAssessments.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredAssessments[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                    milliseconds: 250 + (index * 40),
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(20 * (1 - value), 0),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildStudentCard(entry, isDark),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverage() {
    if (_assessments.isEmpty) return 0;
    final total = _assessments.fold<double>(
      0,
      (sum, e) => sum + e.obtainedMarks,
    );
    return double.parse((total / _assessments.length).toStringAsFixed(1));
  }

  double _calculateTotal() {
    return _assessments.fold<double>(0, (sum, e) => sum + e.obtainedMarks);
  }

  Widget _buildStatItem(String label, String value, bool isDark, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 1),
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

  Widget _buildStudentCard(AssessmentModel entry, bool isDark) {
    final controller = _obtainedControllers[entry.id];

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAssessmentOptions(entry, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.01),
                  ]
                : [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.005),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      entry.studentRoll.replaceAll('CMT-', ''),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : AppColors.lightPrimaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.studentName,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightPrimaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(8)
                            : Colors.black.withAlpha(5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.black.withAlpha(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightPrimaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _hasChanges = true;
                                });
                              },
                            ),
                          ),
                          Text(
                            '/${entry.totalMarks.toInt()}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightCaptionText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Assessment tag (tappable for edit/delete)
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showAssessmentOptions(entry, isDark);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          entry.assessmentType,
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getTypeColor(
                            entry.assessmentType,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.assessmentName,
                            style: TextStyle(
                              color: _getTypeColor(entry.assessmentType),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.more_horiz_rounded,
                            color: _getTypeColor(
                              entry.assessmentType,
                            ).withOpacity(0.6),
                            size: 11,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet with assessment options (Edit/Delete)
  /// [isFromDropdown] - true if triggered from dropdown (affects ALL records of that type)
  ///                     false if triggered from student row (affects single record)
  Future<void> _showAssessmentOptions(
    AssessmentModel assessment,
    bool isDark, {
    bool isFromDropdown = false,
  }) async {
    final typeColor = _getTypeColor(assessment.assessmentType);
    // Count how many records of this assessment name exist
    final count = _assessments
        .where((e) => e.assessmentName == assessment.assessmentName)
        .length;

    // Dynamic content based on context
    final titleText = isFromDropdown
        ? assessment.assessmentName
        : '${assessment.assessmentName} for ${assessment.studentName}';
    final subtitleText = isFromDropdown
        ? '${assessment.assessmentType} • $count records • Whole ${assessment.assessmentType.toLowerCase()}'
        : '${assessment.assessmentType} • ${assessment.studentName}';
    final deleteSubtitleText = isFromDropdown
        ? 'Delete all $count records of this ${assessment.assessmentType.toLowerCase()}'
        : 'Remove this assessment entry for ${assessment.studentName}';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (sheetContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Transform.scale(
              scale: 0.85 + (0.15 * animValue),
              child: Opacity(opacity: animValue, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                // Assessment info header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            typeColor.withOpacity(0.2),
                            typeColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFromDropdown
                            ? Icons.layers_rounded
                            : Icons.edit_note_rounded,
                        color: typeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titleText,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleText,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isFromDropdown) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: typeColor.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                '$count records',
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Geist',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
                const SizedBox(height: 12),
                // Edit option
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  title: isFromDropdown ? 'Edit All' : 'Edit Assessment',
                  subtitle: isFromDropdown
                      ? 'Change name, type, or marks for all $count records'
                      : 'Change name, type, or total marks',
                  color: const Color(0xFF7B61FF),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditAssessmentDialog(
                      assessment,
                      isFromDropdown: isFromDropdown,
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                // Delete option
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  title: isFromDropdown ? 'Delete All' : 'Delete Assessment',
                  subtitle: deleteSubtitleText,
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteAssessment(
                      assessment,
                      isFromDropdown: isFromDropdown,
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a single option tile for the assessment options sheet
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  /// Show edit assessment dialog with category/type/total marks
  /// [isFromDropdown] - true if editing from dropdown (updates ALL records of this type)
  Future<void> _showEditAssessmentDialog(
    AssessmentModel assessment, {
    bool isFromDropdown = false,
  }) async {
    final isDark = AppThemeController.isDarkMode;

    String assessmentName = assessment.assessmentName;
    String assessmentType = assessment.assessmentType;
    double totalMarks = assessment.totalMarks;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final matchingOptions = _assessmentOptions
                .where((opt) => opt['type'] == assessmentType)
                .toList();

            // Ensure current assessmentName exists in matching options
            if (!matchingOptions.any((opt) => opt['label'] == assessmentName)) {
              if (matchingOptions.isNotEmpty) {
                assessmentName = matchingOptions.first['label'] as String;
                totalMarks = (matchingOptions.first['total'] as num).toDouble();
              }
            }

            final activeColor = _getTypeColor(assessmentType);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1120).withOpacity(0.92)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white30 : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: activeColor.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: activeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isFromDropdown
                                        ? 'Edit All ${assessment.assessmentName}'
                                        : 'Edit Assessment',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightPrimaryText,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Geist',
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    isFromDropdown
                                        ? 'Update all ${assessment.assessmentName} records'
                                        : 'Update assessment details',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      fontSize: 12,
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.lightSubtitleText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _quickTypes.map((type) {
                                    final isSelected = assessmentType == type;
                                    final chipColor = _getTypeColor(type);
                                    return InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setSheetState(() {
                                          assessmentType = type;
                                          final matching = _assessmentOptions
                                              .where(
                                                (opt) => opt['type'] == type,
                                              )
                                              .toList();
                                          if (matching.isNotEmpty) {
                                            assessmentName =
                                                matching.first['label']
                                                    as String;
                                            totalMarks =
                                                (matching.first['total'] as num)
                                                    .toDouble();
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? chipColor
                                              : (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.05,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.04,
                                                      )),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? chipColor
                                                : (isDark
                                                      ? Colors.white
                                                            .withOpacity(0.1)
                                                      : Colors.black
                                                            .withOpacity(0.08)),
                                            width: 1.2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: chipColor
                                                        .withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : AppColors
                                                            .lightPrimaryText),
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                // Assessment name dropdown
                                DropdownButtonFormField<String>(
                                  value: assessmentName,
                                  dropdownColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightPrimaryText,
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: matchingOptions
                                      .map<DropdownMenuItem<String>>((option) {
                                        return DropdownMenuItem<String>(
                                          value: option['label'] as String,
                                          child: Text(
                                            '${option['label']} (${option['total']} marks)',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      HapticFeedback.lightImpact();
                                      final option = _assessmentOptions
                                          .firstWhere(
                                            (opt) => opt['label'] == value,
                                          );
                                      setSheetState(() {
                                        assessmentName = value;
                                        totalMarks = (option['total'] as num)
                                            .toDouble();
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Assessment Name',
                                    labelStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.lightSubtitleText,
                                      fontSize: 12,
                                      fontFamily: 'Geist',
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.12)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: activeColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Total marks field
                                TextFormField(
                                  initialValue: totalMarks.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightPrimaryText,
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Total Marks',
                                    labelStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.lightSubtitleText,
                                      fontSize: 12,
                                      fontFamily: 'Geist',
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.12)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: activeColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    if (parsed != null) {
                                      setSheetState(() {
                                        totalMarks = parsed;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Close this dialog and go back to options sheet
                                          Navigator.pop(sheetContext);
                                          // Reopen the options sheet so user can pick another action
                                          Future.delayed(
                                            const Duration(milliseconds: 120),
                                            () {
                                              if (mounted) {
                                                _showAssessmentOptions(
                                                  assessment,
                                                  isDark,
                                                  isFromDropdown:
                                                      isFromDropdown,
                                                );
                                              }
                                            },
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.black.withOpacity(
                                                    0.15,
                                                  ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            fontFamily: 'Geist',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _updateAssessmentDetails(
                                            assessmentId: assessment.id,
                                            oldAssessmentName:
                                                assessment.assessmentName,
                                            assessmentName: assessmentName,
                                            assessmentType: assessmentType,
                                            totalMarks: totalMarks,
                                            isFromDropdown: isFromDropdown,
                                          );
                                          if (mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: activeColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          elevation: 4,
                                          shadowColor: activeColor.withOpacity(
                                            0.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Update',
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Update assessment details and refresh local state
  /// [isFromDropdown] - true if updating from dropdown (updates ALL records of this type)
  /// [oldAssessmentName] - the original assessment name (used to identify which type to update)
  Future<void> _updateAssessmentDetails({
    required String assessmentId,
    required String assessmentName,
    required String assessmentType,
    required double totalMarks,
    String? oldAssessmentName,
    bool isFromDropdown = false,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (isFromDropdown) {
        // Type-level update: update ALL records matching this type for the class
        final updatedList = await _assessmentService
            .updateAssessmentTypeDetails(
              className: widget.className,
              subjectCode: widget.subjectCode,
              semester: widget.semester,
              assessmentName: oldAssessmentName ?? assessmentName,
              newAssessmentName: assessmentName,
              newAssessmentType: assessmentType,
              newTotalMarks: totalMarks,
            );

        if (updatedList != null && updatedList.isNotEmpty && mounted) {
          // Replace all matching local records with the updated ones
          setState(() {
            for (final updated in updatedList) {
              final index = _assessments.indexWhere(
                (item) => item.id == updated.id,
              );
              if (index != -1) {
                _assessments[index] = updated;
              }
            }
            _originalAssessments = _assessments
                .map((e) => e.copyWith())
                .toList();
            _filterAssessments();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All ${updatedList.length} $assessmentName records updated successfully!',
                      style: const TextStyle(fontFamily: 'Geist'),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          HapticFeedback.lightImpact();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update assessment records'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        // Single-record update
        final updated = await _assessmentService.updateAssessmentDetails(
          assessmentId: assessmentId,
          assessmentName: assessmentName,
          assessmentType: assessmentType,
          totalMarks: totalMarks,
        );

        if (updated != null && mounted) {
          // Update the local list
          final index = _assessments.indexWhere(
            (item) => item.id == assessmentId,
          );
          if (index != -1) {
            setState(() {
              _assessments[index] = updated;
              _originalAssessments = _assessments
                  .map((e) => e.copyWith())
                  .toList();
              _filterAssessments();
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Assessment updated successfully!',
                    style: TextStyle(fontFamily: 'Geist'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          HapticFeedback.lightImpact();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update assessment'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete assessment with confirmation dialog
  /// [isFromDropdown] - true if deleting from dropdown (deletes ALL records of this type)
  Future<void> _deleteAssessment(
    AssessmentModel assessment, {
    bool isFromDropdown = false,
  }) async {
    final isDark = AppThemeController.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFromDropdown
                        ? 'Delete All ${assessment.assessmentName}'
                        : 'Delete Assessment',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              isFromDropdown
                  ? 'This will delete ALL "${assessment.assessmentName}" records for this class.\n\nThis action cannot be undone.'
                  : 'Delete "${assessment.assessmentName}" for ${assessment.studentName}? This cannot be undone.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: 'Geist',
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        if (isFromDropdown) {
          // Delete ALL records of this assessment type
          final success = await _assessmentService.deleteAssessmentType(
            widget.className,
            widget.subjectCode,
            widget.semester,
            assessment.assessmentName,
          );

          if (success && mounted) {
            // Find IDs to dispose
            final idsToRemove = _assessments
                .where((e) => e.assessmentName == assessment.assessmentName)
                .map((e) => e.id)
                .toList();
            // Remove all matching records from local list
            setState(() {
              _assessments.removeWhere(
                (item) => item.assessmentName == assessment.assessmentName,
              );
              _originalAssessments = _assessments
                  .map((e) => e.copyWith())
                  .toList();
              // Dispose controllers for deleted entries
              for (final id in idsToRemove) {
                _obtainedControllers[id]?.dispose();
                _obtainedControllers.remove(id);
              }
              // If the currently filtered type is now empty, reset to 'all'
              if (_selectedAssessmentName == assessment.assessmentName) {
                _selectedAssessmentName = 'all';
              }
              _filterAssessments();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All ${assessment.assessmentName} records deleted!',
                        style: const TextStyle(fontFamily: 'Geist'),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            HapticFeedback.mediumImpact();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to delete assessment records'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          // Single-record delete (from student row)
          final success = await _assessmentService.deleteAssessment(
            assessment.id,
          );

          if (success && mounted) {
            // Remove from local list
            setState(() {
              _assessments.removeWhere((item) => item.id == assessment.id);
              _originalAssessments = _assessments
                  .map((e) => e.copyWith())
                  .toList();
              // Dispose the deleted controller
              _obtainedControllers[assessment.id]?.dispose();
              _obtainedControllers.remove(assessment.id);
              _filterAssessments();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Assessment deleted successfully!',
                      style: TextStyle(fontFamily: 'Geist'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            HapticFeedback.mediumImpact();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to delete assessment'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete error: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7B61FF),
              ),
              backgroundColor: isDark
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading assessments...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _listenToAssessments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.layers_clear_rounded,
                size: 50,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Assessments Found',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Click the + button above to add a new assessment entry.'
                  : 'No records match "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium filter dropdown with glass-morphism, icons, and animations
  Widget _buildPremiumFilterDropdown(
    bool isDark,
    String activeFilterValue,
    List<String> uniqueTypes,
  ) {
    final activeColor = activeFilterValue == 'all'
        ? const Color(0xFF7B61FF)
        : _getTypeColor(
            _assessmentOptions
                .firstWhere(
                  (opt) => opt['label'] == activeFilterValue,
                  orElse: () => {'type': 'CT'},
                )['type']
                .toString(),
          );

    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withAlpha(8), activeColor.withAlpha(15)]
              : [Colors.white.withAlpha(220), activeColor.withAlpha(8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activeColor.withAlpha(isDark ? 60 : 100),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withAlpha(isDark ? 30 : 15),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showAssessmentFilterSheet(isDark, uniqueTypes),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [activeColor, activeColor.withAlpha(180)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withAlpha(100),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    activeFilterValue == 'all'
                        ? Icons.dashboard_rounded
                        : _getTypeIcon(activeFilterValue),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeFilterValue,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.lightPrimaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Glass-morphism filter sheet matching the create assessment box design
  Future<void> _showAssessmentFilterSheet(
    bool isDark,
    List<String> uniqueTypes,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (sheetContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Transform.scale(
              scale: 0.85 + (0.15 * animValue),
              child: Opacity(opacity: animValue, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withOpacity(0.92)
                        : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7B61FF),
                                    Color(0xFFA78BFA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7B61FF,
                                    ).withAlpha(80),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.filter_list_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Assessments',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightPrimaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  Text(
                                    'Tap to filter, hold to edit/delete',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      fontSize: 12,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                      // Scrollable filter options
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            children: [
                              // 'All' option
                              _buildGlassFilterItem(
                                icon: Icons.dashboard_rounded,
                                label: 'All',
                                count: _assessments.length,
                                color: const Color(0xFF7B61FF),
                                isSelected: _selectedAssessmentName == 'all',
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  setState(() {
                                    _selectedAssessmentName = 'all';
                                    _filterAssessments();
                                  });
                                },
                                onLongPress: () {
                                  Navigator.pop(sheetContext);
                                },
                              ),
                              const SizedBox(height: 8),
                              // Per-type options
                              ...uniqueTypes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final t = entry.value;
                                final typeColor = _getTypeColor(
                                  _assessmentOptions
                                      .firstWhere(
                                        (opt) => opt['label'] == t,
                                        orElse: () => {'type': 'CT'},
                                      )['type']
                                      .toString(),
                                );
                                final count = _assessments
                                    .where((e) => e.assessmentName == t)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 200 + (index * 50),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, itemAnim, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - itemAnim)),
                                        child: Opacity(
                                          opacity: itemAnim,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildGlassFilterItem(
                                      icon: _getTypeIcon(t),
                                      label: t,
                                      count: count,
                                      color: typeColor,
                                      isSelected: _selectedAssessmentName == t,
                                      isDark: isDark,
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        setState(() {
                                          _selectedAssessmentName = t;
                                          _filterAssessments();
                                        });
                                      },
                                      onLongPress: () {
                                        HapticFeedback.mediumImpact();
                                        final firstMatch = _assessments
                                            .firstWhere(
                                              (e) => e.assessmentName == t,
                                              orElse: () =>
                                                  _assessments.isNotEmpty
                                                  ? _assessments.first
                                                  : AssessmentModel(
                                                      id: '',
                                                      rollNumber: '',
                                                      studentName: '',
                                                      department:
                                                          widget.department,
                                                      semester: widget.semester,
                                                      subjectCode:
                                                          widget.subjectCode,
                                                      subjectName:
                                                          widget.subjectName,
                                                      className:
                                                          widget.className,
                                                      assessmentType: t,
                                                      assessmentName: t,
                                                      obtainedMarks: 0,
                                                      totalMarks: 0,
                                                      teacherName:
                                                          widget.teacher.name,
                                                      createdAt: DateTime.now(),
                                                      updatedAt: DateTime.now(),
                                                    ),
                                            );
                                        Navigator.pop(sheetContext);
                                        Future.delayed(
                                          const Duration(milliseconds: 150),
                                          () {
                                            if (mounted) {
                                              _showAssessmentOptions(
                                                firstMatch,
                                                isDark,
                                                isFromDropdown: true,
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              // Cancel button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.15)
                                          : Colors.black.withOpacity(0.1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Individual glass-morphism filter item
  Widget _buildGlassFilterItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withAlpha(180)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(60), blurRadius: 6),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected ? 'Currently selected' : 'Tap to filter',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a suitable icon for an assessment type
  IconData _getTypeIcon(String assessmentName) {
    final type = _assessmentOptions
        .firstWhere(
          (opt) => opt['label'] == assessmentName,
          orElse: () => {'type': 'CT'},
        )['type']
        .toString();
    switch (type) {
      case 'CT':
        return Icons.assignment_turned_in_rounded;
      case 'Quiz':
        return Icons.quiz_rounded;
      case 'Assignment':
        return Icons.work_outline_rounded;
      case 'Lab':
        return Icons.science_rounded;
      case 'Project':
        return Icons.folder_special_rounded;
      case 'Exam':
        return Icons.menu_book_rounded;
      default:
        return Icons.assessment_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CT':
        return const Color(0xFF3B82F6);
      case 'Quiz':
        return const Color(0xFFF59E0B);
      case 'Assignment':
        return const Color(0xFFA855F7);
      case 'Lab':
      case 'Practical':
        return const Color(0xFF10B981);
      case 'Project':
        return const Color(0xFFEC4899);
      case 'Exam':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF7B61FF);
    }
  }

  /// Returns true if user discarded (and should leave), false if they keep editing
  Future<bool> _showDiscardChangesDialog() async {
    final isDark = AppThemeController.isDarkMode;
    final changes = _getChangedEntries();
    final changeCount = changes.length;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withOpacity(0.85)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFEF4444,
                      ).withOpacity(isDark ? 0.25 : 0.15),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated Glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFEF4444).withOpacity(
                                    0.2 + (0.15 * _pulseController.value),
                                  ),
                                  const Color(0xFFEF4444).withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with slide animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: -20.0, end: 0.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(value, 0),
                                child: child,
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unsaved Edits',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightPrimaryText,
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        '$changeCount unsaved mark change${changeCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : AppColors.lightSubtitleText,
                                          fontFamily: 'Geist',
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Body with slide animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 20.0, end: 0.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value),
                                child: child,
                              );
                            },
                            child: Text(
                              'You have uncommitted mark modifications. What would you like to do?',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.lightSubtitleText,
                                fontFamily: 'Geist',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Actions with fade animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(opacity: value, child: child);
                            },
                            child: Column(
                              children: [
                                // Keep Editing button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context, 0);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.15),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Keep Editing',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightPrimaryText,
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Discard button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      Navigator.pop(context, 1);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      shadowColor: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.5),
                                    ),
                                    child: const Text(
                                      'Discard Changes',
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      HapticFeedback.heavyImpact();
                                      Navigator.pop(context, 2);
                                      // Skip the confirmation dialog because
                                      // user already confirmed intent here
                                      await _saveAllMarks(
                                        skipConfirmation: true,
                                      );
                                      // After successful save, exit the page
                                      if (!mounted) return;
                                      if (_hasChanges == false) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B61FF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      shadowColor: const Color(
                                        0xFF7B61FF,
                                      ).withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.save_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

    if (result == 1) {
      // Discard
      _undoAllChanges();
      return true;
    }
    // 0 = Keep Editing, 2 = Save Changes
    return false;
  }

  /// Undo all changes - reset controllers + assessments to original state
  void _undoAllChanges() {
    setState(() {
      _assessments = _originalAssessments.map((e) => e.copyWith()).toList();
      // Reset controllers to original obtained marks
      for (var entry in _assessments) {
        final controller = _obtainedControllers[entry.id];
        if (controller != null) {
          final formatted = entry.obtainedMarks.toStringAsFixed(
            entry.obtainedMarks.truncateToDouble() == entry.obtainedMarks
                ? 0
                : 1,
          );
          controller.text = formatted;
        }
      }
      _hasChanges = false;
      _filterAssessments();
    });
  }
}
