// lib/views/teacher/teacher_syllabus_view.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../models/syllabus_model.dart';
import '../../services/syllabus_service.dart';
import '../../services/supabase_service.dart';

class TeacherSyllabusView extends StatefulWidget {
  final AppUser teacher;

  const TeacherSyllabusView({super.key, required this.teacher});

  @override
  State<TeacherSyllabusView> createState() => _TeacherSyllabusViewState();
}

class _TeacherSyllabusViewState extends State<TeacherSyllabusView>
    with TickerProviderStateMixin {
  late SyllabusService _syllabusService;
  StreamSubscription<List<SyllabusModel>>? _syllabusSubscription;

  List<SyllabusModel> _syllabusList = [];
  List<SyllabusModel> _filteredList = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  int _selectedSemester = 0; // 0 = All

  // Form fields for adding/editing
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _contentController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _fileNameController = TextEditingController();
  int _formSemester = 6;
  bool _isEditing = false;
  String? _editingId;

  late AnimationController _glowAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<int> _semesterOptions = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _syllabusService = SyllabusService(SupabaseService.client);

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
      curve: Curves.easeOut,
    );

    _listenToSyllabus();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _fadeController.dispose();
    _syllabusSubscription?.cancel();
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _contentController.dispose();
    _fileUrlController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _listenToSyllabus() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _syllabusSubscription?.cancel();
    _syllabusSubscription = _syllabusService
        .getTeacherSyllabusStream(widget.teacher.department?.shortCode ?? 'CST')
        .listen(
          (entries) {
            if (!mounted) return;
            setState(() {
              _syllabusList = entries;
              _filterSyllabus();
              _isLoading = false;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = 'Failed to load syllabus: $error';
              _isLoading = false;
            });
          },
        );
  }

  void _filterSyllabus() {
    List<SyllabusModel> filtered = List.from(_syllabusList);

    if (_selectedSemester > 0) {
      filtered = filtered
          .where((item) => item.semester == _selectedSemester)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.subjectName.toLowerCase().contains(query) ||
            (item.subjectCode?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredList = filtered;
    });
  }

  Future<void> _showAddEditDialog({SyllabusModel? syllabus}) async {
    final isDark = AppThemeController.isDarkMode;
    _isEditing = syllabus != null;
    _editingId = syllabus?.id;

    print('📝 Editing mode: $_isEditing, ID: $_editingId');

    if (syllabus != null) {
      _subjectNameController.text = syllabus.subjectName;
      _subjectCodeController.text = syllabus.subjectCode ?? '';
      _contentController.text = syllabus.content ?? '';
      _fileUrlController.text = syllabus.fileUrl ?? '';
      _fileNameController.text = syllabus.fileName ?? '';
      _formSemester = syllabus.semester;
    } else {
      _subjectNameController.clear();
      _subjectCodeController.clear();
      _contentController.clear();
      _fileUrlController.clear();
      _fileNameController.clear();
      _formSemester = 6;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: const Color(0xFF7B61FF),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              _isEditing ? 'Edit Syllabus' : 'Add New Syllabus',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subject Name
                TextFormField(
                  controller: _subjectNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Subject Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter subject name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Subject Code
                TextFormField(
                  controller: _subjectCodeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Semester
                DropdownButtonFormField<int>(
                  value: _formSemester,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Semester *',
                    border: OutlineInputBorder(),
                  ),
                  items: _semesterOptions.map((sem) {
                    return DropdownMenuItem<int>(
                      value: sem,
                      child: Text('Semester $sem'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _formSemester = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select semester';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Content
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content / Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                // File URL
                TextFormField(
                  controller: _fileUrlController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'File URL (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/syllabus.pdf',
                  ),
                ),
                const SizedBox(height: 12),
                // File Name
                TextFormField(
                  controller: _fileNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'File Name (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'syllabus.pdf',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontFamily: 'Geist',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSyllabus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isEditing ? 'Update' : 'Create',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSyllabus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final department = widget.teacher.department?.shortCode ?? 'CST';
      final uploadedBy = widget.teacher.name;

      print('📝 _isEditing: $_isEditing, _editingId: $_editingId');

      if (_isEditing && _editingId != null) {
        // UPDATE - FIXED
        print('📝 Updating syllabus with ID: $_editingId');

        final result = await _syllabusService.updateSyllabus(
          id: _editingId!,
          subjectName: _subjectNameController.text.isNotEmpty
              ? _subjectNameController.text
              : null,
          subjectCode: _subjectCodeController.text.isNotEmpty
              ? _subjectCodeController.text
              : null,
          content: _contentController.text.isNotEmpty
              ? _contentController.text
              : null,
          fileUrl: _fileUrlController.text.isNotEmpty
              ? _fileUrlController.text
              : null,
          fileName: _fileNameController.text.isNotEmpty
              ? _fileNameController.text
              : null,
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Syllabus updated successfully!'),
              backgroundColor: Color(0xFF7B61FF),
            ),
          );
        } else {
          throw Exception('Update failed - no response');
        }
      } else {
        // CREATE
        print('📝 Creating new syllabus');
        final result = await _syllabusService.createSyllabus(
          subjectName: _subjectNameController.text,
          department: department,
          semester: _formSemester,
          subjectCode: _subjectCodeController.text.isNotEmpty
              ? _subjectCodeController.text
              : null,
          content: _contentController.text.isNotEmpty
              ? _contentController.text
              : null,
          fileUrl: _fileUrlController.text.isNotEmpty
              ? _fileUrlController.text
              : null,
          fileName: _fileNameController.text.isNotEmpty
              ? _fileNameController.text
              : null,
          uploadedBy: uploadedBy,
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Syllabus created successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          throw Exception('Create failed - no response');
        }
      }

      Navigator.pop(context);
      _listenToSyllabus();
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ Error saving syllabus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save syllabus: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteSyllabus(String id, String subjectName) async {
    final isDark = AppThemeController.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Syllabus',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$subjectName"?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontFamily: 'Geist',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontFamily: 'Geist',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _syllabusService.deleteSyllabus(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syllabus deleted successfully!'),
            backgroundColor: Colors.red,
          ),
        );
        _listenToSyllabus();
        HapticFeedback.heavyImpact();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete syllabus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final uniqueSemesters =
        _syllabusList.map((e) => e.semester).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Manage Syllabus',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddEditDialog(),
            icon: Icon(
              Icons.add_rounded,
              color: const Color(0xFF7B61FF),
              size: 28,
            ),
            tooltip: 'Add Syllabus',
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
                // Filter bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Search bar
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
                                      _filterSyllabus();
                                    });
                                  },
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'Geist',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search syllabus...',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: 13,
                                      fontFamily: 'Geist',
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _filterSyllabus();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Semester filter dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        child: DropdownButton<int>(
                          value: _selectedSemester,
                          hint: const Text('All'),
                          underline: const SizedBox(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Geist',
                            fontSize: 12,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text('All Semesters'),
                            ),
                            ...uniqueSemesters.map((sem) {
                              return DropdownMenuItem<int>(
                                value: sem,
                                child: Text('Sem $sem'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSemester = value;
                                _filterSyllabus();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredList.length} subjects',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontSize: 12,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_syllabusList.length} total',
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
                // Syllabus list
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : _errorMessage != null
                      ? _buildErrorState(isDark)
                      : _filteredList.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final syllabus = _filteredList[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 250 + (index * 80),
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
                                child: _buildSyllabusCard(syllabus, isDark),
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
            'Loading syllabus...',
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
              'Failed to Load Syllabus',
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
              onPressed: _listenToSyllabus,
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
              'No Syllabus Found',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the + button to add a new syllabus entry.',
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

  Widget _buildSyllabusCard(SyllabusModel syllabus, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7B61FF).withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: const Color(0xFF7B61FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syllabus.subjectName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (syllabus.subjectCode != null &&
                              syllabus.subjectCode!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                syllabus.subjectCode!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 10,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B61FF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sem ${syllabus.semester}',
                              style: const TextStyle(
                                color: Color(0xFF7B61FF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddEditDialog(syllabus: syllabus),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          _deleteSyllabus(syllabus.id, syllabus.subjectName),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent.withOpacity(0.6),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
