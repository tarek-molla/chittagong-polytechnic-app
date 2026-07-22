// =============================================================================
// lib/services/supabase_service.dart
// Production-ready Supabase client for the CPI Portal application.
// =============================================================================

import '../models/assessment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // ---------------------------------------------------------------------------
  // Project credentials
  // ---------------------------------------------------------------------------
  static const String _projectUrl = 'https://orpwdmnfuzyujpyczlcn.supabase.co';

  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ycHdkbW5mdXp5dWpweWN6bGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzMjc5NTgsImV4cCI6MjA5NTkwMzk1OH0.K1B2o_-TcyxN7LLI18mE1P5Y7rNS_lPGcPa8704QBQU';

  static SupabaseService? _instance;

  static SupabaseService get instance {
    assert(
      _instance != null,
      'SupabaseService.initialize() must be called before accessing instance.',
    );
    return _instance!;
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: _projectUrl, anonKey: _anonKey);
      print('✅ Supabase initialized successfully');
      _instance = SupabaseService._internal();
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  SupabaseService._internal();

  // ---------------------------------------------------------------------------
  // 1. Student Authentication using students_login table
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> authenticateStudent(
    String rollNumber,
    String password,
  ) async {
    try {
      print('🔍 Authenticating student: $rollNumber');

      final response = await client
          .from('students_login')
          .select()
          .eq('roll_number', rollNumber)
          .eq('password', password)
          .eq('is_active', true)
          .limit(1);

      print('📊 Response length: ${response.length}');

      if (response.isNotEmpty) {
        print('✅ Student authenticated: ${response[0]['student_name']}');
        print('👤 Role: ${response[0]['role'] ?? 'student'}');
        return response[0];
      }

      print('❌ Student not found or invalid credentials');
      return null;
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 1b. Teacher Authentication using teachers_login table
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> authenticateTeacher(
    String teacherId,
    String password,
  ) async {
    try {
      print('🔍 Supabase client initialized: ${client != null}');
      print('🔍 Authenticating teacher: $teacherId');
      print('🔑 Password: $password');

      final response = await client
          .from('teachers_login')
          .select('*')
          .eq('teacher_id', teacherId)
          .eq('password', password)
          .eq('is_active', true)
          .limit(1);

      print('📊 Full Response: $response');
      print('📊 Response is List: ${response is List}');
      print('📊 Response length: ${response.length}');

      if (response.isNotEmpty && response is List) {
        print('✅ Teacher authenticated: ${response[0]['name']}');
        return response[0] as Map<String, dynamic>;
      }

      print('❌ Teacher not found');
      return null;
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 1c. Admin Authentication using admin_login table
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> authenticateAdmin(
    String adminId,
    String password,
  ) async {
    try {
      print('🔍 Authenticating admin: $adminId');

      final response = await client
          .from('admin_login')
          .select()
          .eq('admin_id', adminId)
          .eq('password', password)
          .eq('is_active', true)
          .limit(1);

      print('📊 Response length: ${response.length}');

      if (response.isNotEmpty) {
        print('✅ Admin authenticated: ${response[0]['full_name']}');
        return response[0];
      }

      print('❌ Admin not found or invalid credentials');
      return null;
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Student Results Retrieval
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchStudentResults(String rollNum) async {
    try {
      print('🔍 Fetching results for roll number: $rollNum');

      final response = await client
          .from('results')
          .select()
          .eq('roll_num', rollNum)
          .order('created_at', ascending: false);

      print('📊 Results found: ${response.length} records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching results: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Student Attendance Retrieval
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchStudentAttendance(
    String rollNumber,
  ) async {
    try {
      print('🔍 Fetching attendance for roll number: $rollNumber');

      final response = await client
          .from('attendance')
          .select()
          .eq('student_roll', rollNumber)
          .order('subject_name', ascending: true);

      print('📊 Attendance records found: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Admission Application Submission
  // ---------------------------------------------------------------------------

  Future<void> submitAdmissionApplication(Map<String, dynamic> data) async {
    try {
      await client.from('applications').insert({
        'full_name': data['full_name'],
        'father_name': data['father_name'],
        'mother_name': data['mother_name'],
        'email_address': data['email_address'],
        'phone_number': data['phone_number'],
        'nationality': data['nationality'],
        'date_of_birth': data['date_of_birth'],
        'religion': data['religion'],
        'department_choice': data['department_choice'],
      });
      print('✅ Application submitted successfully');
    } catch (e) {
      print('❌ Error submitting application: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Class Routine Management - FIXED VERSION
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchRoutine(
    String department,
    int semester,
  ) async {
    try {
      print('🔍 ===== FETCHING ROUTINE =====');
      print('🔍 Department: $department');
      print('🔍 Semester: $semester (type: ${semester.runtimeType})');

      final client = SupabaseService.client;

      final allRoutines = await client.from('routine').select();
      print('📊 Total routines in table: ${allRoutines.length}');

      if (allRoutines.isEmpty) {
        print('❌ No data in routine table at all!');
        return [];
      }

      print('📝 Sample record: ${allRoutines[0]}');
      print(
        '📝 Departments: ${allRoutines.map((r) => r['department']).toSet().join(', ')}',
      );
      print(
        '📝 Semesters: ${allRoutines.map((r) => r['semester']).toSet().join(', ')}',
      );

      print('🔍 Trying query with semester as int...');
      var response = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      print('📊 Results with int semester: ${response.length}');

      if (response.isEmpty) {
        print('🔄 Trying with semester as string...');
        response = await client
            .from('routine')
            .select()
            .eq('department', department)
            .eq('semester', semester.toString())
            .eq('is_active', true)
            .order('day', ascending: true)
            .order('start_time', ascending: true);

        print('📊 Results with string semester: ${response.length}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching routine: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 6. Get Current Class for Dashboard
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> fetchCurrentClass(
    String department,
    String day,
    String currentTime,
  ) async {
    try {
      print('🔍 Fetching current class for $department - $day at $currentTime');

      final response = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('day', day)
          .eq('is_active', true)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime)
          .limit(1);

      if (response.isNotEmpty) {
        print('✅ Current class: ${response[0]['subject_name']}');
        return {'current': response[0], 'next': null};
      }

      final nextResponse = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('day', day)
          .eq('is_active', true)
          .gt('start_time', currentTime)
          .order('start_time', ascending: true)
          .limit(1);

      if (nextResponse.isNotEmpty) {
        print(
          '📅 Next class: ${nextResponse[0]['subject_name']} at ${nextResponse[0]['start_time']}',
        );
        return {'current': null, 'next': nextResponse[0]};
      }

      print('❌ No classes found for today');
      return null;
    } catch (e) {
      print('❌ Error fetching current class: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 7. Get Today's Classes for Dashboard
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchTodayClasses(
    String department,
    String day,
  ) async {
    try {
      print('🔍 Fetching today\'s classes for $department - $day');

      final response = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('day', day)
          .eq('is_active', true)
          .order('start_time', ascending: true);

      print('📊 Today\'s classes: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching today\'s classes: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 8. Admit Card Retrieval
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> fetchAdmitCard(String rollNumber) async {
    try {
      print('🔍 Fetching admit card for roll number: $rollNumber');

      final response = await client
          .from('admit_card')
          .select()
          .eq('roll_number', rollNumber)
          .eq('is_active', true)
          .limit(1);

      if (response.isNotEmpty) {
        print('✅ Admit card found for: ${response[0]['student_name']}');
        print('👨 Father: ${response[0]['father_name']}');
        print('👩 Mother: ${response[0]['mother_name']}');
        print('📅 DOB: ${response[0]['date_of_birth']}');
        return response[0];
      }

      print('❌ No admit card found for roll number: $rollNumber');
      return null;
    } catch (e) {
      print('❌ Error fetching admit card: $e');
      return null;
    }
  }

  /// Get subjects from admit card as List<Map<String, String>>
  Future<List<Map<String, String>>> fetchAdmitCardSubjects(
    String rollNumber,
  ) async {
    try {
      final admitCard = await fetchAdmitCard(rollNumber);
      if (admitCard != null && admitCard['subjects'] != null) {
        final subjects = admitCard['subjects'] as List;
        return subjects
            .map(
              (s) => {
                'code': s['code']?.toString() ?? '',
                'name': s['name']?.toString() ?? '',
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching subjects: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 9. Continuous Assessments Retrieval
  // ---------------------------------------------------------------------------

  Future<List<AssessmentModel>> fetchStudentAssessments(
    String rollNumber,
  ) async {
    try {
      print('🔍 Fetching assessments for roll number: $rollNumber');

      final response = await client
          .from('continuous_assessment')
          .select()
          .eq('roll_number', rollNumber)
          .eq('is_active', true)
          .order('subject_name', ascending: true);

      print('📊 Assessments found: ${response.length}');
      return (response as List)
          .map((json) => AssessmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching assessments: $e');
      return [];
    }
  }
}
