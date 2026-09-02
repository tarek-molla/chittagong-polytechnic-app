// lib/views/teacher/teacher_notice_view.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../models/notice_model.dart';
import '../../services/notice_service.dart';
import '../../services/supabase_service.dart';

class TeacherNoticeView extends StatefulWidget {
  final AppUser teacher;

  const TeacherNoticeView({super.key, required this.teacher});

  @override
  State<TeacherNoticeView> createState() => _TeacherNoticeViewState();
}

class _TeacherNoticeViewState extends State<TeacherNoticeView>
    with TickerProviderStateMixin {
  late NoticeService _noticeService;
  StreamSubscription<List<NoticeModel>>? _noticeSubscription;

  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String? _editingNoticeId;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();
  String _selectedPriority = 'normal';
  String _selectedCategory = 'GENERAL';
  String? _selectedClass;
  int? _selectedSemester;

  late AnimationController _glowAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _priorities = ['important', 'normal'];
  final List<String> _categories = [
    'ACADEMIC',
    'CLASS',
    'SUGGESTION',
    'GENERAL',
  ];
  final List<String> _classes = [
    'CMT-3rd-A',
    'CMT-3rd-B',
    'CMT-4th-B2',
    'CMT-5th-A',
    'CMT-5th-B',
  ];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _noticeService = NoticeService(SupabaseService.client);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _listenToNotices();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _fadeController.dispose();
    _noticeSubscription?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  void _listenToNotices() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _noticeSubscription?.cancel();
    _noticeSubscription = _noticeService
        .getNoticesStream(
          department: widget.teacher.department?.shortCode ?? 'CST',
          teacherView: true,
        )
        .listen(
          (entries) {
            if (!mounted) return;
            setState(() {
              _notices = entries;
              _isLoading = false;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = 'Failed to load notices: $error';
              _isLoading = false;
            });
          },
        );
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _actionUrlController.clear();
    _selectedClass = null;
    _selectedSemester = null;
    _selectedPriority = 'normal';
    _selectedCategory = 'GENERAL';
    _isEditing = false;
    _editingNoticeId = null;
  }

  Future<void> _showEditNoticeDialog(NoticeModel notice) async {
    final isDark = AppThemeController.isDarkMode;

    _isEditing = true;
    _editingNoticeId = notice.id;

    _titleController.text = notice.title;
    _contentController.text = notice.content;
    _selectedPriority = notice.priority;
    _selectedCategory = notice.category;
    _selectedClass = notice.className;
    _selectedSemester = notice.semester;
    _actionUrlController.text = notice.actionUrl ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildNoticeDialog(isDark, isEditing: true),
    );
  }

  Future<void> _showCreateNoticeDialog() async {
    final isDark = AppThemeController.isDarkMode;
    _resetForm();
    _isEditing = false;
    _editingNoticeId = null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildNoticeDialog(isDark, isEditing: false),
    );
  }

  Widget _buildNoticeDialog(bool isDark, {bool isEditing = false}) {
    return StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
            maxWidth: 440,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2333), Color(0xFF0F1522)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
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
                  key: _formKey,
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
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isEditing
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFF59E0B))
                                          .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isEditing
                                  ? Icons.edit_rounded
                                  : Icons.add_comment_rounded,
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
                                  isEditing ? 'Edit Notice' : 'Post New Notice',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEditing
                                      ? 'Update your notice details'
                                      : 'Broadcast to students and faculty',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _resetForm();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
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
                                label: 'Notice Title',
                                hint: 'Enter notice title...',
                                controller: _titleController,
                                icon: Icons.title_rounded,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildFormField(
                                label: 'Notice Content',
                                hint: 'Write your notice here...',
                                controller: _contentController,
                                icon: Icons.description_rounded,
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter content';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildDropdownField<String>(
                                label: 'Priority',
                                value: _selectedPriority,
                                items: _priorities,
                                icon: Icons.flag_rounded,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      _selectedPriority = value;
                                    });
                                  }
                                },
                                getLabel: (value) => value.toUpperCase(),
                                getColor: _getPriorityColor,
                              ),
                              const SizedBox(height: 14),

                              _buildDropdownField<String>(
                                label: 'Category',
                                value: _selectedCategory,
                                items: _categories,
                                icon: Icons.category_rounded,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      _selectedCategory = value;
                                    });
                                  }
                                },
                                getLabel: (value) => value,
                                getColor: (value) => const Color(0xFF3B82F6),
                              ),
                              const SizedBox(height: 14),

                              _buildDropdownField<String?>(
                                label: 'Target Class',
                                value: _selectedClass,
                                items: _classes,
                                icon: Icons.class_rounded,
                                showNull: true,
                                nullLabel: 'All Classes',
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedClass = value;
                                  });
                                },
                                getLabel: (value) => value ?? '',
                                getColor: (value) => const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(height: 14),

                              _buildDropdownField<String?>(
                                label: 'Target Semester',
                                value: _selectedSemester?.toString(),
                                items: _semesters
                                    .map((e) => e.toString())
                                    .toList(),
                                icon: Icons.numbers_rounded,
                                showNull: true,
                                nullLabel: 'All Semesters',
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedSemester = value != null
                                        ? int.parse(value)
                                        : null;
                                  });
                                },
                                getLabel: (value) => 'Semester $value',
                                getColor: (value) => const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 14),

                              _buildFormField(
                                label: 'Action URL',
                                hint: 'https://example.com (optional)',
                                controller: _actionUrlController,
                                icon: Icons.link_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Bottom Dialog Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _resetForm();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white60,
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
                                                : const Color(0xFFF59E0B))
                                            .withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : isEditing
                                    ? _updateNotice
                                    : _createNotice,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: isEditing
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isEditing
                                                ? Icons.save_rounded
                                                : Icons.send_rounded,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isEditing
                                                ? 'UPDATE NOTICE'
                                                : 'POST NOTICE',
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
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Geist',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 13,
              fontFamily: 'Geist',
            ),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFF59E0B),
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required void Function(T?) onChanged,
    required String Function(T) getLabel,
    required Color Function(T) getColor,
    bool showNull = false,
    String? nullLabel,
  }) {
    final List<DropdownMenuItem<T>> menuItems = [];

    if (showNull) {
      menuItems.add(
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            nullLabel ?? 'None',
            style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'Geist',
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    menuItems.addAll(
      items.map((item) {
        final color = getColor(item);
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                getLabel(item),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Geist',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white38,
              size: 20,
            ),
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Geist',
              fontSize: 13,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white38, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            items: menuItems,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _createNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final department = widget.teacher.department?.shortCode ?? 'CST';
      final teacherName = widget.teacher.name;

      final result = await _noticeService.createNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        actionType: _actionUrlController.text.trim().isNotEmpty
            ? 'link'
            : 'none',
        actionUrl: _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
        department: department,
        semester: _selectedSemester,
        className: _selectedClass,
        teacherName: teacherName,
        priority: _selectedPriority,
        postedByRole: 'teacher',
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notice posted successfully!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
        HapticFeedback.heavyImpact();
        _resetForm();
        if (mounted) {
          Navigator.pop(context);
        }
        _listenToNotices();
      } else {
        throw Exception('Failed to create notice');
      }
    } catch (e) {
      print('❌ Error creating notice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post notice: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _updateNotice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingNoticeId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _noticeService.updateNotice(
        id: _editingNoticeId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        className: _selectedClass,
        semester: _selectedSemester,
        actionType: _actionUrlController.text.trim().isNotEmpty
            ? 'link'
            : 'none',
        actionUrl: _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notice updated successfully!'),
              backgroundColor: Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
          HapticFeedback.heavyImpact();
        }
        _resetForm();
        if (mounted) {
          Navigator.pop(context);
        }
        _listenToNotices();
      } else {
        throw Exception('Failed to update notice');
      }
    } catch (e) {
      print('❌ Error updating notice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notice: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _deleteNotice(String id, String title) async {
    final isDark = AppThemeController.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Notice',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$title"?',
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
        await _noticeService.deleteNotice(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notice deleted successfully!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
        _listenToNotices();
      } catch (e) {
        print('❌ Error deleting notice: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete notice: $e'),
              backgroundColor: Colors.red,
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'important':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B19) : Colors.grey.shade50,
      body: Stack(
        children: [
          if (isDark) ...[
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowAnimationController.value * 40),
                  right: -70 + (_glowAnimationController.value * 30),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyanAccent.withOpacity(0.12),
                          Colors.cyanAccent.withOpacity(0.02),
                          Colors.cyanAccent.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  bottom: -60 - (_glowAnimationController.value * 30),
                  left: -60 - (_glowAnimationController.value * 20),
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
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 95,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : const Color(0xFF070B19),
                      size: 20,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'MANAGE NOTICES',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF070B19),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Geist',
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.cyanAccent.withOpacity(0.06)
                                : Colors.blueAccent.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? Colors.cyanAccent.withOpacity(0.15)
                                  : Colors.blueAccent.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            'TEACHER CONTROL PANEL',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.cyanAccent.withOpacity(0.9)
                                  : Colors.blueAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
              body: _buildBodyContent(isDark),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _glowAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(
                    0.2 + (_glowAnimationController.value * 0.15),
                  ),
                  blurRadius: 16 + (_glowAnimationController.value * 8),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showCreateNoticeDialog(),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: const Color(0xFF070B19),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 20),
              label: const Text(
                'POST NOTICE',
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
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Synchronizing Notices...',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                letterSpacing: 0.5,
                fontSize: 14,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Connection Interrupted',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black54,
                    fontSize: 13,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _listenToNotices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: const Color(0xFF070B19),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_notices.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.02),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  size: 54,
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Notices Posted Yet',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the + button to broadcast a notice.',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black38,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final notice = _notices[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 250 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: _buildNoticeCard(notice, isDark),
                      ),
                    );
                  },
                  child: const SizedBox.shrink(),
                ),
              );
            }, childCount: _notices.length),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(NoticeModel notice, bool isDark) {
    final priorityColor = notice.priorityColor;
    final priorityLabel = notice.priorityLabel;
    final categoryColor = notice.categoryColor;
    final isUrgent = notice.priority == 'urgent';
    final isAdminNotice = notice.postedByRole == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withOpacity(0.5)
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
        ),
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.02)]
              : isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]
              : [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.005),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (isUrgent && !isDark)
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red : priorityColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? Colors.red.withOpacity(0.15)
                                      : priorityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isUrgent ? 'URGENT' : priorityLabel,
                                  style: TextStyle(
                                    color: isUrgent
                                        ? Colors.red
                                        : priorityColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notice.category,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                              if (isAdminNotice)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
                              if (isUrgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    '⚠ URGENT',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notice.timeAgo,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 9,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!isUrgent && !isAdminNotice)
                          IconButton(
                            onPressed: () => _showEditNoticeDialog(notice),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: isDark ? Colors.white38 : Colors.black38,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (!isUrgent && !isAdminNotice)
                          IconButton(
                            onPressed: () =>
                                _deleteNotice(notice.id, notice.title),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent.withOpacity(0.5),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notice.content,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'Geist',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notice.hasAction)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () {
                        if (notice.actionUrl != null) {
                          // Open URL
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.cyanAccent,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (notice.hasAttachments)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: notice.attachments.map((attachment) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                attachment.fileIcon,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                attachment.fileName,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 10,
                                  fontFamily: 'Geist',
                                ),
                              ),
                              Text(
                                ' (${attachment.fileSizeFormatted})',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 9,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted by: ${notice.teacherName ?? 'Admin'}',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 10,
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
    );
  }
}
