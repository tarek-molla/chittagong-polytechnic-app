// =============================================================================
// lib/services/admission_service.dart
// Admission Service for CPI Admin Panel
// Handles applications + auto-student creation on approval + offline caching
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_service.dart';
import 'offline_storage_service.dart';

class AdmissionService {
  final SupabaseClient _supabase;
  final AdminService _adminService;

  AdmissionService([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client,
      _adminService = AdminService(client ?? Supabase.instance.client);

  /// Get all applications from the applications table
  Future<List<Map<String, dynamic>>> getApplications() async {
    // Try to return cached data immediately if offline
    final cached = OfflineStorageService.getCachedData(OfflineStorageService.keyApplications);
    List<Map<String, dynamic>> initialList = [];
    if (cached != null && cached is List) {
      initialList = cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('applications')
          .select()
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(OfflineStorageService.keyApplications, list);
      return list;
    } catch (e) {
      return initialList;
    }
  }

  /// Stream of applications (real-time) with offline cache fallback
  Stream<List<Map<String, dynamic>>> getApplicationsStream() async* {
    final cached = OfflineStorageService.getCachedData(OfflineStorageService.keyApplications);
    if (cached != null && cached is List) {
      yield cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final response = await _supabase
          .from('applications')
          .select()
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(response);
      await OfflineStorageService.cacheData(OfflineStorageService.keyApplications, list);
      yield list;
    } catch (e) {
      // Offline or network error - cached already yielded
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        final response = await _supabase
            .from('applications')
            .select()
            .order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);
        await OfflineStorageService.cacheData(OfflineStorageService.keyApplications, list);
        yield list;
      } catch (_) {}
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
          .from('applications')
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

      await _supabase.from('applications').update(data).eq('id', id);

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
