// =============================================================================
// lib/views/teacher/marks_uploader_view.dart
// Uploader Form for Theory Continuous (TC) and Practical Continuous (PC) Marks.
// Features:
//   • Dropdown selector for targeting student rolls
//   • Form fields for entering TC (/30) and PC (/50) marks
//   • Real-time tabular data matrix showing uploaded history
// =============================================================================

import 'package:flutter/material.dart';
import '../../models/user.dart';

class MarksUploaderView extends StatefulWidget {
  final AppUser teacher;
  final String subjectCode;
  final String subjectName;
  final int semester;

  const MarksUploaderView({
    super.key,
    required this.teacher,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
  });

  @override
  State<MarksUploaderView> createState() => _MarksUploaderViewState();
}

class _MarksUploaderViewState extends State<MarksUploaderView> {
  final _formKey = GlobalKey<FormState>();
  final _tcController = TextEditingController();
  final _pcController = TextEditingController();
  String _selectedStudentRoll = '508412';

  // Local storage cache simulation
  final List<Map<String, String>> _uploadedHistory = [
    {'roll': '508401', 'name': 'Mohammed Akash', 'tc': '24/30', 'pc': '44/50'},
    {'roll': '508402', 'name': 'Nasrin Akter', 'tc': '22/30', 'pc': '42/50'},
    {'roll': '508403', 'name': 'Sumaiya Khan', 'tc': '27/30', 'pc': '48/50'},
  ];

  @override
  void dispose() {
    _tcController.dispose();
    _pcController.dispose();
    super.dispose();
  }

  void _publishEntry() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _uploadedHistory.add({
          'roll': _selectedStudentRoll,
          'name': _selectedStudentRoll == '508412' ? 'Tarek Molla' : 'External Roll',
          'tc': '${_tcController.text}/30',
          'pc': '${_pcController.text}/50',
        });
        _tcController.clear();
        _pcController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks successfully pushed to administrative records.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subjectName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Code: ${widget.subjectCode}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semester Block: ${widget.semester}th Semester',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dropdown Roll Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentRoll,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Target Student Roll',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withAlpha(5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
              items: ['508401', '508402', '508403', '508412']
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        'Roll: $r',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedStudentRoll = val!),
            ),
            const SizedBox(height: 16),

            // TC Marks
            TextFormField(
              controller: _tcController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter TC marks';
                final marks = int.tryParse(val);
                if (marks == null || marks < 0 || marks > 30) return 'Enter value between 0 and 30';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Theory Continuous (TC) /30',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withAlpha(5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PC Marks
            TextFormField(
              controller: _pcController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter PC marks';
                final marks = int.tryParse(val);
                if (marks == null || marks < 0 || marks > 50) return 'Enter value between 0 and 50';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Practical Continuous (PC) /50',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withAlpha(5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Publish CTA Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _publishEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Publish Entry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // History Matrix Section
            const Text(
              "Recent Upload Ledger History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryTable(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.0),
        },
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            children: const [
              Padding(padding: EdgeInsets.all(12.0), child: Text("Roll", style: TextStyle(color: Color(0xFF67E8F9), fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(12.0), child: Text("Student Name", style: TextStyle(color: Color(0xFF67E8F9), fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(12.0), child: Text("TC", style: TextStyle(color: Color(0xFF67E8F9), fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(12.0), child: Text("PC", style: TextStyle(color: Color(0xFF67E8F9), fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          // Table Body List
          ..._uploadedHistory.map((item) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(6), width: 0.8)),
              ),
              children: [
                Padding(padding: const EdgeInsets.all(12.0), child: Text(item['roll']!, style: const TextStyle(color: Colors.white, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12.0), child: Text(item['name']!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.all(12.0), child: Text(item['tc']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12.0), child: Text(item['pc']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            );
          }),
        ],
      ),
    );
  }
}
