import 'package:flutter/material.dart';
import '../models/user.dart';

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

  @override
  void dispose() {
    _tcController.dispose();
    _pcController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Code: ${widget.subjectCode}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
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
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentRoll,
              dropdownColor: const Color(0xFF0F172A),
              decoration: const InputDecoration(
                labelText: 'Target Student Roll',
                labelStyle: TextStyle(color: Colors.white38),
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
            TextFormField(
              controller: _tcController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Theory Continuous (TC) /30',
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pcController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Practical Continuous (PC) /50',
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marks matrix pushed successfully.'),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.all(14),
              ),
              child: const Text(
                'Publish Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
