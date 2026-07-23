// lib/models/user.dart

import 'department.dart';
import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? teacherId;
  final String? rollNumber;
  final String? designation;
  final Department? department;
  final int? semester;
  final UserRole role;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.teacherId,
    this.rollNumber,
    this.designation,
    this.department,
    this.semester,
    required this.role,
  });

  // Factory for Student
  factory AppUser.fromStudentJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['student_name'] ?? '',
      email: json['email'] ?? '',
      rollNumber: json['roll_number'] ?? '',
      department: json['department'] != null
          ? Department.fromShortCode(json['department'])
          : null,
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? ''),
      role: UserRole.student,
    );
  }

  // Factory for Teacher
  factory AppUser.fromTeacherJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      designation: json['designation'] ?? 'Faculty',
      department: json['department'] != null
          ? Department.fromShortCode(json['department'])
          : null,
      role: UserRole.teacher,
    );
  }

  // Factory for Admin
  factory AppUser.fromAdminJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] != null
          ? Department.fromShortCode(json['department'])
          : null,
      role: UserRole.admin,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? teacherId,
    String? rollNumber,
    String? designation,
    Department? department,
    int? semester,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      teacherId: teacherId ?? this.teacherId,
      rollNumber: rollNumber ?? this.rollNumber,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      role: role ?? this.role,
    );
  }

  String get displayId => teacherId ?? rollNumber ?? id;
}
