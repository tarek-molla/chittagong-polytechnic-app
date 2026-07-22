import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

// =============================================================================
// COMMON FROSTED GLASS SHEET CONTAINER
// =============================================================================
class _BaseAdminSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _BaseAdminSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withOpacity(0.4)),
                        ),
                        child: Icon(icon, color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. ROUTINE & SLOT OVERRIDE SHEET
// =============================================================================
class RoutineOverrideSheet extends StatefulWidget {
  const RoutineOverrideSheet({super.key});

  @override
  State<RoutineOverrideSheet> createState() => _RoutineOverrideSheetState();
}

class _RoutineOverrideSheetState extends State<RoutineOverrideSheet> {
  final _formKey = GlobalKey<FormState>();
  String _department = 'CST';
  int _semester = 6;
  String _subject = '';
  String _room = '';
  String _status = 'SWAPPED';
  bool _isLoading = false;

  Future<void> _submitOverride() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await SupabaseService.client.from('class_overrides').upsert({
        'department': _department,
        'semester': _semester,
        'subject_name': _subject,
        'room': _room,
        'status': _status,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine override pushed live!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseAdminSheet(
      title: "Routine & Slot Override",
      subtitle: "Update live classroom slots or cancel sessions",
      icon: Icons.calendar_month_rounded,
      accentColor: const Color(0xFF3B82F6),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Subject Name", (v) => _subject = v ?? ''),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField("Room No (e.g. 321)", (v) => _room = v ?? '')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Geist'),
                      decoration: _inputDecoration("Status"),
                      items: ['NORMAL', 'SWAPPED', 'CANCELED']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSubmitButton("Push Override", _submitOverride, _isLoading, const Color(0xFF3B82F6)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. ASSESSMENT MARKS INGESTION SHEET
// =============================================================================
class AssessmentMarksSheet extends StatefulWidget {
  const AssessmentMarksSheet({super.key});

  @override
  State<AssessmentMarksSheet> createState() => _AssessmentMarksSheetState();
}

class _AssessmentMarksSheetState extends State<AssessmentMarksSheet> {
  final _formKey = GlobalKey<FormState>();
  String _rollNumber = '';
  String _subject = '';
  String _assessmentName = 'Quiz 1';
  double _obtainedMarks = 0;
  double _totalMarks = 20;
  bool _isLoading = false;

  Future<void> _submitMarks() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await SupabaseService.client.from('assessments').insert({
        'roll_number': _rollNumber,
        'subject_name': _subject,
        'assessment_name': _assessmentName,
        'obtained_marks': _obtainedMarks,
        'total_marks': _totalMarks,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment record saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseAdminSheet(
      title: "Assessments Marks Ingestion",
      subtitle: "Ingest continuous assessment TC/PC marks for student",
      icon: Icons.analytics_rounded,
      accentColor: const Color(0xFFA855F7),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Student Roll Number", (v) => _rollNumber = v ?? '', isNum: true),
              const SizedBox(height: 12),
              _buildTextField("Subject Name", (v) => _subject = v ?? ''),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField("Obtained Marks", (v) => _obtainedMarks = double.tryParse(v ?? '') ?? 0, isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField("Total Marks", (v) => _totalMarks = double.tryParse(v ?? '') ?? 20, isNum: true)),
                ],
              ),
              const SizedBox(height: 20),
              _buildSubmitButton("Commit Marks", _submitMarks, _isLoading, const Color(0xFFA855F7)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. ATTENDANCE BATCH LOGGER SHEET
// =============================================================================
class AttendanceLoggerSheet extends StatefulWidget {
  const AttendanceLoggerSheet({super.key});

  @override
  State<AttendanceLoggerSheet> createState() => _AttendanceLoggerSheetState();
}

class _AttendanceLoggerSheetState extends State<AttendanceLoggerSheet> {
  final _formKey = GlobalKey<FormState>();
  String _rollNumber = '';
  String _subject = '';
  int _addPresent = 1;
  int _addTotal = 1;
  bool _isLoading = false;

  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final existing = await SupabaseService.client
          .from('attendance')
          .select()
          .eq('roll_number', _rollNumber)
          .eq('subject_name', _subject)
          .maybeSingle();

      int currentPresent = existing != null ? (existing['present_classes'] ?? 0) : 0;
      int currentTotal = existing != null ? (existing['total_classes'] ?? 0) : 0;

      await SupabaseService.client.from('attendance').upsert({
        if (existing != null) 'id': existing['id'],
        'roll_number': _rollNumber,
        'subject_name': _subject,
        'present_classes': currentPresent + _addPresent,
        'total_classes': currentTotal + _addTotal,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance records updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseAdminSheet(
      title: "Attendance Batch Logger",
      subtitle: "Increment student present/total class tallies",
      icon: Icons.fact_check_rounded,
      accentColor: const Color(0xFF10B981),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Student Roll Number", (v) => _rollNumber = v ?? '', isNum: true),
              const SizedBox(height: 12),
              _buildTextField("Subject Name", (v) => _subject = v ?? ''),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField("Add Present Classes", (v) => _addPresent = int.tryParse(v ?? '') ?? 1, isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField("Add Total Classes", (v) => _addTotal = int.tryParse(v ?? '') ?? 1, isNum: true)),
                ],
              ),
              const SizedBox(height: 20),
              _buildSubmitButton("Update Attendance", _submitAttendance, _isLoading, const Color(0xFF10B981)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 4. ADMIT CLEARANCE REGULATOR SHEET
// =============================================================================
class AdmitClearanceSheet extends StatefulWidget {
  const AdmitClearanceSheet({super.key});

  @override
  State<AdmitClearanceSheet> createState() => _AdmitClearanceSheetState();
}

class _AdmitClearanceSheetState extends State<AdmitClearanceSheet> {
  final _formKey = GlobalKey<FormState>();
  String _rollNumber = '';
  String _term = 'Semester Final';
  bool _isCleared = true;
  bool _isLoading = false;

  Future<void> _submitClearance() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await SupabaseService.client.from('clearances').upsert({
        'roll_number': _rollNumber,
        'term': _term,
        'is_cleared': _isCleared,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clearance set to ${_isCleared ? "CLEARED" : "LOCKED"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseAdminSheet(
      title: "Admit Card Clearance Regulator",
      subtitle: "Grant or restrict exam token access for student",
      icon: Icons.verified_user_rounded,
      accentColor: const Color(0xFFF59E0B),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Student Roll Number", (v) => _rollNumber = v ?? '', isNum: true),
              const SizedBox(height: 12),
              _buildTextField("Exam Term (e.g., Semester Final)", (v) => _term = v ?? 'Semester Final'),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isCleared,
                activeColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFFEF4444),
                title: const Text("Approve Admit Card Access", style: TextStyle(color: Colors.white, fontFamily: 'Geist')),
                subtitle: Text(_isCleared ? "Student can view/download card" : "Access is locked for student", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                onChanged: (v) => setState(() => _isCleared = v),
              ),
              const SizedBox(height: 20),
              _buildSubmitButton("Commit Clearance State", _submitClearance, _isLoading, const Color(0xFFF59E0B)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HELPER UI BUILDERS
// =============================================================================
Widget _buildTextField(String label, FormFieldSetter<String> onSaved, {bool isNum = false}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white, fontFamily: 'Geist'),
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: _inputDecoration(label),
    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    onSaved: onSaved,
  );
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Geist', fontSize: 12),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
  );
}

Widget _buildSubmitButton(String text, VoidCallback onPressed, bool isLoading, Color color) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Geist')),
    ),
  );
}
