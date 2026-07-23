// lib/models/assessment_model.dart

class AssessmentModel {
  final String id;
  final String rollNumber;
  final String studentName;
  final String department;
  final int semester;
  final String subjectCode;
  final String subjectName;
  final String className;
  final String assessmentType;
  final String assessmentName;
  final double obtainedMarks;
  final double totalMarks;
  final bool isActive;
  final String? remarks;
  final String teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Alias for rollNumber to match view expectations
  String get studentRoll => rollNumber;

  AssessmentModel({
    required this.id,
    required this.rollNumber,
    required this.studentName,
    required this.department,
    required this.semester,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.assessmentType,
    required this.assessmentName,
    required this.obtainedMarks,
    required this.totalMarks,
    this.isActive = true,
    this.remarks,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id']?.toString() ?? '',
      rollNumber: json['roll_number']?.toString() ?? json['student_roll']?.toString() ?? 'N/A',
      studentName: json['student_name']?.toString() ?? 'Student',
      subjectCode: json['subject_code']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      department: json['department']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      assessmentName: json['assessment_name']?.toString() ?? 'Assessment',
      assessmentType: json['assessment_type']?.toString() ?? 'CT',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 30.0,
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_number': rollNumber,
      'student_name': studentName,
      'department': department,
      'semester': semester,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'class_name': className,
      'assessment_type': assessmentType,
      'assessment_name': assessmentName,
      'obtained_marks': obtainedMarks,
      'total_marks': totalMarks,
      'is_active': isActive,
      'remarks': remarks,
      'teacher_name': teacherName,
    };
  }

  double get percentage {
    if (totalMarks == 0) return 0;
    return (obtainedMarks / totalMarks) * 100;
  }

  String get status {
    final p = percentage;
    if (p >= 80) return 'Excellent';
    if (p >= 70) return 'Good';
    if (p >= 60) return 'Average';
    if (p >= 40) return 'Passed';
    return 'Failed';
  }

  String get totalDisplay =>
      '${obtainedMarks.toStringAsFixed(0)}/${totalMarks.toStringAsFixed(0)}';

  AssessmentModel copyWith({
    String? id,
    String? rollNumber,
    String? studentName,
    String? department,
    int? semester,
    String? subjectCode,
    String? subjectName,
    String? className,
    String? assessmentType,
    String? assessmentName,
    double? obtainedMarks,
    double? totalMarks,
    bool? isActive,
    String? remarks,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      rollNumber: rollNumber ?? this.rollNumber,
      studentName: studentName ?? this.studentName,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      className: className ?? this.className,
      assessmentType: assessmentType ?? this.assessmentType,
      assessmentName: assessmentName ?? this.assessmentName,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      isActive: isActive ?? this.isActive,
      remarks: remarks ?? this.remarks,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
