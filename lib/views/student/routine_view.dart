import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/routine_service.dart';

class RoutineView extends StatefulWidget {
  final AppUser user;
  const RoutineView({super.key, required this.user});

  @override
  State<RoutineView> createState() => _RoutineViewState();
}

class _RoutineViewState extends State<RoutineView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _glowPulseController;
  late Animation<double> _glowAnimation;

  late RoutineService _routineService;
  StreamSubscription<List<RoutineEntry>>? _routineSubscription;

  int _selectedDay = DateTime.now().weekday; // 1 for Monday, 7 for Sunday
  bool _isLoading = true;
  String? _errorMessage;
  List<RoutineEntry> _allRoutineEntries = [];
  List<RoutineEntry> _displayedRoutineEntries = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    _routineService = RoutineService(SupabaseService.client);
    _listenToRoutineUpdates();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowPulseController.dispose();
    _routineSubscription?.cancel();
    super.dispose();
  }

  void _listenToRoutineUpdates() {
    final department = widget.user.department?.shortCode ?? 'CST';
    final semester = widget.user.semester ?? 6;

    print(
      '📚 Listening to routine updates for $department - Semester $semester',
    );

    _routineSubscription?.cancel();

    _routineSubscription = _routineService
        .getRoutineStream(department, semester)
        .listen(
          (routineEntries) {
            if (!mounted) return;
            print('📊 Received ${routineEntries.length} routine entries');
            setState(() {
              _allRoutineEntries = routineEntries;
              _updateDisplayedRoutine();
              _isLoading = false;
              _errorMessage = null;
            });
          },
          onError: (error) {
            if (!mounted) return;
            print('❌ Routine stream error: $error');
            setState(() {
              _errorMessage = 'Failed to load routine: ${error.toString()}';
              _isLoading = false;
            });
          },
        );
  }

  void _updateDisplayedRoutine() {
    _displayedRoutineEntries =
        _allRoutineEntries.where((entry) => entry.day == _selectedDay).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    print(
      '📅 Displaying ${_displayedRoutineEntries.length} classes for day ${_routineService.getDayName(_selectedDay)}',
    );
  }

  String _getFormattedDayName(int day) {
    return _routineService.getDayName(day);
  }

  List<RoutineEntry> _getClassesForSelectedDay() {
    return _displayedRoutineEntries;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final dayClasses = _getClassesForSelectedDay();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : AppColors.lightBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AnimatedBackgroundPainter(
                animation: const AlwaysStoppedAnimation(0.5),
                isLightMode: !isDark,
              ),
            ),
          ),
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      const Color(0xFF00E5FF).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightPrimaryText,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            AnimatedBuilder(
                              animation: _glowPulseController,
                              builder: (context, child) {
                                final double glowIntensity =
                                    _glowAnimation.value;
                                return Text(
                                  "Class Routine",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Geist',
                                    letterSpacing: -0.5,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightPrimaryText,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF00E5FF)
                                            .withValues(
                                              alpha: 0.3 * glowIntensity,
                                            ),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Text(
                                "${widget.user.department?.shortCode ?? 'CST'} • Sem ${widget.user.semester ?? 6}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.black.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.name,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontFamily: 'Geist',
                          ),
                        ),
                        if (_allRoutineEntries.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "${_allRoutineEntries.length} classes total",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.2),
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Loading routine...",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppColors.lightCaptionText,
                                fontSize: 14,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_errorMessage != null && !_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: isDark
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.red.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppColors.lightCaptionText,
                                fontSize: 14,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF7B61FF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });
                                  _listenToRoutineUpdates();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Retry",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_isLoading && _errorMessage == null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: _buildDaySelector(isDark),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (dayClasses.isEmpty) {
                            return _buildEmptyState(isDark);
                          }
                          final classItem = dayClasses[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 350 + (index * 150),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: _buildClassCard(classItem, isDark, index),
                            ),
                          );
                        },
                        childCount: dayClasses.isEmpty ? 1 : dayClasses.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(8),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.free_breakfast_rounded,
            size: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          Text(
            "No classes on this day",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppColors.lightCaptionText.withValues(alpha: 0.5),
              fontSize: 16,
              fontFamily: 'Geist',
            ),
          ),
          Text(
            "Enjoy your day off! 🎉",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppColors.lightCaptionText.withValues(alpha: 0.4),
              fontSize: 13,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : AppColors.lightCardBorderAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final day = index + 1; // 1 for Monday, 7 for Sunday
          final isSelected = _selectedDay == day;
          final isToday = day == DateTime.now().weekday;
          final hasClasses = _allRoutineEntries.any((item) => item.day == day);

          return Expanded(
            child: InkWell(
              onTap: hasClasses
                  ? () {
                      setState(() {
                        _selectedDay = day;
                        _updateDisplayedRoutine();
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF1E293B)
                            : AppColors.lightBackground)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  border: isToday && !isSelected && hasClasses
                      ? Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _routineService.getDayName(day),
                      style: TextStyle(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF00E5FF)
                                  : AppColors.lightPrimaryText)
                            : (hasClasses
                                  ? (isDark
                                        ? Colors.white54
                                        : AppColors.lightSubtitleText)
                                  : (isDark
                                        ? Colors.white24
                                        : AppColors.lightCaptionText.withValues(
                                            alpha: 0.3,
                                          ))),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    if (isToday && isSelected && hasClasses)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClassCard(RoutineEntry classItem, bool isDark, int index) {
    Color accentColor;
    try {
      final colorStr = classItem.color;
      final hex = colorStr.replaceAll('#', '');
      accentColor = Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      accentColor = const Color(0xFF00E5FF);
    }

    final String type = classItem.type;

    Color getTypeColor(String type) {
      switch (type) {
        case 'Theory':
          return const Color(0xFF3B82F6);
        case 'Practical':
          return const Color(0xFF10B981);
        case 'Lab':
          return const Color(0xFFF59E0B);
        default:
          return const Color(0xFF8B5CF6);
      }
    }

    String formatTime(String time) {
      try {
        if (time.isEmpty) return '';
        final parts = time.split(':');
        if (parts.length < 2) return time;
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      } catch (e) {
        return time;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(6)
                  : Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(8),
              ),
              boxShadow: !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatTime(classItem.startTime),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Text(
                        formatTime(classItem.endTime),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppColors.lightCaptionText.withValues(
                                  alpha: 0.5,
                                ),
                          fontSize: 10,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.1),
                        accentColor,
                        accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              classItem.subjectName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightPrimaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: getTypeColor(type).withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: getTypeColor(type).withAlpha(30),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: getTypeColor(type),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.lightCaptionText.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              classItem.teacherName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppColors.lightCaptionText,
                                fontSize: 12,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.room_outlined,
                            size: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.lightCaptionText.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            classItem.room,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppColors.lightCaptionText,
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentColor.withAlpha(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 10,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFormattedDayName(classItem.day),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
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
  }
}
