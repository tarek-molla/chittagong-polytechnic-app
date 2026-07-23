// =============================================================================
// lib/services/assessment_service.dart
// CPI Faculty Portal — Assessment Database Connection Service
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assessment_model.dart';

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

  /// Fetch or create assessment record
  Future<AssessmentModel?> getOrCreateAssessment(
    String roll,
    String name,
    String subjectCode,
    String subjectName,
    String className,
    int semester,
    String department,
    String teacherName, {
    required String assessmentName,
    required String assessmentType,
    required double totalMarks,
  }) async {
    try {
      final existing = await _supabase
          .from('continuous_assessment')
          .select()
          .eq('roll_number', roll)
          .eq('semester', semester)
          .eq('assessment_type', assessmentType)
          .maybeSingle();

      if (existing != null) {
        return AssessmentModel.fromJson(existing);
      }

      final inserted = await _supabase
          .from('continuous_assessment')
          .insert({
            'roll_number': roll,
            'student_name': name,
            'subject_name': subjectName,
            'semester': semester,
            'department': department,
            'assessment_type': assessmentType,
            'obtained_marks': 0.0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return AssessmentModel.fromJson(inserted);
    } catch (e) {
      print('❌ Error in getOrCreateAssessment: $e');
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
