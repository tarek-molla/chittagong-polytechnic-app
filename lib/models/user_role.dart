// lib/models/user_role.dart

enum UserRole {
  student,
  teacher,
  admin,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get loginRoute {
    switch (this) {
      case UserRole.student:
        return '/student/dashboard';
      case UserRole.teacher:
        return '/teacher/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
    }
  }
}
