// lib/models/syllabus_model.dart

class SyllabusModel {
  final String id;
  final String subjectName;
  final String department;
  final int semester;
  final String? subjectCode;
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final String? uploadedBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyllabusModel({
    required this.id,
    required this.subjectName,
    required this.department,
    required this.semester,
    this.subjectCode,
    this.content,
    this.fileUrl,
    this.fileName,
    this.uploadedBy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SyllabusModel.fromJson(Map<String, dynamic> json) {
    return SyllabusModel(
      id: json['id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      department: json['department'] ?? '',
      semester: json['semester'] ?? 0,
      subjectCode: json['subject_code'],
      content: json['content'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      uploadedBy: json['uploaded_by'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_name': subjectName,
      'department': department,
      'semester': semester,
      'subject_code': subjectCode,
      'content': content,
      'file_url': fileUrl,
      'file_name': fileName,
      'uploaded_by': uploadedBy,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  SyllabusModel copyWith({
    String? id,
    String? subjectName,
    String? department,
    int? semester,
    String? subjectCode,
    String? content,
    String? fileUrl,
    String? fileName,
    String? uploadedBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyllabusModel(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      subjectCode: subjectCode ?? this.subjectCode,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
