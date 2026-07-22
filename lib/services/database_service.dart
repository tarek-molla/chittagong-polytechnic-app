import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice_model.dart';
import '../models/syllabus_model.dart';
import '../models/assessment_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Listens to real-time changes on the 'notices' table (with immediate data)
  Stream<List<NoticeModel>> getNoticesStream() async* {
    try {
      // ✅ Immediately yield data
      final response = await _supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);

      yield (response as List)
          .map((json) => NoticeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching notices: $e');
      yield [];
    }

    // Then listen to real-time changes
    try {
      await for (final changes
          in _supabase
              .from('notices')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false)
              .map(
                (response) =>
                    response.map((json) => NoticeModel.fromJson(json)).toList(),
              )) {
        yield changes;
      }
    } catch (e) {
      print('❌ Error in notice stream: $e');
    }
  }

  /// Pushes a new notice to the database (Restricted by RLS to Admins/Teachers)
  Future<void> createNotice(NoticeModel notice) async {
    try {
      await _supabase.from('notices').insert(notice.toJson());
      print('✅ Notice created successfully');
    } catch (e) {
      print('❌ Error creating notice: $e');
      rethrow;
    }
  }

  /// Pushes a new notice to the database with file attachments
  Future<void> createNoticeWithAttachments(
    NoticeModel notice,
    List<File> files,
  ) async {
    try {
      await _supabase.from('notices').insert(notice.toJson());
      print('✅ Notice with attachments created successfully');
    } catch (e) {
      print('❌ Error creating notice with attachments: $e');
      rethrow;
    }
  }

  /// Get syllabus stream for a department and semester (with immediate data)
  Stream<List<SyllabusModel>> getSyllabusStream(
    String department,
    int semester,
  ) async* {
    // ✅ Immediately yield data on first subscription
    try {
      final response = await _supabase
          .from('syllabus')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('subject_name', ascending: true);

      yield (response as List)
          .map((json) => SyllabusModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching syllabus: $e');
      yield [];
    }

    // Then refresh every 10 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
      try {
        final response = await _supabase
            .from('syllabus')
            .select()
            .eq('department', department)
            .eq('semester', semester)
            .eq('is_active', true)
            .order('subject_name', ascending: true);

        yield (response as List)
            .map((json) => SyllabusModel.fromJson(json))
            .toList();
      } catch (e) {
        print('❌ Error refreshing syllabus: $e');
        // Don't break the stream on error
      }
    }
  }

  /// Upload a syllabus file to Supabase Storage
  Future<String> uploadSyllabusFile(File file, String subjectName) async {
    try {
      final fileName =
          'syllabus/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await _supabase.storage
          .from('syllabus_files')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('syllabus_files')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('❌ Syllabus upload error: $e');
      rethrow;
    }
  }

  /// Create a new syllabus entry
  Future<void> createSyllabus(SyllabusModel syllabus) async {
    try {
      await _supabase.from('syllabus').insert(syllabus.toJson());
      print('✅ Syllabus created: ${syllabus.subjectName}');
    } catch (e) {
      print('❌ Error creating syllabus: $e');
      rethrow;
    }
  }

  /// Update a syllabus entry
  Future<void> updateSyllabus(SyllabusModel syllabus) async {
    try {
      await _supabase
          .from('syllabus')
          .update(syllabus.toJson())
          .eq('id', syllabus.id);
      print('✅ Syllabus updated: ${syllabus.subjectName}');
    } catch (e) {
      print('❌ Error updating syllabus: $e');
      rethrow;
    }
  }

  /// Get continuous assessments for a student
  Future<List<AssessmentModel>> fetchAssessments(String rollNumber) async {
    try {
      final response = await _supabase
          .from('continuous_assessment')
          .select()
          .eq('roll_number', rollNumber)
          .eq('is_active', true)
          .order('subject_name', ascending: true);

      return (response as List)
          .map((json) => AssessmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching assessments: $e');
      return [];
    }
  }
}
