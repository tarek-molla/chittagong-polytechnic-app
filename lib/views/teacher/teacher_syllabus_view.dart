// =============================================================================
// lib/views/teacher/teacher_syllabus_view.dart
// CPI Faculty Portal — Premium Syllabus Management View
// =============================================================================

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
  bool _isDeleting = false;
  String? _errorMessage;
  String _searchQuery = '';
  int? _selectedSemester;
  String _filterMode = 'all';
  String _sortOrder = 'newest';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late TextEditingController _searchController;

  final List<int> _semesterOptions = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _syllabusService = SyllabusService(SupabaseService.client);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _searchController = TextEditingController();

    _listenToSyllabus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _syllabusSubscription?.cancel();
    _searchController.dispose();
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
              _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    List<SyllabusModel> filtered = List.from(_syllabusList);

    if (_selectedSemester != null) {
      filtered = filtered
          .where((item) => item.semester == _selectedSemester)
          .toList();
    }

    if (_filterMode == 'withFile') {
      filtered = filtered
          .where((item) => item.fileUrl != null && item.fileUrl!.isNotEmpty)
          .toList();
    } else if (_filterMode == 'withContent') {
      filtered = filtered
          .where((item) => item.content != null && item.content!.isNotEmpty)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.subjectName.toLowerCase().contains(query) ||
            (item.subjectCode?.toLowerCase().contains(query) ?? false) ||
            (item.content?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_sortOrder == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    setState(() {
      _filteredList = filtered;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===================================================================
  // Glass UI Components
  // ===================================================================

  Widget _buildGlassContainer({
    required Widget child,
    required bool isDark,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderCustomColor,
    double blur = 16,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    borderCustomColor ??
                    (isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.4)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Search & Filter UI
  // ===================================================================

  Widget _buildSearchBar(bool isDark) {
    return _buildGlassContainer(
      isDark: isDark,
      borderRadius: 14,
      blur: 12,
      child: SizedBox(
        height: 46,
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _applyFiltersAndSort();
          },
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search subjects, codes, or content...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white54 : Colors.black45,
              size: 18,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 18,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _applyFiltersAndSort();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, List<int> availableSemesters) {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.dashboard_rounded},
      {
        'key': 'withFile',
        'label': 'With File',
        'icon': Icons.picture_as_pdf_rounded,
      },
      {
        'key': 'withContent',
        'label': 'With Notes',
        'icon': Icons.notes_rounded,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...filters.map((f) {
            final isActive = _filterMode == f['key'];
            final color = const Color(0xFF7B61FF);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _filterMode = f['key'] as String);
                  _applyFiltersAndSort();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withOpacity(0.2)
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? color.withOpacity(0.6)
                              : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.3)),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            f['icon'] as IconData,
                            size: 14,
                            color: isActive
                                ? color
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            f['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? color
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (availableSemesters.isNotEmpty) ...[
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
            ),
            _buildSemesterChip(
              isDark,
              label: 'All Sem',
              isActive: _selectedSemester == null,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedSemester = null);
                _applyFiltersAndSort();
              },
            ),
            ...availableSemesters.map(
              (sem) => _buildSemesterChip(
                isDark,
                label: 'Sem $sem',
                isActive: _selectedSemester == sem,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedSemester = sem);
                  _applyFiltersAndSort();
                },
              ),
            ),
          ],
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
          ),
          _buildSortChip(isDark),
        ],
      ),
    );
  }

  Widget _buildSortChip(bool isDark) {
    final isNewest = _sortOrder == 'newest';
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _sortOrder = isNewest ? 'oldest' : 'newest';
          });
          _applyFiltersAndSort();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isNewest ? 'Newest' : 'Oldest',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildSemesterChip(
    bool isDark, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF00E5FF).withOpacity(0.2)
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF00E5FF).withOpacity(0.6)
                      : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.3)),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? const Color(0xFF00E5FF)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Stats Bar
  // ===================================================================

  Widget _buildStatsBar(bool isDark, int total, int withFile, int withContent) {
    return _buildGlassContainer(
      isDark: isDark,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            isDark,
            'Subjects',
            total.toString(),
            Icons.menu_book_rounded,
            const Color(0xFF7B61FF),
          ),
          _buildStatDivider(isDark),
          _buildStat(
            isDark,
            'Files',
            withFile.toString(),
            Icons.picture_as_pdf_rounded,
            const Color(0xFF00E5FF),
          ),
          _buildStatDivider(isDark),
          _buildStat(
            isDark,
            'Notes',
            withContent.toString(),
            Icons.notes_rounded,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      color: isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.06),
    );
  }

  Widget _buildStat(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // Syllabus Card
  // ===================================================================

  Widget _buildSyllabusCard(bool isDark, SyllabusModel syllabus, int index) {
    final hasFile = syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty;
    final hasContent = syllabus.content != null && syllabus.content!.isNotEmpty;
    final accentColor = hasFile
        ? const Color(0xFF00E5FF)
        : const Color(0xFF7B61FF);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildGlassContainer(
        isDark: isDark,
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAddEditDialog(syllabus: syllabus),
            splashColor: accentColor.withOpacity(0.08),
            highlightColor: accentColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          hasFile
                              ? Icons.picture_as_pdf_rounded
                              : Icons.notes_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syllabus.subjectName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightPrimaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (syllabus.subjectCode != null &&
                                    syllabus.subjectCode!.isNotEmpty)
                                  _buildTag(
                                    text: syllabus.subjectCode!,
                                    bgColor: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    textColor: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    size: 9,
                                  ),
                                _buildTag(
                                  text: 'Sem ${syllabus.semester}',
                                  bgColor: const Color(
                                    0xFF7B61FF,
                                  ).withOpacity(0.15),
                                  textColor: const Color(0xFF7B61FF),
                                  size: 9,
                                ),
                                if (hasFile)
                                  _buildTag(
                                    text: 'PDF',
                                    bgColor: const Color(
                                      0xFF00E5FF,
                                    ).withOpacity(0.15),
                                    textColor: const Color(0xFF00E5FF),
                                    size: 9,
                                  ),
                                if (hasContent)
                                  _buildTag(
                                    text: 'Notes',
                                    bgColor: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.15),
                                    textColor: const Color(0xFFF59E0B),
                                    size: 9,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showAddEditDialog(syllabus: syllabus),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7B61FF,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF7B61FF),
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _deleteSyllabus(syllabus),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hasContent) ...[
                    const SizedBox(height: 8),
                    Text(
                      syllabus.content!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(syllabus.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 10,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasFile && syllabus.fileName != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.attachment_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            syllabus.fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 10,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color bgColor,
    required Color textColor,
    double size = 9,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: size,
          fontWeight: FontWeight.w600,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  // ===================================================================
  // State Views
  // ===================================================================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading syllabus...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 13,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, {String message = ''}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassContainer(
              isDark: isDark,
              borderRadius: 50,
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.menu_book_rounded,
                size: 32,
                color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? 'No Syllabus Entries' : 'No Matches',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.isEmpty
                  ? 'Tap the + button to add your first syllabus entry.'
                  : 'Try adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // Premium Add/Edit Dialog
  // ===================================================================

  Future<void> _showAddEditDialog({SyllabusModel? syllabus}) async {
    final isDark = AppThemeController.isDarkMode;
    final formKey = GlobalKey<FormState>();
    final subjectNameController = TextEditingController(
      text: syllabus?.subjectName ?? '',
    );
    final subjectCodeController = TextEditingController(
      text: syllabus?.subjectCode ?? '',
    );
    final contentController = TextEditingController(
      text: syllabus?.content ?? '',
    );
    final fileUrlController = TextEditingController(
      text: syllabus?.fileUrl ?? '',
    );
    final fileNameController = TextEditingController(
      text: syllabus?.fileName ?? '',
    );
    int formSemester = syllabus?.semester ?? 6;
    final isEditing = syllabus != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, -10),
                          ),
                        ],
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
                          // Handle bar
                          Center(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B61FF)
                                            .withOpacity(
                                              0.2 * _pulseController.value,
                                            ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Header
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7B61FF),
                                        Color(0xFF00E5FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7B61FF,
                                        ).withOpacity(0.4),
                                        blurRadius: 16,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isEditing
                                        ? Icons.edit_rounded
                                        : Icons.add_rounded,
                                    color: Colors.white,
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
                                        isEditing
                                            ? 'Edit Syllabus'
                                            : 'Add Syllabus',
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
                                        isEditing
                                            ? 'Update existing entry'
                                            : 'Create a new syllabus entry',
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
                          ),
                          const SizedBox(height: 16),

                          // Form Fields
                          Flexible(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 15 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Form(
                                  key: formKey,
                                  child: Column(
                                    children: [
                                      _buildGlassTextField(
                                        controller: subjectNameController,
                                        label: 'Subject Name *',
                                        isDark: isDark,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Subject name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: subjectCodeController,
                                        label: 'Subject Code',
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassDropdown(
                                        isDark: isDark,
                                        value: formSemester,
                                        items: _semesterOptions,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setSheetState(() {
                                              formSemester = value;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: contentController,
                                        label: 'Content / Description',
                                        isDark: isDark,
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: fileUrlController,
                                        label: 'File URL (optional)',
                                        isDark: isDark,
                                        hint:
                                            'https://example.com/syllabus.pdf',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: fileNameController,
                                        label: 'File Name (optional)',
                                        isDark: isDark,
                                        hint: 'syllabus.pdf',
                                      ),
                                      const SizedBox(height: 24),

                                      // Actions
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: child,
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  side: BorderSide(
                                                    color: isDark
                                                        ? Colors.white
                                                              .withOpacity(0.2)
                                                        : Colors.black
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                onPressed: _isSaving
                                                    ? null
                                                    : () async {
                                                        if (!formKey
                                                            .currentState!
                                                            .validate()) {
                                                          return;
                                                        }
                                                        await _saveSyllabus(
                                                          id: isEditing
                                                              ? syllabus!.id
                                                              : null,
                                                          subjectName:
                                                              subjectNameController
                                                                  .text,
                                                          subjectCode:
                                                              subjectCodeController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? subjectCodeController
                                                                    .text
                                                              : null,
                                                          semester:
                                                              formSemester,
                                                          content:
                                                              contentController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? contentController
                                                                    .text
                                                              : null,
                                                          fileUrl:
                                                              fileUrlController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? fileUrlController
                                                                    .text
                                                              : null,
                                                          fileName:
                                                              fileNameController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? fileNameController
                                                                    .text
                                                              : null,
                                                          isEditing: isEditing,
                                                        );
                                                        if (mounted) {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        }
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF7B61FF,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  elevation: 4,
                                                  shadowColor: const Color(
                                                    0xFF7B61FF,
                                                  ).withOpacity(0.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                                child: _isSaving
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      )
                                                    : Text(
                                                        isEditing
                                                            ? 'Update'
                                                            : 'Create',
                                                        style: const TextStyle(
                                                          fontFamily: 'Geist',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
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
                        ],
                      ),
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightPrimaryText,
          fontFamily: 'Geist',
          fontSize: 14,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontFamily: 'Geist',
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGlassDropdown({
    required bool isDark,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark
              ? const Color(0xFF131B2E)
              : const Color(0xFFF0F4F8),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((sem) {
            return DropdownMenuItem<int>(
              value: sem,
              child: Text('Semester $sem'),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // CRUD Operations
  // ===================================================================

  Future<void> _saveSyllabus({
    String? id,
    required String subjectName,
    String? subjectCode,
    required int semester,
    String? content,
    String? fileUrl,
    String? fileName,
    required bool isEditing,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final department = widget.teacher.department?.shortCode ?? 'CST';
      final uploadedBy = widget.teacher.name;

      if (isEditing && id != null) {
        await _syllabusService.updateSyllabus(
          id: id,
          subjectName: subjectName,
          subjectCode: subjectCode,
          content: content,
          fileUrl: fileUrl,
          fileName: fileName,
        );
        _showToast('Syllabus updated successfully!');
      } else {
        await _syllabusService.createSyllabus(
          subjectName: subjectName,
          department: department,
          semester: semester,
          subjectCode: subjectCode,
          content: content,
          fileUrl: fileUrl,
          fileName: fileName,
          uploadedBy: uploadedBy,
        );
        _showToast('Syllabus created successfully!');
      }

      _listenToSyllabus();
      HapticFeedback.heavyImpact();
    } catch (e) {
      _showToast('Failed to save: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteSyllabus(SyllabusModel syllabus) async {
    final isDark = AppThemeController.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AlertDialog(
              backgroundColor: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
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
                  Text(
                    'Delete Syllabus',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Delete "${syllabus.subjectName}"? This cannot be undone.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
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
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
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
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final success = await _syllabusService.deleteSyllabus(syllabus.id);
        if (success) {
          _showToast('Syllabus deleted successfully!');
          _listenToSyllabus();
          HapticFeedback.heavyImpact();
        } else {
          _showToast('Failed to delete syllabus', isError: true);
        }
      } catch (e) {
        _showToast('Error: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  // ===================================================================
  // Main Build
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final department = widget.teacher.department?.shortCode ?? 'CST';
    final availableSemesters =
        _syllabusList.map((e) => e.semester).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Manage Syllabus',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
              ),
            ),
            Text(
              '$department • Teacher Portal',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
            ),
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
            onPressed: _isSaving || _isDeleting
                ? null
                : () => _showAddEditDialog(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            tooltip: 'Add Syllabus',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(isDark)
              : _errorMessage != null
              ? _buildErrorState(isDark, _errorMessage!)
              : _buildContent(isDark, availableSemesters),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, List<int> availableSemesters) {
    final total = _syllabusList.length;
    final withFile = _syllabusList
        .where((s) => s.fileUrl != null && s.fileUrl!.isNotEmpty)
        .length;
    final withContent = _syllabusList
        .where((s) => s.content != null && s.content!.isNotEmpty)
        .length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsBar(isDark, total, withFile, withContent),
                const SizedBox(height: 10),
                _buildSearchBar(isDark),
                const SizedBox(height: 10),
                _buildFilterChips(isDark, availableSemesters),
              ],
            ),
          ),
        ),
        if (_filteredList.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _syllabusList.isEmpty
                ? _buildEmptyState(isDark)
                : _buildEmptyState(isDark, message: 'No matches found'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildSyllabusCard(isDark, _filteredList[index], index),
                childCount: _filteredList.length,
              ),
            ),
          ),
      ],
    );
  }
}
