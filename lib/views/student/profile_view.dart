import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../widgets/animated_background_painter.dart';
import '../../services/supabase_service.dart';

class ProfileView extends StatefulWidget {
  final AppUser user;
  const ProfileView({super.key, required this.user});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;

  // Controllers for Edit Profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianPhoneController =
      TextEditingController();

  // Controllers for Change Password
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _academicAlerts = true;
  bool _eventReminders = false;

  // Data
  double _realCGPA = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  // ✅ Store data to update UI
  String _currentName = '';
  String _currentEmail = '';
  String _currentPhone = '';
  String _currentAddress = '';
  String _currentGuardianName = '';
  String _currentGuardianPhone = '';

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _loadUserData();
    _fetchCGPA();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOAD USER DATA
  // ===========================================================================

  void _loadUserData() {
    _currentName = widget.user.name;
    _currentEmail = widget.user.email;
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
  }

  // ===========================================================================
  // FETCH PROFILE DATA FROM SUPABASE
  // ===========================================================================

  Future<void> _fetchProfileData() async {
    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) return;

      final response = await SupabaseService.client
          .from('students_login')
          .select()
          .eq('roll_number', rollNumber)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response[0];
        setState(() {
          _currentPhone = data['phone'] ?? '';
          _currentAddress = data['address'] ?? '';
          _currentGuardianName = data['guardian_name'] ?? '';
          _currentGuardianPhone = data['guardian_phone'] ?? '';

          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _guardianNameController.text = data['guardian_name'] ?? '';
          _guardianPhoneController.text = data['guardian_phone'] ?? '';
        });
      }
    } catch (e) {
      print('❌ Error fetching profile data: $e');
    }
  }

  // ===========================================================================
  // FETCH CGPA
  // ===========================================================================

  Future<void> _fetchCGPA() async {
    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) return;

      final resultsData = await SupabaseService.instance.fetchStudentResults(
        rollNumber,
      );

      if (resultsData.isNotEmpty) {
        final Map<String, List<Map<String, dynamic>>> semesterGroups = {};
        for (var result in resultsData) {
          final semester = result['semester']?.toString() ?? 'Unknown';
          if (!semesterGroups.containsKey(semester)) {
            semesterGroups[semester] = [];
          }
          semesterGroups[semester]!.add(result);
        }

        double totalGpa = 0.0;
        int semesterCount = 0;

        for (var semester in semesterGroups.keys) {
          final subjects = semesterGroups[semester]!;
          double semesterTotalGp = 0.0;
          int semesterTotalCredits = 0;

          for (var subject in subjects) {
            final gp = (subject['grade_point'] as num?)?.toDouble() ?? 0.0;
            final credits = subject['credits'] as int? ?? 3;
            semesterTotalGp += gp * credits;
            semesterTotalCredits += credits;
          }

          if (semesterTotalCredits > 0) {
            final semesterGpa = semesterTotalGp / semesterTotalCredits;
            totalGpa += semesterGpa;
            semesterCount++;
          }
        }

        _realCGPA = semesterCount > 0 ? totalGpa / semesterCount : 0.0;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching CGPA: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===========================================================================
  // 1. EDIT PROFILE
  // ===========================================================================

  void _showEditProfileDialog() {
    final isDark = AppThemeController.isDarkMode;

    // ✅ Reset controllers with current data
    _nameController.text = _currentName;
    _emailController.text = _currentEmail;
    _phoneController.text = _currentPhone;
    _addressController.text = _currentAddress;
    _guardianNameController.text = _currentGuardianName;
    _guardianPhoneController.text = _currentGuardianPhone;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile',
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

                  // Name
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guardian Name
                  TextFormField(
                    controller: _guardianNameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Guardian Name',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guardian Phone
                  TextFormField(
                    controller: _guardianPhoneController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Guardian Phone',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isSaving)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SAVE CHANGES',
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
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final rollNumber = widget.user.rollNumber ?? '';
    if (rollNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No roll number found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Check if anything changed
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newAddress = _addressController.text.trim();
    final newGuardianName = _guardianNameController.text.trim();
    final newGuardianPhone = _guardianPhoneController.text.trim();

    if (newName == _currentName &&
        newEmail == _currentEmail &&
        newPhone == _currentPhone &&
        newAddress == _currentAddress &&
        newGuardianName == _currentGuardianName &&
        newGuardianPhone == _currentGuardianPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {};

      if (newName != _currentName) {
        updateData['student_name'] = newName;
      }

      if (newEmail != _currentEmail) {
        updateData['email'] = newEmail;
      }

      if (newPhone != _currentPhone) {
        updateData['phone'] = newPhone;
      }

      if (newAddress != _currentAddress) {
        updateData['address'] = newAddress;
      }

      if (newGuardianName != _currentGuardianName) {
        updateData['guardian_name'] = newGuardianName;
      }

      if (newGuardianPhone != _currentGuardianPhone) {
        updateData['guardian_phone'] = newGuardianPhone;
      }

      print('📝 Updating profile with: $updateData');

      if (updateData.isNotEmpty) {
        await SupabaseService.client
            .from('students_login')
            .update(updateData)
            .eq('roll_number', rollNumber);
      }

      // ✅ UPDATE LOCAL STATE
      setState(() {
        _currentName = newName;
        _currentEmail = newEmail;
        _currentPhone = newPhone;
        _currentAddress = newAddress;
        _currentGuardianName = newGuardianName;
        _currentGuardianPhone = newGuardianPhone;
        _isSaving = false;
      });

      // ✅ UPDATE THE USER OBJECT IN THE PARENT (through callback)
      // This updates the dashboard/user object if you pass it back

      // Close dialog
      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      print('❌ Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ===========================================================================
  // 2. CHANGE PASSWORD
  // ===========================================================================

  void _showChangePasswordDialog() {
    final isDark = AppThemeController.isDarkMode;

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Password',
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

                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.24)
                              : Colors.black.withOpacity(0.24),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isSaving)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'UPDATE PASSWORD',
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
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Password must be at least 6 characters!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rollNumber = widget.user.rollNumber ?? '';
    if (rollNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No roll number found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final verifyResponse = await SupabaseService.client
          .from('students_login')
          .select('password')
          .eq('roll_number', rollNumber)
          .eq('password', _currentPasswordController.text.trim())
          .limit(1);

      if (verifyResponse.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Current password is incorrect!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await SupabaseService.client
          .from('students_login')
          .update({'password': _newPasswordController.text.trim()})
          .eq('roll_number', rollNumber);

      setState(() => _isSaving = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Password updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() => _isSaving = false);
      print('❌ Error updating password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to update password: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ===========================================================================
  // 3. NOTIFICATION SETTINGS
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
                          backgroundColor: const Color(0xFF00E5FF),
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
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00E5FF),
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
  // 4. SIGN OUT
  // ===========================================================================

  void _signOut() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = AppThemeController.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontFamily: 'Geist',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: const Color(0xFF00E5FF),
                  fontFamily: 'Geist',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // UI BUILD
  // ===========================================================================

  List<Map<String, dynamic>> get _profileMenuItems => [
    {
      'icon': Icons.person_outline_rounded,
      'title': 'Edit Profile',
      'subtitle': 'Update your personal information',
      'onTap': _showEditProfileDialog,
    },
    {
      'icon': Icons.lock_outline_rounded,
      'title': 'Change Password',
      'subtitle': 'Update your account security',
      'onTap': _showChangePasswordDialog,
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Notification Settings',
      'subtitle': 'Manage alert preferences',
      'onTap': _showNotificationSettingsDialog,
    },
    {
      'icon': Icons.logout_rounded,
      'title': 'Sign Out',
      'subtitle': 'Logout from your account',
      'onTap': _signOut,
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
                          const Color(0xFF00E5FF).withOpacity(0.12),
                          const Color(0xFF7B61FF).withOpacity(0.02),
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
                    child: Text(
                      "My Profile",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF070B19),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Geist',
                        letterSpacing: -0.5,
                      ),
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
                            child: _buildProfileCard(isDark),
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
                      final item = _profileMenuItems[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        duration: Duration(milliseconds: 600 + (index * 80)),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1.0 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildProfileMenuItem(
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
                    }, childCount: _profileMenuItems.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final displayName = _currentName.isNotEmpty ? _currentName : 'Student';
    final deptShortCode = widget.user.department?.shortCode ?? 'CST';
    final rollNumber = widget.user.rollNumber ?? 'N/A';
    final cgpa = _isLoading ? '...' : _realCGPA.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          width: 1.2,
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Updated Name (uses _currentName)
                Text(
                  displayName,
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
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$deptShortCode • Roll: $rollNumber",
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
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.04),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        "Semester",
                        "${widget.user.semester ?? 6}th",
                        isDark,
                      ),
                      _buildVerticalDivider(isDark),
                      _buildInfoItem("Department", deptShortCode, isDark),
                      _buildVerticalDivider(isDark),
                      _buildInfoItem("CGPA", cgpa, isDark),
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
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.08),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
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

  Widget _buildProfileMenuItem({
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
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF00E5FF).withOpacity(0.1),
            highlightColor: const Color(0xFF7B61FF).withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : Colors.white.withOpacity(0.6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.15),
                      ),
                    ),
                    child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
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
                                ? Colors.white.withOpacity(0.5)
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
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.2),
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
