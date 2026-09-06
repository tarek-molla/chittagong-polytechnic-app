// =============================================================================
// lib/services/attendance_service.dart
// CPI Faculty Portal — Attendance Data Service
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class DailyAttendanceEntry {
  final int id;
  final String studentRoll;
  final String studentName;
  final String subjectCode;
  final String subjectName;
  final String className;
  final int semester;
  final String department;
  final String date;
  final String status; // 'Present' or 'Absent'
  final String? remarks;
  final String teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyAttendanceEntry({
    required this.id,
    required this.studentRoll,
    required this.studentName,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.semester,
    required this.department,
    required this.date,
    required this.status,
    this.remarks,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceEntry(
      id: json['id'] ?? 0,
      studentRoll: json['student_roll'] ?? '',
      studentName: json['student_name'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      className: json['class_name'] ?? '',
      semester: json['semester'] ?? 0,
      department: json['department'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Absent',
      remarks: json['remarks'],
      teacherName: json['teacher_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_roll': studentRoll,
      'student_name': studentName,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'class_name': className,
      'semester': semester,
      'department': department,
      'date': date,
      'status': status,
      'remarks': remarks,
      'teacher_name': teacherName,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  DailyAttendanceEntry copyWith({
    int? id,
    String? studentRoll,
    String? studentName,
    String? subjectCode,
    String? subjectName,
    String? className,
    int? semester,
    String? department,
    String? date,
    String? status,
    String? remarks,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyAttendanceEntry(
      id: id ?? this.id,
      studentRoll: studentRoll ?? this.studentRoll,
      studentName: studentName ?? this.studentName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      className: className ?? this.className,
      semester: semester ?? this.semester,
      department: department ?? this.department,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Student {
  final String roll;
  final String name;
  final String? email;

  Student({required this.roll, required this.name, this.email});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      roll: json['roll_number'] ?? json['roll'] ?? '',
      name: json['student_name'] ?? json['name'] ?? '',
      email: json['email'],
    );
  }
}

class AttendanceService {
  final SupabaseClient _supabase;

  AttendanceService(this._supabase);

  /// Get students for a class
  Future<List<Student>> getStudents(String className, int semester) async {
    try {
      print('📚 Fetching students for class: $className, semester: $semester');

      final response = await _supabase
          .from('students_login')
          .select()
          .eq('class_name', className)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      print('📊 Found ${response.length} students');

      if (response.isEmpty) {
        print('⚠️ No students found, using sample data');
        return _getSampleStudents();
      }

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching students: $e');
      return _getSampleStudents();
    }
  }

  List<Student> _getSampleStudents() {
    return [
      Student(roll: 'CMT-508401', name: 'Mohammed Akash'),
      Student(roll: 'CMT-508402', name: 'Nasrin Akter'),
      Student(roll: 'CMT-508403', name: 'Sumaiya Khan'),
      Student(roll: 'CMT-508412', name: 'Tarek Molla'),
      Student(roll: 'CMT-508415', name: 'Ahsan Habib'),
      Student(roll: 'CMT-508418', name: 'Farhana Yeasmin'),
    ];
  }

  /// Get daily attendance for a specific date and class
  Future<List<DailyAttendanceEntry>> getDailyAttendance(
    String className,
    int semester,
    String subjectCode,
    String date,
  ) async {
    try {
      final response = await _supabase
          .from('attendance_daily')
          .select()
          .eq('class_name', className)
          .eq('semester', semester)
          .eq('subject_code', subjectCode)
          .eq('date', date);

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => DailyAttendanceEntry.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get or create daily attendance for a specific date
  Future<List<DailyAttendanceEntry>> getOrCreateDailyAttendance(
    String className,
    int semester,
    String subjectCode,
    String subjectName,
    String department,
    String date,
    String teacherName,
  ) async {
    try {
      final existing = await getDailyAttendance(
        className,
        semester,
        subjectCode,
        date,
      );

      if (existing.isNotEmpty) {
        return existing;
      }

      final students = await getStudents(className, semester);

      if (students.isEmpty) {
        return [];
      }

      final entries = students.map((student) {
        return {
          'student_roll': student.roll,
          'student_name': student.name,
          'subject_code': subjectCode,
          'subject_name': subjectName,
          'class_name': className,
          'semester': semester,
          'department': department,
          'date': date,
          'status': 'Absent',
          'teacher_name': teacherName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      final response = await _supabase
          .from('attendance_daily')
          .insert(entries)
          .select();

      return (response as List)
          .map((json) => DailyAttendanceEntry.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update daily attendance status for a student
  Future<DailyAttendanceEntry?> updateDailyAttendanceStatus(
    int attendanceId,
    String status, {
    String? remarks,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (remarks != null) {
        updateData['remarks'] = remarks;
      }

      final response = await _supabase
          .from('attendance_daily')
          .update(updateData)
          .eq('id', attendanceId)
          .select();

      if (response.isNotEmpty) {
        return DailyAttendanceEntry.fromJson(response.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get daily attendance stream for real-time updates
  Stream<List<DailyAttendanceEntry>> getDailyAttendanceStream(
    String className,
    int semester,
    String subjectCode,
    String subjectName,
    String department,
    String date,
    String teacherName,
  ) async* {
    yield await getOrCreateDailyAttendance(
      className,
      semester,
      subjectCode,
      subjectName,
      department,
      date,
      teacherName,
    );

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await getDailyAttendance(
        className,
        semester,
        subjectCode,
        date,
      );
      if (updated.isNotEmpty) {
        yield updated;
      }
    }
  }

  /// Get attendance statistics for a class from daily logs
  Future<Map<String, dynamic>> getDailyAttendanceStats(
    String className,
    int semester,
    String subjectCode,
  ) async {
    try {
      final response = await _supabase
          .from('attendance_daily')
          .select()
          .eq('class_name', className)
          .eq('semester', semester)
          .eq('subject_code', subjectCode);

      if (response.isEmpty) {
        return {
          'totalStudents': 0,
          'presentCount': 0,
          'absentCount': 0,
          'attendanceRate': 0.0,
        };
      }

      final entries = (response as List)
          .map((json) => DailyAttendanceEntry.fromJson(json))
          .toList();

      final presentCount = entries.where((e) => e.status == 'Present').length;
      final absentCount = entries.where((e) => e.status == 'Absent').length;
      final total = presentCount + absentCount;
      final attendanceRate = total > 0 ? (presentCount / total) * 100 : 0.0;

      return {
        'totalStudents': total,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'attendanceRate': attendanceRate,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'presentCount': 0,
        'absentCount': 0,
        'attendanceRate': 0.0,
      };
    }
  }
}
