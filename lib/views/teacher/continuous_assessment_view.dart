// =============================================================================
// lib/views/teacher/continuous_assessment_view.dart
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
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;
  String _searchQuery = '';
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
      duration: const Duration(milliseconds: 500),
    )..forward();

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

  Future<void> _saveAllMarks() async {
    final isDark = AppThemeController.isDarkMode;

    final updates = <String, double>{};
    for (var entry in _assessments) {
      final controller = _obtainedControllers[entry.id];
      if (controller != null) {
        final val = double.tryParse(controller.text) ?? 0.0;
        if (val != entry.obtainedMarks) {
          updates[entry.id] = val;
        }
      }
    }

    if (updates.isEmpty) {
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

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(15)
                : Colors.black.withAlpha(8),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.save_rounded,
                color: Color(0xFF7B61FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Save Marks',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Commit mark changes for ${updates.length} student record(s)?',
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
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      setState(() {
        _isSaving = true;
      });

      int successfulUpdates = 0;
      int failedUpdates = 0;

      try {
        for (var e in updates.entries) {
          final id = e.key;
          final obtained = e.value;
          final original = _assessments.firstWhere((item) => item.id == id);

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
          } else {
            failedUpdates++;
          }
        }

        setState(() {
          _isSaving = false;
          _hasChanges = failedUpdates > 0;
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

          return Dialog(
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
                        ? const Color(0xFF0F172A).withOpacity(0.75)
                        : Colors.white.withOpacity(0.85),
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
                      // Ambient Glow Inside Dialog
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeColor.withOpacity(0.35),
                                activeColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
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
                            const SizedBox(height: 20),

                            // Category Selector Header
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

                            // Dynamic Colored Category Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _quickTypes.map((type) {
                                final isSelected = dialogCategory == type;
                                final chipColor = _getTypeColor(type);

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        dialogCategory = type;
                                        final matching = _assessmentOptions
                                            .where((opt) => opt['type'] == type)
                                            .toList();
                                        if (matching.isNotEmpty) {
                                          dialogName =
                                              matching.first['label'] as String;
                                          dialogMarks =
                                              (matching.first['total'] as num)
                                                  .toDouble();
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
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
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? chipColor
                                              : (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.08,
                                                      )),
                                          width: 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: chipColor.withOpacity(
                                                    0.4,
                                                  ),
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

                            // Assessment Dropdown
                            Container(
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
                                    .map<DropdownMenuItem<String>>((option) {
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
                            ),
                            const SizedBox(height: 16),

                            // Total Marks Field
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextFormField(
                                key: ValueKey(dialogName),
                                initialValue: dialogMarks.toStringAsFixed(0),
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
                                    setModalState(() {
                                      dialogMarks = parsed;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                                    _selectedAssessmentType = dialogCategory;
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    shadowColor: activeColor.withOpacity(0.5),
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
                          ],
                        ),
                      ),
                    ],
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
      final students = await _assessmentService.getClassStudents(
        widget.className,
        widget.semester,
      );

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No active students found registered for this class!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      int created = 0;
      for (var s in students) {
        final res = await _assessmentService.getOrCreateAssessment(
          s['roll'] ?? '',
          s['name'] ?? '',
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
        if (res != null) created++;
      }

      setState(() {
        _selectedAssessmentName = _selectedAssessmentNameForCreate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Created $created records for $_selectedAssessmentNameForCreate',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _listenToAssessments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed creating entries: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
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

    return Scaffold(
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
          onPressed: () {
            if (_hasChanges) {
              _showDiscardChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _addNewAssessment,
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF7B61FF),
              size: 28,
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
                                color: isDark ? Colors.white38 : Colors.black38,
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

                      // Filter Dropdown
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activeFilterValue,
                            dropdownColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...uniqueTypes.map(
                                (t) => DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(t),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAssessmentName = val;
                                  _filterAssessments();
                                });
                              }
                            },
                          ),
                        ),
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

                // Metrics Analytics Banner
                Container(
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

    return Container(
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
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]
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
                      color: isDark ? Colors.white : AppColors.lightPrimaryText,
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
                            keyboardType: const TextInputType.numberWithOptions(
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
                SizedBox(
                  width: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                    child: Center(
                      child: Text(
                        entry.assessmentName,
                        style: TextStyle(
                          color: _getTypeColor(entry.assessmentType),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _showDiscardChangesDialog() async {
    final isDark = AppThemeController.isDarkMode;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard Edits?',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You have uncommitted mark modifications. Discard changes?',
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    if (result == true && mounted) {
      _listenToAssessments();
    }
  }
}
