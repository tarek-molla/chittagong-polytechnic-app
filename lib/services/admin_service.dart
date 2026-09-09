// =============================================================================
// lib/services/admin_service.dart
// Centralized Admin Service for CPI Admin Panel
// Handles all admin operations: Dashboard stats, User management, Activity feed,
// with robust offline caching and offline sync queueing.
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_storage_service.dart';

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // ===========================================================================
  // DASHBOARD STATS
  // ===========================================================================

  /// Get real-time dashboard statistics for a department with offline caching
  Future<Map<String, dynamic>> getDashboardStats(String department) async {
    final cacheKey = '${OfflineStorageService.keyDashboardStats}_$department';
    final cached = OfflineStorageService.getCachedData(cacheKey);
    Map<String, dynamic> defaultStats = {
      'totalStudents': 0,
      'activeFaculty': 0,
      'pendingAdmissions': 0,
      'liveClassrooms': 0,
    };

    if (cached != null && cached is Map) {
      defaultStats = Map<String, dynamic>.from(cached);
    }

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

      final stats = {
        'totalStudents': studentsResponse.length,
        'activeFaculty': facultyResponse.length,
        'pendingAdmissions': admissionsResponse.length,
        'liveClassrooms': liveClassesResponse.length,
      };

      await OfflineStorageService.cacheData(cacheKey, stats);
      return stats;
    } catch (e) {
      debugPrint('⚠️ Error fetching dashboard stats (returning cached): $e');
      return defaultStats;
    }
  }

  /// Stream of dashboard stats for real-time updates
  Stream<Map<String, dynamic>> getDashboardStatsStream(
    String department,
  ) async* {
    yield await getDashboardStats(department);

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      final updated = await getDashboardStats(department);
      yield updated;
    }
  }

  // ===========================================================================
  // DEPARTMENT STATS
  // ===========================================================================

  /// Get student count per department with offline caching
  Future<Map<String, int>> getDepartmentStats() async {
    const cacheKey = '${OfflineStorageService.keyDashboardStats}_departments';
    final cached = OfflineStorageService.getCachedData(cacheKey);
    Map<String, int> defaultStats = {};

    if (cached != null && cached is Map) {
      defaultStats = Map<String, int>.from(cached);
    }

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

      await OfflineStorageService.cacheData(cacheKey, stats);
      return stats;
    } catch (e) {
      debugPrint('⚠️ Error fetching department stats (returning cached): $e');
      return defaultStats;
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
      await _supabase.from(table).update({'is_active': isActive}).eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error toggling user status: $e');
      return false;
    }
  }

  /// Delete user (hard delete)
  Future<bool> deleteUser(String table, String id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  /// Get all students for a department with instant offline cache fallback
  Stream<List<Map<String, dynamic>>> getStudentsStream(
    String department,
  ) async* {
    final cacheKey = '${OfflineStorageService.keyStudents}_$department';
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('students_login')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(cacheKey, list);
      yield list;
    } catch (e) {
      debugPrint('⚠️ Error fetching students: $e');
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('students_login')
            .select()
            .eq('department', department)
            .eq('is_active', true)
            .order('roll_number', ascending: true);
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(cacheKey, list);
        yield list;
      } catch (e) {
        debugPrint('⚠️ Error refreshing students: $e');
      }
    }
  }

  /// Get all teachers for a department with instant offline cache fallback
  Stream<List<Map<String, dynamic>>> getTeachersStream(
    String department,
  ) async* {
    final cacheKey = '${OfflineStorageService.keyTeachers}_$department';
    final controller = StreamController<List<Map<String, dynamic>>>();
    DateTime lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

    // Immediately yield cached teachers if available
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      controller.add(cached.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }

    Future<void> emitFresh() async {
      try {
        final response = await _supabase
            .from('teachers_login')
            .select()
            .eq('department', department)
            .order('name', ascending: true);
        lastFetch = DateTime.now();
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(cacheKey, list);
        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching teachers: $e');
      }
    }

    // Initial fetch
    await emitFresh();

    // Realtime subscription (instant updates on INSERT/UPDATE/DELETE)
    final channel = _supabase.channel('teachers:$department');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'teachers_login',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: department,
          ),
          callback: (payload) async {
            await emitFresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'teachers_login',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: department,
          ),
          callback: (payload) async {
            await emitFresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'teachers_login',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: department,
          ),
          callback: (payload) async {
            await emitFresh();
          },
        );
    channel.subscribe();

    // Polling fallback in case realtime is unavailable
    final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (DateTime.now().difference(lastFetch) >= const Duration(seconds: 28)) {
        await emitFresh();
      }
    });

    yield* controller.stream;

    timer.cancel();
    channel.unsubscribe();
    await _supabase.removeChannel(channel);
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
      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('updated_at');
      updateData.remove('created_at');

      final response = await _supabase
          .from('teachers_login')
          .update(updateData)
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
      // ✅ FIX: semester column is int, form dialog returns String
      final semester = int.tryParse(data['semester']?.toString() ?? '1') ?? 1;
      final admissionYear =
          int.tryParse(
            data['admission_year']?.toString() ??
                DateTime.now().year.toString(),
          ) ??
          DateTime.now().year;

      final response = await _supabase
          .from('students_login')
          .insert({
            'roll_number': data['roll_number'],
            'student_name': data['student_name'],
            'department': data['department'],
            'semester': semester,
            'email': data['email'],
            'password': data['password'] ?? 'student123',
            'phone': data['phone'] ?? '',
            'address': data['address'] ?? '',
            'guardian_name': data['guardian_name'] ?? '',
            'guardian_phone': data['guardian_phone'] ?? '',
            'admission_year': admissionYear,
            'is_active': true,
            'role': 'student',
            'class_name': data['class_name'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
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
      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('updated_at');
      updateData.remove('created_at');
      updateData.remove('id');
      updateData.remove('roll_number');

      // ✅ FIX: semester column is int, form dialog returns String
      if (updateData.containsKey('semester')) {
        updateData['semester'] =
            int.tryParse(updateData['semester'].toString()) ?? 1;
      }

      // ✅ FIX: admission_year column is int
      if (updateData.containsKey('admission_year')) {
        updateData['admission_year'] =
            int.tryParse(updateData['admission_year'].toString()) ?? 2024;
      }

      final response = await _supabase
          .from('students_login')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ Error updating student: $e');
      return null;
    }
  }

  /// Get recent activity across all tables with instant offline cache fallback
  Stream<List<Map<String, dynamic>>> getRecentActivity() async* {
    const cacheKey = OfflineStorageService.keyActivities;
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final client = _supabase;
      final activities = <Map<String, dynamic>>[];

      // Recent applications
      final admissions = await client
          .from('applications')
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

      activities.sort(
        (a, b) =>
            DateTime.parse(b['time'].toString()).compareTo(DateTime.parse(a['time'].toString())),
      );

      final result = activities.take(20).toList();
      await OfflineStorageService.cacheData(cacheKey, result);
      yield result;
    } catch (e) {
      debugPrint('⚠️ Error fetching activity: $e');
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final client = _supabase;
        final activities = <Map<String, dynamic>>[];

        final admissions = await client
            .from('applications')
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
              DateTime.parse(b['time'].toString()).compareTo(DateTime.parse(a['time'].toString())),
        );
        final result = activities.take(20).toList();
        await OfflineStorageService.cacheData(cacheKey, result);
        yield result;
      } catch (e) {
        debugPrint('⚠️ Error refreshing activity: $e');
      }
    }
  }

  // ===========================================================================
  // ROLL NUMBER GENERATION
  // ===========================================================================

  /// Auto-generate roll number: YYYYDEPT####
  String generateRollNumber(String department, int admissionYear) {
    final year = admissionYear.toString().substring(2);
    final deptCode = department.toUpperCase().substring(0, 3);
    final random = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return '$year$deptCode$random';
  }

  // ===========================================================================
  // ROUTINE MANAGEMENT
  // ===========================================================================

  /// Get routine stream for a department with instant offline cache fallback
  Stream<List<Map<String, dynamic>>> getRoutineStream(
    String department,
  ) async* {
    final cacheKey = '${OfflineStorageService.keyRoutine}_$department';
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('routine')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(cacheKey, list);
      yield list;
    } catch (e) {
      debugPrint('⚠️ Error fetching routine: $e');
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
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(cacheKey, list);
        yield list;
      } catch (e) {
        debugPrint('⚠️ Error refreshing routine: $e');
      }
    }
  }

  /// Create routine entry
  Future<Map<String, dynamic>?> createRoutine(Map<String, dynamic> data) async {
    final rowData = {
      'department': data['department'],
      'semester': int.tryParse(data['semester']?.toString() ?? '1') ?? 1,
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
    };

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'routine',
        'action': 'insert',
        'data': rowData,
      });
      return rowData;
    }

    try {
      final response = await _supabase
          .from('routine')
          .insert(rowData)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error creating routine: $e');
      return null;
    }
  }

  /// Update routine entry
  Future<Map<String, dynamic>?> updateRoutine(
    String id,
    Map<String, dynamic> data,
  ) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData.remove('updated_at');
    updateData.remove('created_at');

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'routine',
        'action': 'update',
        'id': id,
        'data': updateData,
      });
      return updateData;
    }

    try {
      final response = await _supabase
          .from('routine')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error updating routine: $e');
      return null;
    }
  }

  /// Delete routine entry (soft delete)
  Future<bool> deleteRoutine(String id) async {
    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'routine',
        'action': 'update',
        'id': id,
        'data': {'is_active': false},
      });
      return true;
    }

    try {
      await _supabase.from('routine').update({'is_active': false}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting routine: $e');
      return false;
    }
  }

  // ===========================================================================
  // NOTICE MANAGEMENT
  // ===========================================================================

  /// Get notices stream with instant offline cache fallback
  Stream<List<Map<String, dynamic>>> getNoticesStream() async* {
    const cacheKey = OfflineStorageService.keyNotices;
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('notices')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(cacheKey, list);
      yield list;
    } catch (e) {
      debugPrint('⚠️ Error fetching notices: $e');
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('notices')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(cacheKey, list);
        yield list;
      } catch (e) {
        debugPrint('⚠️ Error refreshing notices: $e');
      }
    }
  }

  /// Create notice
  Future<Map<String, dynamic>?> createNotice(Map<String, dynamic> data) async {
    final rowData = {
      'title': data['title'],
      'content': data['content'],
      'priority': data['priority'] ?? 'normal',
      'category': data['category'] ?? 'GENERAL',
      'department': data['department'],
      'action_url': data['action_url'],
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'notices',
        'action': 'insert',
        'data': rowData,
      });
      return rowData;
    }

    try {
      final response = await _supabase
          .from('notices')
          .insert(rowData)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error creating notice: $e');
      return null;
    }
  }

  /// Update notice
  Future<Map<String, dynamic>?> updateNotice(
    String id,
    Map<String, dynamic> data,
  ) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData.remove('updated_at');
    updateData.remove('created_at');

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'notices',
        'action': 'update',
        'id': id,
        'data': updateData,
      });
      return updateData;
    }

    try {
      final response = await _supabase
          .from('notices')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error updating notice: $e');
      return null;
    }
  }

  /// Delete notice (soft delete)
  Future<bool> deleteNotice(String id) async {
    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'notices',
        'action': 'update',
        'id': id,
        'data': {'is_active': false},
      });
      return true;
    }

    try {
      await _supabase.from('notices').update({'is_active': false}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting notice: $e');
      return false;
    }
  }

  // ===========================================================================
  // RESULTS MANAGEMENT - FIXED WITH IS_ACTIVE
  // ===========================================================================

  /// Get results stream - Shows ALL results (with instant offline cache fallback)
  Stream<List<Map<String, dynamic>>> getResultsStream(
    String department,
  ) async* {
    const cacheKey = OfflineStorageService.keyResults;
    final cached = OfflineStorageService.getCachedData(cacheKey);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('results')
          .select()
          .eq('is_active', true)
          .order('id', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(cacheKey, list);
      yield list;
    } catch (e) {
      debugPrint('⚠️ Error fetching results: $e');
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('results')
            .select()
            .eq('is_active', true)
            .order('id', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(cacheKey, list);
        yield list;
      } catch (e) {
        debugPrint('⚠️ Error refreshing results: $e');
      }
    }
  }

  /// Create result - With is_active & offline queue support
  Future<Map<String, dynamic>?> createResult(Map<String, dynamic> data) async {
    final rowData = {
      'roll_num': data['roll_num'],
      'reg_num': data['reg_num'],
      'student_name': data['student_name'],
      'semester': data['semester'],
      'department': data['department'],
      'subject_code': data['subject_code'],
      'subject_name': data['subject_name'],
      'credits': int.tryParse(data['credits']?.toString() ?? '3') ?? 3,
      'theory_continuous':
          double.tryParse(data['theory_continuous']?.toString() ?? '0') ?? 0,
      'theory_continuous_max':
          double.tryParse(
            data['theory_continuous_max']?.toString() ?? '100',
          ) ??
          100,
      'practical_continuous':
          double.tryParse(data['practical_continuous']?.toString() ?? '0') ?? 0,
      'practical_continuous_max':
          double.tryParse(
            data['practical_continuous_max']?.toString() ?? '100',
          ) ??
          100,
      'final_exam':
          double.tryParse(data['final_exam']?.toString() ?? '0') ?? 0,
      'final_exam_max':
          double.tryParse(data['final_exam_max']?.toString() ?? '100') ?? 100,
      'grade': data['grade'],
      'grade_point':
          double.tryParse(data['grade_point']?.toString() ?? '0') ?? 0.0,
      'gpa': double.tryParse(data['gpa']?.toString() ?? '0') ?? 0.0,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'results',
        'action': 'insert',
        'data': rowData,
      });
      return rowData;
    }

    try {
      final response = await _supabase
          .from('results')
          .insert(rowData)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error creating result: $e');
      return null;
    }
  }

  /// Update result
  Future<Map<String, dynamic>?> updateResult(
    String id,
    Map<String, dynamic> data,
  ) async {
    final updateData = {
      'theory_continuous':
          double.tryParse(data['theory_continuous']?.toString() ?? '0') ?? 0,
      'theory_continuous_max':
          double.tryParse(
            data['theory_continuous_max']?.toString() ?? '100',
          ) ??
          100,
      'practical_continuous':
          double.tryParse(data['practical_continuous']?.toString() ?? '0') ?? 0,
      'practical_continuous_max':
          double.tryParse(
            data['practical_continuous_max']?.toString() ?? '100',
          ) ??
          100,
      'final_exam':
          double.tryParse(data['final_exam']?.toString() ?? '0') ?? 0,
      'final_exam_max':
          double.tryParse(data['final_exam_max']?.toString() ?? '100') ?? 100,
      'grade': data['grade'],
      'grade_point':
          double.tryParse(data['grade_point']?.toString() ?? '0') ?? 0.0,
      'gpa': double.tryParse(data['gpa']?.toString() ?? '0') ?? 0.0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'results',
        'action': 'update',
        'id': id,
        'data': updateData,
      });
      return updateData;
    }

    try {
      final response = await _supabase
          .from('results')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ Error updating result: $e');
      return null;
    }
  }

  /// Delete result - Soft delete using is_active
  Future<bool> deleteResult(String id) async {
    if (!OfflineStorageService.isOnline) {
      await OfflineStorageService.addToSyncQueue({
        'table': 'results',
        'action': 'update',
        'id': id,
        'data': {'is_active': false},
      });
      return true;
    }

    try {
      await _supabase.from('results').update({'is_active': false}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting result: $e');
      return false;
    }
  }
}
