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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _listenToAssessments();
  }

  @override
  void dispose() {
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
            // Prevent real-time updates from overriding local typing state
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
          backgroundColor: Colors.amber.shade700,
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
                Icons.save_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Save Assessment Marks',
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
          'Commit marks update for ${updates.length} student record(s)?',
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                      size: 20,
                    ),
                    const SizedBox(width: 10),
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
                  'Saved $successfulUpdates records, but $failedUpdates failed. Check Supabase RLS policy.',
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

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? Colors.white12 : AppColors.lightCardBorder,
              ),
            ),
            title: Text(
              'Add New Assessment',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : AppColors.lightSubtitleText,
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickTypes.map((type) {
                    final isSelected = dialogCategory == type;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          dialogCategory = type;
                          final matching = _assessmentOptions
                              .where((opt) => opt['type'] == type)
                              .toList();
                          if (matching.isNotEmpty) {
                            dialogName = matching.first['label'] as String;
                            dialogMarks = (matching.first['total'] as num)
                                .toDouble();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (isDark
                                    ? Colors.white.withAlpha(10)
                                    : AppColors.lightCardBorderAlt),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? Colors.white12
                                      : AppColors.lightCardBorder),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : AppColors.lightPrimaryText),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: dialogName,
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    fontFamily: 'Geist',
                    fontSize: 13,
                  ),
                  items: matchingOptions.map<DropdownMenuItem<String>>((
                    option,
                  ) {
                    return DropdownMenuItem<String>(
                      value: option['label'] as String,
                      child: Text(
                        '${option['label']} (${option['total']} marks)',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final option = _assessmentOptions.firstWhere(
                        (opt) => opt['label'] == value,
                      );
                      setModalState(() {
                        dialogName = value;
                        dialogMarks = (option['total'] as num).toDouble();
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
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey(dialogName),
                  initialValue: dialogMarks.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    fontFamily: 'Geist',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Total Marks',
                    labelStyle: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : AppColors.lightSubtitleText,
                      fontSize: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : AppColors.lightSubtitleText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _selectedAssessmentType = dialogCategory;
                  _selectedAssessmentNameForCreate = dialogName;
                  _selectedTotalMarks = dialogMarks;
                  Navigator.pop(context);
                  _createNewAssessment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
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
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continuous Assessment',
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
                          '${widget.className} • ${widget.subjectCode}',
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
                    onPressed: _addNewAssessment,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    tooltip: 'Add Assessment Type',
                  ),
                ],
              ),
            ),

            // Controls & Save Action Sub-Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(8)
                          : AppColors.lightCardBorderAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeFilterValue,
                        dropdownColor: isDark
                            ? const Color(0xFF0F172A)
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
                            child: Text('All Assessments'),
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
                  const Spacer(),
                  if (_hasChanges)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Unsaved',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAllMarks,
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
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_isSaving ? 'Saving...' : 'Save All'),
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
                        borderRadius: BorderRadius.circular(10),
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

            // Aggregate Quick Statistics Banner
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
                    'Records',
                    totalCount.toString(),
                    isDark,
                    const Color(0xFF8B5CF6),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildStatItem(
                    'Avg Mark',
                    _calculateAverage().toString(),
                    isDark,
                    const Color(0xFF10B981),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildStatItem(
                    'Accumulated',
                    _calculateTotal().toStringAsFixed(0),
                    isDark,
                    const Color(0xFF3B82F6),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? Colors.white12 : Colors.black12,
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

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 42,
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
                            _filterAssessments();
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

            // List Table Column Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      'Roll',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightCaptionText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.bold,
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
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        'Tag',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : AppColors.lightCaptionText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Assessment Rows List
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
                            onPressed: _listenToAssessments,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredAssessments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_late_rounded,
                            size: 44,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No assessments present'
                                : 'No records match "$_searchQuery"',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.lightSubtitleText,
                              fontSize: 13,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addNewAssessment,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Provision New Assessment',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredAssessments.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredAssessments[index];
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

  Widget _buildStudentCard(AssessmentModel entry, bool isDark) {
    final controller = _obtainedControllers[entry.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : AppColors.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
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
          Expanded(
            child: Text(
              entry.studentName,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 90,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(10)
                    : AppColors.lightCardBorderAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.lightCardBorder,
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
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(entry.assessmentType).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getTypeColor(entry.assessmentType).withAlpha(50),
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
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CT':
        return const Color(0xFF3B82F6);
      case 'Quiz':
        return const Color(0xFFF59E0B);
      case 'Assignment':
        return const Color(0xFF8B5CF6);
      case 'Lab':
      case 'Practical':
        return const Color(0xFF10B981);
      case 'Project':
        return const Color(0xFFEC4899);
      case 'Exam':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _showDiscardChangesDialog() async {
    final isDark = AppThemeController.isDarkMode;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    if (result == true && mounted) {
      _listenToAssessments();
    }
  }
}
