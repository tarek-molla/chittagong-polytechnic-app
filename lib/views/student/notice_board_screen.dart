import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../components/notice_card.dart';
import '../components/admin_input_sheet.dart';
import '../../core/theme_provider.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    super.dispose();
  }

  bool _isAdminOrTeacher() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final role = user.userMetadata?['role']?.toString().toLowerCase();
      return role == 'admin' || role == 'teacher';
    } catch (e) {
      debugPrint('❌ Error checking role verification context: $e');
      return false;
    }
  }

  void _showAdminInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const AdminInputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _isAdminOrTeacher();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, child) {
        final isDark = AppThemeController.isDarkMode;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF070B19)
              : Colors.grey.shade50,
          body: Stack(
            children: [
              // Ambient Neon Decorative Backdrops (only in dark mode)
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
              // Light mode soft decorative backdrops
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

              // Primary Content Layout
              SafeArea(
                child: StreamBuilder<List<NoticeModel>>(
                  stream: DatabaseService().getNoticesStream(),
                  builder: (context, snapshot) {
                    return NestedScrollView(
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF070B19),
                              size: 20,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            background: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'CAMPUS NOTICE BOARD',
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
                                    'REALTIME DIGITAL FEED SYSTEM',
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
                      body: _buildBodyContent(context, snapshot, isDark),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: showFab
              ? AnimatedBuilder(
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
                            blurRadius:
                                16 + (_glowAnimationController.value * 8),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton.extended(
                        onPressed: () => _showAdminInputSheet(context),
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: const Color(0xFF070B19),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: const Icon(Icons.add_comment_rounded, size: 20),
                        label: const Text(
                          'BROADCAST',
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
                )
              : null,
        );
      },
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    AsyncSnapshot<List<NoticeModel>> snapshot,
    bool isDark,
  ) {
    if (snapshot.hasError) {
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
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black54,
                    fontSize: 13,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
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
              'Synchronizing Feed...',
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

    final notices = snapshot.data ?? [];

    if (notices.isEmpty) {
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
                'No Updates Broadcasted Yet',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything is quiet right now.',
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
              return AnimatedContainer(
                duration: Duration(milliseconds: 450 + (index * 40)),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 2),
                child: NoticeCard(notice: notices[index]),
              );
            }, childCount: notices.length),
          ),
        ),
      ],
    );
  }
}
