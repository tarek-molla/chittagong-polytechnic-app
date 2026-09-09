// =============================================================================
// lib/views/admin/admission_triage_view.dart
// Premium Admission Triage View for CPI Admin Panel
// Features:
//   • Glassmorphism cards with staggered animations
//   • Real-time admission status management
//   • Approve/Reject with visual feedback
//   • Premium UI with gradients and animations
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../core/router.dart';
import '../../models/user.dart';
import '../../models/admission.dart';
import '../../models/user_role.dart' as role_model;
import '../../services/admission_service.dart';
import '../../widgets/animated_background_painter.dart';
import '../../widgets/offline_indicator_badge.dart';
import '../../widgets/skeleton_loader.dart';

class AdmissionTriageView extends StatefulWidget {
  final AppUser user;

  const AdmissionTriageView({super.key, required this.user});

  @override
  State<AdmissionTriageView> createState() => _AdmissionTriageViewState();
}

class _AdmissionTriageViewState extends State<AdmissionTriageView>
    with TickerProviderStateMixin {
  // ✅ FIXED: Changed from SingleTickerProviderStateMixin
  late AnimationController _animationController;
  late AnimationController _bgAnimController;
  late AnimationController _staggerController;
  late AnimationController _glowController;

  final AdmissionService _admissionService = AdmissionService();

  List<Admission> _applications = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _isSearching = false;
  String _selectedFilter = 'ALL';

  // Stats
  int _totalApplications = 0;
  int _pendingApplications = 0;
  int _approvedApplications = 0;
  int _rejectedApplications = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _fetchApplications();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bgAnimController.dispose();
    _staggerController.dispose();
    _glowController.dispose();
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apps = await _admissionService.getApplications();
      setState(() {
        _applications = apps.map((json) => Admission.fromJson(json)).toList();
        _calculateStats();
        _isLoading = false;
      });
      _staggerController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applications: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    _totalApplications = _applications.length;
    _pendingApplications = _applications.where((a) => a.isPending).length;
    _approvedApplications = _applications.where((a) => a.isApproved).length;
    _rejectedApplications = _applications.where((a) => a.isRejected).length;
  }

  List<Admission> _getFilteredApplications() {
    return _applications.where((app) {
      // Status filter
      if (_selectedFilter == 'PENDING' && !app.isPending) return false;
      if (_selectedFilter == 'APPROVED' && !app.isApproved) return false;
      if (_selectedFilter == 'REJECTED' && !app.isRejected) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = app.fullName.toLowerCase();
        final email = app.email.toLowerCase();
        final department = app.department.toLowerCase();
        if (!name.contains(query) &&
            !email.contains(query) &&
            !department.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isProcessing = true);

    try {
      await _admissionService.updateApplicationStatus(id, status);
      await _fetchApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? '✅ Application approved successfully!'
                  : '❌ Application rejected',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final isStandaloneRoute =
        ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard;
    final filteredApps = _getFilteredApplications();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Admission Triage',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
                color: isDark ? Colors.white : const Color(0xFF4C1D95),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isStandaloneRoute
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF4C1D95),
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
          if (_applications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _ScaleIconButton(
                onTap: () => _showStatsDialog(isDark),
                icon: Icons.bar_chart_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
          IconButton(
            icon: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Icon(
                  Icons.refresh_rounded,
                  color: isDark
                      ? Colors.white.withOpacity(
                          0.7 + (_glowController.value * 0.3),
                        )
                      : const Color(
                          0xFF4C1D95,
                        ).withOpacity(0.7 + (_glowController.value * 0.3)),
                );
              },
            ),
            onPressed: _fetchApplications,
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
          if (isDark) ...[
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowController.value * 40),
                  right: -70 + (_glowController.value * 30),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withOpacity(0.12),
                          const Color(0xFF8B5CF6).withOpacity(0.02),
                          const Color(0xFF8B5CF6).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  bottom: -60 - (_glowController.value * 30),
                  left: -60 - (_glowController.value * 20),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purpleAccent.withOpacity(0.08),
                          Colors.purpleAccent.withOpacity(0.01),
                          Colors.purpleAccent.withOpacity(0),
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
                if (_applications.isNotEmpty) _buildStatsBar(isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildAnimatedSearchBar(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterChips(isDark),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : _errorMessage != null
                      ? _buildErrorState(isDark)
                      : _applications.isEmpty
                      ? _buildEmptyState(isDark)
                      : filteredApps.isEmpty
                      ? _buildNoResultsState(isDark)
                      : RefreshIndicator(
                          onRefresh: _fetchApplications,
                          color: const Color(0xFF8B5CF6),
                          backgroundColor: isDark
                              ? Colors.grey[900]
                              : Colors.white,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              return _buildAnimatedApplicationCard(
                                filteredApps[index],
                                index,
                                isDark,
                              );
                            },
                          ),
                        ),
                ),
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
              : const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '📋',
            '$_totalApplications',
            'Total',
            isDark,
            const Color(0xFF8B5CF6),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF8B5CF6).withOpacity(0.2),
          ),
          _buildStatItem(
            '⏳',
            '$_pendingApplications',
            'Pending',
            isDark,
            const Color(0xFFF59E0B),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF8B5CF6).withOpacity(0.2),
          ),
          _buildStatItem(
            '✅',
            '$_approvedApplications',
            'Approved',
            isDark,
            const Color(0xFF10B981),
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF8B5CF6).withOpacity(0.2),
          ),
          _buildStatItem(
            '❌',
            '$_rejectedApplications',
            'Rejected',
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
            color: isDark ? Colors.white : const Color(0xFF4C1D95),
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
                : const Color(0xFF4C1D95).withOpacity(0.6),
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
              : const Color(0xFF8B5CF6).withOpacity(_isSearching ? 0.5 : 0.2),
          width: _isSearching ? 2 : 1,
        ),
        boxShadow: _isSearching
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        onTap: () => setState(() => _isSearching = true),
        onSubmitted: (_) => setState(() => _isSearching = false),
        decoration: InputDecoration(
          hintText: '🔍 Search by name, email, or department...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : const Color(0xFF4C1D95).withOpacity(0.4),
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
                        : const Color(0xFF4C1D95).withOpacity(0.4),
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                    });
                  },
                )
              : null,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF4C1D95),
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];
    final filterColors = {
      'ALL': const Color(0xFF8B5CF6),
      'PENDING': const Color(0xFFF59E0B),
      'APPROVED': const Color(0xFF10B981),
      'REJECTED': const Color(0xFFEF4444),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          final color = filterColors[filter] ?? const Color(0xFF8B5CF6);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildFilterChip(filter, isSelected, color, isDark),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Color color,
    bool isDark,
  ) {
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
              : const Color(0xFF8B5CF6).withOpacity(0.2),
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
        onTap: () => setState(() => _selectedFilter = label),
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
                    : const Color(0xFF4C1D95),
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

  Widget _buildLoadingState(bool isDark) {
    return const SkeletonList(itemCount: 6);
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF4C1D95),
                fontSize: 18,
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
                    ? Colors.white60
                    : const Color(0xFF4C1D95).withOpacity(0.6),
                fontSize: 14,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchApplications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF8B5CF6).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 64,
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF4C1D95).withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Applications',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF4C1D95),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No admission applications found',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF4C1D95).withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF8B5CF6).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF4C1D95).withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF4C1D95),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF4C1D95).withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedFilter = 'ALL';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedApplicationCard(Admission app, int index, bool isDark) {
    final double start = (index * 0.06).clamp(0.0, 0.5);
    final double end = (start + 0.3).clamp(0.0, 1.0);

    final Animation<double> cardAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: cardAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: cardAnimation.value,
          child: Transform.translate(
            offset: Offset(30 * (1 - cardAnimation.value), 0),
            child: child,
          ),
        );
      },
      child: _PremiumApplicationCard(
        application: app,
        isDark: isDark,
        isProcessing: _isProcessing,
        onApprove: () => _updateStatus(app.id!, 'approved'),
        onReject: () => _updateStatus(app.id!, 'rejected'),
      ),
    );
  }

  void _showStatsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _PremiumStatsDialog(
        total: _totalApplications,
        pending: _pendingApplications,
        approved: _approvedApplications,
        rejected: _rejectedApplications,
        isDark: isDark,
      ),
    );
  }
}

// ── PREMIUM APPLICATION CARD ──────────────────────────────────────────────────
class _PremiumApplicationCard extends StatefulWidget {
  final Admission application;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PremiumApplicationCard({
    required this.application,
    required this.isDark,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PremiumApplicationCard> createState() =>
      _PremiumApplicationCardState();
}

class _PremiumApplicationCardState extends State<_PremiumApplicationCard>
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
    final app = widget.application;
    final isDark = widget.isDark;
    final statusColor = app.statusColor;
    final statusEmoji = app.statusEmoji;

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
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFF8B5CF6).withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF8B5CF6).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusEmoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                app.statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          app.createdAt != null
                              ? '${app.createdAt!.day}/${app.createdAt!.month}/${app.createdAt!.year}'
                              : '',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF4C1D95).withOpacity(0.4),
                            fontSize: 11,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      app.fullName,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF4C1D95),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.department,
                      style: TextStyle(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildDetailChip(
                          Icons.email_rounded,
                          app.email,
                          isDark,
                        ),
                        if (app.phone != null && app.phone!.isNotEmpty)
                          _buildDetailChip(
                            Icons.phone_rounded,
                            app.phone!,
                            isDark,
                          ),
                        if (app.fatherName != null &&
                            app.fatherName!.isNotEmpty)
                          _buildDetailChip(
                            Icons.family_restroom_rounded,
                            'Father: ${app.fatherName}',
                            isDark,
                          ),
                        if (app.motherName != null &&
                            app.motherName!.isNotEmpty)
                          _buildDetailChip(
                            Icons.family_restroom_rounded,
                            'Mother: ${app.motherName}',
                            isDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (app.isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.isProcessing
                                  ? null
                                  : widget.onApprove,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: widget.isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Approve',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.isProcessing
                                  ? null
                                  : widget.onReject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: widget.isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.close_rounded, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Reject',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (app.isApproved) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Application Approved ✓',
                              style: TextStyle(
                                color: const Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (app.isRejected) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Application Rejected ✗',
                              style: TextStyle(
                                color: const Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF8B5CF6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF8B5CF6).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? Colors.white54
                : const Color(0xFF4C1D95).withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label.length > 20 ? '${label.substring(0, 20)}...' : label,
            style: TextStyle(
              color: isDark
                  ? Colors.white60
                  : const Color(0xFF4C1D95).withOpacity(0.6),
              fontSize: 11,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

// ── PREMIUM STATS DIALOG ──────────────────────────────────────────────────
class _PremiumStatsDialog extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final bool isDark;

  const _PremiumStatsDialog({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
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
                : const Color(0xFF8B5CF6).withOpacity(0.3),
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
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Application Statistics',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF4C1D95),
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
                _buildStatCard('📋', '$total', 'Total', isDark),
                const SizedBox(width: 12),
                _buildStatCard('⏳', '$pending', 'Pending', isDark),
                const SizedBox(width: 12),
                _buildStatCard('✅', '$approved', 'Approved', isDark),
                const SizedBox(width: 12),
                _buildStatCard('❌', '$rejected', 'Rejected', isDark),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFF8B5CF6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Status Distribution',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF4C1D95).withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusIndicator(
                        'Pending',
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusIndicator(
                        'Approved',
                        const Color(0xFF10B981),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusIndicator(
                        'Rejected',
                        const Color(0xFFEF4444),
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
                  foregroundColor: const Color(0xFF8B5CF6),
                  backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
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
              : const Color(0xFF8B5CF6).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF4C1D95),
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
                    : const Color(0xFF4C1D95).withOpacity(0.6),
                fontSize: 10,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
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
                    : const Color(0xFF4C1D95).withOpacity(0.6),
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
