// =============================================================================
// lib/core/router.dart
// Centralised route registry for the CPI multi-tenant application.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/student/student_dashboard.dart';
import '../views/student/attendance_detail_view.dart';
import '../views/student/results_ledger_view.dart';
import '../views/student/routine_view.dart';
import '../views/welcome/welcome_view.dart';
import '../views/teacher/teacher_dashboard.dart';
import '../views/teacher/attendance_logger_view.dart';
import '../views/teacher/marks_uploader_view.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/admin/admission_triage_view.dart';
import '../views/admin/routine_scheduler_view.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String signup = '/signup';
  static const String studentDashboard = '/student/dashboard';
  static const String attendanceDetail = '/student/attendance';
  static const String resultsLedger = '/student/results';
  static const String routine = '/student/routine';
  static const String welcome = '/welcome';

  static const String teacherDashboard = '/teacher/dashboard';
  static const String attendanceLogger = '/teacher/attendance-logger';
  static const String marksUploader = '/teacher/marks-uploader';
  static const String adminDashboard = '/admin/dashboard';
  static const String admissionTriage = '/admin/admissions';
  static const String routineScheduler = '/admin/routine';
}

class StudentRouteArgs {
  final AppUser user;
  StudentRouteArgs({required this.user});
}

class TeacherRouteArgs {
  final AppUser user;
  const TeacherRouteArgs({required this.user});
}

class AdminRouteArgs {
  final AppUser user;
  const AdminRouteArgs({required this.user});
}

class AttendanceLoggerArgs {
  final AppUser teacher;
  final String subjectCode;
  final String className;
  final int semester;

  const AttendanceLoggerArgs({
    required this.teacher,
    required this.subjectCode,
    required this.className,
    required this.semester,
  });
}

class MarksUploaderArgs {
  final AppUser teacher;
  final String subjectCode;
  final String subjectName;
  final int semester;

  const MarksUploaderArgs({
    required this.teacher,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
  });
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _fadeRoute(
          settings: settings,
          builder: (_) => const LoginView(),
        );

      case AppRoutes.signup:
        return _slideRoute(
          settings: settings,
          builder: (_) => const SignupView(),
        );

      case AppRoutes.welcome:
        return _fadeRoute(
          settings: settings,
          builder: (_) => const WelcomeView(),
        );

      case AppRoutes.studentDashboard:
        final args = _requireArgs<StudentRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => StudentDashboard(user: args.user),
        );

      case AppRoutes.attendanceDetail:
        final args = _requireArgs<StudentRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => AttendanceDetailView(user: args.user),
        );

      case AppRoutes.resultsLedger:
        final args = _requireArgs<StudentRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => ResultsLedgerView(user: args.user),
        );

      case AppRoutes.routine:
        final args = _requireArgs<StudentRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => RoutineView(user: args.user),
        );

      case AppRoutes.teacherDashboard:
        final args = _requireArgs<TeacherRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => TeacherDashboard(user: args.user),
        );

      case AppRoutes.attendanceLogger:
        final args = _requireArgs<AttendanceLoggerArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => AttendanceLoggerView(
            teacher: args.teacher,
            subjectCode: args.subjectCode,
            className: args.className,
            semester: args.semester,
          ),
        );

      case AppRoutes.marksUploader:
        final args = _requireArgs<MarksUploaderArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => MarksUploaderView(
            teacher: args.teacher,
            subjectCode: args.subjectCode,
            subjectName: args.subjectName,
            semester: args.semester,
          ),
        );

      case AppRoutes.adminDashboard:
        final args = _requireArgs<AdminRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => AdminDashboard(user: args.user),
        );

      case AppRoutes.admissionTriage:
        final args = _requireArgs<AdminRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => AdmissionTriageView(user: args.user),
        );

      case AppRoutes.routineScheduler:
        final args = _requireArgs<AdminRouteArgs>(settings);
        return _slideRoute(
          settings: settings,
          builder: (_) => RoutineSchedulerView(user: args.user),
        );

      default:
        return _fadeRoute(
          settings: settings,
          builder: (_) => _NotFoundPage(routeName: settings.name ?? 'unknown'),
        );
    }
  }

  static T _requireArgs<T>(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! T) {
      throw ArgumentError(
        'Route "${settings.name}" expects arguments of type $T, but received ${args.runtimeType}.',
      );
    }
    return args;
  }

  static PageRoute<T> _fadeRoute<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static PageRoute<T> _slideRoute<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.06);
        const end = Offset.zero;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 420),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final String routeName;
  const _NotFoundPage({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(height: 24),
            Text(
              'No route defined for "$routeName"',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
