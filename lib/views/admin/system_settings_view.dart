// =============================================================================
// lib/views/admin/system_settings_view.dart
// System Settings View for CPI Admin Panel
// Manages system-wide configuration and settings
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cpi_app/core/theme_provider.dart';
import 'package:cpi_app/core/router.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/widgets/animated_background_painter.dart';

class SystemSettingsView extends StatefulWidget {
  final AppUser user;

  const SystemSettingsView({super.key, required this.user});

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;

  // System Settings State
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _academicAlerts = true;
  bool _eventReminders = false;
  bool _isEmergencyMode = false;
  bool _isMaintenanceMode = false;
  bool _isAutoBackup = true;

  // Data
  bool _isLoading = true;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    AppThemeController.themeModeNotifier.addListener(_themeListener);
    _loadSettings();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppThemeController.themeModeNotifier.removeListener(_themeListener);
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // Load settings from Supabase or local storage
      // For now, use defaults
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // 1. SYSTEM SETTINGS (Emergency, Maintenance, Backup)
  // ===========================================================================

  void _showSystemSettingsDialog() {
    final isDark = AppThemeController.isDarkMode;

    _isEmergencyMode = false;
    _isMaintenanceMode = false;
    _isAutoBackup = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'System Settings',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSettingToggle(
                      isDark,
                      'Emergency Mode',
                      'Broadcast alerts to all users',
                      _isEmergencyMode,
                      (value) {
                        setDialogState(() {
                          _isEmergencyMode = value;
                        });
                      },
                      Icons.warning_amber_rounded,
                      Colors.red,
                    ),
                    const SizedBox(height: 16),

                    _buildSettingToggle(
                      isDark,
                      'Maintenance Mode',
                      'Restrict access during maintenance',
                      _isMaintenanceMode,
                      (value) {
                        setDialogState(() {
                          _isMaintenanceMode = value;
                        });
                      },
                      Icons.build_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),

                    _buildSettingToggle(
                      isDark,
                      'Auto Backup',
                      'Automatically backup data daily',
                      _isAutoBackup,
                      (value) {
                        setDialogState(() {
                          _isAutoBackup = value;
                        });
                      },
                      Icons.backup_rounded,
                      Colors.blue,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveSystemSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SAVE SETTINGS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
      },
    );
  }

  Widget _buildSettingToggle(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: color),
      ],
    );
  }

  void _saveSystemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ System settings saved!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ===========================================================================
  // 2. NOTIFICATION SETTINGS
  // ===========================================================================

  void _showNotificationSettingsDialog() {
    final isDark = AppThemeController.isDarkMode;

    _pushNotifications = true;
    _emailNotifications = true;
    _academicAlerts = true;
    _eventReminders = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notification Settings',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildNotificationToggle(
                      isDark,
                      'Push Notifications',
                      'Receive alerts and updates',
                      _pushNotifications,
                      (value) {
                        setDialogState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildNotificationToggle(
                      isDark,
                      'Email Notifications',
                      'Receive email updates',
                      _emailNotifications,
                      (value) {
                        setDialogState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildNotificationToggle(
                      isDark,
                      'Academic Alerts',
                      'Exam schedules, results, etc.',
                      _academicAlerts,
                      (value) {
                        setDialogState(() {
                          _academicAlerts = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildNotificationToggle(
                      isDark,
                      'Event Reminders',
                      'Workshops, seminars, etc.',
                      _eventReminders,
                      (value) {
                        setDialogState(() {
                          _eventReminders = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveNotificationSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SAVE SETTINGS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
      },
    );
  }

  Widget _buildNotificationToggle(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  void _saveNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Notification settings saved!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ===========================================================================
  // 3. QUICK ACTIONS
  // ===========================================================================

  void _showBroadcastDialog() {
    final isDark = AppThemeController.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Broadcast Announcement',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.24)
                            : Colors.black.withValues(alpha: 0.24),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.24)
                            : Colors.black.withValues(alpha: 0.24),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📢 Announcement broadcasted!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BROADCAST',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
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

  // ===========================================================================
  // 4. UI BUILD
  // ===========================================================================

  List<Map<String, dynamic>> get _settingsMenuItems => [
    {
      'icon': Icons.settings_rounded,
      'title': 'System Settings',
      'subtitle': 'Emergency, maintenance, backup',
      'onTap': _showSystemSettingsDialog,
    },
    {
      'icon': Icons.notifications_rounded,
      'title': 'Notification Preferences',
      'subtitle': 'Manage alert settings',
      'onTap': _showNotificationSettingsDialog,
    },
    {
      'icon': Icons.campaign_rounded,
      'title': 'Broadcast Announcement',
      'subtitle': 'Send system-wide message',
      'onTap': _showBroadcastDialog,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    const fallbackLightBackground = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : fallbackLightBackground,
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
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: -120 + (_glowAnimationController.value * 30),
                  right: -100 + (_glowAnimationController.value * 20),
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          const Color(0xFF7B61FF).withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        if (ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: isDark ? Colors.white : const Color(0xFF070B19),
                                size: 18,
                              ),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        Expanded(
                          child: Text(
                            "System Settings",
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF070B19),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Geist',
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 40 * (1.0 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildSystemStatusCard(isDark),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _settingsMenuItems[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        duration: Duration(milliseconds: 600 + (index * 80)),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1.0 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildSettingsMenuItem(
                                icon: item['icon'],
                                title: item['title'],
                                subtitle: item['subtitle'],
                                isDark: isDark,
                                onTap: item['onTap'],
                              ),
                            ),
                          );
                        },
                      );
                    }, childCount: _settingsMenuItems.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.01)]
              : [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.005),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar / Icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "System Administration",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF070B19),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Geist',
                    letterSpacing: -0.3,
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
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "CPI Admin Panel • CST Department",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem("Version", "2.4.0", isDark),
                      _buildVerticalDivider(isDark),
                      _buildInfoItem("Environment", "Production", isDark),
                      _buildVerticalDivider(isDark),
                      _buildInfoItem("Status", "Active", isDark),
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

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            highlightColor: const Color(0xFFD97706).withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white.withValues(alpha: 0.6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF070B19),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.2),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
