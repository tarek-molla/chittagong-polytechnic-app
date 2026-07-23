// =============================================================================
// lib/services/supabase_service.dart
// Production-ready Supabase client for the CPI Portal application.
// =============================================================================

import '../models/assessment_model.dart';
import '../models/syllabus_model.dart';
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
      print('🔍 Authenticating teacher: $teacherId');

      final response = await client
          .from('teachers_login')
          .select()
          .eq('teacher_id', teacherId)
          .eq('password', password)
          .eq('is_active', true)
          .limit(1);

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
  // 5. Class Routine Management
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchRoutine(
    String department,
    int semester,
  ) async {
    try {
      print('🔍 Fetching routine for $department - Semester $semester');

      final client = SupabaseService.client;

      var response = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        response = await client
            .from('routine')
            .select()
            .eq('department', department)
            .eq('semester', semester.toString())
            .eq('is_active', true)
            .order('day', ascending: true)
            .order('start_time', ascending: true);
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
        return {'current': null, 'next': nextResponse[0]};
      }

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
      final response = await client
          .from('routine')
          .select()
          .eq('department', department)
          .eq('day', day)
          .eq('is_active', true)
          .order('start_time', ascending: true);

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
      final response = await client
          .from('admit_card')
          .select()
          .eq('roll_number', rollNumber)
          .eq('is_active', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response[0];
      }

      return null;
    } catch (e) {
      print('❌ Error fetching admit card: $e');
      return null;
    }
  }

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
  // 9. Continuous Assessments Retrieval - UPDATED
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

  // ---------------------------------------------------------------------------
  // 10. Get Assessment Stream for Real-time Updates - NEW
  // ---------------------------------------------------------------------------

  Stream<List<AssessmentModel>> getAssessmentStream(String rollNumber) async* {
    // Initial fetch
    yield await fetchStudentAssessments(rollNumber);

    // Listen for changes using periodic refresh
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchStudentAssessments(rollNumber);
      yield updated;
    }
  }

  // ---------------------------------------------------------------------------
  // 11. CRUD Operations for Continuous Assessment - NEW
  // ---------------------------------------------------------------------------

  /// Get assessments for a class and subject
  Future<List<Map<String, dynamic>>> getClassAssessments(
    String className,
    String subjectCode,
    int semester,
  ) async {
    try {
      final response = await client
          .from('continuous_assessment')
          .select()
          .eq('class_name', className)
          .eq('subject_code', subjectCode)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching class assessments: $e');
      return [];
    }
  }

  /// Create a new assessment
  Future<Map<String, dynamic>?> createAssessment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('continuous_assessment')
          .insert({
            'roll_number': data['roll_number'],
            'student_name': data['student_name'],
            'department': data['department'],
            'semester': data['semester'],
            'subject_name': data['subject_name'],
            'subject_code': data['subject_code'],
            'class_name': data['class_name'],
            'assessment_type': data['assessment_type'],
            'assessment_name': data['assessment_name'],
            'obtained_marks': data['obtained_marks'] ?? 0,
            'total_marks': data['total_marks'] ?? 0,
            'teacher_name': data['teacher_name'],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ Error creating assessment: $e');
      return null;
    }
  }

  /// Update assessment marks
  Future<Map<String, dynamic>?> updateAssessmentMarks(
    String assessmentId,
    double obtainedMarks,
    double totalMarks, {
    String? remarks,
  }) async {
    try {
      final response = await client
          .from('continuous_assessment')
          .update({
            'obtained_marks': obtainedMarks,
            'total_marks': totalMarks,
            'remarks': remarks,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ Error updating assessment marks: $e');
      return null;
    }
  }

  /// Delete an assessment (soft delete)
  Future<bool> deleteAssessment(String assessmentId) async {
    try {
      await client
          .from('continuous_assessment')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
      return true;
    } catch (e) {
      print('❌ Error deleting assessment: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 12. Syllabus Management - NEW
  // ---------------------------------------------------------------------------

  /// Get syllabus stream for real-time updates
  Stream<List<Map<String, dynamic>>> getSyllabusStream(
    String department,
    int semester,
  ) async* {
    // Initial fetch
    yield await fetchSyllabus(department, semester);

    // Listen for changes using periodic refresh
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchSyllabus(department, semester);
      yield updated;
    }
  }

  /// Fetch syllabus for a department and semester
  Future<List<Map<String, dynamic>>> fetchSyllabus(
    String department,
    int semester,
  ) async {
    try {
      final query = client
          .from('syllabus')
          .select()
          .eq('department', department)
          .eq('is_active', true);

      if (semester > 0) {
        query.eq('semester', semester);
      }

      final response = await query
          .order('semester', ascending: true)
          .order('subject_name', ascending: true);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching syllabus: $e');
      return [];
    }
  }

  /// Get all syllabus for a department (Teacher View)
  Future<List<Map<String, dynamic>>> getAllSyllabus(String department) async {
    try {
      final response = await client
          .from('syllabus')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('semester', ascending: true)
          .order('subject_name', ascending: true);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching all syllabus: $e');
      return [];
    }
  }

  /// Create a new syllabus entry
  Future<Map<String, dynamic>?> createSyllabus({
    required String subjectName,
    required String department,
    required int semester,
    String? subjectCode,
    String? content,
    String? fileUrl,
    String? fileName,
    required String uploadedBy,
  }) async {
    try {
      final newEntry = {
        'subject_name': subjectName,
        'department': department,
        'semester': semester,
        'subject_code': subjectCode,
        'content': content,
        'file_url': fileUrl,
        'file_name': fileName,
        'uploaded_by': uploadedBy,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('syllabus')
          .insert(newEntry)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error creating syllabus: $e');
      return null;
    }
  }

  /// Update an existing syllabus
  Future<Map<String, dynamic>?> updateSyllabus({
    required String id,
    String? subjectName,
    String? subjectCode,
    String? content,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (subjectName != null) updateData['subject_name'] = subjectName;
      if (subjectCode != null) updateData['subject_code'] = subjectCode;
      if (content != null) updateData['content'] = content;
      if (fileUrl != null) updateData['file_url'] = fileUrl;
      if (fileName != null) updateData['file_name'] = fileName;

      final response = await client
          .from('syllabus')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error updating syllabus: $e');
      return null;
    }
  }

  /// Delete a syllabus (soft delete)
  Future<bool> deleteSyllabus(String id) async {
    try {
      await client
          .from('syllabus')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting syllabus: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 12. Syllabus Management - UPDATED with Teacher View
  // ---------------------------------------------------------------------------

  /// Get ALL syllabus for a department (Teacher View - all semesters)
  Stream<List<Map<String, dynamic>>> getTeacherSyllabusStream(
    String department,
  ) async* {
    // Initial fetch
    yield await fetchAllSyllabus(department);

    // Listen for changes using periodic refresh
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchAllSyllabus(department);
      yield updated;
    }
  }

  /// Fetch ALL syllabus for a department (Teacher View)
  Future<List<Map<String, dynamic>>> fetchAllSyllabus(String department) async {
    try {
      final response = await client
          .from('syllabus')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('semester', ascending: true)
          .order('subject_name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching all syllabus: $e');
      return [];
    }
  }
}

