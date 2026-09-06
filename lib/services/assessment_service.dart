// =============================================================================
// lib/services/assessment_service.dart
// CPI Faculty Portal — Assessment Database Connection Service
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assessment_model.dart';

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

class AssessmentService {
  final SupabaseClient _supabase;

  AssessmentService(this._supabase);

  /// Get live assessment stream filtered by class, subject, and semester
  Stream<List<AssessmentModel>> getAssessmentStream(
    String className,
    String subjectCode,
    int semester,
  ) async* {
    yield await getClassAssessments(className, subjectCode, semester);

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await getClassAssessments(
        className,
        subjectCode,
        semester,
      );
      yield updated;
    }
  }

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

  /// Get registered students for class/semester from students table
  Future<List<Map<String, dynamic>>> getClassStudents(
    String className,
    int semester,
  ) async {
    try {
      final response = await _supabase
          .from('students')
          .select('roll_number, student_name')
          .eq('semester', semester)
          .order('roll_number', ascending: true);

      return (response as List)
          .map(
            (e) => {
              'roll': e['roll_number'] ?? '',
              'name': e['student_name'] ?? '',
            },
          )
          .toList();
    } catch (e) {
      print('❌ Error fetching class students: $e');
      return [];
    }
  }

  /// Fetch all assessment entries from continuous_assessment
  Future<List<AssessmentModel>> getClassAssessments(
    String className,
    String subjectCode,
    int semester,
  ) async {
    try {
      final response = await _supabase
          .from('continuous_assessment')
          .select()
          .eq('semester', semester)
          .order('roll_number', ascending: true);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => AssessmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching class assessments: $e');
      return [];
    }
  }

  /// Get or create assessment for a student
  Future<AssessmentModel?> getOrCreateAssessment(
    String studentRoll,
    String studentName,
    String subjectCode,
    String subjectName,
    String className,
    int semester,
    String department,
    String teacherName, {
    String assessmentName = 'CT-1',
    String assessmentType = 'Theory',
    double totalMarks = 30,
  }) async {
    try {
      print('📝 Creating assessment for: $studentRoll - $assessmentName');

      // Check if assessment exists
      final response = await _supabase
          .from('continuous_assessment')
          .select()
          .eq('roll_number', studentRoll)
          .eq('subject_code', subjectCode)
          .eq('assessment_name', assessmentName)
          .eq('assessment_type', assessmentType)
          .maybeSingle();

      if (response != null) {
        print('✅ Assessment already exists for $studentRoll');
        return AssessmentModel.fromJson(response);
      }

      // Create new assessment
      final newEntry = {
        'roll_number': studentRoll,
        'student_name': studentName,
        'department': department,
        'semester': semester,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'class_name': className,
        'assessment_type': assessmentType,
        'assessment_name': assessmentName,
        'obtained_marks': 0,
        'total_marks': totalMarks,
        'is_active': true,
        'teacher_name': teacherName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final insertResponse = await _supabase
          .from('continuous_assessment')
          .insert(newEntry)
          .select()
          .single();

      print('✅ Created assessment for $studentRoll');
      return AssessmentModel.fromJson(insertResponse);
    } catch (e) {
      print('❌ Error creating assessment: $e');
      return null;
    }
  }

  /// Update marks safely by primary key ID
  Future<AssessmentModel?> updateAssessmentMarks(
    String assessmentId, {
    required double obtainedMarks,
    required double totalMarks,
    String? remarks,
  }) async {
    try {
      final response = await _supabase
          .from('continuous_assessment')
          .update({'obtained_marks': obtainedMarks})
          .eq('id', assessmentId)
          .select();

      if (response == null || (response as List).isEmpty) {
        print('⚠️ Update warning: 0 rows modified for ID: $assessmentId');
        return null;
      }

      return AssessmentModel.fromJson((response as List).first);
    } catch (e) {
      print('❌ Error updating assessment marks: $e');
      return null;
    }
  }
}
