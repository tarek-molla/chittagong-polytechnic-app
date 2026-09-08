// =============================================================================
// lib/services/admin_service.dart
// Centralized Admin Service for CPI Admin Panel
// Handles all admin operations: Dashboard stats, User management, Activity feed
// =============================================================================

import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // ===========================================================================
  // DASHBOARD STATS
  // ===========================================================================

  /// Get real-time dashboard statistics for a department
  Future<Map<String, dynamic>> getDashboardStats(String department) async {
    try {
      final client = _supabase;

      // Total Students
      final studentsResponse = await client
          .from('students_login')
          .select('id')
          .eq('department', department)
          .eq('is_active', true);

      // Active Faculty
      final facultyResponse = await client
          .from('teachers_login')
          .select('id')
          .eq('department', department)
          .eq('is_active', true);

      // Pending Admissions
      final admissionsResponse = await client
          .from('applications')
          .select('id')
          .eq('department', department)
          .eq('status', 'pending');

      // Live Classrooms (current day/time)
      final now = DateTime.now();
      final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      final currentDay = dayNames[now.weekday - 1];
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final liveClassesResponse = await client
          .from('routine')
          .select('id')
          .eq('department', department)
          .eq('day', currentDay)
          .eq('is_active', true)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime);

      return {
        'totalStudents': studentsResponse.length,
        'activeFaculty': facultyResponse.length,
        'pendingAdmissions': admissionsResponse.length,
        'liveClassrooms': liveClassesResponse.length,
      };
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      return {
        'totalStudents': 0,
        'activeFaculty': 0,
        'pendingAdmissions': 0,
        'liveClassrooms': 0,
      };
    }
  }

  /// Stream of dashboard stats for real-time updates
  Stream<Map<String, dynamic>> getDashboardStatsStream(
    String department,
  ) async* {
    // Initial fetch
    yield await getDashboardStats(department);

    // Listen for changes using periodic refresh
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      final updated = await getDashboardStats(department);
      yield updated;
    }
  }

  // ===========================================================================
  // DEPARTMENT STATS
  // ===========================================================================

  /// Get student count per department
  Future<Map<String, int>> getDepartmentStats() async {
    try {
      final client = _supabase;
      final departments = ['CST', 'CIVIL', 'EE', 'ME', 'ECT'];
      final stats = <String, int>{};

      for (final dept in departments) {
        final response = await client
            .from('students_login')
            .select('id')
            .eq('department', dept)
            .eq('is_active', true);
        stats[dept] = response.length;
      }

      return stats;
    } catch (e) {
      print('❌ Error fetching department stats: $e');
      return {};
    }
  }

  /// Stream of department stats
  Stream<Map<String, int>> getDepartmentStatsStream() async* {
    yield await getDepartmentStats();
    await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
      yield await getDepartmentStats();
    }
  }

  // ===========================================================================
  // USER MANAGEMENT
  // ===========================================================================

  /// Toggle user active status
  Future<bool> toggleUserStatus(String table, String id, bool isActive) async {
    try {
      await _supabase
          .from(table)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error toggling user status: $e');
      return false;
    }
  }

  /// Delete user (soft delete)
  Future<bool> deleteUser(String table, String id) async {
    try {
      await _supabase
          .from(table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  /// Get all students for a department
  Stream<List<Map<String, dynamic>>> getStudentsStream(
    String department,
  ) async* {
    try {
      final response = await _supabase
          .from('students_login')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching students: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('students_login')
            .select()
            .eq('department', department)
            .eq('is_active', true)
            .order('roll_number', ascending: true);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing students: $e');
      }
    }
  }

  /// Get all teachers for a department
  Stream<List<Map<String, dynamic>>> getTeachersStream(
    String department,
  ) async* {
    try {
      final response = await _supabase
          .from('teachers_login')
          .select()
          .eq('department', department)
          .order('name', ascending: true);

      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching teachers: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('teachers_login')
            .select()
            .eq('department', department)
            .order('name', ascending: true);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing teachers: $e');
      }
    }
  }

  /// Create a new teacher
  Future<Map<String, dynamic>?> createTeacher(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('teachers_login')
          .insert({
            'teacher_id': data['teacher_id'],
            'name': data['name'],
            'email': data['email'],
            'department': data['department'],
            'phone': data['phone'],
            'password': data['password'] ?? 'teacher123',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error creating teacher: $e');
      return null;
    }
  }

  /// Update a teacher
  Future<Map<String, dynamic>?> updateTeacher(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('teachers_login')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating teacher: $e');
      return null;
    }
  }

  /// Create a new student
  Future<Map<String, dynamic>?> createStudent(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('students_login')
          .insert({
            'roll_number': data['roll_number'],
            'student_name': data['student_name'],
            'department': data['department'],
            'semester': data['semester'],
            'email': data['email'],
            'password': data['password'] ?? 'student123',
            'phone': data['phone'],
            'address': data['address'],
            'guardian_name': data['guardian_name'],
            'guardian_phone': data['guardian_phone'],
            'admission_year': data['admission_year'],
            'is_active': true,
            'role': 'student',
            'class_name': data['class_name'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error creating student: $e');
      return null;
    }
  }

  /// Update a student
  Future<Map<String, dynamic>?> updateStudent(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('students_login')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating student: $e');
      return null;
    }
  }

  // ===========================================================================
  // ACTIVITY FEED
  // ===========================================================================

  /// Get recent activity across all tables
  Stream<List<Map<String, dynamic>>> getRecentActivity() async* {
    try {
      final client = _supabase;

      // Fetch recent activities from multiple tables
      final activities = <Map<String, dynamic>>[];

      // Recent admissions
      final admissions = await client
          .from('admissions')
          .select('id, full_name, department, status, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      for (var a in admissions) {
        activities.add({
          'type': 'admission',
          'title': 'New Admission: ${a['full_name']}',
          'subtitle': '${a['department']} • ${a['status']}',
          'time': a['created_at'],
          'color': 0xFF8B5CF6,
        });
      }

      // Recent notices
      final notices = await client
          .from('notices')
          .select('id, title, priority, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      for (var n in notices) {
        activities.add({
          'type': 'notice',
          'title': 'Notice: ${n['title']}',
          'subtitle': 'Priority: ${n['priority']}',
          'time': n['created_at'],
          'color': 0xFFF59E0B,
        });
      }

      // Recent routine changes
      final routines = await client
          .from('routine')
          .select('id, subject_name, teacher_name, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      for (var r in routines) {
        activities.add({
          'type': 'routine',
          'title': 'Routine: ${r['subject_name']}',
          'subtitle': 'Teacher: ${r['teacher_name']}',
          'time': r['created_at'],
          'color': 0xFF2563EB,
        });
      }

      // Sort by time
      activities.sort(
        (a, b) =>
            DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])),
      );

      yield activities.take(20).toList();
    } catch (e) {
      print('❌ Error fetching activity: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final client = _supabase;
        final activities = <Map<String, dynamic>>[];

        final admissions = await client
            .from('admissions')
            .select('id, full_name, department, status, created_at')
            .order('created_at', ascending: false)
            .limit(10);

        for (var a in admissions) {
          activities.add({
            'type': 'admission',
            'title': 'New Admission: ${a['full_name']}',
            'subtitle': '${a['department']} • ${a['status']}',
            'time': a['created_at'],
            'color': const Color(0xFF8B5CF6).value,
          });
        }

        final notices = await client
            .from('notices')
            .select('id, title, priority, created_at')
            .order('created_at', ascending: false)
            .limit(10);

        for (var n in notices) {
          activities.add({
            'type': 'notice',
            'title': 'Notice: ${n['title']}',
            'subtitle': 'Priority: ${n['priority']}',
            'time': n['created_at'],
            'color': const Color(0xFFF59E0B).value,
          });
        }

        final routines = await client
            .from('routine')
            .select('id, subject_name, teacher_name, created_at')
            .order('created_at', ascending: false)
            .limit(10);

        for (var r in routines) {
          activities.add({
            'type': 'routine',
            'title': 'Routine: ${r['subject_name']}',
            'subtitle': 'Teacher: ${r['teacher_name']}',
            'time': r['created_at'],
            'color': const Color(0xFF2563EB).value,
          });
        }

        activities.sort(
          (a, b) =>
              DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])),
        );
        yield activities.take(20).toList();
      } catch (e) {
        print('❌ Error refreshing activity: $e');
      }
    }
  }

  // ===========================================================================
  // SYSTEM SETTINGS
  // ===========================================================================

  /// Load system settings from Supabase
  Future<Map<String, dynamic>> loadSystemSettings() async {
    try {
      final client = _supabase;

      // Try to load from system_settings table first
      try {
        final response = await client.from('system_settings').select().single();
        return Map<String, dynamic>.from(response);
      } catch (e) {
        // If table doesn't exist, return default settings
        print('System settings table not found, using defaults: $e');
        return {
          'isEmergencyModeActive': false,
          'isSystemMaintenanceMode': false,
          'isNotificationsEnabled': true,
          'isAutoBackupEnabled': true,
          'selectedDepartment': 'CST',
        };
      }
    } catch (e) {
      print('❌ Error loading system settings: $e');
      return {
        'isEmergencyModeActive': false,
        'isSystemMaintenanceMode': false,
        'isNotificationsEnabled': true,
        'isAutoBackupEnabled': true,
        'selectedDepartment': 'CST',
      };
    }
  }

  /// Update system setting in Supabase
  Future<bool> updateSystemSetting(String key, dynamic value) async {
    try {
      final client = _supabase;

      // Try to update in system_settings table
      try {
        await client
            .from('system_settings')
            .update({key: value})
            .eq('id', 'default');
        return true;
      } catch (e) {
        // If table doesn't exist, just simulate the update
        print('System settings table not found, simulating update: $e');
        return true;
      }
    } catch (e) {
      print('❌ Error updating system setting: $e');
      return false;
    }
  }

  // ===========================================================================
  // ROLL NUMBER GENERATION
  // ===========================================================================

  /// Auto-generate roll number: YYYYDEPT####
  String generateRollNumber(String department, int admissionYear) {
    final year = admissionYear.toString().substring(2); // Last 2 digits
    final deptCode = department.toUpperCase().substring(0, 3);
    final random = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return '$year$deptCode$random';
  }

  // ===========================================================================
  // ROUTINE MANAGEMENT
  // ===========================================================================

  /// Get routine stream for a department
  Stream<List<Map<String, dynamic>>> getRoutineStream(
    String department,
  ) async* {
    try {
      final response = await _supabase
          .from('routine')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching routine: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('routine')
            .select()
            .eq('department', department)
            .eq('is_active', true)
            .order('day', ascending: true)
            .order('start_time', ascending: true);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing routine: $e');
      }
    }
  }

  /// Create routine entry
  Future<Map<String, dynamic>?> createRoutine(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('routine')
          .insert({
            'department': data['department'],
            'semester': data['semester'],
            'day': data['day'],
            'subject_name': data['subject_name'],
            'teacher_name': data['teacher_name'],
            'room': data['room'],
            'start_time': data['start_time'],
            'end_time': data['end_time'],
            'type': data['type'] ?? 'Theory',
            'color': data['color'] ?? '#3B82F6',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error creating routine: $e');
      return null;
    }
  }

  /// Update routine entry
  Future<Map<String, dynamic>?> updateRoutine(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('routine')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating routine: $e');
      return null;
    }
  }

  /// Delete routine entry (soft delete)
  Future<bool> deleteRoutine(String id) async {
    try {
      await _supabase
          .from('routine')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting routine: $e');
      return false;
    }
  }

  // ===========================================================================
  // NOTICE MANAGEMENT
  // ===========================================================================

  /// Get notices stream
  Stream<List<Map<String, dynamic>>> getNoticesStream() async* {
    try {
      final response = await _supabase
          .from('notices')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching notices: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('notices')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing notices: $e');
      }
    }
  }

  /// Create notice
  Future<Map<String, dynamic>?> createNotice(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('notices')
          .insert({
            'title': data['title'],
            'content': data['content'],
            'priority': data['priority'] ?? 'normal',
            'category': data['category'] ?? 'GENERAL',
            'department': data['department'],
            'action_url': data['action_url'],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error creating notice: $e');
      return null;
    }
  }

  /// Update notice
  Future<Map<String, dynamic>?> updateNotice(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('notices')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating notice: $e');
      return null;
    }
  }

  /// Delete notice (soft delete)
  Future<bool> deleteNotice(String id) async {
    try {
      await _supabase
          .from('notices')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting notice: $e');
      return false;
    }
  }

  // ===========================================================================
  // RESULTS MANAGEMENT
  // ===========================================================================

  /// Get results stream
  Stream<List<Map<String, dynamic>>> getResultsStream(
    String department,
  ) async* {
    try {
      final response = await _supabase
          .from('results')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching results: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('results')
            .select()
            .eq('department', department)
            .eq('is_active', true)
            .order('created_at', ascending: false);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing results: $e');
      }
    }
  }

  /// Create result
  Future<Map<String, dynamic>?> createResult(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('results')
          .insert({
            'roll_number': data['roll_number'],
            'student_name': data['student_name'],
            'semester': data['semester'],
            'subject_code': data['subject_code'],
            'subject_name': data['subject_name'],
            'grade': data['grade'],
            'grade_point': data['grade_point'],
            'total_marks': data['total_marks'],
            'obtained_marks': data['obtained_marks'],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error creating result: $e');
      return null;
    }
  }

  /// Update result
  Future<Map<String, dynamic>?> updateResult(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('results')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating result: $e');
      return null;
    }
  }

  /// Delete result (soft delete)
  Future<bool> deleteResult(String id) async {
    try {
      await _supabase
          .from('results')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting result: $e');
      return false;
    }
  }
}
