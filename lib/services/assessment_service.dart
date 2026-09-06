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

  /// Get students for a class from students_login table
  Future<List<Student>> getStudents(String className, int semester) async {
    try {
      print('📚 Fetching students for class: $className, semester: $semester');

      final response = await _supabase
          .from('students_login')
          .select('roll_number, student_name')
          .eq('class_name', className)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      print('📊 Found ${response.length} students');

      if (response.isEmpty) {
        print('⚠️ No students found');
        return [];
      }

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching students: $e');
      return [];
    }
  }

  /// Get registered students for class/semester from students_login table
  Future<List<Map<String, dynamic>>> getClassStudents(
    String className,
    int semester,
  ) async {
    try {
      print(
        '📊 Fetching class students from students_login for: $className, semester: $semester',
      );

      final response = await _supabase
          .from('students_login')
          .select('roll_number, student_name')
          .eq('class_name', className)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      print('📊 Found ${response.length} students in class: $className');

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
      print(
        '📊 Fetching assessments for: $className, $subjectCode, semester: $semester',
      );

      final response = await _supabase
          .from('continuous_assessment')
          .select()
          .eq('class_name', className)
          .eq('subject_code', subjectCode)
          .eq('semester', semester)
          .order('roll_number', ascending: true);

      print('📊 Found ${response.length} assessments');

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
    String assessmentType = 'CT',
    double totalMarks = 30,
  }) async {
    try {
      print('📝 Creating assessment for: $studentRoll - $assessmentName');

      // Check if assessment exists using the unique constraint fields
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

      // Create new assessment with all required fields
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

      print('📝 Inserting: $newEntry');

      final insertResponse = await _supabase
          .from('continuous_assessment')
          .insert(newEntry)
          .select()
          .maybeSingle();

      if (insertResponse == null) {
        print('❌ Insert returned null - RLS policy might be blocking');
        return null;
      }

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
      print('🔧 Updating ID=$assessmentId -> $obtainedMarks / $totalMarks');

      // First check if the record exists
      final checkResponse = await _supabase
          .from('continuous_assessment')
          .select('id, roll_number, obtained_marks')
          .eq('id', assessmentId)
          .maybeSingle();

      if (checkResponse == null) {
        print('❌ Record not found for ID: $assessmentId');

        // Try with UUID cast (if it's not already UUID)
        try {
          print('🔄 Trying with cast to UUID...');
          final uuidCheck = await _supabase
              .from('continuous_assessment')
              .select('id')
              .eq('id', assessmentId.toString())
              .maybeSingle();

          if (uuidCheck != null) {
            print('✅ Found with UUID cast');
          } else {
            print('❌ Still not found after UUID cast');
          }
        } catch (e) {
          print('❌ UUID cast failed: $e');
        }

        return null;
      }

      print('✅ Record found, updating...');

      // Update the record
      final response = await _supabase
          .from('continuous_assessment')
          .update({
            'obtained_marks': obtainedMarks,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId)
          .select()
          .maybeSingle();

      if (response == null) {
        print('❌ Update returned null - no rows modified');
        return null;
      }

      print('✅ Updated assessment marks for ID: $assessmentId');
      return AssessmentModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating assessment marks: $e');
      return null;
    }
  }

  /// Delete an assessment entry
  Future<bool> deleteAssessment(String assessmentId) async {
    try {
      await _supabase
          .from('continuous_assessment')
          .delete()
          .eq('id', assessmentId);
      return true;
    } catch (e) {
      print('❌ Error deleting assessment: $e');
      return false;
    }
  }
}
