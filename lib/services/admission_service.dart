// =============================================================================
// lib/services/admission_service.dart
// Admission Service for CPI Admin Panel
// Handles applications + auto-student creation on approval
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_service.dart';

class AdmissionService {
  final SupabaseClient _supabase;
  final AdminService _adminService;

  AdmissionService([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client,
      _adminService = AdminService(client ?? Supabase.instance.client);

  /// Get all applications from the admissions table
  Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final response = await _supabase
          .from('admissions')
          .select()
          .order('created_at', ascending: false);

      print('📊 Found ${response.length} applications');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching applications: $e');
      return [];
    }
  }

  /// Stream of applications (real-time)
  Stream<List<Map<String, dynamic>>> getApplicationsStream() async* {
    try {
      final response = await _supabase
          .from('admissions')
          .select()
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching applications: $e');
      yield [];
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('admissions')
            .select()
            .order('created_at', ascending: false);
        yield List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Error refreshing applications: $e');
      }
    }
  }

  /// Update application status - on approval, auto-creates student record
  Future<bool> updateApplicationStatus(
    String id,
    String status, {
    String? remarks,
  }) async {
    try {
      // Get the application first
      final appResponse = await _supabase
          .from('admissions')
          .select()
          .eq('id', id)
          .single();

      final Map<String, dynamic> data = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (remarks != null && remarks.isNotEmpty) {
        data['admin_remarks'] = remarks;
      }

      await _supabase.from('admissions').update(data).eq('id', id);

      // If approved, auto-create student record
      if (status == 'approved' && appResponse != null) {
        await _createStudentFromApplication(appResponse);
      }

      print('✅ Application $id updated to $status');
      return true;
    } catch (e) {
      print('❌ Error updating application: $e');
      return false;
    }
  }

  /// Create new application (for signup)
  Future<void> createApplication(Map<String, dynamic> data) async {
    try {
      await _supabase.from('admissions').insert({
        'full_name': data['full_name'],
        'email': data['email'],
        'phone': data['phone'],
        'father_name': data['father_name'],
        'mother_name': data['mother_name'],
        'nationality': data['nationality'],
        'religion': data['religion'],
        'department': data['department'],
        'dob': data['dob'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Application created for ${data['full_name']}');
    } catch (e) {
      print('❌ Error creating application: $e');
      rethrow;
    }
  }

  /// Auto-create student from approved application
  Future<void> _createStudentFromApplication(
    Map<String, dynamic> application,
  ) async {
    try {
      final department = application['department'] ?? 'CST';
      final admissionYear = DateTime.now().year;
      final rollNumber = _adminService.generateRollNumber(
        department,
        admissionYear,
      );

      // Check if a student with this email already exists
      final existing = await _supabase
          .from('students_login')
          .select('id')
          .eq('email', application['email'])
          .maybeSingle();

      if (existing != null) {
        print('⚠️ Student with email ${application['email']} already exists');
        return;
      }

      await _supabase.from('students_login').insert({
        'roll_number': rollNumber,
        'student_name': application['full_name'],
        'department': department,
        'semester': 1,
        'email': application['email'],
        'phone': application['phone'],
        'password': 'student123',
        'guardian_name': application['father_name'],
        'guardian_phone': application['phone'],
        'address': application['address'],
        'admission_year': admissionYear,
        'is_active': true,
        'role': 'student',
        'class_name': '$department-1st-A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Student created from application: $rollNumber');
    } catch (e) {
      print('❌ Error creating student from application: $e');
      rethrow;
    }
  }
}
