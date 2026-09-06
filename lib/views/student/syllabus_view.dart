// =============================================================================
// lib/views/student/syllabus_view.dart
// CPI Student Portal — Premium Syllabus & Suggestions View
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/syllabus_model.dart';
import '../../models/user.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../services/database_service.dart';

class SyllabusView extends StatefulWidget {
  final AppUser user;

  const SyllabusView({super.key, required this.user});

  @override
  State<SyllabusView> createState() => _SyllabusViewState();
}

class _SyllabusViewState extends State<SyllabusView>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _glowAnimationController;
  late final TextEditingController _searchController;

  // Search & filter state
  String _searchQuery = '';
  String _filterMode = 'all';
  int? _selectedSemester;
  String _sortOrder = 'newest';
  String? _expandedCardId;

  // Data state
  List<SyllabusModel> _allSyllabus = [];
  List<SyllabusModel> _filteredSyllabus = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<SyllabusModel>>? _subscription;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _searchController = TextEditingController();

    _loadSyllabus();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fadeController.dispose();
    _glowAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadSyllabus() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final department = widget.user.department?.shortCode ?? 'CST';
    final semester = widget.user.semester ?? 6;

    _subscription?.cancel();
    _subscription = DatabaseService()
        .getSyllabusStream(department, semester)
        .listen(
          (data) {
            if (mounted) {
              setState(() {
                _allSyllabus = data;
                _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    List<SyllabusModel> filtered = List.from(_allSyllabus);

    // Apply filter
    if (_filterMode == 'withFile') {
      filtered = filtered
          .where((s) => s.fileUrl != null && s.fileUrl!.isNotEmpty)
          .toList();
    } else if (_filterMode == 'withContent') {
      filtered = filtered
          .where((s) => s.content != null && s.content!.isNotEmpty)
          .toList();
    }

    // Apply semester filter
    if (_selectedSemester != null) {
      filtered = filtered
          .where((s) => s.semester == _selectedSemester)
          .toList();
    }

    // Apply search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((s) {
        return s.subjectName.toLowerCase().contains(q) ||
            (s.subjectCode?.toLowerCase().contains(q) ?? false) ||
            (s.content?.toLowerCase().contains(q) ?? false) ||
            (s.fileName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Apply sort
    if (_sortOrder == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    setState(() {
      _filteredSyllabus = filtered;
    });
  }

  void _refreshData() {
    _loadSyllabus();
    _fadeController.forward(from: 0);
  }

  // ===================================================================
  // Helpers
  // ===================================================================

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

  void _showCustomToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
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
            : const Color(0xFF7B61FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSyllabus(SyllabusModel syllabus) async {
    HapticFeedback.lightImpact();
    if (syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty) {
      try {
        final url = Uri.parse(syllabus.fileUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showCustomToast('Could not open file source link.', isError: true);
        }
      } catch (e) {
        _showCustomToast('Error launching resource: $e', isError: true);
      }
    } else if (syllabus.content != null && syllabus.content!.isNotEmpty) {
      setState(() {
        _expandedCardId = _expandedCardId == syllabus.id ? null : syllabus.id;
      });
    } else {
      _showCustomToast('No syllabus content or files attached.', isError: true);
    }
  }

  // ===================================================================
  // Build helpers
  // ===================================================================

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.cyanAccent.withOpacity(0.15)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applyFiltersAndSort();
          });
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
            color: isDark ? Colors.cyanAccent : Colors.black45,
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
                    setState(() {
                      _searchQuery = '';
                      _applyFiltersAndSort();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  setState(() {
                    _filterMode = f['key'] as String;
                    _applyFiltersAndSort();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.18)
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? color.withOpacity(0.6)
                          : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05)),
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
            );
          }),
          if (availableSemesters.isNotEmpty) ...[
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
            _buildSemesterChip(
              isDark,
              label: 'All Sem',
              isActive: _selectedSemester == null,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedSemester = null;
                  _applyFiltersAndSort();
                });
              },
            ),
            ...availableSemesters.map(
              (sem) => _buildSemesterChip(
                isDark,
                label: 'Sem $sem',
                isActive: _selectedSemester == sem,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedSemester = sem;
                    _applyFiltersAndSort();
                  });
                },
              ),
            ),
          ],
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: isDark
                ? Colors.white.withOpacity(0.1)
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
            _applyFiltersAndSort();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00E5FF).withOpacity(0.15)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00E5FF).withOpacity(0.5)
                  : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
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
    );
  }

  Widget _buildStatsBar(bool isDark, int total, int withFile, int withContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
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
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05),
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

  Widget _buildTag({
    required String text,
    required Color bgColor,
    required Color textColor,
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
          fontSize: 9,
          fontWeight: FontWeight.w600,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  // ===================================================================
  // Morphing Card Builder
  // ===================================================================

  Widget _buildSyllabusCard(bool isDark, SyllabusModel syllabus, int index) {
    final hasFile = syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty;
    final hasContent = syllabus.content != null && syllabus.content!.isNotEmpty;
    final isExpanded = _expandedCardId == syllabus.id;
    final accentColor = hasFile
        ? const Color(0xFF00E5FF)
        : const Color(0xFF7B61FF);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isExpanded
              ? (isDark ? const Color(0xFF131B2E) : Colors.white)
              : (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.85)),
          borderRadius: BorderRadius.circular(isExpanded ? 22 : 18),
          border: Border.all(
            color: isExpanded
                ? accentColor.withOpacity(0.6)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04)),
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isExpanded ? 22 : 18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isExpanded ? 22 : 18),
                onTap: () => _openSyllabus(syllabus),
                splashColor: accentColor.withOpacity(0.08),
                highlightColor: accentColor.withOpacity(0.05),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isExpanded ? 18 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.all(isExpanded ? 12 : 10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              hasFile
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.notes_rounded,
                              color: accentColor,
                              size: isExpanded ? 22 : 20,
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
                                    fontSize: isExpanded ? 17 : 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Geist',
                                  ),
                                  maxLines: isExpanded ? 3 : 1,
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
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.black.withOpacity(0.04),
                                        textColor: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    _buildTag(
                                      text: 'Sem ${syllabus.semester}',
                                      bgColor: const Color(
                                        0xFF7B61FF,
                                      ).withOpacity(0.12),
                                      textColor: const Color(0xFF7B61FF),
                                    ),
                                    if (hasFile)
                                      _buildTag(
                                        text: 'PDF',
                                        bgColor: const Color(
                                          0xFF00E5FF,
                                        ).withOpacity(0.12),
                                        textColor: const Color(0xFF00E5FF),
                                      ),
                                    if (hasContent)
                                      _buildTag(
                                        text: 'Notes',
                                        bgColor: const Color(
                                          0xFFF59E0B,
                                        ).withOpacity(0.12),
                                        textColor: const Color(0xFFF59E0B),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (hasContent && !hasFile)
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: accentColor,
                                  size: 12,
                                ),
                              ),
                            )
                          else if (hasFile)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.open_in_new_rounded,
                                color: accentColor,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                      if (hasContent) ...[
                        const SizedBox(height: 10),
                        AnimatedCrossFade(
                          firstChild: Text(
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
                          secondChild: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.04),
                              ),
                            ),
                            child: Text(
                              syllabus.content!,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 13,
                                fontFamily: 'Geist',
                                height: 1.5,
                              ),
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        ),
                      ],
                      const SizedBox(height: 10),
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
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 10,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (hasContent && !hasFile)
                            Text(
                              isExpanded ? 'Show less' : 'See details',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w700,
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

  // ===================================================================
  // State views
  // ===================================================================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Synchronizing syllabus...',
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
              onPressed: _refreshData,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 32,
                color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? 'No Syllabus Available' : 'No Matches',
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
                  ? 'Syllabus content will appear here when available.'
                  : 'Try adjusting your search query or filters.',
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
  // Main build
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final department = widget.user.department?.shortCode ?? 'CST';
    final semester = widget.user.semester ?? 6;

    // Show loading only on initial load
    if (_isLoading && _allSyllabus.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF070B19)
            : AppColors.lightBackground,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            if (isDark) ...[
              AnimatedBuilder(
                animation: _glowAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: -120 + (_glowAnimationController.value * 30),
                    right: -70 + (_glowAnimationController.value * 20),
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
            ],
            SafeArea(child: _buildLoadingState(isDark)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF070B19)
            : AppColors.lightBackground,
        extendBodyBehindAppBar: true,
        body: SafeArea(child: _buildErrorState(isDark, _errorMessage!)),
      );
    }

    final total = _allSyllabus.length;
    final withFile = _allSyllabus
        .where((s) => s.fileUrl != null && s.fileUrl!.isNotEmpty)
        .length;
    final withContent = _allSyllabus
        .where((s) => s.content != null && s.content!.isNotEmpty)
        .length;
    final availableSemesters =
        _allSyllabus.map((e) => e.semester).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (isDark) ...[
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowAnimationController.value * 30),
                  right: -70 + (_glowAnimationController.value * 20),
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
                          Colors.deepPurpleAccent.withOpacity(0.10),
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App Bar Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'SYLLABUS & NOTES',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightPrimaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.cyanAccent.withOpacity(0.08)
                                      : Colors.blueAccent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.cyanAccent.withOpacity(0.2)
                                        : Colors.blueAccent.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  '$department • SEMESTER $semester',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: isDark
                                        ? Colors.cyanAccent
                                        : Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: _allSyllabus.isEmpty
                        ? _buildEmptyState(isDark)
                        : CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStatsBar(
                                        isDark,
                                        total,
                                        withFile,
                                        withContent,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildSearchBar(isDark),
                                      const SizedBox(height: 12),
                                      _buildFilterChips(
                                        isDark,
                                        availableSemesters,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_filteredSyllabus.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _buildEmptyState(
                                    isDark,
                                    message: 'No matches found',
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    24,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildSyllabusCard(
                                        isDark,
                                        _filteredSyllabus[index],
                                        index,
                                      ),
                                      childCount: _filteredSyllabus.length,
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
        ],
      ),
    );
  }
}
