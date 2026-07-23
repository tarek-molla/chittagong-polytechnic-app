// =============================================================================
// lib/views/auth/login_view.dart
// Multi-role entry gateway for the CPI application.
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../models/department.dart';
import '../../core/router.dart';
import '../../services/supabase_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------

  UserRole _selectedRole = UserRole.student;
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _accentAnimController;
  late Animation<Color?> _accentColorAnim;

  // --------------------------------------------------------------------------
  // Role colour theme map
  // --------------------------------------------------------------------------

  static const Map<UserRole, _RoleTheme> _roleThemes = {
    UserRole.student: _RoleTheme(
      primaryColor: Color(0xFF3B82F6),
      gradientEnd: Color(0xFF1D4ED8),
      label: 'Student',
      icon: Icons.school_rounded,
      rollHint: 'Enter your roll number',
      passwordHint: 'Enter your portal password',
    ),
    UserRole.teacher: _RoleTheme(
      primaryColor: Color(0xFF10B981),
      gradientEnd: Color(0xFF047857),
      label: 'Teacher',
      icon: Icons.person_4_rounded,
      rollHint: 'Enter your employee ID',
      passwordHint: 'Enter your staff password',
    ),
    UserRole.admin: _RoleTheme(
      primaryColor: Color(0xFFF59E0B),
      gradientEnd: Color(0xFFB45309),
      label: 'Admin',
      icon: Icons.admin_panel_settings_rounded,
      rollHint: 'Enter your admin ID',
      passwordHint: 'Enter your admin password',
    ),
  };

  _RoleTheme get _currentTheme => _roleThemes[_selectedRole]!;

  @override
  void initState() {
    super.initState();
    _accentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _accentColorAnim = AlwaysStoppedAnimation<Color?>(
      _currentTheme.primaryColor,
    );
  }

  @override
  void dispose() {
    _accentAnimController.dispose();
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(UserRole newRole) {
    if (newRole == _selectedRole) return;

    final Color fromColor = _currentTheme.primaryColor;
    setState(() {
      _selectedRole = newRole;
      _errorMessage = null;
      _rollController.clear();
      _passwordController.clear();
    });
    final Color toColor = _currentTheme.primaryColor;

    _accentColorAnim = ColorTween(begin: fromColor, end: toColor).animate(
      CurvedAnimation(parent: _accentAnimController, curve: Curves.easeInOut),
    );

    _accentAnimController.forward(from: 0);
  }

  String? _validateRollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Roll number is required';
    }
    if (value.trim().length < 6) {
      return 'Enter a valid roll number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // Login Methods
  // --------------------------------------------------------------------------

  Future<void> _attemptLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final id = _rollController.text.trim();
      final password = _passwordController.text.trim();

      print('🔍 Attempting login with ID: $id, Role: ${_selectedRole.label}');

      Map<String, dynamic>? userData;
      AppUser user;

      switch (_selectedRole) {
        case UserRole.student:
          userData = await SupabaseService.instance.authenticateStudent(
            id,
            password,
          );
          if (userData != null) {
            user = _buildStudentFromData(userData, id);
          } else {
            setState(() {
              _errorMessage =
                  'Invalid roll number or password. Please try again.';
              _isLoading = false;
            });
            return;
          }
          break;

        case UserRole.teacher:
          userData = await SupabaseService.instance.authenticateTeacher(
            id,
            password,
          );
          if (userData != null) {
            user = _buildTeacherFromData(userData, id);
          } else {
            setState(() {
              _errorMessage =
                  'Invalid Teacher ID or password. Please try again.';
              _isLoading = false;
            });
            return;
          }
          break;

        case UserRole.admin:
          userData = await SupabaseService.instance.authenticateAdmin(
            id,
            password,
          );
          if (userData != null) {
            user = _buildAdminFromData(userData, id);
          } else {
            setState(() {
              _errorMessage = 'Invalid Admin ID or password. Please try again.';
              _isLoading = false;
            });
            return;
          }
          break;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToDashboard(user);
      }
    } catch (e) {
      print('❌ Login error: $e');
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  AppUser _buildStudentFromData(
    Map<String, dynamic> studentData,
    String rollNumber,
  ) {
    // Parse department
    Department department = Department.cst;
    final deptStr = studentData['department']?.toString() ?? '';
    if (deptStr.isNotEmpty) {
      try {
        department = Department.values.firstWhere(
          (d) =>
              d.name.toLowerCase() == deptStr.toLowerCase() ||
              d.shortCode.toLowerCase() == deptStr.toLowerCase(),
          orElse: () => Department.cst,
        );
      } catch (_) {
        department = Department.cst;
      }
    }

    return AppUser(
      id: studentData['id']?.toString() ?? 'std-$rollNumber',
      name: studentData['student_name']?.toString() ?? 'Student',
      email: studentData['email']?.toString() ?? '$rollNumber@cpi.edu.bd',
      role: UserRole.student,
      department: department,
      rollNumber: rollNumber,
      semester: studentData['semester'] as int? ?? 4,
    );
  }

  AppUser _buildTeacherFromData(
    Map<String, dynamic> teacherData,
    String employeeId,
  ) {
    // Parse department if available
    Department? department;
    final deptStr = teacherData['department']?.toString() ?? '';
    if (deptStr.isNotEmpty) {
      try {
        department = Department.values.firstWhere(
          (d) =>
              d.name.toLowerCase() == deptStr.toLowerCase() ||
              d.shortCode.toLowerCase() == deptStr.toLowerCase(),
        );
      } catch (_) {}
    }

    return AppUser(
      id: teacherData['id']?.toString() ?? 'tch-$employeeId',
      name: teacherData['name']?.toString() ?? 'Teacher',
      email: teacherData['email']?.toString() ?? '',
      role: UserRole.teacher,
      department: department,
      teacherId: employeeId,
    );
  }

  AppUser _buildAdminFromData(Map<String, dynamic> adminData, String adminId) {
    return AppUser(
      id: adminData['id']?.toString() ?? 'adm-$adminId',
      name: adminData['full_name']?.toString() ?? 'Admin',
      email: adminData['email']?.toString() ?? '',
      role: UserRole.admin,
      teacherId: adminId,
    );
  }

  void _navigateToDashboard(AppUser user) {
    switch (user.role) {
      case UserRole.student:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.studentDashboard,
          arguments: StudentRouteArgs(user: user),
        );
      case UserRole.teacher:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.teacherDashboard,
          arguments: TeacherRouteArgs(user: user),
        );
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminDashboard,
          arguments: AdminRouteArgs(user: user),
        );
    }
  }

  void _goToWelcome() {
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            const Positioned.fill(child: _LoginMeshBackground()),

            // ✅ Removed back button - using gesture instead
            SafeArea(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  // ✅ Swipe right to go back to Welcome
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 300) {
                    _goToWelcome();
                  }
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 52),
                          _buildHeader(),
                          const SizedBox(height: 36),
                          _buildRoleSelector(),
                          const SizedBox(height: 32),
                          _buildFormCard(),
                          const Spacer(),
                          _buildFooterSignupLink(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _accentAnimController,
          builder: (context, child) {
            final Color accentColor =
                (_accentColorAnim.value ?? _currentTheme.primaryColor);
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.12),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(_currentTheme.icon, size: 32, color: accentColor),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'CPI Portal',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chittagong Polytechnic Institute',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return AnimatedBuilder(
      animation: _accentAnimController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: UserRole.values.map((role) {
              final theme = _roleThemes[role]!;
              final bool isSelected = _selectedRole == role;
              final Color accent =
                  _accentColorAnim.value ?? _currentTheme.primaryColor;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchRole(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: isSelected
                          ? Border.all(color: accent.withOpacity(0.5), width: 1)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          theme.icon,
                          size: 16,
                          color: isSelected ? accent : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          theme.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? accent
                                : const Color(0xFF64748B),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFormCard() {
    return AnimatedBuilder(
      animation: _accentAnimController,
      builder: (context, child) {
        final Color accentColor =
            _accentColorAnim.value ?? _currentTheme.primaryColor;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in as ${_currentTheme.label}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your institutional credentials below',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildInputField(
                      controller: _rollController,
                      label: 'Roll Number',
                      hint: _currentTheme.rollHint,
                      icon: Icons.badge_rounded,
                      accentColor: accentColor,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: _validateRollNumber,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: _currentTheme.passwordHint,
                      icon: Icons.lock_outline_rounded,
                      accentColor: accentColor,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onSubmitted: (_) => _attemptLogin(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    _LoginButton(
                      isLoading: _isLoading,
                      accentColor: accentColor,
                      gradientEnd: _currentTheme.gradientEnd,
                      onPressed: _attemptLogin,
                    ),

                    // ✅ Removed Quick Demo Login button
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13.5,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, size: 19, color: const Color(0xFF475569)),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "New applicant? ",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.signup);
          },
          child: AnimatedBuilder(
            animation: _accentAnimController,
            builder: (context, child) {
              final Color accent =
                  _accentColorAnim.value ?? _currentTheme.primaryColor;
              return Text(
                'Apply for admission',
                style: TextStyle(
                  color: accent,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: accent.withOpacity(0.6),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone sub-widgets
// ---------------------------------------------------------------------------

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final Color accentColor;
  final Color gradientEnd;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.isLoading,
    required this.accentColor,
    required this.gradientEnd,
    required this.onPressed,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          if (!widget.isLoading) widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.38),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginMeshBackground extends StatefulWidget {
  const _LoginMeshBackground();

  @override
  State<_LoginMeshBackground> createState() => _LoginMeshBackgroundState();
}

class _LoginMeshBackgroundState extends State<_LoginMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) =>
            CustomPaint(painter: _LoginMeshPainter(t: _controller.value)),
      ),
    );
  }
}

class _LoginMeshPainter extends CustomPainter {
  final double t;
  _LoginMeshPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Using radial gradients for soft edges instead of MaskFilter.blur
    final angle = t * 2 * math.pi;

    final rect = Offset.zero & size;

    // Draw first gradient
    final paint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.4),
              const Color(0xFF1E3A8A).withOpacity(0.0),
            ],
            stops: const [0.0, 0.7],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.2 + math.sin(angle) * 80,
                size.height * 0.3 + math.cos(angle) * 120,
              ),
              radius: 200,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.sin(angle) * 80,
        size.height * 0.3 + math.cos(angle) * 120,
      ),
      200,
      paint1,
    );

    // Draw second gradient
    final paint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF065F46).withOpacity(0.3),
              const Color(0xFF065F46).withOpacity(0.0),
            ],
            stops: const [0.0, 0.7],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.8 + math.cos(angle + 1.8) * 100,
                size.height * 0.55 + math.sin(angle + 1.0) * 90,
              ),
              radius: 180,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.cos(angle + 1.8) * 100,
        size.height * 0.55 + math.sin(angle + 1.0) * 90,
      ),
      180,
      paint2,
    );

    // Draw third gradient
    final paint3 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF78350F).withOpacity(0.25),
              const Color(0xFF78350F).withOpacity(0.0),
            ],
            stops: const [0.0, 0.7],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.5 + math.sin(angle + 3.5) * 110,
                size.height * 0.8 + math.cos(angle + 2.2) * 80,
              ),
              radius: 160,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + math.sin(angle + 3.5) * 110,
        size.height * 0.8 + math.cos(angle + 2.2) * 80,
      ),
      160,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginMeshPainter old) => old.t != t;
}

class _RoleTheme {
  final Color primaryColor;
  final Color gradientEnd;
  final String label;
  final IconData icon;
  final String rollHint;
  final String passwordHint;

  const _RoleTheme({
    required this.primaryColor,
    required this.gradientEnd,
    required this.label,
    required this.icon,
    required this.rollHint,
    required this.passwordHint,
  });
}
