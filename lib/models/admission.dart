import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/admission_service.dart';

class AdmissionTriageView extends StatefulWidget {
  final AppUser user;

  const AdmissionTriageView({super.key, required this.user});

  @override
  State<AdmissionTriageView> createState() => _AdmissionTriageViewState();
}

class _AdmissionTriageViewState extends State<AdmissionTriageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AdmissionService _admissionService = AdmissionService();

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _fetchApplications();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applications: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Admission Applications',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
            ),
            onPressed: _fetchApplications,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isDark)
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
                      const Color(0xFF8B5CF6).withOpacity(0.08),
                      const Color(0xFF8B5CF6).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: _isLoading
                ? _buildLoadingState(isDark)
                : _errorMessage != null
                ? _buildErrorState(isDark)
                : _applications.isEmpty
                ? _buildEmptyState(isDark)
                : _buildApplicationList(isDark),
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
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading applications...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark
                  ? Colors.red.withOpacity(0.6)
                  : Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
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
              ),
              child: const Text('Retry'),
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
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No Applications',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
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
                  : Colors.black.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        return _buildApplicationCard(app, isDark);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app, bool isDark) {
    final status = app['status'] ?? 'pending';
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
        ),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]
              : [
                  Colors.black.withOpacity(0.03),
                  Colors.black.withOpacity(0.01),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Status
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
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      app['created_at'] != null
                          ? app['created_at'].toString().substring(0, 10)
                          : '',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Name
                Text(
                  app['full_name'] ?? 'Unknown',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),

                // Department
                Text(
                  app['department'] ?? 'No Department',
                  style: TextStyle(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),

                // Details
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildDetailChip(
                      Icons.email_rounded,
                      app['email'] ?? '',
                      isDark,
                    ),
                    _buildDetailChip(
                      Icons.phone_rounded,
                      app['phone'] ?? '',
                      isDark,
                    ),
                    _buildDetailChip(
                      Icons.family_restroom_rounded,
                      app['father_name'] ?? '',
                      isDark,
                    ),
                    _buildDetailChip(
                      Icons.calendar_today_rounded,
                      app['dob']?.toString() ?? '',
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons (if pending)
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(app['id'] as String, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(app['id'] as String, 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'approved') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application Approved',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (status == 'rejected') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application Rejected',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
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
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label.length > 20 ? '${label.substring(0, 20)}...' : label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isLoading = true);

    try {
      await _admissionService.updateApplicationStatus(id, status);
      await _fetchApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Application ${status == 'approved' ? 'approved' : 'rejected'}!',
            ),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
