// lib/services/notice_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice_model.dart';

class NoticeService {
  final SupabaseClient _supabase;

  NoticeService(this._supabase);

  /// Get notices stream for real-time updates
  Stream<List<NoticeModel>> getNoticesStream({
    String? department,
    String? className,
    bool teacherView = false,
  }) async* {
    yield await fetchNotices(
      department: department,
      className: className,
      teacherView: teacherView,
    );

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      final updated = await fetchNotices(
        department: department,
        className: className,
        teacherView: teacherView,
      );
      yield updated;
    }
  }

  /// Fetch notices from database
  Future<List<NoticeModel>> fetchNotices({
    String? department,
    String? className,
    bool teacherView = false,
  }) async {
    try {
      final query = _supabase.from('notices').select();

      if (department != null && department.isNotEmpty) {
        query.eq('department', department);
      }

      if (className != null && className.isNotEmpty) {
        query.eq('class_name', className);
      }

      // Only show active notices
      query.eq('is_active', true);

      // Teachers cannot see ADMINISTRATIVE/EMERGENCY notices
      if (teacherView) {
        query.neq('category', 'ADMINISTRATIVE');
        query.neq('category', 'EMERGENCY');
      }

      final response = await query.order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      var notices = (response as List)
          .map((json) => NoticeModel.fromJson(json))
          .toList();

      // Sort: URGENT first, then by created_at
      notices.sort((a, b) {
        if (a.priority == 'urgent' && b.priority != 'urgent') return -1;
        if (b.priority == 'urgent' && a.priority != 'urgent') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return notices;
    } catch (e) {
      print('❌ Error fetching notices: $e');
      return [];
    }
  }

  /// Create a new notice
  Future<NoticeModel?> createNotice({
    required String title,
    required String content,
    required String category,
    required String actionType,
    String? actionUrl,
    List<Attachment>? attachments,
    String? department,
    int? semester,
    String? className,
    String? subjectCode,
    String? subjectName,
    String? teacherName,
    String priority = 'normal',
    String postedByRole = 'teacher',
  }) async {
    try {
      print('📝 Creating notice: $title');

      // Validate teachers can't post urgent
      if (postedByRole == 'teacher' && priority == 'urgent') {
        print('❌ Teachers cannot post urgent notices');
        return null;
      }

      // Validate teachers can't post admin-only categories
      if (postedByRole == 'teacher' &&
          ['ADMINISTRATIVE', 'EMERGENCY'].contains(category)) {
        print('❌ Teachers cannot post admin-only categories');
        return null;
      }

      final newEntry = {
        'title': title,
        'content': content,
        'category': category,
        'action_type': actionType,
        'action_url': actionUrl,
        'attachments': attachments?.map((a) => a.toJson()).toList() ?? [],
        'department': department ?? 'CST',
        'semester': semester,
        'class_name': className,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'teacher_name': teacherName,
        'priority': priority,
        'is_active': true,
        'posted_by_role': postedByRole,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('notices')
          .insert(newEntry)
          .select()
          .single();

      print('✅ Notice created successfully: ${response['id']}');
      return NoticeModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating notice: $e');
      if (e is PostgrestException) {
        print('   Message: ${e.message}');
        print('   Code: ${e.code}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      return null;
    }
  }

  /// Update an existing notice
  Future<NoticeModel?> updateNotice({
    required String id,
    String? title,
    String? content,
    String? category,
    String? actionType,
    String? actionUrl,
    List<Attachment>? attachments,
    String? priority,
    String? className,
    int? semester,
  }) async {
    try {
      print('📝 Updating notice: $id');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null && title.isNotEmpty) updateData['title'] = title;
      if (content != null && content.isNotEmpty)
        updateData['content'] = content;
      if (category != null && category.isNotEmpty)
        updateData['category'] = category;
      if (actionType != null) updateData['action_type'] = actionType;
      if (actionUrl != null) updateData['action_url'] = actionUrl;
      if (attachments != null) {
        updateData['attachments'] = attachments.map((a) => a.toJson()).toList();
      }
      if (priority != null && priority.isNotEmpty)
        updateData['priority'] = priority;
      if (className != null) {
        updateData['class_name'] = className.isEmpty ? null : className;
      }
      if (semester != null) {
        updateData['semester'] = semester;
      } else {
        updateData['semester'] = null;
      }

      print('📝 Update data: $updateData');

      final response = await _supabase
          .from('notices')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      print('✅ Notice updated successfully: ${response['id']}');
      return NoticeModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating notice: $e');
      if (e is PostgrestException) {
        print('   Message: ${e.message}');
        print('   Code: ${e.code}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      return null;
    }
  }

  /// Hard Delete a notice (permanently remove from database)
  Future<bool> deleteNotice(String id) async {
    try {
      print('📝 Hard deleting notice: $id');

      await _supabase.from('notices').delete().eq('id', id);

      print('✅ Notice permanently deleted: $id');
      return true;
    } catch (e) {
      print('❌ Error deleting notice: $e');
      return false;
    }
  }

  /// Get important notices
  Future<List<NoticeModel>> getImportantNotices({
    String? department,
    String? className,
    int limit = 5,
  }) async {
    try {
      final query = _supabase
          .from('notices')
          .select()
          .eq('is_active', true)
          .eq('priority', 'urgent');

      if (department != null && department.isNotEmpty) {
        query.eq('department', department);
      }

      if (className != null && className.isNotEmpty) {
        query.eq('class_name', className);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => NoticeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching important notices: $e');
      return [];
    }
  }

  /// Get notice statistics
  Future<Map<String, dynamic>> getNoticeStats({
    String? department,
    String? className,
  }) async {
    try {
      final query = _supabase
          .from('notices')
          .select('priority, category, is_active')
          .eq('is_active', true);

      if (department != null && department.isNotEmpty) {
        query.eq('department', department);
      }

      if (className != null && className.isNotEmpty) {
        query.eq('class_name', className);
      }

      final response = await query;

      if (response.isEmpty) {
        return {
          'total': 0,
          'urgent': 0,
          'important': 0,
          'normal': 0,
          'categories': {},
        };
      }

      final entries = response as List;
      final total = entries.length;
      final urgent = entries.where((e) => e['priority'] == 'urgent').length;
      final important = entries
          .where((e) => e['priority'] == 'important')
          .length;
      final normal = entries.where((e) => e['priority'] == 'normal').length;

      final categories = <String, int>{};
      for (var entry in entries) {
        final category = entry['category'] ?? 'GENERAL';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'total': total,
        'urgent': urgent,
        'important': important,
        'normal': normal,
        'categories': categories,
      };
    } catch (e) {
      print('❌ Error fetching notice stats: $e');
      return {};
    }
  }
}
