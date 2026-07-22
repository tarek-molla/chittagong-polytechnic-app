// =============================================================================
// lib/models/user.dart
// Multi-role user model for CPI multi-tenant application.
// Supports Student, Teacher, and Admin roles with relevant identity fields.
// =============================================================================

/// Enumerates the three role archetypes in the CPI system.
enum UserRole { student, teacher, admin }

/// Department codes recognised by Chittagong Polytechnic Institute.
enum Department {
  cst, // Computer Science & Technology
  et, // Electronics Technology
  civil, // Civil Technology
  power, // Power Technology
  rae, // Refrigeration & Air-conditioning
  auto, // Automobile Technology
  mech, // Mechanical Technology
  arch, // Architecture & Interior Design
}

extension DepartmentExtension on Department {
  static Department? fromString(String? departmentString) {
    if (departmentString == null) return null;
    try {
      return Department.values.firstWhere(
        (e) => e.toString().split('.').last == departmentString,
      );
    } catch (e) {
      return null; // Or throw an error, depending on desired behavior for invalid department strings
    }
  }
}

/// Human-readable label for each department enum value.
extension DepartmentLabel on Department {
  String get label {
    switch (this) {
      case Department.cst:
        return 'Computer Science & Technology';
      case Department.et:
        return 'Electronics Technology';
      case Department.civil:
        return 'Civil Technology';
      case Department.power:
        return 'Power Technology';
      case Department.rae:
        return 'Refrigeration & Air-conditioning';
      case Department.auto:
        return 'Automobile Technology';
      case Department.mech:
        return 'Mechanical Technology';
      case Department.arch:
        return 'Architecture & Interior Design';
    }
  }

  /// Short code used in form dropdowns and display chips.
  String get shortCode {
    switch (this) {
      case Department.cst:
        return 'CST';
      case Department.et:
        return 'ET';
      case Department.civil:
        return 'CIVIL';
      case Department.power:
        return 'POWER';
      case Department.rae:
        return 'RAE';
      case Department.auto:
        return 'AUTO';
      case Department.mech:
        return 'MECH';
      case Department.arch:
        return 'ARCH';
    }
  }
}

/// Human-readable label for each role enum value.
extension UserRoleLabel on UserRole {
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
}

/// Core user entity shared across the entire application.
///
/// [id]           – Unique user identifier (UUID or server-assigned string).
/// [name]         – Full display name.
/// [email]        – Institutional email address.
/// [role]         – One of [UserRole.student], [UserRole.teacher], [UserRole.admin].
/// [department]   – Academic department; null for admin role.
/// [rollNumber]   – Student roll number; null for teacher/admin.
/// [employeeId]   – Employee/staff ID; null for student role.
/// [semester]     – Current semester (1–8); meaningful for students only.
/// [avatarUrl]    – Optional remote avatar image URL.
/// [isActive]     – Account activation state; defaults to true.
/// [joinedAt]     – Timestamp of account creation (UTC).
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final Department? department;
  final String? rollNumber;
  final String? employeeId;
  final int? semester;
  final String? avatarUrl;
  final bool isActive;
  final DateTime joinedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.rollNumber,
    this.employeeId,
    this.semester,
    this.avatarUrl,
    this.isActive = true,
    required this.joinedAt,
  });

  // ---------------------------------------------------------------------------
  // Role-specific convenience getters
  // ---------------------------------------------------------------------------

  /// Returns true when this user is a student.
  bool get isStudent => role == UserRole.student;

  /// Returns true when this user is a teacher.
  bool get isTeacher => role == UserRole.teacher;

  /// Returns true when this user is an admin.
  bool get isAdmin => role == UserRole.admin;

  /// Returns the display identifier string appropriate for the role.
  ///
  /// Students see their roll number, teachers/admins see their employee ID,
  /// and if neither is set it falls back to the user [id].
  String get displayId {
    if (isStudent && rollNumber != null) return rollNumber!;
    if ((isTeacher || isAdmin) && employeeId != null) return employeeId!;
    return id;
  }

  // ---------------------------------------------------------------------------
  // Serialisation helpers
  // ---------------------------------------------------------------------------

  /// Constructs an [AppUser] from a raw JSON [map] (e.g., from a REST API).
  factory AppUser.fromJson(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      department: DepartmentExtension.fromString(map['department'] as String?),
      rollNumber: map['rollNumber'] as String?,
      employeeId: map['employeeId'] as String?,
      semester: map['semester'] as int?,
      avatarUrl: map['avatarUrl'] as String?,
      isActive: map['isActive'] as bool,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'department': department?.name,
      'rollNumber': rollNumber,
      'employeeId': employeeId,
      'semester': semester,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  /// Serialises this [AppUser] to a JSON-compatible [Map].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department?.name,
      'rollNumber': rollNumber,
      'employeeId': employeeId,
      'semester': semester,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  /// Returns a new [AppUser] with optionally overridden fields.
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    Department? department,
    String? rollNumber,
    String? employeeId,
    int? semester,
    String? avatarUrl,
    bool? isActive,
    DateTime? joinedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      employeeId: employeeId ?? this.employeeId,
      semester: semester ?? this.semester,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() =>
      'AppUser(id: $id, name: $name, role: ${role.label}, dept: ${department?.shortCode})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
