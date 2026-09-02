// lib/models/notice_model.dart

import 'package:flutter/material.dart';

class Attachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'pdf', 'image', 'doc', etc.
  final double fileSize; // in KB

  Attachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? 'Attachment',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'doc',
      fileSize: (json['file_size'] is num)
          ? (json['file_size'] as num).toDouble()
          : (double.tryParse(json['file_size']?.toString() ?? '0') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }

  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'image':
      case 'png':
      case 'jpg':
      case 'jpeg':
        return '🖼️';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }

  String get fileSizeFormatted {
    if (fileSize > 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} MB';
    }
    return '${fileSize.toStringAsFixed(1)} KB';
  }
}

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String actionType;
  final String? actionUrl;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final String? department;
  final int? semester;
  final String? className;
  final String? subjectCode;
  final String? subjectName;
  final String? teacherName;
  final String priority;
  final bool isActive;
  final DateTime? updatedAt;
  final String postedByRole;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.actionType,
    this.actionUrl,
    this.attachments = const [],
    required this.createdAt,
    this.department,
    this.semester,
    this.className,
    this.subjectCode,
    this.subjectName,
    this.teacherName,
    this.priority = 'normal',
    this.isActive = true,
    this.updatedAt,
    this.postedByRole = 'teacher',
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    List<Attachment> parsedAttachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return NoticeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Notice',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      actionType: json['action_type']?.toString() ?? 'none',
      actionUrl: json['action_url']?.toString(),
      attachments: parsedAttachments,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      department: json['department']?.toString(),
      semester: json['semester'] is int
          ? json['semester'] as int
          : int.tryParse(json['semester']?.toString() ?? ''),
      className: json['class_name']?.toString(),
      subjectCode: json['subject_code']?.toString(),
      subjectName: json['subject_name']?.toString(),
      teacherName: json['teacher_name']?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active']?.toString().toLowerCase() == 'true'),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      postedByRole: json['posted_by_role']?.toString() ?? 'teacher',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'action_type': actionType,
      'action_url': actionUrl,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'department': department,
      'semester': semester,
      'class_name': className,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'teacher_name': teacherName,
      'priority': priority,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
      'posted_by_role': postedByRole,
    };
  }

  // Getters for UI
  Color get categoryColor {
    switch (category.toUpperCase()) {
      case 'ACADEMIC':
        return const Color(0xFF10B981); // Green
      case 'CLASS':
        return const Color(0xFF3B82F6); // Blue
      case 'SUGGESTION':
        return const Color(0xFF8B5CF6); // Purple
      case 'GENERAL':
        return const Color(0xFF6B7280); // Gray
      case 'ADMINISTRATIVE':
        return const Color(0xFFF59E0B); // Orange
      case 'EMERGENCY':
        return const Color(0xFFEF4444); // Red
      case 'EXAMINATION':
        return const Color(0xFFEC4899); // Pink
      case 'EVENT':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'important':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'URGENT';
      case 'important':
        return 'IMPORTANT';
      default:
        return 'NORMAL';
    }
  }

  bool get hasAction {
    return actionType != 'none' && actionUrl != null && actionUrl!.isNotEmpty;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasAttachments => attachments.isNotEmpty;
}
