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
  // ✅ Changed to TickerProviderStateMixin for multiple controllers
  late NoticeService _noticeService;
  StreamSubscription<List<NoticeModel>>? _noticeSubscription;

  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedPriority = 'normal';
  String _selectedCategory = 'GENERAL';
  String? _selectedClass;
  int? _selectedSemester;
  String? _actionUrl;

  late AnimationController _glowAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _priorities = ['normal', 'important', 'urgent'];
  final List<String> _categories = [
    'GENERAL',
    'ACADEMIC',
    'EXAMINATION',
    'ADMINISTRATIVE',
    'EVENT',
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

  Future<void> _showCreateNoticeDialog() async {
    final isDark = AppThemeController.isDarkMode;

    _titleController.clear();
    _contentController.clear();
    _selectedPriority = 'normal';
    _selectedCategory = 'GENERAL';
    _selectedClass = null;
    _selectedSemester = null;
    _actionUrl = null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 10),
            Text(
              'Post New Notice',
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
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Notice Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notice Content *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              color: _getPriorityColor(priority),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Target Class (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ..._classes.map((className) {
                      return DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Target Semester (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Semesters'),
                    ),
                    ..._semesters.map((sem) {
                      return DropdownMenuItem(
                        value: sem,
                        child: Text('Semester $sem'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: TextEditingController(text: _actionUrl),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Action URL (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com',
                  ),
                  onChanged: (value) {
                    _actionUrl = value;
                  },
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
            onPressed: _isSaving ? null : _createNotice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
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
                : const Text(
                    'POST NOTICE',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
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
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        actionType: _actionUrl != null && _actionUrl!.isNotEmpty
            ? 'link'
            : 'none',
        actionUrl: _actionUrl,
        department: department,
        semester: _selectedSemester,
        className: _selectedClass,
        teacherName: teacherName,
        priority: _selectedPriority,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notice posted successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        HapticFeedback.heavyImpact();
      } else {
        throw Exception('Failed to create notice');
      }

      if (mounted) {
        Navigator.pop(context);
      }
      _listenToNotices();
    } catch (e) {
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
          'Are you sure you want to delete "$title"?',
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
            SnackBar(
              content: const Text('Notice deleted successfully!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        _listenToNotices();
      } catch (e) {
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
          if (!isDark) ...[
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowAnimationController.value * 20),
                  right: -70 + (_glowAnimationController.value * 15),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.06),
                          Colors.blue.withOpacity(0.01),
                          Colors.blue.withOpacity(0),
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
                  bottom: -60 - (_glowAnimationController.value * 15),
                  left: -60 - (_glowAnimationController.value * 10),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withOpacity(0.04),
                          Colors.purple.withOpacity(0.005),
                          Colors.purple.withOpacity(0),
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
        boxShadow: [
          if (notice.priority == 'urgent' && !isDark)
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.1),
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
                        color: priorityColor,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priorityLabel,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
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
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notice.category,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 8,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                notice.timeAgo,
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
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteNotice(notice.id, notice.title),
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
                        if (notice.actionUrl != null) {}
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
