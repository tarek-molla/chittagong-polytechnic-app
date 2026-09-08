// =============================================================================
// lib/models/admission.dart
// CPI Admission Model — Matches 'applications' table
// =============================================================================

import 'package:flutter/material.dart';

class Admission {
  final String? id;
  final String fullName;
  final String email;
  final String? phone;
  final String department;
  final String? fatherName;
  final String? motherName;
  final String? dob;
  final String? address;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Admission({
    this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.department,
    this.fatherName,
    this.motherName,
    this.dob,
    this.address,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory Admission.fromJson(Map<String, dynamic> json) {
    return Admission(
      id: json['id']?.toString(),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      department: json['department'] ?? 'CST',
      fatherName: json['father_name'],
      motherName: json['mother_name'],
      dob: json['dob'],
      address: json['address'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'father_name': fatherName,
      'mother_name': motherName,
      'dob': dob,
      'address': address,
      'status': status,
    };
  }

  Admission copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? fatherName,
    String? motherName,
    String? dob,
    String? address,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Admission(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for UI
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get statusLabel {
    return status.toUpperCase();
  }

  String get statusEmoji {
    switch (status) {
      case 'pending':
        return '📋';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '📌';
    }
  }
}
