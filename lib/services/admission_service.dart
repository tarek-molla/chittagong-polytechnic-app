import 'package:supabase_flutter/supabase_flutter.dart';

class AdmissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all applications from the applications table
  Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final response = await _supabase
          .from('applications')
          .select()
          .order('created_at', ascending: false);

      print('📊 Found ${response.length} applications');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching applications: $e');
      return [];
    }
  }

  /// Update application status
  Future<void> updateApplicationStatus(
    String id,
    String status, {
    String? remarks,
  }) async {
    try {
      // ✅ Only update columns that exist
      final Map<String, dynamic> data = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (remarks != null && remarks.isNotEmpty) {
        data['admin_remarks'] = remarks;
      }

      await _supabase.from('applications').update(data).eq('id', id);

      print('✅ Application $id updated to $status');
    } catch (e) {
      print('❌ Error updating application: $e');
      rethrow;
    }
  }

  /// Create new application (for signup) - ✅ Matches your table columns
  Future<void> createApplication(Map<String, dynamic> data) async {
    try {
      await _supabase.from('applications').insert({
        'full_name': data['full_name'],
        'email': data['email'],
        'phone': data['phone'],
        'father_name': data['father_name'],
        'mother_name': data['mother_name'],
        'nationality': data['nationality'],
        'religion': data['religion'],
        'department': data['department'],
        'dob': data['dob'],
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Application created for ${data['full_name']}');
    } catch (e) {
      print('❌ Error creating application: $e');
      rethrow;
    }
  }
}
