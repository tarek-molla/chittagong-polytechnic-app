// lib/models/department.dart

enum Department {
  cst('CST', 'Computer Science & Technology'),
  civil('CIVIL', 'Civil Technology'),
  electrical('EE', 'Electrical Engineering'),
  mechanical('ME', 'Mechanical Engineering'),
  electronics('ECT', 'Electronics & Communication Technology');

  final String shortCode;
  final String fullName;

  const Department(this.shortCode, this.fullName);

  static Department fromShortCode(String code) {
    return Department.values.firstWhere(
      (d) => d.shortCode == code,
      orElse: () => Department.cst,
    );
  }
}
