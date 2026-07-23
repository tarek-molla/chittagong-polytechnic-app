// lib/services/syllabus_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/syllabus_model.dart';

class SyllabusService {
  final SupabaseClient _supabase;

  SyllabusService(this._supabase);

  /// Get syllabus stream for real-time updates (Student View - by semester)
  Stream<List<SyllabusModel>> getSyllabusStream(
    String department,
    int semester,
  ) async* {
    yield await fetchSyllabus(department, semester);
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchSyllabus(department, semester);
      yield updated;
    }
  }

  /// Get ALL syllabus for a department (Teacher View - all semesters)
  Stream<List<SyllabusModel>> getTeacherSyllabusStream(
    String department,
  ) async* {
    yield await fetchAllSyllabus(department);
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchAllSyllabus(department);
      yield updated;
    }
  }

  /// Fetch syllabus for a department and semester (Student View)
  Future<List<SyllabusModel>> fetchSyllabus(
    String department,
    int semester,
  ) async {
    try {
      final query = _supabase
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

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => SyllabusModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching syllabus: $e');
      return [];
    }
  }

  /// Fetch ALL syllabus for a department (Teacher View)
  Future<List<SyllabusModel>> fetchAllSyllabus(String department) async {
    try {
      final response = await _supabase
          .from('syllabus')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .order('semester', ascending: true)
          .order('subject_name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => SyllabusModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching all syllabus: $e');
      return [];
    }
  }

  /// Create a new syllabus entry
  Future<SyllabusModel?> createSyllabus({
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
      print('📝 Creating syllabus: $subjectName, $department, Sem $semester');

      final newEntry = {
        'subject_name': subjectName,
        'department': department,
        'semester': semester,
        'subject_code': subjectCode ?? '',
        'content': content ?? '',
        'file_url': fileUrl ?? '',
        'file_name': fileName ?? '',
        'uploaded_by': uploadedBy,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('syllabus')
          .insert(newEntry)
          .select()
          .maybeSingle();

      if (response == null) {
        print('❌ No response from insert');
        return null;
      }

      print('✅ Syllabus created successfully: ${response['id']}');
      return SyllabusModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating syllabus: $e');
      if (e is PostgrestException) {
        print('❌ PostgrestException details:');
        print('   Message: ${e.message}');
        print('   Code: ${e.code}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      return null;
    }
  }

  /// Update an existing syllabus
  Future<SyllabusModel?> updateSyllabus({
    required String id,
    String? subjectName,
    String? subjectCode,
    String? content,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      print('📝 Updating syllabus ID: $id');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (subjectName != null && subjectName.isNotEmpty) {
        updateData['subject_name'] = subjectName;
      }
      if (subjectCode != null && subjectCode.isNotEmpty) {
        updateData['subject_code'] = subjectCode;
      } else {
        updateData['subject_code'] = '';
      }
      if (content != null && content.isNotEmpty) {
        updateData['content'] = content;
      } else {
        updateData['content'] = '';
      }
      if (fileUrl != null && fileUrl.isNotEmpty) {
        updateData['file_url'] = fileUrl;
      } else {
        updateData['file_url'] = '';
      }
      if (fileName != null && fileName.isNotEmpty) {
        updateData['file_name'] = fileName;
      } else {
        updateData['file_name'] = '';
      }

      print('📝 Update data: $updateData');

      final response = await _supabase
          .from('syllabus')
          .update(updateData)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response == null) {
        print('❌ No response from update');
        return null;
      }

      print('✅ Syllabus updated successfully: ${response['id']}');
      return SyllabusModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating syllabus: $e');
      if (e is PostgrestException) {
        print('❌ PostgrestException details:');
        print('   Message: ${e.message}');
        print('   Code: ${e.code}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      return null;
    }
  }

  /// Delete a syllabus (soft delete)
  Future<bool> deleteSyllabus(String id) async {
    try {
      await _supabase
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
}
