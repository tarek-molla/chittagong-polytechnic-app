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
      id: json['id'] as String,
      subjectName: json['subject_name'] as String,
      department: json['department'] as String,
      semester: json['semester'] as int,
      subjectCode: json['subject_code'] as String?,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
