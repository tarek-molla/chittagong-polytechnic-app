class AssessmentModel {
  final String id;
  final String rollNumber;
  final String studentName;
  final String department;
  final int semester;
  final String subjectName;
  final String assessmentType;
  final String assessmentName;
  final double obtainedMarks;
  final double totalMarks;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssessmentModel({
    required this.id,
    required this.rollNumber,
    required this.studentName,
    required this.department,
    required this.semester,
    required this.subjectName,
    required this.assessmentType,
    required this.assessmentName,
    required this.obtainedMarks,
    required this.totalMarks,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as String,
      rollNumber: json['roll_number'] as String,
      studentName: json['student_name'] as String,
      department: json['department'] as String,
      semester: json['semester'] as int,
      subjectName: json['subject_name'] as String,
      assessmentType: json['assessment_type'] as String,
      assessmentName: json['assessment_name'] as String,
      obtainedMarks: (json['obtained_marks'] as num).toDouble(),
      totalMarks: (json['total_marks'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_number': rollNumber,
      'student_name': studentName,
      'department': department,
      'semester': semester,
      'subject_name': subjectName,
      'assessment_type': assessmentType,
      'assessment_name': assessmentName,
      'obtained_marks': obtainedMarks,
      'total_marks': totalMarks,
      'is_active': isActive,
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

  String get totalDisplay => '${obtainedMarks.toStringAsFixed(0)}/${totalMarks.toStringAsFixed(0)}';
}
