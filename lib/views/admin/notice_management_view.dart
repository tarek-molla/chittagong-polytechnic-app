// =============================================================================
// lib/views/admin/notice_management_view.dart
// Premium Notice Management View for CPI Admin Panel
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

class NoticeManagementView extends StatefulWidget {
  final AppUser user;

  const NoticeManagementView({super.key, required this.user});

  @override
  State<NoticeManagementView> createState() => _NoticeManagementViewState();
}

class _NoticeManagementViewState extends State<NoticeManagementView>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService(SupabaseService.client);
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  late AnimationController _bgAnimController;
  late AnimationController _staggerController;
  late AnimationController _fabController;

  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _filteredNotices = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  String _selectedPriority = 'ALL';
  String _searchQuery = '';
  bool _isSearching = false;

  // Stats
  int _totalNotices = 0;
  int _activeNotices = 0;
  int _urgentNotices = 0;

  // Expanded notices
  final Set<String> _expandedNoticeIds = {};

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();
  String _selectedPriorityForm = 'normal';
  String _selectedCategory = 'GENERAL';
  String? _selectedClass;
  int? _selectedSemester;
  bool _isEditing = false;
  String? _editingNoticeId;
  bool _isSaving = false;

  final List<String> _priorities = ['normal', 'important', 'urgent'];
  final List<String> _categories = [
    'GENERAL',
    'EXAMINATION',
    'ADMISSION',
    'ROUTINE',
    'EVENT',
    'ACADEMIC',
    'HOLIDAY',
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
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadNotices();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  String get _department => widget.user.department?.shortCode ?? 'CST';

  void _loadNotices() {
    _subscription?.cancel();
    setState(() => _isLoading = true);

    _subscription = _adminService.getNoticesStream().listen(
      (notices) {
        if (mounted) {
          setState(() {
            _notices = notices;
            _calculateStats();
            _applyFilters();
            _isLoading = false;
            _isProcessing = false;
          });
          _staggerController.forward(from: 0.0);
          _fabController.forward();
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

  void _calculateStats() {
    _totalNotices = _notices.length;
    _activeNotices = _notices.where((n) => n['is_active'] == true).length;
    _urgentNotices = _notices
        .where((n) => n['priority']?.toString().toLowerCase() == 'urgent')
        .length;
  }

  void _refreshList() {
    _loadNotices();
  }

  void _applyFilters() {
    setState(() {
      _filteredNotices = _notices.where((n) {
        final matchesPriority =
            _selectedPriority == 'ALL' ||
            n['priority']?.toString().toLowerCase() ==
                _selectedPriority.toLowerCase();

        final title = n['title']?.toString().toLowerCase() ?? '';
        final content = n['content']?.toString().toLowerCase() ?? '';
        final matchesSearch =
            _searchQuery.isEmpty ||
            title.contains(_searchQuery.toLowerCase()) ||
            content.contains(_searchQuery.toLowerCase());

        return matchesPriority && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onPriorityChanged(String priority) {
    setState(() => _selectedPriority = priority);
    _applyFilters();
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _actionUrlController.clear();
    _selectedClass = null;
    _selectedSemester = null;
    _selectedPriorityForm = 'normal';
    _selectedCategory = 'GENERAL';
    _isEditing = false;
    _editingNoticeId = null;
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'important':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ACADEMIC':
        return const Color(0xFF10B981);
      case 'CLASS':
        return const Color(0xFF3B82F6);
      case 'SUGGESTION':
        return const Color(0xFF8B5CF6);
      case 'GENERAL':
        return const Color(0xFF6B7280);
      case 'EXAMINATION':
        return const Color(0xFFEC4899);
      case 'ADMISSION':
        return const Color(0xFFF59E0B);
      case 'ROUTINE':
        return const Color(0xFF06B6D4);
      case 'EVENT':
        return const Color(0xFF8B5CF6);
      case 'HOLIDAY':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'important':
        return Icons.priority_high_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ===========================================================================
  // CREATE NOTICE DIALOG - Amber Theme for Admin
  // ===========================================================================
  Future<void> _showCreateNoticeDialog() async {
    _resetForm();
    _isEditing = false;
    _editingNoticeId = null;
    await _showNoticeDialog(isEditing: false);
  }

  Future<void> _showEditNoticeDialog(Map<String, dynamic> notice) async {
    _isEditing = true;
    _editingNoticeId = notice['id'].toString();
    _titleController.text = notice['title']?.toString() ?? '';
    _contentController.text = notice['content']?.toString() ?? '';
    _selectedPriorityForm = notice['priority']?.toString() ?? 'normal';
    _selectedCategory = notice['category']?.toString() ?? 'GENERAL';
    _selectedClass = notice['class_name']?.toString();
    _selectedSemester = notice['semester'] as int?;
    _actionUrlController.text = notice['action_url']?.toString() ?? '';
    await _showNoticeDialog(isEditing: true);
  }

  Future<void> _showNoticeDialog({required bool isEditing}) async {
    final isDark = AppThemeController.isDarkMode;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
              maxWidth: 440,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1B2333), const Color(0xFF0F1522)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : const Color(0xFFF59E0B).withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.7)
                      : const Color(0xFFF59E0B).withOpacity(0.2),
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
                        // Header - Amber themed
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.3),
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
                                    isEditing
                                        ? 'Edit Notice'
                                        : 'Post New Notice',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF78350F),
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
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(
                                              0xFF92400E,
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
                                    : const Color(0xFFF59E0B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  _resetForm();
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF78350F),
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
                                  isDark: isDark,
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
                                  isDark: isDark,
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
                                  value: _selectedPriorityForm,
                                  items: _priorities,
                                  icon: Icons.flag_rounded,
                                  isDark: isDark,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        _selectedPriorityForm = value;
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
                                  isDark: isDark,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        _selectedCategory = value;
                                      });
                                    }
                                  },
                                  getLabel: (value) => value,
                                  getColor: _getCategoryColor,
                                ),
                                const SizedBox(height: 14),

                                _buildDropdownField<String?>(
                                  label: 'Target Class',
                                  value: _selectedClass,
                                  items: _classes,
                                  icon: Icons.class_rounded,
                                  isDark: isDark,
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
                                  isDark: isDark,
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
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Bottom Dialog Actions - Amber themed
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
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF78350F),
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
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withOpacity(0.35),
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
                                    foregroundColor: isEditing
                                        ? Colors.white
                                        : const Color(0xFF78350F),
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
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF78350F),
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
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF78350F),
            fontSize: 14,
            fontFamily: 'Geist',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : const Color(0xFF78350F).withOpacity(0.4),
              fontSize: 13,
              fontFamily: 'Geist',
            ),
            prefixIcon: Icon(
              icon,
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF78350F).withOpacity(0.4),
              size: 18,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFFEF3C7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.2),
              ),
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
    required bool isDark,
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
            style: TextStyle(
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF78350F).withOpacity(0.4),
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
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF78350F),
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
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF78350F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.2),
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF78350F).withOpacity(0.4),
              size: 20,
            ),
            dropdownColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFFFFBEB),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF78350F),
              fontFamily: 'Geist',
              fontSize: 13,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isDark
                    ? Colors.white38
                    : const Color(0xFF78350F).withOpacity(0.4),
                size: 18,
              ),
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

    setState(() => _isSaving = true);

    try {
      final result = await _adminService.createNotice({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _selectedPriorityForm,
        'category': _selectedCategory,
        'department': _department,
        'class_name': _selectedClass,
        'semester': _selectedSemester,
        'action_url': _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
        'is_active': true,
      });

      setState(() => _isSaving = false);

      if (result != null && mounted) {
        showAdminToast(
          context,
          message: 'Notice posted successfully! 📢',
          isSuccess: true,
        );
        _resetForm();
        Navigator.pop(context);
        _refreshList();
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to post notice',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showAdminToast(
          context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateNotice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingNoticeId == null) return;

    setState(() => _isSaving = true);

    try {
      final result = await _adminService.updateNotice(_editingNoticeId!, {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _selectedPriorityForm,
        'category': _selectedCategory,
        'class_name': _selectedClass,
        'semester': _selectedSemester,
        'action_url': _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
      });

      setState(() => _isSaving = false);

      if (result != null && mounted) {
        showAdminToast(
          context,
          message: 'Notice updated successfully! ✨',
          isSuccess: true,
        );
        _resetForm();
        Navigator.pop(context);
        _refreshList();
      } else if (mounted) {
        showAdminToast(
          context,
          message: 'Failed to update notice',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showAdminToast(
          context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteNotice(Map<String, dynamic> notice) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Notice',
      message:
          'Are you sure you want to delete "${notice['title']}"?\n\nThis action cannot be undone.',
      color: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed && mounted) {
      setState(() => _isProcessing = true);
      try {
        final success = await _adminService.deleteNotice(
          notice['id'].toString(),
        );
        setState(() => _isProcessing = false);

        if (mounted) {
          if (success) {
            showAdminToast(
              context,
              message: 'Notice deleted! 🗑️',
              isSuccess: true,
            );
            _refreshList();
          } else {
            showAdminToast(
              context,
              message: 'Failed to delete notice',
              isError: true,
            );
          }
        }
      } catch (e) {
        print('❌ Delete error: $e');
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
    _fabController.dispose();
    _subscription?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _actionUrlController.dispose();
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
          : const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Notice Board',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
                color: isDark ? Colors.white : const Color(0xFF78350F),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Colors.transparent
            : const Color(0xFFFFFBEB).withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isStandaloneRoute
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF78350F),
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
          if (_filteredNotices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _ScaleIconButton(
                onTap: () => _showStatsDialog(isDark),
                icon: Icons.bar_chart_rounded,
                accentColor: const Color(0xFF7B61FF),
                isDark: isDark,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _ScaleIconButton(
              onTap: _isProcessing ? null : _showCreateNoticeDialog,
              icon: Icons.add_rounded,
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
                if (_filteredNotices.isNotEmpty) _buildStatsBar(isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildAnimatedSearchBar(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAnimatedFilterChips(isDark),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildContent(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFF59E0B).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '📋',
            '$_totalNotices',
            'Total',
            isDark,
            const Color(0xFF7B61FF),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFF59E0B).withOpacity(0.2),
          ),
          _buildStatItem(
            '✅',
            '$_activeNotices',
            'Active',
            isDark,
            const Color(0xFF10B981),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFF59E0B).withOpacity(0.2),
          ),
          _buildStatItem(
            '🚨',
            '$_urgentNotices',
            'Urgent',
            isDark,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String icon,
    String value,
    String label,
    bool isDark,
    Color color,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF78350F),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white60
                : const Color(0xFF78350F).withOpacity(0.6),
            fontSize: 9,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSearchBar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.85),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(_isSearching ? 0.3 : 0.1)
              : const Color(0xFFF59E0B).withOpacity(_isSearching ? 0.5 : 0.2),
          width: _isSearching ? 2 : 1,
        ),
        boxShadow: _isSearching
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        onTap: () => setState(() => _isSearching = true),
        onSubmitted: (_) => setState(() => _isSearching = false),
        decoration: InputDecoration(
          hintText: '🔍 Search notices...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : const Color(0xFF78350F).withOpacity(0.4),
            fontSize: 13,
            fontFamily: 'Geist',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? Colors.white60
                        : const Color(0xFF78350F).withOpacity(0.4),
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                    });
                    _applyFilters();
                  },
                )
              : null,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF78350F),
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildAnimatedFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('ALL', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('URGENT', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('IMPORTANT', isDark),
          const SizedBox(width: 6),
          _buildFilterChip('NORMAL', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedPriority == label;
    Color color;
    switch (label.toLowerCase()) {
      case 'urgent':
        color = const Color(0xFFEF4444);
        break;
      case 'important':
        color = const Color(0xFFF59E0B);
        break;
      case 'normal':
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = const Color(0xFF7B61FF);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? color
            : isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.8),
        border: Border.all(
          color: isSelected
              ? color
              : isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFF59E0B).withOpacity(0.2),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: GestureDetector(
        onTap: () => _onPriorityChanged(label),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.white70
                    : const Color(0xFF78350F),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
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
          _loadNotices();
        }),
        isDark: isDark,
      );
    }

    if (_filteredNotices.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadNotices(),
      color: const Color(0xFFF59E0B),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filteredNotices.length,
        itemBuilder: (context, index) =>
            _buildAnimatedNoticeCard(_filteredNotices[index], index, isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.2),
                  const Color(0xFFD97706).withOpacity(0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.campaign_rounded,
              size: 60,
              color: isDark
                  ? Colors.white30
                  : const Color(0xFF78350F).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty && _selectedPriority == 'ALL'
                ? 'No Notices Yet'
                : 'No Notices Found',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF78350F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedPriority == 'ALL'
                ? 'Post your first notice to keep everyone informed 📢'
                : 'Try adjusting your filters or search',
            style: TextStyle(
              color: isDark
                  ? Colors.white60
                  : const Color(0xFF78350F).withOpacity(0.6),
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _selectedPriority != 'ALL')
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedPriority = 'ALL';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNoticeCard(
    Map<String, dynamic> notice,
    int index,
    bool isDark,
  ) {
    final double start = (index * 0.06).clamp(0.0, 0.5);
    final double end = (start + 0.3).clamp(0.0, 1.0);

    final Animation<double> cardAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final isExpanded = _expandedNoticeIds.contains(notice['id'].toString());

    return AnimatedBuilder(
      animation: cardAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: cardAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - cardAnimation.value)),
            child: child,
          ),
        );
      },
      child: _PremiumNoticeCard(
        notice: notice,
        isDark: isDark,
        isExpanded: isExpanded,
        isProcessing: _isProcessing,
        onToggle: () {
          setState(() {
            final id = notice['id'].toString();
            if (_expandedNoticeIds.contains(id)) {
              _expandedNoticeIds.remove(id);
            } else {
              _expandedNoticeIds.add(id);
            }
          });
        },
        onEdit: () => _showEditNoticeDialog(notice),
        onDelete: () => _deleteNotice(notice),
      ),
    );
  }

  void _showStatsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _PremiumStatsDialog(
        totalNotices: _totalNotices,
        activeNotices: _activeNotices,
        urgentNotices: _urgentNotices,
        isDark: isDark,
      ),
    );
  }
}

// ── PREMIUM NOTICE CARD ──────────────────────────────────────────────────────
class _PremiumNoticeCard extends StatefulWidget {
  final Map<String, dynamic> notice;
  final bool isDark;
  final bool isExpanded;
  final bool isProcessing;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PremiumNoticeCard({
    required this.notice,
    required this.isDark,
    required this.isExpanded,
    required this.isProcessing,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PremiumNoticeCard> createState() => _PremiumNoticeCardState();
}

class _PremiumNoticeCardState extends State<_PremiumNoticeCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    final notice = widget.notice;
    final isDark = widget.isDark;
    final isExpanded = widget.isExpanded;

    final priority = notice['priority']?.toString() ?? 'normal';
    final priorityColor = _getPriorityColor(priority);
    final priorityIcon = _getPriorityIcon(priority);
    final isActive = notice['is_active'] == true;
    final category = notice['category']?.toString() ?? 'GENERAL';
    final categoryColor = _getCategoryColor(category);
    final isUrgent = priority == 'urgent';
    final isImportant = priority == 'important';
    final isAdminNotice = notice['posted_by_role']?.toString() == 'admin';

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUrgent
                  ? [Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.02)]
                  : isImportant
                  ? [
                      const Color(0xFFF59E0B).withOpacity(0.08),
                      const Color(0xFFF59E0B).withOpacity(0.02),
                    ]
                  : isDark
                  ? [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.01),
                    ]
                  : [
                      const Color(0xFFFEF3C7).withOpacity(0.5),
                      Colors.white.withOpacity(0.5),
                    ],
            ),
            border: Border.all(
              color: isExpanded
                  ? categoryColor.withOpacity(0.5)
                  : isUrgent
                  ? Colors.red.withOpacity(0.5)
                  : isImportant
                  ? const Color(0xFFF59E0B).withOpacity(0.5)
                  : isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF59E0B).withOpacity(0.2),
              width: isExpanded ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isUrgent && !isDark)
                BoxShadow(
                  color: Colors.red.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              if (isImportant && !isDark)
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(20),
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
                              color: isUrgent
                                  ? Colors.red
                                  : isImportant
                                  ? const Color(0xFFF59E0B)
                                  : priorityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notice['title'] ?? 'Untitled',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF78350F),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Geist',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(
                                                0xFF78350F,
                                              ).withOpacity(0.4),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildBadge(
                                      isUrgent
                                          ? 'URGENT'
                                          : isImportant
                                          ? 'IMPORTANT'
                                          : priority.toUpperCase(),
                                      isUrgent
                                          ? Colors.red
                                          : isImportant
                                          ? const Color(0xFFF59E0B)
                                          : priorityColor,
                                      isDark,
                                    ),
                                    _buildBadge(
                                      category,
                                      categoryColor,
                                      isDark,
                                    ),
                                    _buildStatusBadge(isActive, isDark),
                                    if (isAdminNotice)
                                      _buildBadge('ADMIN', Colors.red, isDark),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(notice['created_at']),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(
                                            0xFF78350F,
                                          ).withOpacity(0.4),
                                    fontSize: 9,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit button - Admin can edit all
                          IconButton(
                            onPressed: widget.onEdit,
                            icon: Icon(
                              Icons.edit_outlined,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF78350F).withOpacity(0.4),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Delete button - Admin can delete all
                          IconButton(
                            onPressed: widget.onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: isDark
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : Colors.redAccent,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedCrossFade(
                        firstChild: Text(
                          notice['content'] ?? '',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF78350F).withOpacity(0.7),
                            fontSize: 13,
                            height: 1.4,
                            fontFamily: 'Geist',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        secondChild: Text(
                          notice['content'] ?? '',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF78350F),
                            fontSize: 13,
                            height: 1.5,
                            fontFamily: 'Geist',
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                      if (notice['action_url'] != null &&
                          notice['action_url'].toString().isNotEmpty &&
                          isExpanded) ...[
                        const SizedBox(height: 12),
                        Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showAdminToast(
                                context,
                                message:
                                    'Opening link: ${notice['action_url']}',
                                isSuccess: false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor.withOpacity(0.15),
                              foregroundColor: categoryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: categoryColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Open Action Link',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF78350F).withOpacity(0.4),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Posted by: ${notice['teacher_name'] ?? 'Admin'}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF78350F).withOpacity(0.4),
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
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isDark) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

// ── PREMIUM STATS DIALOG ──────────────────────────────────────────────────
class _PremiumStatsDialog extends StatelessWidget {
  final int totalNotices;
  final int activeNotices;
  final int urgentNotices;
  final bool isDark;

  const _PremiumStatsDialog({
    required this.totalNotices,
    required this.activeNotices,
    required this.urgentNotices,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? const Color(0xFF1A1F36) : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notice Statistics',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF78350F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('📋', '$totalNotices', 'Total', isDark),
                const SizedBox(width: 12),
                _buildStatCard('✅', '$activeNotices', 'Active', isDark),
                const SizedBox(width: 12),
                _buildStatCard('🚨', '$urgentNotices', 'Urgent', isDark),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Priority Distribution',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF78350F).withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityIndicator(
                        'Urgent',
                        const Color(0xFFEF4444),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityIndicator(
                        'Important',
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityIndicator(
                        'Normal',
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF78350F),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white60
                    : const Color(0xFF78350F).withOpacity(0.6),
                fontSize: 10,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : const Color(0xFF78350F).withOpacity(0.7),
                fontSize: 10,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SCALE ICON BUTTON ────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
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
            gradient: LinearGradient(
              colors: [
                widget.accentColor.withOpacity(widget.isDark ? 0.3 : 0.4),
                widget.accentColor.withOpacity(widget.isDark ? 0.15 : 0.2),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.accentColor.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.onTap == null ? Colors.grey : widget.accentColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────
Color _getPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return const Color(0xFFEF4444);
    case 'important':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF3B82F6);
  }
}

IconData _getPriorityIcon(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return Icons.warning_amber_rounded;
    case 'important':
      return Icons.priority_high_rounded;
    default:
      return Icons.info_rounded;
  }
}

Color _getCategoryColor(String category) {
  switch (category.toUpperCase()) {
    case 'ACADEMIC':
      return const Color(0xFF10B981);
    case 'CLASS':
      return const Color(0xFF3B82F6);
    case 'SUGGESTION':
      return const Color(0xFF8B5CF6);
    case 'GENERAL':
      return const Color(0xFF6B7280);
    case 'EXAMINATION':
      return const Color(0xFFEC4899);
    case 'ADMISSION':
      return const Color(0xFFF59E0B);
    case 'ROUTINE':
      return const Color(0xFF06B6D4);
    case 'EVENT':
      return const Color(0xFF8B5CF6);
    case 'HOLIDAY':
      return const Color(0xFF10B981);
    default:
      return const Color(0xFF6B7280);
  }
}
