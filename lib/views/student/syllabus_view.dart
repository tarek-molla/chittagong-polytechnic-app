import 'dart:ui';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    super.dispose();
  }

  Future<void> _openSyllabus(SyllabusModel syllabus) async {
    if (syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty) {
      try {
        final url = Uri.parse(syllabus.fileUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showCustomToast(
            context,
            'Could not open file source link.',
            isError: true,
          );
        }
      } catch (e) {
        _showCustomToast(
          context,
          'Error launching resource: $e',
          isError: true,
        );
      }
    } else if (syllabus.content != null && syllabus.content!.isNotEmpty) {
      _showContentBottomSheet(syllabus);
    } else {
      _showCustomToast(
        context,
        'No syllabus content or files attached to this subject.',
        isError: true,
      );
    }
  }

  void _showCustomToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.redAccent.withOpacity(0.9)
            : const Color(0xFF7B61FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showContentBottomSheet(SyllabusModel syllabus) {
    final isDark = AppThemeController.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D1120).withOpacity(0.85)
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF00E5FF),
                        size: 22,
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
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          if (syllabus.subjectCode != null)
                            Text(
                              'Code: ${syllabus.subjectCode}',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                                fontFamily: 'Geist',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      syllabus.content ?? 'No content layout provided.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 15,
                        height: 1.6,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final String department = widget.user.department?.shortCode ?? 'CST';
    final int semester = widget.user.semester ?? 6;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Syllabus & Suggestions',
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
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.06),
                      const Color(0xFF00E5FF).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            child: StreamBuilder<List<SyllabusModel>>(
              stream: DatabaseService().getSyllabusStream(department, semester),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(isDark);
                }
                if (snapshot.hasError) {
                  return _buildErrorState(isDark, snapshot.error.toString());
                }
                final syllabusList = snapshot.data ?? [];
                if (syllabusList.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return _buildSyllabusList(isDark, syllabusList);
              },
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
            'Syncing dynamic portal content...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
              letterSpacing: 0.2,
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
              'Sync Stream Disrupted',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
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
              'No Suggestions Released',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Geist',
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your academic panel options haven\'t received live suggestions or text data files yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusList(bool isDark, List<SyllabusModel> list) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final syllabus = list[index];
        final hasFile =
            syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty;
        final hasContent =
            syllabus.content != null && syllabus.content!.isNotEmpty;

        return AnimatedContainer(
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.01),
                    ]
                  : [
                      Colors.black.withOpacity(0.02),
                      Colors.black.withOpacity(0.005),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.02),
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
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openSyllabus(syllabus),
                splashColor: const Color(0xFF7B61FF).withOpacity(0.1),
                highlightColor: const Color(0xFF00E5FF).withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFile
                              ? const Color(0xFF00E5FF).withOpacity(0.1)
                              : const Color(0xFF7B61FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasFile
                                ? const Color(0xFF00E5FF).withOpacity(0.25)
                                : const Color(0xFF7B61FF).withOpacity(0.25),
                          ),
                        ),
                        child: Icon(
                          hasFile
                              ? Icons.picture_as_pdf_rounded
                              : Icons.terminal_rounded,
                          color: hasFile
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF7B61FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (syllabus.subjectCode != null &&
                                    syllabus.subjectCode!.isNotEmpty)
                                  _buildTag(
                                    text: syllabus.subjectCode!,
                                    bgColor: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05),
                                    textColor: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                if (hasFile)
                                  _buildTag(
                                    text: 'RESOURCE LINK',
                                    bgColor: const Color(
                                      0xFF00E5FF,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF00E5FF),
                                  ),
                                if (hasContent && !hasFile)
                                  _buildTag(
                                    text: 'LIVE UPDATE',
                                    bgColor: const Color(
                                      0xFF7B61FF,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF9E8BFF),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark ? Colors.white24 : Colors.black26,
                        size: 14,
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
  }

  Widget _buildTag({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
